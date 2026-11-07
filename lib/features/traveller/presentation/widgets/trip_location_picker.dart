import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/traveller_map_data.dart';
import '../viewmodels/traveller_view_model.dart';
import 'trip_route_map.dart';

Future<String?> showTripLocationPicker(
  BuildContext context, {
  String title = 'Choose a location',
}) => showModalBottomSheet<String>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (_) => _TripLocationPicker(title: title),
);

class _TripLocationPicker extends ConsumerStatefulWidget {
  const _TripLocationPicker({required this.title});
  final String title;
  @override
  ConsumerState<_TripLocationPicker> createState() =>
      _TripLocationPickerState();
}

class _TripLocationPickerState extends ConsumerState<_TripLocationPicker> {
  String _query = '';
  bool _map = false;
  MapCoordinate? _selected;
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(travellerViewModelProvider);
    final matches = state.catalog.locations.where(
      (p) => '${p.name} ${p.district}'.toLowerCase().contains(
        _query.toLowerCase(),
      ),
    );
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .78,
        child: Column(
          children: [
            ListTile(
              title: Text(widget.title),
              trailing: IconButton(
                tooltip: 'Close location picker',
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      key: const ValueKey('trip-location-search'),
                      onChanged: (value) => setState(() => _query = value),
                      decoration: const InputDecoration(
                        hintText: 'Search places or cities',
                        prefixIcon: Icon(Icons.search),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: _map ? 'Search list' : 'Choose on map',
                    icon: Icon(_map ? Icons.list : Icons.map_outlined),
                    onPressed: () {
                      FocusScope.of(context).unfocus();
                      setState(() => _map = !_map);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _map
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: TripRouteMap(
                          stops: [
                            for (final name in state.draft.stops)
                              if (state.positionFor(name) case final position?)
                                TravellerMapMarker(
                                  id: name,
                                  name: name,
                                  position: position,
                                ),
                          ],
                          pickedPoint: _selected,
                          onTap: (point) => setState(() => _selected = point),
                        ),
                      ),
                    )
                  : matches.isEmpty
                  ? const Center(child: Text('No locations found'))
                  : ListView(
                      children: [
                        for (final place in matches)
                          ListTile(
                            key: ValueKey('pick-${place.id}'),
                            leading: const Icon(Icons.place_outlined),
                            title: Text(place.name),
                            subtitle: Text(place.district),
                            onTap: () => Navigator.pop(context, place.name),
                          ),
                      ],
                    ),
            ),
            if (_map)
              Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton.icon(
                  key: const ValueKey('trip-use-map-pin'),
                  onPressed: _selected == null
                      ? null
                      : () {
                          final name = ref
                              .read(travellerViewModelProvider.notifier)
                              .registerMapStop(_selected!);
                          Navigator.pop(context, name);
                        },
                  icon: const Icon(Icons.check),
                  label: Text(
                    _selected == null
                        ? 'Tap the map to select a location'
                        : 'Use selected location',
                  ),
                ),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

/// A transactional editor: Cancel/Back restores the incoming draft.
Future<void> showTripRouteEditor(
  BuildContext context,
  WidgetRef ref, {
  String title = 'Edit Route',
  TripSuggestion? suggestion,
}) async {
  final vm = ref.read(travellerViewModelProvider.notifier);
  final before = ref.read(travellerViewModelProvider).draft;
  if (suggestion != null) vm.useSuggestion(suggestion);
  final applied = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _TripRouteEditor(title: title),
  );
  if (context.mounted && applied != true) vm.updateDraft(before);
}

class _TripRouteEditor extends ConsumerWidget {
  const _TripRouteEditor({required this.title});
  final String title;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(travellerViewModelProvider);
    final vm = ref.read(travellerViewModelProvider.notifier);
    final stops = state.draft.stops;
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * .8,
      child: Column(
        children: [
          ListTile(
            title: Text(title),
            subtitle: const Text('Drag or use arrows to reorder stops'),
            trailing: IconButton(
              tooltip: 'Cancel route edits',
              onPressed: () => Navigator.pop(context, false),
              icon: const Icon(Icons.close),
            ),
          ),
          Expanded(
            child: ReorderableListView.builder(
              itemCount: stops.length,
              onReorderItem: (from, to) {
                vm.moveStop(from, to - from);
              },
              itemBuilder: (context, i) => ListTile(
                key: ValueKey('edit-stop-$i-${stops[i]}'),
                leading: CircleAvatar(child: Text('${i + 1}')),
                title: Text(stops[i]),
                subtitle: Text(
                  i == 0
                      ? 'Start'
                      : i == stops.length - 1
                      ? 'End'
                      : 'Stop',
                ),
                onTap: () async {
                  final name = await showTripLocationPicker(
                    context,
                    title: 'Edit stop ${i + 1}',
                  );
                  if (name != null) vm.changeStop(i, name);
                },
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Move stop ${i + 1} up',
                      icon: const Icon(Icons.arrow_upward, size: 19),
                      onPressed: i == 0 ? null : () => vm.moveStop(i, -1),
                    ),
                    IconButton(
                      tooltip: 'Move stop ${i + 1} down',
                      icon: const Icon(Icons.arrow_downward, size: 19),
                      onPressed: i == stops.length - 1
                          ? null
                          : () => vm.moveStop(i, 1),
                    ),
                    if (i > 0 && i < stops.length - 1)
                      IconButton(
                        tooltip: 'Remove stop ${i + 1}',
                        icon: const Icon(Icons.close, size: 19),
                        onPressed: () => vm.removeStop(i),
                      ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.add_location_alt_outlined),
                    label: const Text('Add Stop'),
                    onPressed: () async {
                      final name = await showTripLocationPicker(context);
                      if (name != null &&
                          !vm.addIntermediateStop(name) &&
                          context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              ref.read(travellerViewModelProvider).error!,
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    key: const ValueKey('trip-apply-route'),
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Apply Route'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
