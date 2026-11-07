import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../../../core/services/evidence_service.dart';
import 'hunter_ui.dart';

/// Hunter-only live camera widget: no gallery, switch cameras, photo or video.
/// A video captured here is not guaranteed to be a true panoramic 360 video.
class HunterCameraCapture extends StatefulWidget {
  const HunterCameraCapture({
    super.key,
    required this.video,
    required this.onCaptured,
  });
  final bool video;
  final ValueChanged<CapturedEvidence> onCaptured;

  @override
  State<HunterCameraCapture> createState() => _HunterCameraCaptureState();
}

class _HunterCameraCaptureState extends State<HunterCameraCapture> {
  CameraController? _camera;
  List<CameraDescription> _cameras = const [];
  int _selectedCamera = 0;
  bool _busy = false;
  bool _recording = false;
  String? _error;

  Future<void> _openCamera({bool switchCamera = false}) async {
    if (_busy || _recording) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    CameraController? next;
    try {
      final cameras = _cameras.isEmpty ? await availableCameras() : _cameras;
      if (cameras.isEmpty) throw StateError('No phone camera was detected');
      final index = switchCamera
          ? (_selectedCamera + 1) % cameras.length
          : _selectedCamera;
      next = CameraController(
        cameras[index],
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await next.initialize();
      if (!mounted) return;
      final previous = _camera;
      setState(() {
        _cameras = cameras;
        _selectedCamera = index;
        _camera = next;
        _error = null;
      });
      next = null;
      await previous?.dispose();
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Camera unavailable or permission denied. Retry, open device settings, or use the explicit DEMO option.',
        );
      }
    } finally {
      if (next != null) await next.dispose();
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _capture() async {
    final camera = _camera;
    if (camera == null || _busy) return;
    setState(() => _busy = true);
    try {
      if (widget.video && !_recording) {
        await camera.startVideoRecording();
        if (mounted) setState(() => _recording = true);
      } else {
        final image = widget.video
            ? await camera.stopVideoRecording()
            : await camera.takePicture();
        final bytes = widget.video ? null : await image.readAsBytes();
        if (mounted) {
          setState(() => _recording = false);
          widget.onCaptured(
            CapturedEvidence(
              path: image.path,
              bytes: bytes,
              video: widget.video,
            ),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _recording = false;
          _error = 'Camera capture failed. Try again or select the DEMO evidence option.';
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    // The controller is released when this route leaves the navigation tree.
    _camera?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ready = _camera?.value.isInitialized == true;
    return HunterPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(17),
            child: SizedBox(
              height: 255,
              child: ready
                  ? CameraPreview(_camera!)
                  : const DecoratedBox(
                      decoration: BoxDecoration(color: Color(0xFF052935)),
                      child: Center(
                        child: Icon(
                          Icons.camera_outlined,
                          color: hunterGold,
                          size: 76,
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 10),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                _error!,
                style: const TextStyle(color: Color(0xFFFFBB90), fontSize: 11),
              ),
            ),
          if (!ready)
            HunterAction(
              label: _busy ? 'Opening camera...' : 'Open Live Camera',
              icon: Icons.camera_alt_outlined,
              onPressed: _busy ? null : () => _openCamera(),
            )
          else ...[
            Row(
              children: [
                Expanded(
                  child: HunterAction(
                    label: _recording
                        ? 'Stop & Use Video'
                        : widget.video
                        ? 'Start Video'
                        : 'Capture Photo',
                    icon: _recording
                        ? Icons.stop_circle_outlined
                        : widget.video
                        ? Icons.videocam_outlined
                        : Icons.camera_alt_outlined,
                    green: true,
                    onPressed: _busy ? null : _capture,
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 55,
                  height: 45,
                  child: IconButton.filledTonal(
                    tooltip: 'Switch front / rear camera',
                    onPressed: _busy || _recording || _cameras.length < 2
                        ? null
                        : () => _openCamera(switchCamera: true),
                    icon: const Icon(Icons.flip_camera_android_outlined),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 9),
          HunterAction(
            label: widget.video
                ? 'Use DEMO video evidence'
                : 'Use DEMO photo evidence',
            icon: Icons.science_outlined,
            secondary: true,
            onPressed: _busy || _recording
                ? null
                : () => widget.onCaptured(
                    CapturedEvidence(demo: true, video: widget.video),
                  ),
          ),
          const SizedBox(height: 7),
          Text(
            widget.video
                ? 'Video timestamp comes from the local capture. True 360° coverage, orientation and GPS verification are not guaranteed in this prototype.'
                : 'Captured photo uses the device camera. Gallery evidence is not accepted; DEMO evidence is explicitly labelled.',
            style: const TextStyle(fontSize: 10, color: Colors.white70),
          ),
        ],
      ),
    );
  }
}
