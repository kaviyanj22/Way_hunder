import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/mock_home_repository.dart';
import '../../domain/entities/home_content.dart';
import '../../domain/repositories/home_repository.dart';

final homeRepositoryProvider = Provider<HomeRepository>(
  (ref) => MockHomeRepository(),
);
final homeViewModelProvider = NotifierProvider<HomeViewModel, HomeState>(
  HomeViewModel.new,
);

class HomeState {
  const HomeState({
    required this.content,
    this.query = '',
    this.readNotifications = const {},
  });
  final HomeContent content;
  final String query;
  final Set<String> readNotifications;
  List<DemoPlace> get searchResults {
    final term = query.trim().toLowerCase();
    if (term.isEmpty) return content.places;
    return content.places
        .where(
          (p) => '${p.name} ${p.district} ${p.category}'.toLowerCase().contains(
            term,
          ),
        )
        .toList(growable: false);
  }

  int get unreadCount => content.notifications
      .where((n) => !readNotifications.contains(n.id))
      .length;
}

class HomeViewModel extends Notifier<HomeState> {
  @override
  HomeState build() =>
      HomeState(content: ref.watch(homeRepositoryProvider).load());
  void search(String query) => state = HomeState(
    content: state.content,
    query: query,
    readNotifications: state.readNotifications,
  );
  void markNotificationsRead() => state = HomeState(
    content: state.content,
    query: state.query,
    readNotifications: Set.unmodifiable(
      state.content.notifications.map((n) => n.id),
    ),
  );
}
