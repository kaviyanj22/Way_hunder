import 'hunter_models.dart';

abstract interface class HunterRepository {
  HunterSeed load();
  bool isDuplicate(String name);
  String? validateDetails(HunterDraft draft);
}
