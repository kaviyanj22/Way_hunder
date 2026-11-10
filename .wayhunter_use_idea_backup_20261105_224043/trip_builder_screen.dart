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
final _money = NumberFormat.decimalPattern('en');

class TripBuilderScreen extends ConsumerStatefulWidget {
  const TripBuilderScreen({super.key});
  @override
  ConsumerState<TripBuilderScreen> createState() => _TripBuilderScreenState();
}

class _TripBuilderScreenState extends ConsumerState<TripBuilderScreen> {
  final _name = TextEditingController();
  String? _pendingPlace;
  bool _submitting = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _feedback() {
    final error = ref.read(travellerViewModelProvider).error;
    if (error == null) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(error), behavior: SnackBarBehavior.floating),
      );
  }

  Future<void> _date({required bool start}) async {
    FocusScope.of(context).unfocus();
    final draft = ref.read(travellerViewModelProvider).draft;
    final now = DateTime.now();
    final first = !start && draft.startDate != null
        ? draft.startDate!
        : DateTime(now.year - 10);
    final last = DateTime(math.max(now.year + 10, first.year + 1), 12, 31);
    var initial =
        (start ? draft.startDate : draft.endDate) ?? draft.startDate ?? now;
    if (initial.isBefore(first)) initial = first;
    if (initial.isAfter(last)) initial = last;
    final selected = await showDatePicker(
      context: context,
      helpText: start ? 'Select start date' : 'Select end date',
      initialDate: initial,
      firstDate: first,
      lastDate: last,
    );
    if (selected == null || !mounted) return;
    final vm = ref.read(travellerViewModelProvider.notifier);
    if (start) {
      vm.setStartDate(selected);
    } else {
      vm.setEndDate(selected);
    }
    _feedback();
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
        !mounted) {
      return;
    }
    if (ref.read(travellerViewModelProvider.notifier).generateAi()) {
      context.go('/traveller/ai');
    } else {
      _feedback();
    }
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

  Future<void> _number({required bool people}) async {
    final state = ref.read(travellerViewModelProvider);
    final value = await showDialog<num>(
      context: context,
      builder: (_) => _NumberDialog(
        people: people,
        initial: people ? state.draft.people : state.draft.budget,
        presets: people ? const [] : state.catalog.budgetOptions,
      ),
    );
    if (value == null || !mounted) return;
    final vm = ref.read(travellerViewModelProvider.notifier);
    final current = ref.read(travellerViewModelProvider).draft;
    vm.updateDraft(
      people
          ? current.copyWith(people: value.toInt())
          : current.copyWith(budget: value.toDouble()),
    );
  }

  Future<void> _vehicle() async {
    final state = ref.read(travellerViewModelProvider);
    final selected = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Select vehicle'),
        children: [
          for (final vehicle in state.catalog.vehicles)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, vehicle),
              child: ListTile(
                dense: true,
                title: Text(vehicle),
                trailing: state.draft.vehicle == vehicle
                    ? const Icon(Icons.check, color: _cyan)
                    : null,
              ),
            ),
        ],
      ),
    );
    if (selected == null || !mounted) return;
    final vm = ref.read(travellerViewModelProvider.notifier);
    vm.updateDraft(
      ref.read(travellerViewModelProvider).draft.copyWith(vehicle: selected),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(travellerViewModelProvider);
    final draft = state.draft;
    final vm = ref.read(travellerViewModelProvider.notifier);
    if (_name.text != draft.title) {
      _name.value = TextEditingValue(
        text: draft.title,
        selection: TextSelection.collapsed(offset: draft.title.length),
      );
    }
    final stops = draft.stops;
    final markers = [
      for (var i = 0; i < stops.length; i++)
        if (state.positionFor(stops[i]) case final point?)
          TravellerMapMarker(id: 'stop-$i', name: stops[i], position: point),
    ];
    void back() {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/traveller');
      }
    }

    return PopScope(
      canPop: context.canPop(),
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) context.go('/traveller');
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          ImageFiltered(
            imageFilter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Image.asset(
              AppAssets.homeBackground,
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
                colors: [Color(0x66000713), Color(0xBB000713)],
              ),
            ),
          ),
          Scaffold(
            backgroundColor: Colors.transparent,
            resizeToAvoidBottomInset: false,
            bottomNavigationBar: const _TripNavigation(),
            body: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 2, 12, 8),
                child: LayoutBuilder(
                  builder: (context, constraints) => Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: SizedBox(
                        width: math.max(
                          360,
                          math.min(460, constraints.maxWidth),
                        ),
                        height: 744,
                        child: MediaQuery.withClampedTextScaling(
                          maxScaleFactor: 1.25,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              SizedBox(
                                height: 58,
                                child: Column(
                                  children: [
                                    SizedBox(
                                      height: 28,
                                      child: Row(
                                        children: [
                                          IconButton(
                                            tooltip: 'Go back',
                                            padding: EdgeInsets.zero,
                                            constraints:
                                                const BoxConstraints.tightFor(
                                                  width: 32,
                                                  height: 28,
                                                ),
                                            onPressed: back,
                                            icon: const Icon(
                                              Icons.arrow_back_rounded,
                                              size: 22,
                                            ),
                                          ),
                                          const Expanded(
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.explore_outlined,
                                                  color: _cyan,
                                                  size: 23,
                                                ),
                                                SizedBox(width: 6),
                                                Text(
                                                  'WAYHUNTER',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w900,
                                                    letterSpacing: 2,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          IconButton(
                                            tooltip: 'Profile',
                                            padding: EdgeInsets.zero,
                                            constraints:
                                                const BoxConstraints.tightFor(
                                                  width: 32,
                                                  height: 28,
                                                ),
                                            onPressed: () =>
                                                context.push('/profile'),
                                            icon: const Icon(
                                              Icons.account_circle_outlined,
                                              size: 22,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Expanded(
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.add_road,
                                              color: _cyan,
                                              size: 24,
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              'Create New Trip',
                                              style: TextStyle(
                                                fontSize: 22,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 6),
                              _TripCard(
                                height: 126,
                                title: 'Trip Basics',
                                icon: Icons.assignment_outlined,
                                child: Column(
                                  children: [
                                    _LabeledRow(
                                      label: 'Trip Name',
                                      child: TextField(
                                        key: ValueKey(
                                          'trip-title-${draft.editingId}',
                                        ),
                                        controller: _name,
                                        onChanged: vm.setTitle,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.white,
                                        ),
                                        decoration: _input(
                                          'Enter trip name (e.g., Northern Explorer)',
                                          icon: Icons.edit_outlined,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    _LabeledRow(
                                      label: 'Start Date',
                                      child: _Selector(
                                        key: const ValueKey('trip-start-date'),
                                        label: draft.startDate == null
                                            ? 'Select start date'
                                            : DateFormat('dd MMM yyyy')
                                                  .format(draft.startDate!),
                                        icon: Icons.calendar_month_outlined,
                                        onTap: () => _date(start: true),
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    _LabeledRow(
                                      label: 'End Date',
                                      child: _Selector(
                                        key: const ValueKey('trip-end-date'),
                                        label: draft.endDate == null
                                            ? 'Select end date'
                                            : DateFormat('dd MMM yyyy')
                                                  .format(draft.endDate!),
                                        icon: Icons.calendar_month_outlined,
                                        onTap: () => _date(start: false),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              _TripCard(
                                height: 192,
                                title: 'Route Builder',
                                icon: Icons.route_outlined,
                                action: InkWell(
                                  key: const ValueKey('trip-edit-route'),
                                  onTap: () =>
                                      showTripRouteEditor(context, ref),
                                  child: const Tooltip(
                                    message: 'Edit and reorder route',
                                    child: Icon(
                                      Icons.edit_road,
                                      size: 19,
                                      color: _cyan,
                                    ),
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Expanded(
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              children: [
                                                _Selector(
                                                  key: const ValueKey(
                                                    'trip-start-location',
                                                  ),
                                                  label: stops.isEmpty
                                                      ? 'Start Location'
                                                      : stops.first,
                                                  icon: Icons.search,
                                                  onTap: () => _location(
                                                    'Start Location',
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                _Selector(
                                                  key: const ValueKey(
                                                    'trip-add-place',
                                                  ),
                                                  label:
                                                      _pendingPlace ??
                                                      'Add Place',
                                                  icon: Icons.search,
                                                  onTap: () =>
                                                      _location('Add Place'),
                                                ),
                                                const SizedBox(height: 4),
                                                SizedBox(
                                                  height: 28,
                                                  child: _GlowButton(
                                                    key: const ValueKey(
                                                      'trip-add-stop',
                                                    ),
                                                    label: 'Add Stop',
                                                    icon: Icons.add,
                                                    onPressed: _addStop,
                                                    small: true,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                _Selector(
                                                  key: const ValueKey(
                                                    'trip-end-location',
                                                  ),
                                                  label: stops.length < 2
                                                      ? 'End Location'
                                                      : stops.last,
                                                  icon: Icons.search,
                                                  onTap: () =>
                                                      _location('End Location'),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              child: TripRouteMap(
                                                stops: markers,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    SizedBox(
                                      height: 27,
                                      child: stops.isEmpty
                                          ? const Align(
                                              alignment: Alignment.centerLeft,
                                              child: Text(
                                                'Select your start and end locations',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Color(0xFFB6CDDA),
                                                ),
                                              ),
                                            )
                                          : Row(
                                              children: [
                                                for (
                                                  var i = 0;
                                                  i <
                                                      math.min(
                                                        stops.length,
                                                        stops.length > 4
                                                            ? 3
                                                            : 4,
                                                      );
                                                  i++
                                                ) ...[
                                                  if (i > 0)
                                                    const Icon(
                                                      Icons.chevron_right,
                                                      color: _cyan,
                                                      size: 12,
                                                    ),
                                                  Expanded(
                                                    child: _StopChip(
                                                      index: i,
                                                      name: stops[i],
                                                      edit: () => _location(
                                                        'Edit stop ${i + 1}',
                                                        index: i,
                                                      ),
                                                      action: (action) {
                                                        if (action == 'edit') {
                                                          _location(
                                                            'Edit stop ${i + 1}',
                                                            index: i,
                                                          );
                                                        } else if (action ==
                                                            'remove') {
                                                          vm.removeStop(i);
                                                        } else {
                                                          vm.moveStop(
                                                            i,
                                                            action == 'up'
                                                                ? -1
                                                                : 1,
                                                          );
                                                        }
                                                      },
                                                      canRemove:
                                                          i > 0 &&
                                                          i < stops.length - 1,
                                                      canUp: i > 0,
                                                      canDown:
                                                          i < stops.length - 1,
                                                    ),
                                                  ),
                                                ],
                                                if (stops.length > 4)
                                                  TextButton(
                                                    onPressed: () =>
                                                        showTripRouteEditor(
                                                          context,
                                                          ref,
                                                        ),
                                                    style: TextButton.styleFrom(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 4,
                                                          ),
                                                      minimumSize: Size.zero,
                                                    ),
                                                    child: Text(
                                                      '+${stops.length - 3}',
                                                      style: const TextStyle(
                                                        fontSize: 11,
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              _TripCard(
                                height: 144,
                                title: 'Suggested Trip Plans',
                                icon: Icons.lightbulb_outline,
                                action: InkWell(
                                  key: const ValueKey('trip-previous-plans'),
                                  onTap: () => context.go('/traveller/reuse'),
                                  child: const Tooltip(
                                    message: 'Previous Traveller Plan',
                                    child: Icon(
                                      Icons.history,
                                      size: 19,
                                      color: _cyan,
                                    ),
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    for (
                                      var i = 0;
                                      i < state.catalog.suggestions.length;
                                      i++
                                    ) ...[
                                      if (i > 0) const SizedBox(height: 4),
                                      Expanded(
                                        child: _SuggestionCard(
                                          idea: state.catalog.suggestions[i],
                                          use: () => _idea(
                                            state.catalog.suggestions[i],
                                            edit: false,
                                          ),
                                          edit: () => _idea(
                                            state.catalog.suggestions[i],
                                            edit: true,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              _TripCard(
                                height: 82,
                                title: 'Travel Details',
                                icon: Icons.directions_car_outlined,
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: _DetailField(
                                        label: 'Budget',
                                        icon: Icons.payments_outlined,
                                        selector: _Selector(
                                          key: const ValueKey('trip-budget'),
                                          label: draft.budget <= 0
                                              ? 'Select / enter LKR'
                                              : 'LKR ${_money.format(draft.budget)}',
                                          onTap: () => _number(people: false),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _DetailField(
                                        label: 'Vehicle',
                                        icon: Icons.directions_car_outlined,
                                        selector: _Selector(
                                          key: const ValueKey('trip-vehicle'),
                                          label: draft.vehicle,
                                          onTap: _vehicle,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _DetailField(
                                        label: 'People Count',
                                        icon: Icons.groups_outlined,
                                        selector: _Selector(
                                          key: const ValueKey('trip-people'),
                                          label:
                                              '${draft.people} ${draft.people == 1 ? 'person' : 'people'}',
                                          onTap: () => _number(people: true),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),
                              SizedBox(
                                height: 46,
                                child: _GlowButton(
                                  key: const ValueKey('trip-ai'),
                                  label: 'AI Trip Plane',
                                  icon: Icons.auto_awesome_outlined,
                                  ai: true,
                                  onPressed: _ai,
                                ),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                height: 46,
                                child: _GlowButton(
                                  key: const ValueKey('trip-submit'),
                                  label: _submitting
                                      ? 'Saving…'
                                      : 'Submit Trip',
                                  icon: Icons.send_outlined,
                                  onPressed: _submitting ? null : _submit,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

InputDecoration _input(String hint, {IconData? icon}) => InputDecoration(
  hintText: hint,
  hintStyle: const TextStyle(fontSize: 10, color: Color(0xFFD4E9F4)),
  isDense: true,
  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  prefixIcon: icon == null ? null : Icon(icon, size: 14),
  prefixIconConstraints: const BoxConstraints(minWidth: 26, minHeight: 24),
  filled: true,
  fillColor: const Color(0x66307991),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(9),
    borderSide: const BorderSide(color: Color(0xFF5795AA)),
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(9),
    borderSide: const BorderSide(color: Color(0xFF5795AA)),
  ),
);

class _LabeledRow extends StatelessWidget {
  const _LabeledRow({required this.label, required this.child});
  final String label;
  final Widget child;
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 28,
    child: Row(
      children: [
        SizedBox(
          width: 88,
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(child: child),
      ],
    ),
  );
}

class _Selector extends StatelessWidget {
  const _Selector({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
  });
  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 28,
    child: Material(
      color: const Color(0x66307991),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(9),
        side: const BorderSide(color: Color(0xFF5795AA)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 7),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: Colors.white),
                const SizedBox(width: 6),
              ],
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: Colors.white),
                ),
              ),
              const Icon(Icons.expand_more, size: 15, color: Colors.white),
            ],
          ),
        ),
      ),
    ),
  );
}

class _TripCard extends StatelessWidget {
  const _TripCard({
    required this.height,
    required this.title,
    required this.icon,
    required this.child,
    this.action,
  });
  final double height;
  final String title;
  final IconData icon;
  final Widget child;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Container(
    height: height,
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFF6BE8FF), width: 1),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xC9165A6B), Color(0xCC031725)],
      ),
      boxShadow: [
        BoxShadow(
          color: _cyan.withValues(alpha: .22),
          blurRadius: 8,
          spreadRadius: 1,
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 22,
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFF7AF6FF), size: 20),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              ?action,
            ],
          ),
        ),
        Expanded(child: child),
      ],
    ),
  );
}

class _DetailField extends StatelessWidget {
  const _DetailField({
    required this.label,
    required this.icon,
    required this.selector,
  });
  final String label;
  final IconData icon;
  final Widget selector;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      SizedBox(
        height: 16,
        child: Row(
          children: [
            Icon(icon, size: 13, color: Colors.white),
            const SizedBox(width: 4),
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 11, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 2),
      selector,
    ],
  );
}

class _GlowButton extends StatelessWidget {
  const _GlowButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.ai = false,
    this.small = false,
  });
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool ai, small;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(30),
      gradient: LinearGradient(
        colors: ai
            ? const [Color(0xFFAC28EE), Color(0xFF1566B6), Color(0xFF00D98B)]
            : const [Color(0xFF00C7F2), Color(0xFF008EAB), Color(0xFF00DB8D)],
      ),
      boxShadow: [
        BoxShadow(
          color: (ai ? const Color(0xFF9471FF) : _cyan).withValues(alpha: .45),
          blurRadius: small ? 7 : 13,
          spreadRadius: 1,
        ),
      ],
    ),
    child: FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: Colors.transparent,
        disabledBackgroundColor: Colors.transparent,
        shadowColor: Colors.transparent,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: small ? 4 : 16),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: const StadiumBorder(
          side: BorderSide(color: Color(0xFFC2FFFF), width: 1.1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: small ? 13 : 23),
          SizedBox(width: small ? 3 : 10),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: small ? 11 : 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          if (!small) ...[
            const SizedBox(width: 12),
            const Icon(Icons.arrow_forward, size: 22),
          ],
        ],
      ),
    ),
  );
}

class _StopChip extends StatelessWidget {
  const _StopChip({
    required this.index,
    required this.name,
    required this.edit,
    required this.action,
    required this.canRemove,
    required this.canUp,
    required this.canDown,
  });
  final int index;
  final String name;
  final VoidCallback edit;
  final ValueChanged<String> action;
  final bool canRemove, canUp, canDown;
  @override
  Widget build(BuildContext context) => Material(
    color: const Color(0x9903293A),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
      side: const BorderSide(color: _cyan),
    ),
    child: InkWell(
      key: ValueKey('trip-stop-chip-$index'),
      onTap: edit,
      child: Row(
        children: [
          const SizedBox(width: 3),
          CircleAvatar(
            radius: 8,
            backgroundColor: const Color(0xFF5BFFF1),
            child: Text(
              '${index + 1}',
              style: const TextStyle(fontSize: 9, color: Colors.black),
            ),
          ),
          const SizedBox(width: 3),
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 9, color: Colors.white),
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'Actions for stop ${index + 1}',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 170),
            iconSize: 12,
            icon: const Icon(Icons.more_vert),
            style: IconButton.styleFrom(
              minimumSize: const Size(16, 25),
              maximumSize: const Size(16, 25),
              padding: EdgeInsets.zero,
            ),
            onSelected: action,
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'edit', child: Text('Edit stop')),
              if (canUp)
                const PopupMenuItem(value: 'up', child: Text('Move earlier')),
              if (canDown)
                const PopupMenuItem(value: 'down', child: Text('Move later')),
              if (canRemove)
                const PopupMenuItem(
                  value: 'remove',
                  child: Text('Remove stop'),
                ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _SuggestionCard extends StatelessWidget {
  const _SuggestionCard({
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
        borderRadius: BorderRadius.circular(9),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Image.asset(
              idea.thumbnailAsset,
              width: 43,
              height: 49,
              fit: BoxFit.cover,
            ),
            const Icon(Icons.route, color: Color(0xFF75FFF0), size: 25),
          ],
        ),
      ),
      const SizedBox(width: 6),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Tooltip(
              message: idea.plan.title,
              child: Text(
                idea.plan.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                CircleAvatar(
                  radius: 7,
                  backgroundImage: idea.avatarAsset == null
                      ? null
                      : AssetImage(idea.avatarAsset!),
                  child: idea.avatarAsset == null
                      ? Text(
                          idea.author
                              .split(' ')
                              .map((p) => p[0])
                              .take(2)
                              .join(),
                          style: const TextStyle(fontSize: 7),
                        )
                      : null,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'by ${idea.author}',
                    maxLines: 1,
                    style: const TextStyle(
                      fontSize: 9,
                      color: Color(0xFFD6EBF4),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                'LKR ${_money.format(idea.plan.budget)}   •   ${idea.plan.vehicle}   •   ${idea.plan.people} People',
                style: const TextStyle(fontSize: 9, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(width: 5),
      SizedBox(
        width: 70,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 22,
              width: 70,
              child: _GlowButton(
                key: ValueKey('use-${idea.id}'),
                label: 'Use Idea',
                icon: Icons.arrow_forward,
                onPressed: use,
                small: true,
              ),
            ),
            SizedBox(
              height: 23,
              child: TextButton.icon(
                key: ValueKey('edit-${idea.id}'),
                onPressed: edit,
                icon: const Icon(Icons.edit_outlined, size: 12),
                label: const Text('Edit Idea'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  minimumSize: Size.zero,
                  textStyle: const TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 10,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class _NumberDialog extends StatefulWidget {
  const _NumberDialog({
    required this.people,
    required this.initial,
    required this.presets,
  });
  final bool people;
  final num initial;
  final List<double> presets;
  @override
  State<_NumberDialog> createState() => _NumberDialogState();
}

class _NumberDialogState extends State<_NumberDialog> {
  final _form = GlobalKey<FormState>();
  late final _controller = TextEditingController(
    text: widget.initial > 0 ? widget.initial.toStringAsFixed(0) : '',
  );
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.people ? 'People Count' : 'Budget (LKR)'),
    content: SingleChildScrollView(
      child: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.presets.isNotEmpty)
              Wrap(
                spacing: 6,
                children: [
                  for (final amount in widget.presets)
                    ActionChip(
                      label: Text(_money.format(amount)),
                      onPressed: () =>
                          _controller.text = amount.toStringAsFixed(0),
                    ),
                ],
              ),
            TextFormField(
              key: const ValueKey('trip-number-input'),
              controller: _controller,
              keyboardType: TextInputType.numberWithOptions(
                decimal: !widget.people,
              ),
              decoration: InputDecoration(
                labelText: widget.people ? 'Travellers' : 'LKR',
              ),
              validator: (text) {
                final value = widget.people
                    ? int.tryParse(text ?? '')
                    : double.tryParse(text ?? '');
                return value == null || !value.isFinite || value <= 0
                    ? 'Enter a positive ${widget.people ? 'whole number' : 'budget'}.'
                    : null;
              },
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () {
          if (_form.currentState!.validate()) {
            Navigator.pop(context, num.parse(_controller.text));
          }
        },
        child: const Text('Apply'),
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
          backgroundColor: const Color(0xD8071D2A),
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
