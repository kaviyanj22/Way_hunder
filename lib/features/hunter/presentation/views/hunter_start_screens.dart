import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/demo_map.dart';
import 'hunter_compact_map.dart';
import '../../domain/hunter_models.dart';
import '../viewmodels/hunter_view_model.dart';
import 'hunter_ui.dart';

class HunterHomeScreen extends ConsumerWidget {
  const HunterHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(hunterViewModelProvider);
    final vm = ref.read(hunterViewModelProvider.notifier);
    return HunterShell(
      title: 'Hunter',
      backRoute: '/home',
      compactHeader: true,
      fillBody: true,
      child: LayoutBuilder(
        builder: (context, space) {
          // The page never scrolls. Only the contributions list is scrollable.
          final mapHeight = (space.maxHeight * .22)
              .clamp(58.0, 138.0)
              .toDouble();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              HunterPanel(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: SizedBox(
                  height: 42,
                  child: TextField(
                    onChanged: vm.search,
                    textInputAction: TextInputAction.search,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Search ${state.seed.district} places',
                      prefixIcon: const Icon(Icons.search, color: hunterGold),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      isDense: true,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              HunterPanel(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 7),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.verified_outlined,
                          color: hunterGold,
                          size: 17,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            'Current district: ${state.seed.district}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            minimumSize: const Size(0, 28),
                            padding: const EdgeInsets.symmetric(horizontal: 5),
                          ),
                          icon: const Icon(
                            Icons.my_location_outlined,
                            size: 15,
                          ),
                          label: const Text(
                            'GPS',
                            style: TextStyle(fontSize: 11),
                          ),
                          onPressed: state.busy
                              ? null
                              : () async {
                                  await vm.requestGpsPermission();
                                  if (context.mounted) {
                                    hunterMessage(
                                      context,
                                      ref
                                          .read(hunterViewModelProvider)
                                          .locationStatus,
                                    );
                                  }
                                },
                        ),
                      ],
                    ),
                    HunterCompactMap(height: mapHeight),
                    const SizedBox(height: 3),
                    const Text(
                      'DEMO district / pins · not verified GPS',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 10, color: Colors.white70),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              HunterAction(
                label: 'Add Location',
                icon: Icons.add_location_alt_outlined,
                green: true,
                onPressed: () {
                  vm.beginDiscovery();
                  context.push('/hunter/add');
                },
              ),
              const SizedBox(height: 7),
              Expanded(
                child: HunterPanel(
                  padding: const EdgeInsets.fromLTRB(9, 6, 9, 3),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'My Discoveries',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          TextButton(
                            style: TextButton.styleFrom(
                              minimumSize: const Size(0, 30),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                              ),
                            ),
                            onPressed: () => context.push('/hunter/rewards'),
                            child: const Text(
                              'View All',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      Expanded(
                        // This is the ONLY vertically scrolling Hunter Home area.
                        child: state.discoveries.isEmpty
                            ? const Center(
                                child: Text(
                                  'No matching places. Add a discovery!',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white70,
                                  ),
                                ),
                              )
                            : ListView.builder(
                                key: const PageStorageKey(
                                  'hunter-discoveries-scroll-only',
                                ),
                                padding: EdgeInsets.zero,
                                primary: false,
                                physics: const ClampingScrollPhysics(),
                                itemCount: state.discoveries.length,
                                itemBuilder: (context, index) {
                                  final submission = state.discoveries[index];
                                  return SizedBox(
                                    height: 56,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(10),
                                      onTap: () {
                                        vm.selectSubmission(submission.id);
                                        context.push('/hunter/verification');
                                      },
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.place,
                                            color: hunterGold,
                                            size: 22,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  submission.name,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  maxLines: 1,
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                Text(
                                                  '${submission.district} · ${submission.status.label}',
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    fontSize: 10,
                                                    color: Colors.white70,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const Icon(
                                            Icons.chevron_right,
                                            color: hunterGold,
                                            size: 18,
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 7),
              HunterAction(
                label: 'Rewards & My Places',
                secondary: true,
                icon: Icons.workspace_premium_outlined,
                onPressed: () => context.push('/hunter/rewards'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class AddNewPlaceScreen extends ConsumerStatefulWidget {
  const AddNewPlaceScreen({super.key, this.videoAttached = false});
  final bool videoAttached;
  @override
  ConsumerState<AddNewPlaceScreen> createState() => _AddNewPlaceScreenState();
}

class _AddNewPlaceScreenState extends ConsumerState<AddNewPlaceScreen> {
  late final TextEditingController _name;
  late final TextEditingController _address;
  late final TextEditingController _description;
  @override
  void initState() {
    super.initState();
    // Controllers are created once; never create/dispose text controllers in dialogs.
    _name = TextEditingController(
      text: ref.read(hunterViewModelProvider).draft.name,
    );
    _address = TextEditingController(
      text: ref.read(hunterViewModelProvider).draft.address,
    );
    _description = TextEditingController(
      text: ref.read(hunterViewModelProvider).draft.description,
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    _description.dispose();
    super.dispose();
  }

  void _continue() {
    final vm = ref.read(hunterViewModelProvider.notifier);
    if (!vm.validateDetails()) {
      hunterMessage(
        context,
        ref.read(hunterViewModelProvider).error ??
            'Complete all place details.',
      );
      return;
    }
    final draft = ref.read(hunterViewModelProvider).draft;
    if (!draft.gpsChecked) {
      context.push('/hunter/gps');
      return;
    }
    // H-DUP is a validation step, not an extra UI page. Never bypass it.
    if (!draft.duplicateChecked && !vm.checkDuplicate()) {
      hunterAlert(
        context,
        'Possible duplicate',
        ref.read(hunterViewModelProvider).error ??
            'Edit this place and try again.',
      );
      return;
    }
    context.push('/hunter/camera360');
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(hunterViewModelProvider);
    final vm = ref.read(hunterViewModelProvider.notifier);
    return HunterShell(
      title: 'Add New Place',
      subtitle: widget.videoAttached
          ? '360 video attached · capture normal photo next'
          : 'GPS, district, live evidence and verification',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HunterPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(Icons.gps_fixed, color: hunterGreen),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Current District: ${state.seed.district}',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                const Text(
                  'GPS and restricted-area validation are simulated in this prototype.',
                  style: TextStyle(fontSize: 10, color: Colors.white70),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _address,
                  minLines: 1,
                  maxLines: 2,
                  onChanged: (v) => vm.updateDetails(address: v),
                  decoration: const InputDecoration(
                    labelText: 'Auto-detected address / location',
                    prefixIcon: Icon(Icons.place_outlined),
                    isDense: true,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 9),
          const DemoMap(height: 130),
          const SizedBox(height: 9),
          HunterPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _name,
                  onChanged: (v) => vm.updateDetails(name: v),
                  decoration: const InputDecoration(
                    labelText: 'Place Name *',
                    hintText: 'e.g. Gurunagar Beach',
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _description,
                  minLines: 1,
                  maxLines: 2,
                  onChanged: (v) => vm.updateDetails(description: v),
                  decoration: const InputDecoration(
                    labelText: 'Description *',
                    hintText: 'Describe why this place is special',
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 10),
                const HunterSectionLabel(
                  'Category',
                  icon: Icons.category_outlined,
                ),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    for (final category in HunterCategory.values)
                      ChoiceChip(
                        label: Text(
                          category.label,
                          style: const TextStyle(fontSize: 11),
                        ),
                        selected: state.draft.category == category,
                        onSelected: (_) => vm.updateDetails(category: category),
                        selectedColor: hunterGold,
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          if (state.draft.has360) ...[
            HunterPanel(
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: hunterGreen),
                  const SizedBox(width: 10),
                  const Expanded(child: Text('360° DEMO recording complete')),
                  TextButton(
                    onPressed: () {
                      vm.retake360();
                      context.push('/hunter/camera360');
                    },
                    child: const Text('Retake 360'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            HunterAction(
              label: state.draft.gpsChecked && state.draft.duplicateChecked
                  ? 'Add Normal Photo'
                  : 'Recheck GPS / Duplicate',
              icon: Icons.camera_alt_outlined,
              onPressed: state.draft.gpsChecked && state.draft.duplicateChecked
                  ? () => context.push('/hunter/photo-camera')
                  : _continue,
            ),
          ] else
            HunterAction(
              label: 'Open 360 Camera',
              icon: Icons.videocam_outlined,
              onPressed: _continue,
            ),
          const SizedBox(height: 8),
          HunterAction(
            label: 'Cancel',
            icon: Icons.close,
            secondary: true,
            onPressed: () => context.go('/hunter'),
          ),
          if (state.error != null)
            Padding(
              padding: const EdgeInsets.only(top: 7),
              child: Text(
                state.error!,
                style: const TextStyle(color: Color(0xFFFFC0A0)),
              ),
            ),
        ],
      ),
    );
  }
}

class HunterGpsScreen extends ConsumerWidget {
  const HunterGpsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(hunterViewModelProvider);
    final vm = ref.read(hunterViewModelProvider.notifier);
    return HunterShell(
      title: 'GPS / District Check',
      subtitle: 'H-GPS · Required before live evidence',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HunterPanel(
            child: Column(
              children: [
                const Icon(Icons.gps_fixed, size: 58, color: hunterGreen),
                const SizedBox(height: 12),
                Text(
                  'Current District: ${state.seed.district}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  state.locationStatus,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
                const SizedBox(height: 14),
                HunterAction(
                  label: 'Request Location Permission',
                  icon: Icons.my_location,
                  secondary: true,
                  onPressed: state.busy
                      ? null
                      : () => vm.requestGpsPermission(),
                ),
                const SizedBox(height: 9),
                HunterAction(
                  label: 'Open App Settings',
                  icon: Icons.settings_outlined,
                  secondary: true,
                  onPressed: () => vm.openSettings(),
                ),
                const SizedBox(height: 11),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('DEMO: simulate restricted area'),
                  subtitle: const Text('Toggle to test a blocked location'),
                  value: state.draft.restricted,
                  onChanged: (v) => vm.setRestricted(v ?? false),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          HunterAction(
            label: 'Verify District (DEMO)',
            icon: Icons.verified_outlined,
            green: true,
            onPressed: () {
              if (!vm.runDemoGpsCheck()) {
                hunterMessage(
                  context,
                  ref.read(hunterViewModelProvider).error ?? 'Location blocked',
                );
                return;
              }
              // Duplicate and near-name checks run automatically in place.
              if (!vm.checkDuplicate()) {
                hunterAlert(
                  context,
                  'Duplicate place detected',
                  ref.read(hunterViewModelProvider).error ??
                      'Edit the place and retry.',
                );
                return;
              }
              context.push('/hunter/camera360');
            },
          ),
          if (state.error != null)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                state.error!,
                style: const TextStyle(color: Color(0xFFFFBE9B)),
              ),
            ),
        ],
      ),
    );
  }
}
