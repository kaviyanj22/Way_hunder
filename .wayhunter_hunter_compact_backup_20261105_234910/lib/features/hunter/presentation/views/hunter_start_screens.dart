import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/demo_map.dart';
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
      title: 'Location Hunter',
      subtitle: 'Discover places in your current district',
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        HunterPanel(padding: const EdgeInsets.all(9), child: TextField(
          onChanged: vm.search,
          decoration: InputDecoration(prefixIcon: const Icon(Icons.search),
            hintText: 'Search ${state.seed.district} places', isDense: true, border: InputBorder.none),
        )),
        const SizedBox(height: 9),
        HunterPanel(child: Column(children: [
          Row(children: [
            const Icon(Icons.map_outlined, color: hunterGreen, size: 28),
            const SizedBox(width: 8),
            Expanded(child: Text('${state.seed.district} District', style:
              const TextStyle(fontSize: 19, fontWeight: FontWeight.w800))),
          ]),
          const SizedBox(height: 8),
          const DemoMap(height: 170),
          const SizedBox(height: 7),
          Row(children: [
            const Icon(Icons.verified_outlined, color: hunterGreen, size: 22),
            const SizedBox(width: 8),
            Expanded(child: Text('Current district: ${state.seed.district}',
              style: const TextStyle(fontWeight: FontWeight.w700))),
          ]),
          const Text('DEMO district. GPS permission is separate from verified district boundaries.',
            style: TextStyle(color: Colors.white70, fontSize: 10)),
          const SizedBox(height: 8),
          HunterAction(label: 'Request GPS Permission', secondary: true,
            icon: Icons.my_location, onPressed: () async {
              await vm.requestGpsPermission();
              if (context.mounted) {
                hunterMessage(context, ref.read(hunterViewModelProvider).locationStatus);
              }
            }),
        ])),
        const SizedBox(height: 9),
        HunterAction(label: 'Add Location', icon: Icons.add_location_alt_outlined,
          green: true, onPressed: () {
            vm.beginDiscovery();
            context.push('/hunter/add');
          }),
        const SizedBox(height: 10),
        HunterPanel(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            const Expanded(child: HunterSectionLabel('My Discoveries', icon: Icons.explore)),
            TextButton(onPressed: () => context.push('/hunter/rewards'),
              child: const Text('View All')),
          ]),
          for (final submission in state.discoveries.take(4))
            ListTile(
              dense: true, contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(backgroundColor: hunterGreen.withValues(alpha: .22),
                child: const Icon(Icons.place, color: hunterGreen)),
              title: Text(submission.name, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text('${submission.district} · ${submission.status.label}'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                vm.selectSubmission(submission.id);
                context.push('/hunter/verification');
              },
            ),
          if (state.discoveries.isEmpty)
            const Text('No matching contributions. Add your first discovery!',
              style: TextStyle(color: Colors.white70)),
        ])),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: HunterAction(label: 'Rewards & My Places',
            secondary: true, icon: Icons.workspace_premium_outlined,
            onPressed: () => context.push('/hunter/rewards'))),
          const SizedBox(width: 8),
          Expanded(child: HunterAction(label: 'Leaderboard',
            secondary: true, icon: Icons.emoji_events_outlined,
            onPressed: () => context.push('/hunter/leaderboard'))),
        ]),
      ]),
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
    _name = TextEditingController(text: ref.read(hunterViewModelProvider).draft.name);
    _address = TextEditingController(text: ref.read(hunterViewModelProvider).draft.address);
    _description = TextEditingController(text: ref.read(hunterViewModelProvider).draft.description);
  }
  @override
  void dispose() { _name.dispose(); _address.dispose(); _description.dispose(); super.dispose(); }

  void _continue() {
    final vm = ref.read(hunterViewModelProvider.notifier);
    if (!vm.validateDetails()) {
      hunterMessage(context, ref.read(hunterViewModelProvider).error ?? 'Complete all place details.');
      return;
    }
    final draft = ref.read(hunterViewModelProvider).draft;
    context.push(!draft.gpsChecked ? '/hunter/gps' :
      !draft.duplicateChecked ? '/hunter/duplicate' : '/hunter/camera360');
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(hunterViewModelProvider);
    final vm = ref.read(hunterViewModelProvider.notifier);
    return HunterShell(
      title: 'Add New Place', subtitle: widget.videoAttached
        ? '360 video attached · capture normal photo next'
        : 'GPS, district, live evidence and verification',
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        HunterPanel(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            const Icon(Icons.gps_fixed, color: hunterGreen),
            const SizedBox(width: 8),
            Expanded(child: Text('Current District: ${state.seed.district}',
              style: const TextStyle(fontWeight: FontWeight.w800))),
          ]),
          const SizedBox(height: 5),
          const Text('GPS and restricted-area validation are simulated in this prototype.',
            style: TextStyle(fontSize: 10, color: Colors.white70)),
          const SizedBox(height: 8),
          TextField(controller: _address, minLines: 1, maxLines: 2,
            onChanged: (v) => vm.updateDetails(address: v),
            decoration: const InputDecoration(labelText: 'Auto-detected address / location',
              prefixIcon: Icon(Icons.place_outlined), isDense: true)),
        ])),
        const SizedBox(height: 9),
        const DemoMap(height: 130),
        const SizedBox(height: 9),
        HunterPanel(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          TextField(controller: _name,
            onChanged: (v) => vm.updateDetails(name: v),
            decoration: const InputDecoration(labelText: 'Place Name *',
              hintText: 'e.g. Gurunagar Beach', isDense: true)),
          const SizedBox(height: 8),
          TextField(controller: _description, minLines: 1, maxLines: 2,
            onChanged: (v) => vm.updateDetails(description: v),
            decoration: const InputDecoration(labelText: 'Description *',
              hintText: 'Describe why this place is special', isDense: true)),
          const SizedBox(height: 10),
          const HunterSectionLabel('Category', icon: Icons.category_outlined),
          Wrap(spacing: 6, runSpacing: 4, children: [
            for (final category in HunterCategory.values)
              ChoiceChip(
                label: Text(category.label, style: const TextStyle(fontSize: 11)),
                selected: state.draft.category == category,
                onSelected: (_) => vm.updateDetails(category: category),
                selectedColor: hunterGold,
              ),
          ]),
        ])),
        const SizedBox(height: 10),
        if (state.draft.has360) ...[
          HunterPanel(child: Row(children: [
            const Icon(Icons.check_circle, color: hunterGreen),
            const SizedBox(width: 10),
            const Expanded(child: Text('360° DEMO recording complete')),
            TextButton(onPressed: () {
              vm.retake360(); context.push('/hunter/camera360');
            }, child: const Text('Retake 360')),
          ])),
          const SizedBox(height: 10),
          HunterAction(label: state.draft.gpsChecked && state.draft.duplicateChecked
              ? 'Add Normal Photo' : 'Recheck GPS / Duplicate',
            icon: Icons.camera_alt_outlined,
            onPressed: state.draft.gpsChecked && state.draft.duplicateChecked
              ? () => context.push('/hunter/photo-camera') : _continue),
        ] else
          HunterAction(label: 'Open 360 Camera', icon: Icons.videocam_outlined,
            onPressed: _continue),
        const SizedBox(height: 8),
        HunterAction(label: 'Cancel', icon: Icons.close, secondary: true,
          onPressed: () => context.go('/hunter')),
        if (state.error != null) Padding(padding: const EdgeInsets.only(top: 7),
          child: Text(state.error!, style: const TextStyle(color: Color(0xFFFFC0A0)))),
      ]),
    );
  }
}

class HunterGpsScreen extends ConsumerWidget {
  const HunterGpsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(hunterViewModelProvider);
    final vm = ref.read(hunterViewModelProvider.notifier);
    return HunterShell(title: 'GPS / District Check', subtitle: 'H-GPS · Required before live evidence',
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        HunterPanel(child: Column(children: [
          const Icon(Icons.gps_fixed, size: 58, color: hunterGreen),
          const SizedBox(height: 12),
          Text('Current District: ${state.seed.district}', style:
            const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(state.locationStatus, textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: Colors.white70)),
          const SizedBox(height: 14),
          HunterAction(label: 'Request Location Permission',
            icon: Icons.my_location, secondary: true,
            onPressed: state.busy ? null : () => vm.requestGpsPermission()),
          const SizedBox(height: 9),
          HunterAction(label: 'Open App Settings', icon: Icons.settings_outlined,
            secondary: true, onPressed: () => vm.openSettings()),
          const SizedBox(height: 11),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('DEMO: simulate restricted area'),
            subtitle: const Text('Toggle to test a blocked location'),
            value: state.draft.restricted,
            onChanged: (v) => vm.setRestricted(v ?? false),
          ),
        ])),
        const SizedBox(height: 10),
        HunterAction(label: 'Verify District (DEMO)', icon: Icons.verified_outlined,
          green: true, onPressed: () {
            if (vm.runDemoGpsCheck()) {
              context.push('/hunter/duplicate');
            } else {
              hunterMessage(context, ref.read(hunterViewModelProvider).error ?? 'Blocked');
            }
          }),
        if (state.error != null) Padding(padding: const EdgeInsets.all(8),
          child: Text(state.error!, style: const TextStyle(color: Color(0xFFFFBE9B)))),
      ]));
  }
}

class HunterDuplicateScreen extends ConsumerWidget {
  const HunterDuplicateScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(hunterViewModelProvider);
    final vm = ref.read(hunterViewModelProvider.notifier);
    return HunterShell(title: 'Duplicate Check', subtitle: 'H-DUP · 200 m / image similarity demo check',
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        HunterPanel(child: Column(children: [
          const Icon(Icons.content_copy_outlined, color: hunterGold, size: 56),
          const SizedBox(height: 9),
          Text('Place: ${state.draft.name}', style:
            const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          const Text('Current prototype checks existing place names. Real 200 m GPS/image duplicate detection needs a backend.',
            textAlign: TextAlign.center, style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 10),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Simulate nearby duplicate'),
            value: state.draft.simulateDuplicate,
            onChanged: vm.setDuplicateSimulation,
          ),
        ])),
        const SizedBox(height: 10),
        HunterAction(label: 'Check & Continue', icon: Icons.fact_check_outlined,
          green: true, onPressed: () {
            if (vm.checkDuplicate()) {
              context.push('/hunter/camera360');
            } else {
              hunterMessage(context, ref.read(hunterViewModelProvider).error ?? 'Possible duplicate');
            }
          }),
        if (state.error != null) Padding(padding: const EdgeInsets.all(9),
          child: Column(children: [
            Text(state.error!, style: const TextStyle(color: Color(0xFFFFBB8A))),
            const SizedBox(height: 8),
            HunterAction(label: 'Edit Place / Retry', secondary: true,
              onPressed: () => context.push('/hunter/add')),
          ])),
      ]));
  }
}
