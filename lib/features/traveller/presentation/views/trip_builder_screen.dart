import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/wayhunter_palette.dart';
import '../../domain/entities/traveller_map_data.dart';
import '../viewmodels/traveller_view_model.dart';
import '../widgets/trip_location_picker.dart';
import '../widgets/trip_route_map.dart';

const _cyan = WayhunterPalette.travellerCyan;
const _mint = Color(0xFF12E6A4);
const _purple = Color(0xFFAB40E8);
final _money = NumberFormat.decimalPattern('en');

/// Wayhunter Create Trip — approved two-screen visual flow.
///
/// Step 1: trip name + two-month date-range calendar.
/// Step 2: real Traveller route picker/map + existing suggested-plan,
/// AI, friends and submit flows. It intentionally uses the existing
/// Traveller ViewModel and routes; it is NOT a detached demo screen.
class TripBuilderScreen extends ConsumerStatefulWidget {
  const TripBuilderScreen({super.key});

  @override
  ConsumerState<TripBuilderScreen> createState() => _TripBuilderScreenState();
}

class _TripBuilderScreenState extends ConsumerState<TripBuilderScreen> {
  final _name = TextEditingController();
  String? _pendingPlace;
  bool _submitting = false;
  int _step = 1;
  bool _datesInitialized = false;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  late DateTime _visibleMonth;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _message(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  void _feedback() {
    final error = ref.read(travellerViewModelProvider).error;
    if (error != null) _message(error);
  }

  DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  bool _sameDay(DateTime? a, DateTime b) =>
      a != null && a.year == b.year && a.month == b.month && a.day == b.day;

  void _chooseDay(DateTime day) {
    final today = _dateOnly(DateTime.now());
    if (day.isBefore(today)) {
      _message('Choose today or a future trip date.');
      return;
    }
    setState(() {
      if (_rangeStart == null || _rangeEnd != null) {
        _rangeStart = day;
        _rangeEnd = null;
      } else if (day.isBefore(_rangeStart!)) {
        _rangeEnd = _rangeStart;
        _rangeStart = day;
      } else {
        _rangeEnd = day;
      }
    });
  }

  void _continueToRoute() {
    FocusScope.of(context).unfocus();
    if (_name.text.trim().length < 3) {
      _message('Enter a trip name with at least 3 characters.');
      return;
    }
    if (_rangeStart == null || _rangeEnd == null) {
      _message('Select both your start date and end date.');
      return;
    }
    ref
        .read(travellerViewModelProvider.notifier)
        .setDates(_rangeStart!, _rangeEnd!);
    setState(() => _step = 2);
  }

  void _back() {
    if (_step == 2) {
      setState(() => _step = 1);
    } else if (context.canPop()) {
      context.pop();
    } else {
      context.go('/traveller');
    }
  }

  Future<void> _location(String role, {int? index}) async {
    FocusScope.of(context).unfocus();
    final name = await showTripLocationPicker(context, title: role);
    if (name == null || !mounted) return;
    final vm = ref.read(travellerViewModelProvider.notifier);
    if (index != null) {
      vm.changeStop(index, name);
    } else if (role == 'Start Location') {
      vm.setStartLocation(name);
    } else if (role == 'End Location') {
      vm.setEndLocation(name);
    } else {
      setState(() => _pendingPlace = name);
    }
    _feedback();
  }

  Future<void> _addStop() async {
    var name = _pendingPlace;
    name ??= await showTripLocationPicker(context, title: 'Add Place');
    if (name == null || !mounted) return;
    if (ref
        .read(travellerViewModelProvider.notifier)
        .addIntermediateStop(name)) {
      setState(() => _pendingPlace = null);
    } else {
      setState(() => _pendingPlace = name);
      _feedback();
    }
  }

  Future<bool> _confirm(String title, String message, String action) async =>
      await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(action),
            ),
          ],
        ),
      ) ??
      false;

  Future<void> _idea(TripSuggestion idea, {required bool edit}) async {
    final draft = ref.read(travellerViewModelProvider).draft;
    if ((draft.stops.isNotEmpty ||
            draft.budget > 0 ||
            draft.title.trim().isNotEmpty ||
            draft.people > 1) &&
        !await _confirm(
          edit ? 'Edit suggested idea?' : 'Use suggested idea?',
          'Replace the current route and travel details? Your trip name and dates will be kept.',
          edit ? 'Edit Idea' : 'Use Idea',
        )) {
      return;
    }
    if (!mounted) return;
    if (edit) {
      await showTripRouteEditor(
        context,
        ref,
        title: 'Edit Idea',
        suggestion: idea,
      );
    } else {
      ref.read(travellerViewModelProvider.notifier).useSuggestion(idea);
    }
    if (mounted) setState(() => _pendingPlace = null);
  }

  Future<void> _ai() async {
    FocusScope.of(context).unfocus();
    if (!await _confirm(
          'Prepare an AI trip plan?',
          'Use your route, dates, budget and people count for a local itinerary. Missing details will be filled from a suggested plan.',
          'Generate plan',
        ) ||
        !mounted)
      return;
    if (ref.read(travellerViewModelProvider.notifier).generateAi()) {
      context.go('/traveller/ai');
    } else {
      _feedback();
    }
  }

  Future<void> _selectFriends() async {
    FocusScope.of(context).unfocus();
    final current = ref.read(travellerViewModelProvider).draft.friendIds;
    final selected = await context.push<List<String>>(
      '/traveller/pick-friends',
      extra: List<String>.of(current),
    );
    if (!mounted || selected == null) return;
    final vm = ref.read(travellerViewModelProvider.notifier);
    final existingDraft = ref.read(travellerViewModelProvider).draft;
    vm.updateDraft(
      existingDraft.copyWith(friendIds: List.unmodifiable(selected)),
    );
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final vm = ref.read(travellerViewModelProvider.notifier);
    if (!vm.saveDraft()) {
      _feedback();
      return;
    }
    setState(() => _submitting = true);
    await vm.persistenceSettled;
    if (!mounted) return;
    setState(() => _submitting = false);
    context.go('/traveller/plans');
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(travellerViewModelProvider);
    final draft = state.draft;
    final vm = ref.read(travellerViewModelProvider.notifier);

    if (!_datesInitialized) {
      _datesInitialized = true;
      _rangeStart = draft.startDate == null
          ? null
          : _dateOnly(draft.startDate!);
      _rangeEnd = draft.endDate == null ? null : _dateOnly(draft.endDate!);
      final initial = draft.startDate ?? DateTime.now();
      _visibleMonth = DateTime(initial.year, initial.month);
      // Returning from a copied Suggested/Previous Plan opens the route
      // review instead of losing the selected route on the date screen.
      if (draft.method == TripMethod.previous &&
          draft.stops.length >= 2 &&
          draft.startDate != null &&
          draft.endDate != null) {
        _step = 2;
      }
    }
    if (_name.text != draft.title) {
      _name.value = TextEditingValue(
        text: draft.title,
        selection: TextSelection.collapsed(offset: draft.title.length),
      );
    }
    final stops = draft.stops;
    final markers = <TravellerMapMarker>[
      for (var i = 0; i < stops.length; i++)
        if (state.positionFor(stops[i]) case final point?)
          TravellerMapMarker(id: 'stop-$i', name: stops[i], position: point),
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _back();
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          ImageFiltered(
            imageFilter: ui.ImageFilter.blur(sigmaX: 3, sigmaY: 3),
            child: Image.asset(
              AppAssets.travellerSoftBackground,
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              excludeFromSemantics: true,
            ),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xB5001527), Color(0xCE00131F)],
              ),
            ),
          ),
          Scaffold(
            backgroundColor: Colors.transparent,
            resizeToAvoidBottomInset: true,
            bottomNavigationBar: _step == 2 ? const _TripNavigation() : null,
            body: SafeArea(
              bottom: _step == 1,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 540),
                  child: Column(
                    children: [
                      _header(),
                      Expanded(
                        child: _step == 1
                            ? _stepOne(vm)
                            : _stepTwo(
                                state,
                                draft.friendIds.length,
                                stops,
                                markers,
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _header() => Padding(
    padding: const EdgeInsets.fromLTRB(18, 12, 18, 7),
    child: Column(
      children: [
        Row(
          children: [
            IconButton.filledTonal(
              tooltip: _step == 1 ? 'Back to Traveller' : 'Back to dates',
              onPressed: _back,
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xAA003448),
                side: const BorderSide(color: _cyan),
              ),
            ),
            const Expanded(
              child: Center(
                child: Text(
                  'WAYHUNTER',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                    letterSpacing: 2.5,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 48),
          ],
        ),
        const SizedBox(height: 7),
        Row(
          children: [
            Text(
              'Step $_step of 2',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: _step / 2,
                  minHeight: 7,
                  backgroundColor: const Color(0x606E9DAB),
                  valueColor: const AlwaysStoppedAnimation<Color>(_cyan),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _stepOne(TravellerViewModel vm) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _ScreenHeading('Create New Trip'),
                const SizedBox(height: 18),
                _GlassSection(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Trip Name',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        key: const ValueKey('trip-title-step1'),
                        controller: _name,
                        onChanged: vm.setTitle,
                        textCapitalization: TextCapitalization.words,
                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.white,
                        ),
                        decoration: _fieldDecoration(
                          'Enter trip name (e.g., Northern Explorer)',
                          Icons.edit_outlined,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _GlassSection(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _SectionTitle(
                        Icons.calendar_month_outlined,
                        'Select Dates',
                      ),
                      const SizedBox(height: 13),
                      const Divider(color: Color(0x446AE9FF), height: 1),
                      const SizedBox(height: 16),
                      _calendarHeading(),
                      const SizedBox(height: 12),
                      _monthCalendar(_visibleMonth),
                      const SizedBox(height: 22),
                      Text(
                        DateFormat('MMMM yyyy').format(
                          DateTime(_visibleMonth.year, _visibleMonth.month + 1),
                        ),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _monthCalendar(
                        DateTime(_visibleMonth.year, _visibleMonth.month + 1),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 9, 16, 15),
          child: Column(
            children: [
              _GlassSection(
                padding: const EdgeInsets.symmetric(
                  vertical: 11,
                  horizontal: 15,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.date_range, color: _cyan, size: 22),
                    const SizedBox(width: 9),
                    Flexible(
                      child: Text(
                        _rangeLabel(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 11),
              _GradientButton(
                key: const ValueKey('trip-continue'),
                text: 'Continue',
                icon: Icons.arrow_forward_rounded,
                onPressed: _continueToRoute,
                height: 54,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _calendarHeading() => Row(
    children: [
      _calendarArrow(
        Icons.chevron_left,
        () => setState(
          () => _visibleMonth = DateTime(
            _visibleMonth.year,
            _visibleMonth.month - 1,
          ),
        ),
      ),
      Expanded(
        child: Text(
          DateFormat('MMMM yyyy').format(_visibleMonth),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
      ),
      _calendarArrow(
        Icons.chevron_right,
        () => setState(
          () => _visibleMonth = DateTime(
            _visibleMonth.year,
            _visibleMonth.month + 1,
          ),
        ),
      ),
    ],
  );

  Widget _calendarArrow(IconData icon, VoidCallback onTap) =>
      IconButton.filledTonal(
        onPressed: onTap,
        icon: Icon(icon, color: Colors.white),
        style: IconButton.styleFrom(backgroundColor: const Color(0x88234D61)),
      );

  Widget _monthCalendar(DateTime month) {
    const names = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    final startOffset = DateTime(month.year, month.month, 1).weekday % 7;
    final count = DateUtils.getDaysInMonth(month.year, month.month);
    final total = ((startOffset + count + 6) ~/ 7) * 7;
    final today = _dateOnly(DateTime.now());
    return Column(
      children: [
        Row(
          children: [
            for (final name in names)
              Expanded(
                child: Center(
                  child: Text(
                    name,
                    style: const TextStyle(
                      color: Color(0xFFBACBD6),
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 7),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 3,
            crossAxisSpacing: 3,
            childAspectRatio: 1,
          ),
          itemCount: total,
          itemBuilder: (context, index) {
            final number = index - startOffset + 1;
            if (number < 1 || number > count) return const SizedBox();
            final date = DateTime(month.year, month.month, number);
            final boundary =
                _sameDay(_rangeStart, date) || _sameDay(_rangeEnd, date);
            final middle =
                _rangeStart != null &&
                _rangeEnd != null &&
                date.isAfter(_rangeStart!) &&
                date.isBefore(_rangeEnd!);
            final past = date.isBefore(today);
            return Semantics(
              button: true,
              selected: boundary || middle,
              label: DateFormat('dd MMMM yyyy').format(date),
              child: InkWell(
                key: ValueKey('trip-date-${month.year}-${month.month}-$number'),
                onTap: past ? null : () => _chooseDay(date),
                borderRadius: BorderRadius.circular(99),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: boundary
                        ? _cyan
                        : middle
                        ? _cyan.withValues(alpha: .22)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(99),
                    border: _sameDay(today, date)
                        ? Border.all(color: _mint, width: 1.3)
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      '$number',
                      style: TextStyle(
                        color: past
                            ? Colors.white38
                            : boundary
                            ? const Color(0xFF002D3A)
                            : Colors.white,
                        fontWeight: boundary
                            ? FontWeight.w900
                            : FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  String _rangeLabel() {
    if (_rangeStart == null) return 'Select a start and end date';
    if (_rangeEnd == null) {
      return '${DateFormat('dd MMM yyyy').format(_rangeStart!)} · Choose end date';
    }
    final sameYear = _rangeStart!.year == _rangeEnd!.year;
    return '${DateFormat(sameYear ? 'dd MMM' : 'dd MMM yyyy').format(_rangeStart!)}'
        ' – ${DateFormat('dd MMM yyyy').format(_rangeEnd!)}';
  }

  Widget _stepTwo(
    TravellerState state,
    int friendCount,
    List<String> stops,
    List<TravellerMapMarker> markers,
  ) {
    return SingleChildScrollView(
      key: const PageStorageKey('create-trip-step2-scroll'),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _ScreenHeading('Create New Trip'),
          const SizedBox(height: 17),
          _GlassSection(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: _SectionTitle(
                        Icons.route_outlined,
                        'Route Builder',
                      ),
                    ),
                    IconButton(
                      key: const ValueKey('trip-edit-route'),
                      tooltip: 'Edit and reorder route',
                      onPressed: () => showTripRouteEditor(context, ref),
                      icon: const Icon(Icons.edit_road_outlined, color: _cyan),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                LayoutBuilder(
                  builder: (context, box) {
                    // Real map is preserved; use a compact two-column layout on phones.
                    final mapWidth = math.max(112.0, box.maxWidth * .43);
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              _RoutePicker(
                                key: const ValueKey('trip-start-location'),
                                label: stops.isEmpty
                                    ? 'Start Place'
                                    : stops.first,
                                icon: Icons.place_outlined,
                                onTap: () => _location('Start Location'),
                              ),
                              const SizedBox(height: 8),
                              _RoutePicker(
                                key: const ValueKey('trip-add-place'),
                                label: _pendingPlace ?? 'Add Place',
                                icon: Icons.add_location_alt_outlined,
                                onTap: () => _location('Add Place'),
                              ),
                              const SizedBox(height: 8),
                              _RoutePicker(
                                key: const ValueKey('trip-end-location'),
                                label: stops.length < 2
                                    ? 'End Place'
                                    : stops.last,
                                icon: Icons.flag_outlined,
                                onTap: () => _location('End Location'),
                              ),
                              const SizedBox(height: 9),
                              _GradientButton(
                                key: const ValueKey('trip-add-stop'),
                                text: 'Add Stop',
                                icon: Icons.add_rounded,
                                onPressed: _addStop,
                                height: 38,
                                fontSize: 13,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          width: mapWidth,
                          height: 202,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: TripRouteMap(stops: markers),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Select your route stops',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFFC9E4EC),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    OutlinedButton.icon(
                      key: const ValueKey('trip-pick-on-map'),
                      onPressed: () => _location('Add Place'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 11),
                        side: const BorderSide(color: _cyan),
                        minimumSize: const Size(0, 38),
                        shape: const StadiumBorder(),
                      ),
                      icon: const Icon(Icons.map_outlined, size: 17),
                      label: const Text(
                        'Pick on map',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                if (stops.length > 2) ...[
                  const SizedBox(height: 3),
                  Text(
                    '${stops.length - 2} stop(s) added · Tap edit to reorder',
                    style: const TextStyle(
                      color: Color(0xFFBDDCED),
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          _GlassSection(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: _SectionTitle(
                        Icons.lightbulb_outline,
                        'Suggested Trip Plans',
                      ),
                    ),
                    IconButton(
                      key: const ValueKey('trip-previous-plans'),
                      tooltip: 'Previous traveller plans',
                      onPressed: () => context.go('/traveller/reuse'),
                      icon: const Icon(Icons.history_rounded, color: _cyan),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                for (var i = 0; i < state.catalog.suggestions.length; i++) ...[
                  if (i > 0)
                    const Divider(color: Color(0x446AE9FF), height: 17),
                  _SuggestionTile(
                    idea: state.catalog.suggestions[i],
                    use: () => context.push(
                      '/traveller/suggestion/${Uri.encodeComponent(state.catalog.suggestions[i].id)}',
                    ),
                    edit: () => _idea(state.catalog.suggestions[i], edit: true),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: _GradientButton(
                  key: const ValueKey('trip-ai'),
                  text: 'AI Trip Plan',
                  icon: Icons.auto_awesome_outlined,
                  gradient: const [_purple, Color(0xFF0D75CF), _mint],
                  height: 47,
                  fontSize: 13,
                  onPressed: _ai,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _GradientButton(
                  key: const ValueKey('trip-add-friends'),
                  text: friendCount == 0
                      ? 'Add Friends'
                      : 'Friends ($friendCount)',
                  icon: Icons.group_add_outlined,
                  gradient: const [Color(0xFF00669E), _cyan, _mint],
                  height: 47,
                  fontSize: 13,
                  onPressed: _selectFriends,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 270),
              child: _GradientButton(
                key: const ValueKey('trip-submit'),
                text: _submitting ? 'Saving…' : 'Submit Trip',
                icon: Icons.send_outlined,
                onPressed: _submitting ? null : _submit,
                height: 50,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

InputDecoration _fieldDecoration(String hint, IconData icon) => InputDecoration(
  hintText: hint,
  hintMaxLines: 1,
  hintStyle: const TextStyle(color: Color(0xFFB8D5E1), fontSize: 13),
  filled: true,
  fillColor: const Color(0x88305C70),
  isDense: true,
  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
  prefixIcon: Icon(icon, color: const Color(0xFFCCF9FF), size: 21),
  prefixIconConstraints: const BoxConstraints(minWidth: 42, minHeight: 45),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(15),
    borderSide: const BorderSide(color: Color(0xFF6EDFF2)),
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(15),
    borderSide: const BorderSide(color: Color(0xFF6EDFF2)),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(15),
    borderSide: const BorderSide(color: _cyan, width: 1.8),
  ),
);

class _ScreenHeading extends StatelessWidget {
  const _ScreenHeading(this.title);
  final String title;

  @override
  Widget build(BuildContext context) => Text(
    title,
    style: const TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.w900,
      fontSize: 29,
      letterSpacing: -.4,
    ),
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.icon, this.title);
  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, color: _cyan, size: 25),
      const SizedBox(width: 9),
      Flexible(
        child: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
      ),
    ],
  );
}

class _GlassSection extends StatelessWidget {
  const _GlassSection({
    required this.child,
    this.padding = const EdgeInsets.all(14),
  });
  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(22),
    child: BackdropFilter(
      filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xE2044554), Color(0xE5031D2B)],
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFF56E9FF), width: 1.2),
          boxShadow: [
            BoxShadow(color: _cyan.withValues(alpha: .20), blurRadius: 14),
          ],
        ),
        child: child,
      ),
    ),
  );
}

class _RoutePicker extends StatelessWidget {
  const _RoutePicker({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: const Color(0xB1124354),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(13),
      side: const BorderSide(color: Color(0xFF72D3E5)),
    ),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(13),
      child: SizedBox(
        height: 47,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, color: Colors.white),
                ),
              ),
              const Icon(Icons.expand_more, color: Colors.white, size: 16),
            ],
          ),
        ),
      ),
    ),
  );
}

class _GradientButton extends StatelessWidget {
  const _GradientButton({
    super.key,
    required this.text,
    required this.icon,
    required this.onPressed,
    this.height = 48,
    this.fontSize = 15,
    this.gradient = const [Color(0xFF00BDE7), Color(0xFF00D8C1), _mint],
  });
  final String text;
  final IconData icon;
  final VoidCallback? onPressed;
  final double height, fontSize;
  final List<Color> gradient;

  @override
  Widget build(BuildContext context) => Container(
    height: height,
    decoration: BoxDecoration(
      gradient: LinearGradient(colors: gradient),
      borderRadius: BorderRadius.circular(40),
      border: Border.all(color: const Color(0xFFC5FFFF), width: 1),
      boxShadow: [
        BoxShadow(color: _cyan.withValues(alpha: .25), blurRadius: 9),
      ],
    ),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(40),
        onTap: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: fontSize + 6, color: Colors.white),
            const SizedBox(width: 7),
            Flexible(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _SuggestionTile extends StatelessWidget {
  const _SuggestionTile({
    required this.idea,
    required this.use,
    required this.edit,
  });
  final TripSuggestion idea;
  final VoidCallback use, edit;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.asset(
          idea.thumbnailAsset,
          width: 60,
          height: 83,
          fit: BoxFit.cover,
        ),
      ),
      const SizedBox(width: 9),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              idea.plan.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              'by ${idea.author}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: Color(0xFFC9E4EB)),
            ),
            const SizedBox(height: 5),
            Text(
              'LKR ${_money.format(idea.plan.budget)} · '
              '${idea.plan.vehicle} · ${idea.plan.people} People',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10.5, color: Color(0xFFDBF2F8)),
            ),
          ],
        ),
      ),
      const SizedBox(width: 7),
      SizedBox(
        width: 89,
        child: Column(
          children: [
            SizedBox(
              height: 35,
              child: _GradientButton(
                key: ValueKey('use-${idea.id}'),
                text: 'Use Plan',
                icon: Icons.arrow_forward_rounded,
                onPressed: use,
                fontSize: 10.5,
                height: 35,
              ),
            ),
            TextButton.icon(
              key: ValueKey('edit-${idea.id}'),
              onPressed: edit,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 32),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.edit_outlined, size: 13),
              label: const Text('Edit Plan', style: TextStyle(fontSize: 10.5)),
            ),
          ],
        ),
      ),
    ],
  );
}

class _TripNavigation extends StatelessWidget {
  const _TripNavigation();

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    maintainBottomViewPadding: true,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: NavigationBar(
          height: 68,
          selectedIndex: 1,
          backgroundColor: const Color(0xE8071D2A),
          indicatorColor: _cyan.withValues(alpha: .22),
          onDestinationSelected: (i) => context.go(switch (i) {
            0 => '/home',
            1 => '/traveller',
            2 => '/leaderboard',
            _ => '/profile',
          }),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              label: 'Home',
            ),
            NavigationDestination(icon: Icon(Icons.hiking), label: 'Traveller'),
            NavigationDestination(
              icon: Icon(Icons.emoji_events_outlined),
              label: 'Leaderboard',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              label: 'Profile',
            ),
          ],
        ),
      ),
    ),
  );
}
