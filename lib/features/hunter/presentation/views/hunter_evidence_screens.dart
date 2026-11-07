import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'hunter_camera_capture.dart';
import '../../domain/hunter_models.dart';
import '../viewmodels/hunter_view_model.dart';
import 'hunter_ui.dart';

class Hunter360CameraScreen extends ConsumerWidget {
  const Hunter360CameraScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.read(hunterViewModelProvider.notifier);
    final state = ref.watch(hunterViewModelProvider);
    return HunterShell(
      title: 'Live 360 Camera',
      subtitle: 'H-CAM · In-app camera only · no gallery',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HunterPanel(
            child: Column(
              children: [
                const Icon(Icons.threesixty, color: hunterGold, size: 53),
                const SizedBox(height: 8),
                const Text(
                  '360° Location Evidence',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 7),
                const Text(
                  'Choose Silent video, then start and stop recording. A normal video is NOT a verified 360-degree panorama. The prototype labels all submissions DEMO.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: Colors.white70),
                ),
                const SizedBox(height: 10),
                Text(
                  'District: ${state.seed.district} · GPS demo check complete: ${state.draft.gpsChecked ? 'Yes' : 'No'}',
                  style: const TextStyle(fontSize: 11, color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          HunterCameraCapture(
            video: true,
            onCaptured: (captured) {
              if (!captured.video) {
                hunterMessage(
                  context,
                  '360 evidence step requires video. Select Silent video, or use its DEMO video fallback.',
                );
                return;
              }
              if (vm.complete360()) {
                context.go('/hunter/video-complete');
              } else {
                hunterMessage(
                  context,
                  ref.read(hunterViewModelProvider).error ??
                      'Complete GPS and duplicate checks first.',
                );
              }
            },
          ),
          const SizedBox(height: 8),
          HunterAction(
            label: 'Back to Place Details',
            secondary: true,
            icon: Icons.edit_outlined,
            onPressed: () => context.push('/hunter/add'),
          ),
        ],
      ),
    );
  }
}

class HunterVideoCompleteScreen extends ConsumerWidget {
  const HunterVideoCompleteScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(hunterViewModelProvider);
    final vm = ref.read(hunterViewModelProvider.notifier);
    return HunterShell(
      backRoute: '/hunter/add',
      title: '360° Video Complete',
      subtitle: 'UJ-009 · Review / Retake / Add normal photo',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HunterPanel(
            child: Column(
              children: [
                const SizedBox(height: 5),
                const Icon(Icons.threesixty, size: 85, color: hunterGold),
                const SizedBox(height: 9),
                const Text(
                  'Video evidence step completed',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 7),
                const Text(
                  'DEMO: No verified 360 panorama or permanent video storage is available in this build.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: Colors.white70),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: vm.toggle360Preview,
                  icon: const Icon(Icons.play_circle_outline),
                  label: Text(
                    state.previewing360
                        ? 'Close demo preview'
                        : 'Preview evidence (DEMO)',
                  ),
                ),
                if (state.previewing360)
                  const Text(
                    'DEMO preview only · no recording is being played',
                    style: TextStyle(color: hunterGold, fontSize: 11),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 9),
          HunterPanel(
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: hunterGreen, size: 26),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    '360° evidence step completed · ${state.seed.district}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 9),
          HunterAction(
            label: 'Retake 360°',
            icon: Icons.refresh,
            secondary: true,
            onPressed: () {
              vm.retake360();
              context.push('/hunter/camera360');
            },
          ),
          const SizedBox(height: 9),
          HunterAction(
            label: 'Add Normal Photo',
            icon: Icons.camera_alt_outlined,
            green: true,
            onPressed: () => context.push('/hunter/video-attached'),
          ),
        ],
      ),
    );
  }
}

class HunterNormalPhotoCameraScreen extends ConsumerWidget {
  const HunterNormalPhotoCameraScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.read(hunterViewModelProvider.notifier);
    return HunterShell(
      title: 'Normal Photo Camera',
      subtitle: 'UJ-011 · Live photo proof required',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HunterPanel(
            child: const Row(
              children: [
                Icon(Icons.camera_alt_outlined, color: hunterGold),
                SizedBox(width: 9),
                Expanded(
                  child: Text(
                    'Capture live location photo. Gallery uploads are disabled.',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          HunterCameraCapture(
            video: false,
            onCaptured: (captured) {
              if (vm.attachPhoto(
                HunterEvidence(
                  bytes: captured.bytes,
                  path: captured.path,
                  demo: captured.demo,
                ),
              )) {
                context.go('/hunter/review');
              } else {
                hunterMessage(
                  context,
                  ref.read(hunterViewModelProvider).error ??
                      'Finish the 360 recording first.',
                );
              }
            },
          ),
          const SizedBox(height: 10),
          HunterAction(
            label: 'Back to Video Attached',
            icon: Icons.arrow_back,
            secondary: true,
            onPressed: () => context.push('/hunter/video-attached'),
          ),
        ],
      ),
    );
  }
}

class HunterReviewScreen extends ConsumerWidget {
  const HunterReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(hunterViewModelProvider);
    final vm = ref.read(hunterViewModelProvider.notifier);
    final draft = state.draft;
    return HunterShell(
      backRoute: '/hunter/video-attached',
      title: 'Review New Place',
      subtitle: 'UJ-012 · Check all evidence before submission',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HunterPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(Icons.video_file_outlined, color: hunterGold),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        draft.has360
                            ? '360° VIDEO · DEMO evidence attached'
                            : '360° video missing',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 9),
                SizedBox(
                  height: 180,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: draft.photo?.bytes != null
                        ? Image.memory(draft.photo!.bytes!, fit: BoxFit.cover)
                        : DecoratedBox(
                            decoration: const BoxDecoration(
                              color: Color(0xFF104253),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.photo_camera,
                                  size: 53,
                                  color: hunterGold,
                                ),
                                Text(
                                  draft.photo == null
                                      ? 'Normal photo not captured'
                                      : draft.photo!.demo
                                      ? 'DEMO photo evidence'
                                      : 'Live photo attached',
                                ),
                              ],
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 10),
                Text('Place Name: ${draft.name}'),
                Text('Category: ${draft.category.label}'),
                Text('Location: ${draft.address}'),
                Text('Description: ${draft.description}'),
                Text(
                  'GPS: ${draft.gpsChecked ? 'DEMO checked' : 'missing'} · Duplicate: ${draft.duplicateChecked ? 'DEMO checked' : 'missing'}',
                ),
              ],
            ),
          ),
          const SizedBox(height: 9),
          Row(
            children: [
              Expanded(
                child: HunterAction(
                  label: 'Edit Details',
                  icon: Icons.edit_outlined,
                  secondary: true,
                  onPressed: () => context.push('/hunter/video-attached'),
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: HunterAction(
                  label: 'Retake Photo',
                  icon: Icons.camera_alt_outlined,
                  secondary: true,
                  onPressed: () {
                    vm.retakePhoto();
                    context.push('/hunter/photo-camera');
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          HunterAction(
            label: 'Retake 360°',
            icon: Icons.threesixty,
            secondary: true,
            onPressed: () {
              vm.retake360();
              context.push('/hunter/camera360');
            },
          ),
          const SizedBox(height: 10),
          HunterAction(
            label: 'Submit for Verification',
            icon: Icons.send,
            green: true,
            onPressed: () async {
              if (!vm.submit()) {
                await hunterAlert(
                  context,
                  'Check your evidence',
                  ref.read(hunterViewModelProvider).error ??
                      'Please complete the evidence.',
                );
                return;
              }
              if (!context.mounted) return;
              await hunterAlert(
                context,
                'Submitted successfully!',
                'Your place is Pending (local developer demo). You will receive HP only after approval.',
              );
              if (context.mounted) context.go('/hunter/verification');
            },
          ),
        ],
      ),
    );
  }
}

class HunterVerificationScreen extends ConsumerWidget {
  const HunterVerificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(hunterViewModelProvider);
    final selected = state.selected;
    return HunterShell(
      backRoute: '/hunter/rewards',
      title: 'Verification Status',
      subtitle: 'UJ-013 · Submission review',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HunterPanel(
            child: Column(
              children: [
                Icon(
                  selected == null
                      ? Icons.pending_actions
                      : selected.status == HunterStatus.approved
                      ? Icons.verified
                      : selected.status == HunterStatus.rejected
                      ? Icons.cancel_outlined
                      : Icons.hourglass_top,
                  color: selected?.status == HunterStatus.approved
                      ? hunterGreen
                      : hunterGold,
                  size: 72,
                ),
                const SizedBox(height: 9),
                Text(
                  selected?.name ?? 'No selected submission',
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  'Status: ${selected?.status.label ?? 'Unknown'}',
                  style: const TextStyle(fontSize: 17, color: hunterGold),
                ),
                const SizedBox(height: 8),
                Text(
                  selected?.status == HunterStatus.approved
                      ? 'Approved in local demo · HP credited'
                      : selected?.status == HunterStatus.rejected
                      ? 'Rejected: ${selected?.reason ?? 'Evidence needs review'}'
                      : 'Awaiting review · DEMO pending submission',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'No online admin or real verification is connected.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (selected?.status == HunterStatus.pending)
            HunterAction(
              label: 'Developer DEMO Admin Review',
              icon: Icons.admin_panel_settings_outlined,
              onPressed: () => context.push('/hunter/admin-review'),
            ),
          const SizedBox(height: 9),
          HunterAction(
            label: 'View My Discoveries & Rewards',
            icon: Icons.workspace_premium_outlined,
            secondary: true,
            onPressed: () => context.go('/hunter/rewards'),
          ),
          const SizedBox(height: 8),
          HunterAction(
            label: 'Back to Hunter Home',
            icon: Icons.home_outlined,
            secondary: true,
            onPressed: () => context.go('/hunter'),
          ),
        ],
      ),
    );
  }
}
