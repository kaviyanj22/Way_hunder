import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/device_permission_service.dart';
import '../../../../core/storage/local_demo_storage.dart';
import '../../../auth/presentation/viewmodels/auth_view_model.dart';
import '../../domain/hunter_models.dart';
import '../providers/hunter_providers.dart';

const _keep = Object();

class HunterState {
  const HunterState({
    required this.seed,
    required this.userId,
    required this.submissions,
    this.draft = const HunterDraft(),
    this.error,
    this.notice,
    this.locationStatus =
        'District is a DEMO selection, not verified live GPS.',
    this.busy = false,
    this.selectedId,
    this.query = '',
    this.rewardsTab = 'All',
    this.leaderboardFilter = 'District',
    this.previewing360 = false,
  });
  final HunterSeed seed;
  final String userId;
  final List<HunterSubmission> submissions;
  final HunterDraft draft;
  final String? error;
  final String? notice;
  final String locationStatus;
  final bool busy;
  final String? selectedId;
  final String query;
  final String rewardsTab;
  final String leaderboardFilter;
  final bool previewing360;
  HunterSubmission? get selected {
    for (final submission in submissions) {
      if (submission.id == selectedId) return submission;
    }
    return null;
  }

  List<HunterSubmission> get discoveries => submissions
      .where(
        (s) =>
            s.userId == userId &&
            s.district == seed.district &&
            s.name.toLowerCase().contains(query.toLowerCase()),
      )
      .toList(growable: false);
  List<HunterSubmission> get filteredSubmissions => discoveries
      .where((s) => rewardsTab == 'All' || s.status.label == rewardsTab)
      .toList(growable: false);
  HunterState copyWith({
    HunterDraft? draft,
    List<HunterSubmission>? submissions,
    Object? error = _keep,
    Object? notice = _keep,
    String? locationStatus,
    bool? busy,
    String? selectedId,
    String? query,
    String? rewardsTab,
    String? leaderboardFilter,
    bool? previewing360,
  }) => HunterState(
    seed: seed,
    userId: userId,
    submissions: submissions ?? this.submissions,
    draft: draft ?? this.draft,
    error: identical(error, _keep) ? this.error : error as String?,
    notice: identical(notice, _keep) ? this.notice : notice as String?,
    locationStatus: locationStatus ?? this.locationStatus,
    busy: busy ?? this.busy,
    selectedId: selectedId ?? this.selectedId,
    query: query ?? this.query,
    rewardsTab: rewardsTab ?? this.rewardsTab,
    leaderboardFilter: leaderboardFilter ?? this.leaderboardFilter,
    previewing360: previewing360 ?? this.previewing360,
  );
}

final hunterViewModelProvider = NotifierProvider<HunterViewModel, HunterState>(
  HunterViewModel.new,
);

class HunterViewModel extends Notifier<HunterState> {
  @override
  HunterState build() {
    final seed = ref.watch(hunterRepositoryProvider).load();
    final userId =
        ref.watch(authViewModelProvider.select((s) => s.user?.id)) ??
        seed.userId;
    Future.microtask(() => _restore(userId));
    return HunterState(
      seed: seed,
      userId: userId,
      submissions: seed.submissions.where((s) => s.userId == userId).toList(),
      draft: HunterDraft(address: seed.district),
    );
  }

  String get _storageKey => 'hunterSubmissions:${state.userId}';
  Future<void> _restore(String userId) async {
    try {
      final json = await ref
          .read(localDemoStorageProvider)
          .readString('hunterSubmissions:$userId');
      if (!ref.mounted || state.userId != userId || json == null) return;
      final entries = (jsonDecode(json) as List)
          .map(
            (e) =>
                HunterSubmission.fromJson(Map<String, Object?>.from(e as Map)),
          )
          .where((s) => s.userId == userId)
          .toList();
      if (state.submissions.every(
        (s) => state.seed.submissions.any((base) => base.id == s.id),
      )) {
        state = state.copyWith(submissions: entries);
      }
    } catch (_) {
      /* Invalid local demo data leaves centralized seeds available. */
    }
  }

  void _persist() {
    final value = jsonEncode(state.submissions.map((s) => s.toJson()).toList());
    unawaited(
      ref.read(localDemoStorageProvider).writeString(_storageKey, value),
    );
  }

  bool _fail(String text) {
    state = state.copyWith(error: text, notice: null);
    return false;
  }

  void beginDiscovery() => state = state.copyWith(
    draft: HunterDraft(address: state.seed.district),
    error: null,
    notice: null,
    previewing360: false,
  );
  void updateDetails({
    String? name,
    String? address,
    String? description,
    HunterCategory? category,
  }) {
    state = state.copyWith(
      draft: state.draft.copyWith(
        name: name,
        address: address,
        description: description,
        category: category,
        gpsChecked: false,
        duplicateChecked: false,
      ),
      error: null,
      notice: null,
    );
  }

  bool validateDetails() {
    final error = ref
        .read(hunterRepositoryProvider)
        .validateDetails(state.draft);
    if (error != null) return _fail(error);
    state = state.copyWith(error: null);
    return true;
  }

  void setRestricted(bool value) => state = state.copyWith(
    draft: state.draft.copyWith(
      restricted: value,
      gpsChecked: false,
      duplicateChecked: false,
    ),
    error: null,
  );
  void setDuplicateSimulation(bool value) => state = state.copyWith(
    draft: state.draft.copyWith(
      simulateDuplicate: value,
      duplicateChecked: false,
    ),
    error: null,
  );
  Future<void> requestGpsPermission() async {
    if (state.busy) return;
    state = state.copyWith(busy: true, error: null);
    final result = await ref
        .read(devicePermissionServiceProvider)
        .requestLocation();
    if (!ref.mounted) return;
    state = state.copyWith(
      busy: false,
      locationStatus:
          '$result District validation still uses the explicit DEMO check below.',
    );
  }

  Future<bool> openSettings() async {
    final opened = await ref
        .read(devicePermissionServiceProvider)
        .openSettings();
    if (ref.mounted) {
      state = state.copyWith(
        notice: opened ? 'Return here after changing permission and retry.' : 'App settings are unavailable on this device. Demo checks remain available.',
      );
    }
    return opened;
  }

  bool runDemoGpsCheck() {
    if (!validateDetails()) return false;
    if (state.draft.restricted) {
      return _fail(
        'DEMO restricted zone. Move to an allowed location or turn off the simulation to retry.',
      );
    }
    state = state.copyWith(
      draft: state.draft.copyWith(gpsChecked: true),
      error: null,
      notice:
          'DEMO district check passed for ${state.seed.district}. This is not a verified GPS boundary.',
    );
    return true;
  }

  bool checkDuplicate() {
    if (!state.draft.gpsChecked) {
      return _fail('Complete the location check first.');
    }
    final existing =
        ref.read(hunterRepositoryProvider).isDuplicate(state.draft.name) ||
        state.submissions.any(
          (s) => s.name.toLowerCase() == state.draft.name.trim().toLowerCase(),
        );
    if (state.draft.simulateDuplicate || existing) {
      return _fail(
        'Possible duplicate in this DEMO check. Try another name/location. Distance (200 m) and image similarity are simulated, not secure verification.',
      );
    }
    state = state.copyWith(
      draft: state.draft.copyWith(duplicateChecked: true),
      error: null,
      notice: 'No matching demo name found. The 200 m/image checks are illustrative only.',
    );
    return true;
  }

  bool complete360() {
    if (!state.draft.gpsChecked || !state.draft.duplicateChecked) {
      return _fail(
        'Complete location and duplicate checks before the evidence step.',
      );
    }
    state = state.copyWith(
      draft: state.draft.copyWith(has360: true),
      previewing360: false,
      error: null,
      notice: 'DEMO 360 evidence attached. No real 360 video was recorded.',
    );
    return true;
  }

  void retake360() => state = state.copyWith(
    draft: state.draft.copyWith(has360: false, clearPhoto: true),
    previewing360: false,
    error: null,
  );
  void toggle360Preview() => state = state.copyWith(
    previewing360: !state.previewing360,
    notice: 'DEMO visual playback only. There is no recorded 360 video file.',
  );
  bool attachPhoto(HunterEvidence evidence) {
    if (!state.draft.has360 ||
        !state.draft.duplicateChecked ||
        !state.draft.gpsChecked) {
      return _fail('Complete the required checks and 360 evidence step first.');
    }
    state = state.copyWith(
      draft: state.draft.copyWith(photo: evidence),
      error: null,
    );
    return true;
  }

  void retakePhoto() => state = state.copyWith(
    draft: state.draft.copyWith(clearPhoto: true),
    error: null,
  );
  bool submit() {
    if (!validateDetails()) return false;
    final draft = state.draft;
    if (!draft.gpsChecked ||
        !draft.duplicateChecked ||
        !draft.has360 ||
        draft.photo == null) {
      return _fail(
        'Complete GPS, duplicate check, 360 evidence and a normal photo before submitting.',
      );
    }
    if (state.submissions.any(
      (s) => s.name.toLowerCase() == draft.name.trim().toLowerCase(),
    )) {
      return _fail('This discovery has already been submitted.');
    }
    final id = 'hunter-local-${DateTime.now().microsecondsSinceEpoch}';
    final submission = HunterSubmission(
      id: id,
      userId: state.userId,
      name: draft.name.trim(),
      district: state.seed.district,
      category: draft.category.label,
      description: draft.description.trim(),
      address: draft.address.trim(),
      status: HunterStatus.pending,
      demoEvidence: true,
      photo: draft.photo,
    );
    state = state.copyWith(
      submissions: [...state.submissions, submission],
      selectedId: id,
      error: null,
      notice: 'Submission saved as Pending. No rewards are awarded until developer demo approval.',
    );
    _persist();
    return true;
  }

  void selectSubmission(String id) =>
      state = state.copyWith(selectedId: id, error: null, notice: null);
  bool moderate(HunterStatus decision) {
    final submission = state.selected;
    if (submission == null) return _fail('Select a submission first.');
    if (submission.status != HunterStatus.pending) {
      return _fail('A final decision already exists for this submission.');
    }
    if (decision == HunterStatus.pending) {
      return _fail('Choose Approved or Rejected.');
    }
    state = state.copyWith(
      submissions: state.submissions
          .map(
            (s) => s.id == submission.id
                ? s.withStatus(
                    decision,
                    reason: decision == HunterStatus.rejected
                        ? 'Developer demo review: evidence needs another review.'
                        : null,
                  )
                : s,
          )
          .toList(),
      error: null,
      notice: decision == HunterStatus.approved
          ? 'Approved in the local developer demo. Hunter rewards added once.'
          : 'Rejected in the local developer demo. No rewards added.',
    );
    if (decision == HunterStatus.approved) {
      ref.read(hunterRewardCreditProvider)(
        sourceId: 'hunter:${submission.id}',
        hp: state.seed.rewardHp,
        title: 'Approved Hunter discovery: ${submission.name}',
      );
    }
    _persist();
    return true;
  }

  void search(String value) => state = state.copyWith(query: value);
  void setRewardsTab(String value) => state = state.copyWith(rewardsTab: value);
  void setLeaderboardFilter(String value) =>
      state = state.copyWith(leaderboardFilter: value);
}
