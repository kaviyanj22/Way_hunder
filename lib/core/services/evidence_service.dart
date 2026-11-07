import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

class CapturedEvidence {
  const CapturedEvidence({
    this.bytes,
    this.path,
    this.demo = false,
    this.video = false,
  });
  final Uint8List? bytes;
  final String? path;
  final bool demo;
  final bool video;
}

class EvidenceService {
  Future<CapturedEvidence?> pickGallery() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1400,
      imageQuality: 85,
    );
    if (file == null) return null;
    return CapturedEvidence(bytes: await file.readAsBytes(), path: file.path);
  }
}

final evidenceServiceProvider = Provider<EvidenceService>(
  (ref) => EvidenceService(),
);
