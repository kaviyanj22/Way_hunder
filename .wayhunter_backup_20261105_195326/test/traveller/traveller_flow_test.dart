import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wayhunter_mobile/app/app_router.dart';
import 'package:wayhunter_mobile/core/constants/app_assets.dart';
import 'package:wayhunter_mobile/features/traveller/presentation/viewmodels/traveller_view_model.dart';
import 'package:wayhunter_mobile/features/traveller/presentation/views/traveller_screens.dart';

import '../widget_test.dart' show boot, demoSignIn, capture, loadReviewFonts;

Future<void> tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull, reason: 'After tapping $finder');
}

Future<void> enter(WidgetTester tester, String key, String value) async {
  final finder = find.byKey(ValueKey(key));
  await tester.ensureVisible(finder);
  await tester.enterText(finder, value);
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull, reason: 'After entering $key');
}

void main() {
  setUpAll(loadReviewFonts);
  testWidgets(
    'Home opens actual Traveller and user completes create, stops, save, active and finish',
    (tester) async {
      final container = await boot(tester);
      await demoSignIn(tester);
      await tap(
        tester,
        find.image(const AssetImage(AppAssets.travellerButton)),
      );
      expect(find.byType(TravellerLandingScreen), findsOneWidget);
      expect(find.textContaining('entry preview'), findsNothing);
      await capture(tester, 'traveller-landing');
      await tap(tester, find.byKey(const ValueKey('traveller-create')));
      await enter(tester, 'trip-title-null', 'Coastal Weekend');
      await tap(tester, find.byKey(const ValueKey('trip-start-date')));
      await tester.tap(find.text('10').hitTestable().first);
      await tester.pumpAndSettle();
      await tap(tester, find.text('OK'));
      await tap(tester, find.byKey(const ValueKey('trip-end-date')));
      await tester.tap(find.text('14').hitTestable().first);
      await tester.pumpAndSettle();
      await tap(tester, find.text('OK'));
      expect(
        tester.takeException(),
        isNull,
        reason: 'After selecting separate start and end dates',
      );
      await tap(tester, find.byKey(const ValueKey('trip-start-location')));
      await tap(tester, find.byKey(const ValueKey('pick-city-Jaffna')));
      await tap(tester, find.byKey(const ValueKey('trip-end-location')));
      await tap(tester, find.byKey(const ValueKey('pick-city-Kandy')));
      await tap(tester, find.byKey(const ValueKey('trip-add-place')));
      await tap(tester, find.byKey(const ValueKey('pick-city-Mannar')));
      await tap(tester, find.byKey(const ValueKey('trip-add-stop')));
      await tap(tester, find.byKey(const ValueKey('trip-edit-route')));
      await tap(tester, find.byTooltip('Move stop 2 down'));
      expect(container.read(travellerViewModelProvider).draft.stops, [
        'Jaffna',
        'Kandy',
        'Mannar',
      ]);
      await tap(tester, find.byTooltip('Move stop 3 up'));
      await tap(tester, find.byKey(const ValueKey('trip-apply-route')));
      await tap(tester, find.byKey(const ValueKey('trip-budget')));
      await enter(tester, 'trip-number-input', '12000');
      await tap(tester, find.text('Apply'));
      await capture(tester, 'traveller-builder');
      await tap(tester, find.byKey(const ValueKey('trip-submit')));
      expect(find.byType(MyPlansScreen), findsOneWidget);
      final trip = container
          .read(travellerViewModelProvider)
          .plans
          .firstWhere((p) => p.title == 'Coastal Weekend');
      await tap(tester, find.byKey(ValueKey('start-${trip.id}')));
      expect(find.byType(ActiveTripScreen), findsOneWidget);
      expect(container.read(travellerViewModelProvider).nearbyLoaded, isFalse);
      await capture(tester, 'traveller-active');
      await tap(tester, find.byKey(const ValueKey('trip-end')));
      await tap(tester, find.byKey(const ValueKey('trip-finish-save')));
      expect(find.byType(MyPlansScreen), findsOneWidget);
      final state = container.read(travellerViewModelProvider);
      expect(state.tab, PlanTab.completed);
      expect(state.active, isNull);
      expect(
        state.filteredPlans.any(
          (p) => p.id == trip.id && p.status == TripStatus.completed,
        ),
        isTrue,
      );
      expect(tester.takeException(), isNull);
      final vm = container.read(travellerViewModelProvider.notifier);
      final other = state.plans.firstWhere(
        (p) => p.id != trip.id && p.ownerId == state.ownerId,
      );
      vm.start(other.id);
      container.read(appRouterProvider).go('/traveller/finish?id=${trip.id}');
      await tester.pumpAndSettle();
      expect(find.text('Coastal Weekend'), findsOneWidget);
      expect(find.text('Open Completed Trips'), findsOneWidget);
    },
  );

  testWidgets(
    'independent active tools submit local evidence, friends and nearby without losing trip',
    (tester) async {
      final container = await boot(tester);
      await demoSignIn(tester);
      final vm = container.read(travellerViewModelProvider.notifier);
      await tester.pumpAndSettle();
      final plan = container.read(travellerViewModelProvider).plans.first;
      expect(vm.start(plan.id), isTrue);
      final router = container.read(appRouterProvider);
      router.go('/traveller/active');
      await tester.pumpAndSettle();
      await tap(tester, find.text('Find Nearby Places'));
      expect(container.read(travellerViewModelProvider).nearbyLoaded, isTrue);
      await tap(tester, find.widgetWithText(ChoiceChip, 'Food'));
      expect(
        container
            .read(travellerViewModelProvider)
            .filteredNearby
            .every((p) => p.category == 'Food'),
        isTrue,
      );
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(ActiveTripScreen), findsOneWidget);
      await tap(tester, find.text('Road Alert'));
      await tap(tester, find.text('Show Estimated Alternative'));
      expect(container.read(travellerViewModelProvider).alternateRoute, isTrue);
      await tap(tester, find.text('Resume trip'));
      await tap(tester, find.text('Report Hazard'));
      await enter(tester, 'hazard-description', 'A tree blocks the demo road.');
      await tap(tester, find.text('Use DEMO evidence'));
      await tap(tester, find.text('Submit Local Report'));
      expect(container.read(travellerViewModelProvider).hazards.length, 1);
      expect(find.byType(ActiveTripScreen), findsOneWidget);
      await tap(tester, find.text('Add Memories'));
      await enter(tester, 'memory-caption', 'A beautiful demo stop.');
      await tap(tester, find.text('Use DEMO evidence'));
      await tap(tester, find.text('Post Memories Locally'));
      expect(container.read(travellerViewModelProvider).memories.length, 1);
      await tap(tester, find.text('Trip Friends'));
      await tap(tester, find.text('Send DEMO check-in alert'));
      expect(container.read(travellerViewModelProvider).alerted, isNotEmpty);
      await tap(tester, find.text('Invite / Accept Friends'));
      await enter(tester, 'invite-name', 'New Friend');
      await tap(tester, find.text('Create DEMO Invitation'));
      await tap(tester, find.text('Simulate Accept'));
      expect(
        container.read(travellerViewModelProvider).invitations.single.accepted,
        isTrue,
      );
      await tap(tester, find.text('View Trip Friends'));
      await tap(tester, find.text('Return to Active Trip'));
      expect(container.read(travellerViewModelProvider).active?.id, plan.id);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'AI and connected previous segments are optional editable planning branches',
    (tester) async {
      final container = await boot(tester);
      await demoSignIn(tester);
      final router = container.read(appRouterProvider);
      final vm = container.read(travellerViewModelProvider.notifier);
      router.go('/traveller/create');
      await tester.pumpAndSettle();
      await tap(tester, find.byKey(const ValueKey('trip-ai')));
      await tap(tester, find.text('Generate plan'));
      expect(find.byType(AiTripPlanScreen), findsOneWidget);
      await tap(tester, find.text('Save AI Plan'));
      expect(find.byType(MyPlansScreen), findsOneWidget);
      expect(
        container
            .read(travellerViewModelProvider)
            .plans
            .any((p) => p.method == TripMethod.ai),
        isTrue,
      );
      vm.newTrip();
      router.go('/traveller/create');
      await tester.pumpAndSettle();
      await tap(tester, find.byKey(const ValueKey('trip-previous-plans')));
      await tap(tester, find.byType(CheckboxListTile).first);
      await tap(tester, find.text('Use Selected Segments'));
      expect(find.byType(TripBuilderScreen), findsOneWidget);
      expect(container.read(travellerViewModelProvider).draft.stops.length, 2);
      expect(
        container.read(travellerViewModelProvider).draft.method,
        TripMethod.previous,
      );
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(TravellerLandingScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'all fourteen Traveller screens render at 320 pixels with working Back destinations',
    (tester) async {
      final container = await boot(tester, size: const Size(320, 640));
      await demoSignIn(tester);
      final vm = container.read(travellerViewModelProvider.notifier);
      final router = container.read(appRouterProvider);
      vm.start(container.read(travellerViewModelProvider).plans.first.id);
      vm.edit(container.read(travellerViewModelProvider).active!);
      const paths = [
        '/traveller',
        '/traveller/create',
        '/traveller/ai',
        '/traveller/reuse',
        '/traveller/plans',
        '/traveller/active',
        '/traveller/nearby',
        '/traveller/road-alert',
        '/traveller/hazard',
        '/traveller/memories',
        '/traveller/friends',
        '/traveller/finish',
        '/traveller/review',
        '/traveller/invites',
      ];
      for (final path in paths) {
        router.go(path);
        await tester.pumpAndSettle();
        expect(router.state.uri.path, path);
        expect(find.textContaining('entry preview'), findsNothing);
        expect(tester.takeException(), isNull, reason: path);
      }
      await tap(
        tester,
        find.widgetWithText(SwitchListTile, 'Demo safety alerts'),
      );
      expect(
        container.read(travellerViewModelProvider).safetyAlertsEnabled,
        isFalse,
      );
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(router.state.uri.path, '/traveller/friends');
      expect(find.text('Safety alerts paused'), findsOneWidget);
    },
  );
}
