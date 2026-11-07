import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/wayhunter_palette.dart';
import '../../../../core/widgets/module_scaffold.dart';
import '../viewmodels/traveller_view_model.dart';
import '../widgets/traveller_map.dart';
import '../widgets/trip_location_picker.dart';

/// Opens only when a specific Create Trip -> Use Idea button is tapped.
/// The existing Create Trip and Edit Idea widgets are not replaced.
class SuggestedTripDetailScreen extends ConsumerStatefulWidget {
  const SuggestedTripDetailScreen({super.key, required this.suggestionId});
  final String suggestionId;

  @override
  ConsumerState<SuggestedTripDetailScreen> createState() =>
      _SuggestedTripDetailScreenState();
}

class _SuggestedTripDetailScreenState
    extends ConsumerState<SuggestedTripDetailScreen> {
  int _tab = 0;
  static const _cyan = Color(0xFF00E8F6);
  static const _teal = Color(0xFF00D6AD);
  static const _white = Color(0xFFE8F9FF);

  static const _assets = <String>[
    'assets/images/backgrounds/suggestion_fort.png',
    'assets/images/backgrounds/suggestion_temple.png',
    'assets/images/backgrounds/suggestion_beach.png',
    'assets/images/backgrounds/suggestion_elephants.png',
    'assets/images/backgrounds/suggestion_friends.png',
    'assets/images/backgrounds/suggestion_sunset.png',
  ];

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(travellerViewModelProvider);
    final matches = state.catalog.suggestions.where(
      (idea) => idea.id == widget.suggestionId,
    );
    final idea = matches.isEmpty ? null : matches.first;
    if (idea == null) {
      return ModuleScaffold(
        title: 'Suggested Trip Plan',
        subtitle: 'Trip not found',
        backRoute: '/traveller/create',
        module: WayhunterModule.traveller,
        child: TextButton(
          onPressed: () => context.go('/traveller/create'),
          child: const Text('Back to Create Trip'),
        ),
      );
    }
    final plan = idea.plan;
    final overview = _tab == 0;
    return ModuleScaffold(
      title: 'Suggested Trip Plan',
      subtitle: 'Explore a real trip plan from a fellow traveller',
      backRoute: '/traveller/create',
      module: WayhunterModule.traveller,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _hero(context, idea),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _tabButton('Trip Overview', Icons.map_outlined, 0),
                _tabButton(
                  'Photos & Memories',
                  Icons.photo_library_outlined,
                  1,
                ),
                _tabButton('Stays', Icons.bed_outlined, 2),
                _tabButton('Traveller Notes', Icons.description_outlined, 3),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (overview) ...[
            _twoColumns(_routePanel(state, plan), _summaryPanel(plan)),
            const SizedBox(height: 12),
            _twoColumns(_itineraryPanel(plan), _photosPanel()),
            const SizedBox(height: 12),
            _twoColumns(_staysPanel(plan), _notesPanel(idea)),
          ] else if (_tab == 1)
            _photosPanel()
          else if (_tab == 2)
            _staysPanel(plan)
          else
            _notesPanel(idea),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _twoColumns(Widget a, Widget b) => LayoutBuilder(
    builder: (context, constraints) {
      // Two columns as in the supplied reference, except on very narrow screens.
      if (constraints.maxWidth >= 365) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: a),
            const SizedBox(width: 10),
            Expanded(child: b),
          ],
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [a, const SizedBox(height: 12), b],
      );
    },
  );

  Widget _hero(BuildContext context, TripSuggestion idea) {
    final plan = idea.plan;
    final dateText = DateFormat('dd MMM yyyy').format(plan.startDate);
    return _glass(
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  _assets[0],
                  width: 94,
                  height: 118,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundImage: const AssetImage(
                            'assets/images/backgrounds/suggestion_author.png',
                          ),
                          backgroundColor: _cyan,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'by ${idea.author}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: _white, fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'From $dateText',
                      style: const TextStyle(
                        color: Color(0xFFB4DAE5),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              SizedBox(
                width: 102,
                child: Column(
                  children: [
                    _action(
                      'Use This Plan',
                      Icons.arrow_forward,
                      () => _usePlan(idea),
                      filled: true,
                      key: ValueKey('suggestion-use-${idea.id}'),
                    ),
                    const SizedBox(height: 8),
                    _action('Edit Plan', Icons.edit_outlined, () {
                      showTripRouteEditor(
                        context,
                        ref,
                        title: 'Edit Plan',
                        suggestion: idea,
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _meta(
                Icons.payments_outlined,
                'LKR ${NumberFormat.decimalPattern('en').format(plan.budget)}',
              ),
              _meta(Icons.directions_car_outlined, plan.vehicle),
              _meta(Icons.groups_outlined, '${plan.people} People'),
              _meta(Icons.calendar_month_outlined, '${plan.days} Days'),
            ],
          ),
        ],
      ),
    );
  }

  void _usePlan(TripSuggestion idea) {
    ref.read(travellerViewModelProvider.notifier).useSuggestion(idea);
    if (!mounted) return;
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/traveller/create');
    }
  }

  Widget _tabButton(String name, IconData icon, int index) {
    final selected = _tab == index;
    return Padding(
      padding: const EdgeInsets.only(right: 7),
      child: InkWell(
        onTap: () => setState(() => _tab = index),
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: selected
                ? const LinearGradient(colors: [_cyan, _teal])
                : null,
            color: selected ? null : const Color(0xC7093244),
            border: Border.all(
              color: selected ? _teal : const Color(0xFF3B9AAE),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected ? const Color(0xFF002334) : _white,
              ),
              const SizedBox(width: 5),
              Text(
                name,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: selected ? const Color(0xFF002334) : _white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _routePanel(TravellerState state, TripPlan plan) => _section(
    'Trip Route Map',
    Icons.map_outlined,
    Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TravellerMap(
          height: 210,
          compact: true,
          routePoints: state.pointsFor(plan.stops),
        ),
        const SizedBox(height: 7),
        Text(
          plan.stops.join(' → '),
          style: const TextStyle(color: _white, fontSize: 10),
        ),
        const Text(
          'Route line is a demo preview, not road directions.',
          style: TextStyle(color: Color(0xFFAAC9D7), fontSize: 9),
        ),
      ],
    ),
  );

  Widget _summaryPanel(TripPlan plan) => _section(
    'Trip Summary',
    Icons.assignment_outlined,
    Column(
      children: [
        _info(
          Icons.date_range,
          'Dates',
          '${DateFormat('dd MMM').format(plan.startDate)} – ${DateFormat('dd MMM yyyy').format(plan.endDate)}',
        ),
        _info(Icons.route, 'Route', plan.stops.join(' → ')),
        _info(Icons.bed_outlined, 'Stays', '${plan.days - 1} nights'),
        _info(
          Icons.payments_outlined,
          'Budget',
          'LKR ${NumberFormat.decimalPattern('en').format(plan.budget)}',
        ),
        _info(Icons.directions_car_outlined, 'Vehicle', plan.vehicle),
        _info(Icons.groups_outlined, 'Travellers', '${plan.people} People'),
      ],
    ),
  );

  Widget _itineraryPanel(TripPlan plan) => _section(
    'Itinerary (${plan.days} Days)',
    Icons.calendar_month_outlined,
    Column(
      children: [
        for (var i = 0; i < plan.days; i++)
          _listRow(
            leading: CircleAvatar(
              radius: 17,
              backgroundColor: const Color(0xFF086174),
              child: Text(
                'D${i + 1}',
                style: const TextStyle(
                  fontSize: 10,
                  color: _white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title:
                plan.stops[i < plan.stops.length ? i : plan.stops.length - 1],
            subtitle: DateFormat('dd MMM')
                .format(plan.startDate.add(Duration(days: i))),
          ),
      ],
    ),
  );

  Widget _photosPanel() => _section(
    'Photos & Memories',
    Icons.photo_library_outlined,
    Column(
      children: [
        for (var row = 0; row < 3; row++) ...[
          Row(
            children: [
              for (var col = 0; col < 2; col++) ...[
                if (col > 0) const SizedBox(width: 5),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(
                      _assets[row * 2 + col],
                      fit: BoxFit.cover,
                      height: 76,
                      width: double.infinity,
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (row < 2) const SizedBox(height: 5),
        ],
        const SizedBox(height: 7),
        const Text(
          'Sample memories from the suggested trip.',
          style: TextStyle(color: Color(0xFFB6DAE5), fontSize: 10),
        ),
      ],
    ),
  );

  Widget _staysPanel(TripPlan plan) => _section(
    'Stays (${plan.days - 1} Nights)',
    Icons.bed_outlined,
    Column(
      children: [
        _stay(
          'Accommodation near ${plan.stops.first}',
          'assets/images/backgrounds/suggestion_hotel.png',
        ),
        _stay(
          'Accommodation near ${plan.stops[plan.stops.length ~/ 2]}',
          'assets/images/backgrounds/suggestion_resthouse.png',
        ),
        _stay(
          'Accommodation near ${plan.stops.last}',
          'assets/images/backgrounds/suggestion_kandy.png',
        ),
        const Text(
          'Stays are illustrative; no live reservations or ratings.',
          style: TextStyle(color: Color(0xFFAAC9D7), fontSize: 9),
        ),
      ],
    ),
  );

  Widget _stay(String title, String asset) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.asset(asset, width: 53, height: 47, fit: BoxFit.cover),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10, color: _white),
          ),
        ),
        const Icon(Icons.chevron_right, color: _cyan, size: 17),
      ],
    ),
  );

  Widget _notesPanel(TripSuggestion idea) => _section(
    'Traveller Notes & Memories',
    Icons.description_outlined,
    Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '“A memorable route through Sri Lanka’s local heritage and scenic landscapes.”',
          style: const TextStyle(
            fontStyle: FontStyle.italic,
            color: _white,
            fontSize: 12,
            height: 1.55,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          '— ${idea.author}',
          textAlign: TextAlign.right,
          style: const TextStyle(color: _cyan, fontSize: 11),
        ),
        const SizedBox(height: 8),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Icon(Icons.thumb_up_alt_outlined, color: _cyan),
            Icon(Icons.photo_camera_outlined, color: _cyan),
            Icon(Icons.groups_outlined, color: _cyan),
          ],
        ),
      ],
    ),
  );

  Widget _info(IconData icon, String name, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: _cyan, size: 14),
        const SizedBox(width: 5),
        SizedBox(
          width: 51,
          child: Text(
            name,
            style: const TextStyle(color: Color(0xFFB8E4EC), fontSize: 9),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: _white, fontSize: 9.5),
          ),
        ),
      ],
    ),
  );

  Widget _listRow({
    required Widget leading,
    required String title,
    required String subtitle,
  }) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [
        leading,
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _white,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(color: Color(0xFFA8D6E1), fontSize: 9),
              ),
            ],
          ),
        ),
        const Icon(Icons.chevron_right, size: 17, color: _cyan),
      ],
    ),
  );

  Widget _section(String title, IconData icon, Widget body) => _glass(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(icon, color: _cyan, size: 19),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        body,
      ],
    ),
  );

  Widget _glass({required Widget child}) => Container(
    padding: const EdgeInsets.all(11),
    decoration: BoxDecoration(
      color: const Color(0xDE052733),
      borderRadius: BorderRadius.circular(17),
      border: Border.all(color: _cyan.withValues(alpha: 0.88), width: 1.1),
      boxShadow: [
        BoxShadow(color: _cyan.withValues(alpha: 0.13), blurRadius: 9),
      ],
    ),
    child: child,
  );

  Widget _meta(IconData icon, String text) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, color: _cyan, size: 13),
      const SizedBox(width: 4),
      Text(text, style: const TextStyle(color: _white, fontSize: 10)),
    ],
  );

  Widget _action(
    String label,
    IconData icon,
    VoidCallback onTap, {
    bool filled = false,
    Key? key,
  }) => SizedBox(
    width: double.infinity,
    height: 36,
    child: DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: filled ? const LinearGradient(colors: [_cyan, _teal]) : null,
        color: filled ? null : const Color(0xD4083446),
        border: Border.all(color: _cyan),
      ),
      child: TextButton.icon(
        key: key,
        onPressed: onTap,
        icon: Icon(
          icon,
          size: 12,
          color: filled ? const Color(0xFF02212C) : _white,
        ),
        label: FittedBox(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: filled ? const Color(0xFF02212C) : _white,
            ),
          ),
        ),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 5),
        ),
      ),
    ),
  );
}
