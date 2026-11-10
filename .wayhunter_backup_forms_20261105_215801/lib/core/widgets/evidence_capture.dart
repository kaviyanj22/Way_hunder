import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/evidence_service.dart';
import 'glass_panel.dart';
export '../services/evidence_service.dart' show CapturedEvidence;

class EvidenceCapture extends ConsumerStatefulWidget {
  const EvidenceCapture({
    super.key,
    required this.onCaptured,
    this.allowGallery = false,
    this.allowVideo = false,
  });
  final ValueChanged<CapturedEvidence> onCaptured;
  final bool allowGallery;
  final bool allowVideo;
  @override
  ConsumerState<EvidenceCapture> createState() => _EvidenceCaptureState();
}

class _EvidenceCaptureState extends ConsumerState<EvidenceCapture> {
  CameraController? _camera;
  String? _error;
  bool _busy = false;
  bool _video = false;
  Future<void> _open() async {
    if (_busy) return;
    setState(() => _busy = true);
    CameraController? openingCamera;
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) throw StateError('No camera available');
      final camera = CameraController(
        cameras.first,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      openingCamera = camera;
      await camera.initialize();
      if (!mounted) {
        return;
      }
      await _camera?.dispose();
      setState(() {
        _camera = camera;
        _error = null;
      });
      openingCamera = null;
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Camera unavailable or permission denied. Retry, change app permissions, or explicitly use DEMO evidence.',
        );
      }
    } finally {
      if (openingCamera != null) await openingCamera.dispose();
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _capture() async {
    final camera = _camera;
    if (camera == null || _busy) return;
    setState(() => _busy = true);
    try {
      if (_video && !camera.value.isRecordingVideo) {
        await camera.startVideoRecording();
        if (mounted) setState(() => _busy = false);
        return;
      }
      final file = _video
          ? await camera.stopVideoRecording()
          : await camera.takePicture();
      final bytes = _video ? null : await file.readAsBytes();
      if (mounted) {
        widget.onCaptured(
          CapturedEvidence(path: file.path, bytes: bytes, video: _video),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Capture could not finish. Please retry or choose the explicit DEMO fallback.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _gallery() async {
    try {
      final evidence = await ref.read(evidenceServiceProvider).pickGallery();
      if (mounted && evidence != null) widget.onCaptured(evidence);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Gallery is unavailable here. Use the camera or the explicit DEMO fallback.',
        );
      }
    }
  }

  @override
  void dispose() {
    _camera?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => GlassPanel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_camera?.value.isInitialized == true)
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(height: 260, child: CameraPreview(_camera!)),
          )
        else
          const SizedBox(
            height: 140,
            child: Center(child: Icon(Icons.camera_alt_outlined, size: 64)),
          ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              _error!,
              style: const TextStyle(color: Color(0xFFFFCD82)),
            ),
          ),
        if (widget.allowVideo)
          Wrap(
            spacing: 10,
            children: [
              ChoiceChip(
                label: const Text('Photo'),
                selected: !_video,
                onSelected: _camera?.value.isRecordingVideo == true
                    ? null
                    : (_) => setState(() => _video = false),
              ),
              ChoiceChip(
                label: const Text('Silent video'),
                selected: _video,
                onSelected: _camera?.value.isRecordingVideo == true
                    ? null
                    : (_) => setState(() => _video = true),
              ),
            ],
          ),
        if (_camera == null)
          FilledButton.icon(
            onPressed: _busy ? null : _open,
            icon: const Icon(Icons.videocam_outlined),
            label: Text(_busy ? 'Opening camera…' : 'Open live camera'),
          )
        else
          FilledButton.icon(
            onPressed: _busy ? null : _capture,
            icon: Icon(
              _camera!.value.isRecordingVideo
                  ? Icons.stop_circle_outlined
                  : Icons.camera_alt_outlined,
            ),
            label: Text(
              _camera!.value.isRecordingVideo
                  ? 'Stop recording'
                  : _video
                  ? 'Start silent video'
                  : 'Capture photo',
            ),
          ),
        if (widget.allowGallery)
          OutlinedButton.icon(
            onPressed: _busy ? null : _gallery,
            icon: const Icon(Icons.photo_library_outlined),
            label: const Text('Gallery'),
          ),
        TextButton(
          onPressed: _busy
              ? null
              : () => widget.onCaptured(
                  CapturedEvidence(demo: true, video: _video),
                ),
          child: const Text('Use DEMO evidence'),
        ),
        const Text(
          'DEMO fallback is a simulation, not live proof. Native photos stay on this device.',
          style: TextStyle(fontSize: 11),
        ),
      ],
    ),
  );
}
