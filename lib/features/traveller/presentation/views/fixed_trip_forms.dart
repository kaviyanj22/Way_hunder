import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/wayhunter_palette.dart';
import '../../../../core/widgets/evidence_capture.dart';
import '../../../../core/widgets/glass_panel.dart';
import '../viewmodels/traveller_view_model.dart';

// These are deliberately two fixed, non-vertically-scrollable trip forms.
// Text editing and camera capture open their own accessible modal surfaces.
// They use the SAME TravellerViewModel as Profile -> Posts and Active Trip.
const _cyan = WayhunterPalette.travellerCyan;
const _green = Color(0xFF20D8A1);

class FixedHazardReportScreen extends ConsumerWidget {
  const FixedHazardReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(travellerViewModelProvider);
    final vm = ref.read(travellerViewModelProvider.notifier);
    final trip = state.active;
    if (trip == null) return const _NoActiveTrip();

    return _TripFormFrame(
      title: 'Report Hazard',
      icon: Icons.warning_amber_rounded,
      titleColor: const Color(0xFFFFCA58),
      trip: trip,
      currentStop: state.currentStop,
      submitLabel: 'Submit Report',
      submitKey: const ValueKey('fixed-hazard-submit'),
      onSubmit: () => _submit(context, ref, memory: false),
      contentBuilder: (context, compact) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: compact ? 47 : 55,
            child: _ActionTile(
              icon: Icons.report_problem_outlined,
              title: 'Hazard Type *',
              value: state.hazardType,
              trailing: Icons.expand_more,
              onTap: () async {
                final type = await showModalBottomSheet<String>(
                  context: context,
                  showDragHandle: true,
                  backgroundColor: const Color(0xFF06283A),
                  builder: (sheetContext) => SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Choose hazard type',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        for (final item in const [
                          'Blocked Road',
                          'Flooding',
                          'Landslide',
                          'Accident',
                          'Other',
                        ])
                          ListTile(
                            title: Text(item),
                            trailing: item == state.hazardType
                                ? const Icon(Icons.check, color: _green)
                                : null,
                            onTap: () => Navigator.of(sheetContext).pop(item),
                          ),
                      ],
                    ),
                  ),
                );
                if (type != null) vm.hazardDraft(type: type);
              },
            ),
          ),
          const SizedBox(height: 7),
          SizedBox(
            height: compact ? 82 : 99,
            child: _ActionTile(
              icon: Icons.edit_note_rounded,
              title: 'Reason / Description *',
              value: state.hazardDescription.trim().isEmpty
                  ? 'Tap to describe the danger or blocked road'
                  : state.hazardDescription,
              valueLines: 3,
              trailing: Icons.edit_outlined,
              onTap: () => _editText(
                context,
                title: 'Describe the hazard',
                initialValue: state.hazardDescription,
                maxLength: 200,
                onSave: (value) => vm.hazardDraft(description: value),
              ),
            ),
          ),
          const SizedBox(height: 7),
          SizedBox(
            height: compact ? 44 : 50,
            child: _ActionTile(
              icon: Icons.location_on_outlined,
              title: 'Location (Trip Stop · Demo)',
              value: state.currentStop,
            ),
          ),
          const SizedBox(height: 7),
          SizedBox(
            height: compact ? 43 : 49,
            child: _CaptureButtons(
              onPhoto: () => _captureSheet(context, vm, memory: false),
              onVideo: () =>
                  _captureSheet(context, vm, memory: false, video: true),
            ),
          ),
          const SizedBox(height: 7),
          Expanded(
            child: _EvidenceStrip(
              title: 'Attachments (max 5)',
              evidence: state.hazardEvidence,
              onRemove: (id) => vm.removeEvidence(id, memory: false),
              onAdd: () => _captureSheet(context, vm, memory: false),
              emptyMessage: 'Add a photo or video before submitting.',
            ),
          ),
        ],
      ),
    );
  }
}

class FixedAddMemoriesScreen extends ConsumerWidget {
  const FixedAddMemoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(travellerViewModelProvider);
    final vm = ref.read(travellerViewModelProvider.notifier);
    final trip = state.active;
    if (trip == null) return const _NoActiveTrip();

    return _TripFormFrame(
      title: 'Add Memories',
      icon: Icons.camera_alt_outlined,
      titleColor: _cyan,
      trip: trip,
      currentStop: state.currentStop,
      submitLabel: 'Post Memories',
      submitKey: const ValueKey('fixed-memory-submit'),
      onSubmit: () => _submit(context, ref, memory: true),
      contentBuilder: (context, compact) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: compact ? 43 : 49,
            child: _CaptureButtons(
              onPhoto: () => _captureSheet(context, vm, memory: true),
              onVideo: () =>
                  _captureSheet(context, vm, memory: true, video: true),
            ),
          ),
          const SizedBox(height: 7),
          Expanded(
            child: _EvidenceStrip(
              title: 'Add Photo / Video',
              evidence: state.memoryEvidence,
              onRemove: (id) => vm.removeEvidence(id, memory: true),
              onAdd: () => _captureSheet(context, vm, memory: true),
              emptyMessage: 'Capture or select a trip memory.',
            ),
          ),
          const SizedBox(height: 7),
          SizedBox(
            height: compact ? 76 : 92,
            child: _ActionTile(
              icon: Icons.edit_outlined,
              title: 'Caption / Description *',
              value: state.memoryCaption.trim().isEmpty
                  ? 'Tap to write about this trip moment'
                  : state.memoryCaption,
              valueLines: 3,
              trailing: Icons.edit_note,
              onTap: () => _editText(
                context,
                title: 'Write your travel memory',
                initialValue: state.memoryCaption,
                maxLength: 300,
                onSave: vm.caption,
              ),
            ),
          ),
          const SizedBox(height: 7),
          SizedBox(
            height: compact ? 43 : 48,
            child: _ActionTile(
              icon: Icons.location_on_outlined,
              title: 'Location (Trip Stop · Demo)',
              value: state.currentStop,
            ),
          ),
          const SizedBox(height: 7),
          SizedBox(
            height: compact ? 48 : 57,
            child: GlassPanel(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              child: Row(
                children: [
                  const Icon(Icons.sell_outlined, size: 18, color: _cyan),
                  const SizedBox(width: 6),
                  const Text('Tags', style: TextStyle(fontSize: 11)),
                  const SizedBox(width: 7),
                  Expanded(
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        for (final tag in const [
                          'Relaxed',
                          'Scenic',
                          'Heritage',
                          'Memorable',
                        ])
                          Padding(
                            padding: const EdgeInsets.only(right: 5),
                            child: ChoiceChip(
                              label: Text(
                                tag,
                                style: const TextStyle(fontSize: 10),
                              ),
                              selected: state.memoryTags.contains(tag),
                              onSelected: (_) => vm.tag(tag),
                              visualDensity: VisualDensity.compact,
                              labelPadding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// IMPORTANT: A success dialog is displayed ONLY if the ViewModel accepted
/// the record. Validation failures show a clear explanation and keep the draft.
Future<void> _submit(
  BuildContext context,
  WidgetRef ref, {
  required bool memory,
}) async {
  final vm = ref.read(travellerViewModelProvider.notifier);
  final saved = memory ? vm.postMemory() : vm.submitHazard();
  if (!context.mounted) return;

  if (!saved) {
    final error =
        ref.read(travellerViewModelProvider).error ??
        'Unable to save. Please complete the required fields.';
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Check your details'),
        content: Text(error),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    return;
  }

  // Wait for local metadata persistence before telling the user to continue.
  await vm.persistenceSettled;
  if (!context.mounted) return;
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.check_circle, color: _green),
          SizedBox(width: 9),
          Expanded(child: Text('Submitted successfully!')),
        ],
      ),
      content: Text(
        memory
            ? 'Your memory has been saved locally. Find it in Profile → Posts.'
            : 'Your hazard report has been saved locally. This demo has not sent a live road alert.',
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('OK'),
        ),
      ],
    ),
  );
  if (context.mounted) context.go('/traveller/active');
}

/// Collect caption/description without managing a TextEditingController from
/// outside the popup. The TextFormField owns and disposes its editing state
/// only after the dialog route has completely left the widget tree.
Future<void> _editText(
  BuildContext context, {
  required String title,
  required String initialValue,
  required int maxLength,
  required void Function(String) onSave,
}) async {
  var draftText = initialValue;
  final result = await showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: TextFormField(
        initialValue: initialValue,
        autofocus: true,
        minLines: 2,
        maxLines: 5,
        maxLength: maxLength,
        textCapitalization: TextCapitalization.sentences,
        onChanged: (text) => draftText = text,
        decoration: const InputDecoration(
          hintText: 'Enter details here',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            FocusScope.of(dialogContext).unfocus();
            Navigator.of(dialogContext).pop();
          },
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            FocusScope.of(dialogContext).unfocus();
            Navigator.of(dialogContext).pop(draftText.trim());
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
  if (!context.mounted || result == null) return;
  // Commit only after the popup has returned; do not rebuild an active dialog.
  onSave(result);
}

/// Capture media inside the modal, but update the shared Riverpod state only
/// after the modal closes. Changing provider state inside onCaptured while the
/// CameraPreview/InheritedWidgets are deactivating can crash route teardown.
Future<void> _captureSheet(
  BuildContext context,
  TravellerViewModel vm, {
  required bool memory,
  bool video = false,
}) async {
  final captured = await showModalBottomSheet<CapturedEvidence>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: const Color(0xFF042336),
    builder: (sheetContext) => SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(sheetContext).height * .71,
        child: SingleChildScrollView(
          // Only the media picker scrolls; the main form stays fixed.
          padding: const EdgeInsets.fromLTRB(14, 4, 14, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                video ? 'Capture video' : 'Capture photo',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 10),
              EvidenceCapture(
                allowGallery: true,
                allowVideo: true,
                initialVideo: video,
                onCaptured: (evidence) {
                  if (sheetContext.mounted) {
                    Navigator.of(sheetContext).pop(evidence);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    ),
  );
  if (!context.mounted || captured == null) return;
  vm.addEvidence(captured, memory: memory);
}

class _TripFormFrame extends StatelessWidget {
  const _TripFormFrame({
    required this.title,
    required this.icon,
    required this.titleColor,
    required this.trip,
    required this.currentStop,
    required this.contentBuilder,
    required this.submitLabel,
    required this.submitKey,
    required this.onSubmit,
  });

  final String title, currentStop, submitLabel;
  final IconData icon;
  final Color titleColor;
  final TripPlan trip;
  final Widget Function(BuildContext, bool) contentBuilder;
  final Key submitKey;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) => Theme(
    data: Theme.of(context).copyWith(
      colorScheme: Theme.of(context).colorScheme.copyWith(primary: _cyan),
    ),
    child: Stack(
      fit: StackFit.expand,
      children: [
        ImageFiltered(
          imageFilter: ui.ImageFilter.blur(sigmaX: 4, sigmaY: 4),
          child: Image.asset(AppAssets.homeBackground, fit: BoxFit.cover),
        ),
        const ColoredBox(color: Color(0xA9001424)),
        Scaffold(
          backgroundColor: Colors.transparent,
          resizeToAvoidBottomInset: false,
          bottomNavigationBar: const _TripFormNavigation(),
          body: SafeArea(
            bottom: false,
            child: LayoutBuilder(
              builder: (context, viewport) {
                final compact = viewport.maxHeight < 675;
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 580),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(9, 0, 9, 7),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(
                            height: compact ? 38 : 45,
                            child: Row(
                              children: [
                                IconButton(
                                  tooltip: 'Back to Active Trip',
                                  onPressed: () =>
                                      context.go('/traveller/active'),
                                  icon: const Icon(Icons.arrow_back),
                                ),
                                const Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'WAYHUNTER',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 2,
                                        ),
                                      ),
                                      Text(
                                        'TRAVELLER',
                                        style: TextStyle(
                                          fontSize: 9,
                                          letterSpacing: 2,
                                          color: _cyan,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Profile',
                                  onPressed: () => context.go('/profile'),
                                  icon: const Icon(
                                    Icons.account_circle_outlined,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            height: compact ? 37 : 49,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(icon, color: titleColor, size: 27),
                                const SizedBox(width: 10),
                                Flexible(
                                  child: Text(
                                    title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: compact ? 22 : 25,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            height: compact ? 62 : 74,
                            child: GlassPanel(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 7,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    trip.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'Current stop: $currentStop  ·  Live Trip (demo)',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF9CE9F6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Expanded(child: contentBuilder(context, compact)),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 53,
                            child: _SubmitButton(
                              key: submitKey,
                              label: submitLabel,
                              onPressed: onSubmit,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    ),
  );
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.value,
    this.trailing,
    this.onTap,
    this.valueLines = 1,
  });

  final IconData icon;
  final String title, value;
  final IconData? trailing;
  final VoidCallback? onTap;
  final int valueLines;

  @override
  Widget build(BuildContext context) => GlassPanel(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Row(
        children: [
          Icon(icon, color: _cyan, size: 19),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFA4E7F2),
                    fontSize: 11,
                  ),
                ),
                if (value.isNotEmpty)
                  Text(
                    value,
                    maxLines: valueLines,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
          if (trailing != null) Icon(trailing, color: _cyan, size: 20),
        ],
      ),
    ),
  );
}

class _CaptureButtons extends StatelessWidget {
  const _CaptureButtons({required this.onPhoto, required this.onVideo});
  final VoidCallback onPhoto, onVideo;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: OutlinedButton.icon(
          onPressed: onPhoto,
          icon: const Icon(Icons.photo_camera_outlined, size: 18),
          label: const Text('Photo'),
          style: OutlinedButton.styleFrom(
            padding: EdgeInsets.zero,
            foregroundColor: _cyan,
            side: const BorderSide(color: _cyan),
            visualDensity: VisualDensity.compact,
          ),
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: OutlinedButton.icon(
          onPressed: onVideo,
          icon: const Icon(Icons.videocam_outlined, size: 18),
          label: const Text('Video'),
          style: OutlinedButton.styleFrom(
            padding: EdgeInsets.zero,
            foregroundColor: Colors.white,
            side: const BorderSide(color: Color(0xFF5EADBE)),
            visualDensity: VisualDensity.compact,
          ),
        ),
      ),
    ],
  );
}

class _EvidenceStrip extends StatelessWidget {
  const _EvidenceStrip({
    required this.title,
    required this.evidence,
    required this.onRemove,
    required this.onAdd,
    required this.emptyMessage,
  });

  final String title, emptyMessage;
  final List<TripEvidence> evidence;
  final void Function(String) onRemove;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) => GlassPanel(
    padding: const EdgeInsets.all(8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
            Text(
              '${evidence.length}',
              style: const TextStyle(color: _cyan, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Expanded(
          child: evidence.isEmpty
              ? InkWell(
                  onTap: onAdd,
                  child: Center(
                    child: Text(
                      emptyMessage,
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF9ED7E6),
                        fontSize: 12,
                      ),
                    ),
                  ),
                )
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: evidence.length + 1,
                  separatorBuilder: (_, _) => const SizedBox(width: 7),
                  itemBuilder: (context, index) {
                    if (index == evidence.length) {
                      return InkWell(
                        onTap: onAdd,
                        child: Container(
                          width: 85,
                          decoration: BoxDecoration(
                            border: Border.all(color: _cyan),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_circle_outline, color: _cyan),
                              Text('Add More', style: TextStyle(fontSize: 10)),
                            ],
                          ),
                        ),
                      );
                    }
                    final item = evidence[index];
                    return SizedBox(
                      width: 100,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(11),
                            child: item.video
                                ? const ColoredBox(
                                    color: Color(0xFF064862),
                                    child: Center(
                                      child: Icon(
                                        Icons.play_circle_filled,
                                        size: 37,
                                        color: Colors.white,
                                      ),
                                    ),
                                  )
                                : item.bytes != null
                                ? Image.memory(item.bytes!, fit: BoxFit.cover)
                                : item.path != null
                                ? Image.file(
                                    File(item.path!),
                                    fit: BoxFit.cover,
                                    errorBuilder: (
                                      context,
                                      error,
                                      stackTrace,
                                    ) => const Icon(Icons.photo_outlined),
                                  )
                                : const ColoredBox(
                                    color: Color(0xFF064862),
                                    child: Center(
                                      child: Text(
                                        'DEMO',
                                        style: TextStyle(fontSize: 11),
                                      ),
                                    ),
                                  ),
                          ),
                          Positioned(
                            right: 1,
                            top: 1,
                            child: InkWell(
                              onTap: () => onRemove(item.id),
                              child: const CircleAvatar(
                                radius: 13,
                                backgroundColor: Color(0xD900101B),
                                child: Icon(Icons.close, size: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    ),
  );
}

class _SubmitButton extends StatelessWidget {
  const _SubmitButton({
    super.key,
    required this.label,
    required this.onPressed,
  });
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(18),
      gradient: const LinearGradient(colors: [_cyan, _green]),
      boxShadow: [
        BoxShadow(color: _cyan.withValues(alpha: .3), blurRadius: 12),
      ],
    ),
    child: TextButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.send_outlined, color: Color(0xFF00283C)),
      label: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF00283C),
          fontSize: 16,
          fontWeight: FontWeight.w900,
        ),
      ),
    ),
  );
}

class _TripFormNavigation extends StatelessWidget {
  const _TripFormNavigation();
  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(9, 0, 9, 6),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: NavigationBar(
          height: 64,
          backgroundColor: const Color(0xE6001727),
          indicatorColor: _cyan.withValues(alpha: .26),
          selectedIndex: 1,
          onDestinationSelected: (index) => context.go(switch (index) {
            0 => '/home',
            1 => '/traveller/active',
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

class _NoActiveTrip extends StatelessWidget {
  const _NoActiveTrip();
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('No Active Trip')),
    body: Center(
      child: FilledButton.icon(
        onPressed: () => context.go('/traveller/plans'),
        icon: const Icon(Icons.route),
        label: const Text('Open My Plans'),
      ),
    ),
  );
}
