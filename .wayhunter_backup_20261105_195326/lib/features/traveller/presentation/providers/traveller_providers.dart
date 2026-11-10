import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/local_demo_storage.dart';
import '../../data/repositories/mock_traveller_repository.dart';
import '../../domain/repositories/traveller_repository.dart';

final travellerRepositoryProvider = Provider<TravellerRepository>(
  (ref) => MockTravellerRepository(ref.read(localDemoStorageProvider)),
);
