import 'dart:convert';
import 'dart:typed_data';

import '../../../core/storage/local_demo_storage.dart';
import '../domain/entities/trip.dart';

/// Local-only prototype persistence for a traveller's posts and hazard reports.
/// No API calls are made. Large photos / video paths may remain dependent on
/// device temporary storage; this is not a production media-storage design.
class TravellerActivitySnapshot {
  const TravellerActivitySnapshot({
    required this.memories,
    required this.hazards,
  });
  final List<TripMemory> memories;
  final List<TripHazard> hazards;
}

class TravellerActivityStore {
  TravellerActivityStore(this.storage);
  final LocalDemoStorage storage;

  String _key(String userId) => 'traveller-activity:v1:$userId';

  Map<String, Object?> _encodeEvidence(TripEvidence evidence) => {
    'id': evidence.id,
    'path': evidence.path,
    'video': evidence.video,
    'demo': evidence.demo,
    // SharedPreferences is not meant for large binary content. Only small
    // thumbnail-sized photos are embedded; original media is not uploaded.
    if (evidence.bytes != null && evidence.bytes!.lengthInBytes <= 1024 * 1024)
      'photoBytes': base64Encode(evidence.bytes!),
  };

  TripEvidence _decodeEvidence(Map<String, dynamic> raw) {
    Uint8List? bytes;
    final image = raw['photoBytes'];
    if (image is String) {
      try {
        bytes = base64Decode(image);
      } catch (_) {
        /* Retain metadata. */
      }
    }
    return TripEvidence(
      id: raw['id'] as String? ?? '',
      path: raw['path'] as String?,
      video: raw['video'] == true,
      demo: raw['demo'] == true,
      bytes: bytes,
    );
  }

  Future<TravellerActivitySnapshot?> restore(String userId) async {
    final saved = await storage.readString(_key(userId));
    if (saved == null) return null;
    try {
      final payload = Map<String, dynamic>.from(jsonDecode(saved) as Map);
      final memories = (payload['memories'] as List? ?? const [])
          .map((item) {
            final value = Map<String, dynamic>.from(item as Map);
            return TripMemory(
              id: value['id'] as String,
              tripId: value['tripId'] as String,
              caption: value['caption'] as String,
              stop: value['stop'] as String,
              tags: Set<String>.from(value['tags'] as List? ?? const []),
              evidence: (value['evidence'] as List? ?? const [])
                  .map(
                    (e) => _decodeEvidence(Map<String, dynamic>.from(e as Map)),
                  )
                  .toList(),
            );
          })
          .toList(growable: false);
      final hazards = (payload['hazards'] as List? ?? const [])
          .map((item) {
            final value = Map<String, dynamic>.from(item as Map);
            return TripHazard(
              id: value['id'] as String,
              tripId: value['tripId'] as String,
              type: value['type'] as String,
              description: value['description'] as String,
              stop: value['stop'] as String,
              evidence: (value['evidence'] as List? ?? const [])
                  .map(
                    (e) => _decodeEvidence(Map<String, dynamic>.from(e as Map)),
                  )
                  .toList(),
            );
          })
          .toList(growable: false);
      return TravellerActivitySnapshot(memories: memories, hazards: hazards);
    } catch (_) {
      // Invalid/old local data should never prevent the Traveller app opening.
      return null;
    }
  }

  Future<void> save(
    String userId,
    List<TripMemory> memories,
    List<TripHazard> hazards,
  ) async {
    final payload = <String, Object?>{
      'memories': [
        for (final m in memories)
          {
            'id': m.id,
            'tripId': m.tripId,
            'caption': m.caption,
            'stop': m.stop,
            'tags': m.tags.toList(),
            'evidence': m.evidence.map(_encodeEvidence).toList(),
          },
      ],
      'hazards': [
        for (final h in hazards)
          {
            'id': h.id,
            'tripId': h.tripId,
            'type': h.type,
            'description': h.description,
            'stop': h.stop,
            'evidence': h.evidence.map(_encodeEvidence).toList(),
          },
      ],
    };
    await storage.writeString(_key(userId), jsonEncode(payload));
  }
}
