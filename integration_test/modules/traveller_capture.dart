import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wayhunter_mobile/features/traveller/presentation/viewmodels/traveller_view_model.dart';

import '../screenshot_harness.dart';

/// Visits the production Traveller routes and their locally simulated branches.
/// The existing catalog and ViewModel methods supply all application state.
Future<void> captureTraveller(ScreenshotHarness h) async {
  await h.reset();
  const module = 'traveller';
  var number = 0;
  Future<void> shot(
    String slug,
    String name,
    String route, {
    String notes = '',
  }) async {
    number++;
    await h.capture(
      module,
      '${number.toString().padLeft(2, '0')}_$slug.png',
      name,
      route,
      notes: notes,
    );
  }

  Future<void> dismiss() async {
    h.router.pop();
    await h.settle();
  }

  Future<void> lower() async {
    final scroll = find.byType(SingleChildScrollView).first;
    if (scroll.evaluate().isNotEmpty) {
      await h.tester.drag(scroll, const Offset(0, -460));
      await h.settle();
    }
  }

  TravellerViewModel getVm() =>
      h.container.read(travellerViewModelProvider.notifier);
  TravellerState getState() => h.container.read(travellerViewModelProvider);

  await h.attempt(module, 'Traveller landing map', '/traveller', () async {
    await h.go('/traveller');
    await shot('landing', 'Traveller landing map', '/traveller');
  });

  await h.attempt(
    module,
    'Trip builder and selectors',
    '/traveller/create',
    () async {
      getVm().newTrip();
      await h.go('/traveller/create');
      await shot(
        'create_trip_empty',
        'Create trip — empty draft',
        '/traveller/create',
      );
      await h.tap(find.byKey(const ValueKey('trip-submit')));
      await shot(
        'create_trip_validation',
        'Create trip — validation feedback',
        '/traveller/create',
      );

      await h.tap(find.byKey(const ValueKey('trip-start-date')));
      await shot('date_picker', 'Trip start date picker', '/traveller/create');
      await h.tap(find.text('Cancel').last);
      await h.tap(find.byKey(const ValueKey('trip-start-location')));
      await shot(
        'location_picker',
        'Trip location search picker',
        '/traveller/create',
      );
      await h.tester.enterText(
        find.byKey(const ValueKey('trip-location-search')),
        'no-matching-demo-location',
      );
      await h.settle();
      await shot(
        'location_no_results',
        'Trip location search — no results',
        '/traveller/create',
      );
      await h.tap(find.byTooltip('Choose on map'));
      await shot(
        'location_map_picker',
        'Trip location map picker',
        '/traveller/create',
      );
      await h.tap(find.byTooltip('Close location picker'));

      final plan = getState().catalog.plans.first;
      getVm().edit(plan);
      await h.settle();
      await shot(
        'create_trip_filled',
        'Create trip — existing demo route',
        '/traveller/create',
      );
      for (final item in [
        ('trip-budget', 'budget_picker', 'Trip budget dialog'),
        ('trip-vehicle', 'vehicle_picker', 'Trip vehicle dialog'),
        ('trip-people', 'people_picker', 'Trip people count dialog'),
      ]) {
        await h.tap(find.byKey(ValueKey(item.$1)));
        await shot(item.$2, item.$3, '/traveller/create');
        await dismiss();
      }
      await h.tap(find.byKey(const ValueKey('trip-edit-route')));
      await shot(
        'route_editor_sheet',
        'Trip route reorder editor',
        '/traveller/create',
      );
      await h.tap(find.byTooltip('Cancel route edits'));
      await h.tap(find.byTooltip('Actions for stop 2'));
      await shot(
        'stop_actions',
        'Trip stop edit/reorder/remove menu',
        '/traveller/create',
      );
      await dismiss();
      await h.tap(find.byKey(const ValueKey('trip-ai')));
      await shot(
        'ai_confirmation',
        'Prepare AI plan confirmation',
        '/traveller/create',
      );
      await h.tap(find.text('Cancel').last);
      final idea = getState().catalog.suggestions.first;
      await h.tap(find.byKey(ValueKey('edit-${idea.id}')));
      expect(find.text('Edit suggested idea?'), findsOneWidget);
      await shot(
        'replace_idea_confirmation',
        'Replace route with suggested idea confirmation',
        '/traveller/create',
      );
      await h.tap(find.text('Cancel').last);
    },
  );

  await h.attempt(module, 'Edit Route review', '/traveller/review', () async {
    getVm().edit(getState().catalog.plans.first);
    await h.go('/traveller/review');
    await shot('route_review', 'Edit Route review', '/traveller/review');
    await lower();
    await shot(
      'route_review_controls',
      'Edit Route — stop controls',
      '/traveller/review',
    );
    await h.tap(find.byKey(const ValueKey('trip-add-stop')));
    await shot(
      'route_review_add_stop',
      'Edit Route — choose stop',
      '/traveller/review',
    );
    await dismiss();
  });

  await h.attempt(module, 'AI plan tabs', '/traveller/ai', () async {
    getVm().generateAi();
    await h.go('/traveller/ai');
    await shot('ai_day_plan', 'AI trip itinerary', '/traveller/ai');
    for (final tab in ['Stays', 'Budget']) {
      await h.tap(find.widgetWithText(ChoiceChip, tab));
      await shot('ai_${tab.toLowerCase()}', 'AI trip — $tab', '/traveller/ai');
    }
  });

  await h.attempt(
    module,
    'Reuse route segments tabs',
    '/traveller/reuse',
    () async {
      await h.go('/traveller/reuse');
      await shot(
        'reuse_segments',
        'Previous traveller — route segments',
        '/traveller/reuse',
      );
      for (final tab in [
        ('Photos & memories', 'photos'),
        ('Stays', 'stays'),
        ('Traveller notes', 'notes'),
      ]) {
        await h.tap(find.widgetWithText(ChoiceChip, tab.$1));
        await shot(
          'reuse_${tab.$2}',
          'Previous traveller — ${tab.$1}',
          '/traveller/reuse',
        );
      }
    },
  );

  await h.attempt(
    module,
    'Suggested trip details',
    '/traveller/suggestion/:id',
    () async {
      final id = getState().catalog.suggestions.first.id;
      final route = '/traveller/suggestion/$id';
      await h.go(route);
      await shot('suggestion_overview', 'Suggested trip overview', route);
      await lower();
      await shot(
        'suggestion_overview_lower',
        'Suggested trip itinerary and stays',
        route,
      );
      // Return to the top so the actual horizontal tab bar remains accessible.
      await h.go('/home');
      await h.go(route);
      for (final tab in [
        ('Photos & Memories', 'photos'),
        ('Stays', 'stays'),
        ('Traveller Notes', 'notes'),
      ]) {
        await h.tap(find.text(tab.$1).first);
        await shot('suggestion_${tab.$2}', 'Suggested trip — ${tab.$1}', route);
      }
      await h.tap(find.text('Edit Plan').first);
      await shot('suggestion_edit', 'Suggested trip route editor', route);
      await h.tap(find.byTooltip('Cancel route edits'));
    },
  );

  await h.attempt(module, 'Saved plan tabs', '/traveller/plans', () async {
    getVm().setTab(PlanTab.mine);
    await h.go('/traveller/plans');
    await shot('my_plans', 'My Plans', '/traveller/plans');
    for (final tab in [PlanTab.shared, PlanTab.completed]) {
      getVm().setTab(tab);
      await h.settle();
      await shot(
        'plans_${tab.name}',
        'My Plans — ${tab.name}',
        '/traveller/plans',
      );
    }
  });

  await h.attempt(module, 'Active trip', '/traveller/active', () async {
    final state = getState();
    final plan = state.plans.firstWhere(
      (p) => p.ownerId == state.ownerId && p.status != TripStatus.completed,
    );
    getVm().start(plan.id);
    await h.go('/traveller/active');
    await shot('active_trip', 'Active trip dashboard', '/traveller/active');
    getVm().nextStop();
    await h.settle();
    await shot(
      'active_trip_progress',
      'Active trip — demo next stop',
      '/traveller/active',
    );
  });

  await h.attempt(
    module,
    'Nearby places and details',
    '/traveller/nearby',
    () async {
      await h.go('/traveller/nearby');
      await shot(
        'nearby_on_demand',
        'Nearby places before on-demand search',
        '/traveller/nearby',
      );
      getVm().loadNearby();
      await h.settle();
      await shot(
        'nearby_all',
        'Nearby places — all categories',
        '/traveller/nearby',
      );
      for (final category in [
        'Hotel',
        'Food',
        'Fuel',
        'Hospital',
        'Attraction',
      ]) {
        getVm().category(category);
        await h.settle();
        await shot(
          'nearby_${category.toLowerCase()}',
          'Nearby places — $category',
          '/traveller/nearby',
        );
      }
      getVm().category('All');
      await h.settle();
      await h.tap(find.text('View details').first);
      await shot(
        'nearby_details',
        'Nearby place details dialog',
        '/traveller/nearby',
      );
      await h.tap(find.text('Close').last);
    },
  );

  await h.attempt(
    module,
    'Road alert and alternative',
    '/traveller/road-alert',
    () async {
      await h.go('/traveller/road-alert');
      await shot('road_alert', 'Road alert ahead', '/traveller/road-alert');
      await h.tap(find.text('View details').first);
      await shot(
        'road_alert_details',
        'Road alert details dialog',
        '/traveller/road-alert',
      );
      await h.tap(find.text('Close').last);
      getVm().alternativeRoute();
      await h.settle();
      await shot(
        'road_alternative',
        'Estimated alternative route demonstration',
        '/traveller/road-alert',
      );
    },
  );

  await h.attempt(
    module,
    'Hazard report states',
    '/traveller/hazard',
    () async {
      await h.go('/traveller/hazard');
      await shot('hazard', 'Report hazard', '/traveller/hazard');
      await h.tap(find.byKey(const ValueKey('fixed-hazard-submit')));
      await shot(
        'hazard_validation',
        'Hazard report required details',
        '/traveller/hazard',
      );
      await h.tap(find.text('OK').last);
      await h.tap(find.text('Hazard Type *'));
      await shot(
        'hazard_types',
        'Choose hazard type sheet',
        '/traveller/hazard',
      );
      await dismiss();
      await h.tap(find.text('Reason / Description *'));
      FocusManager.instance.primaryFocus?.unfocus();
      await SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
      await h.settle();
      await shot(
        'hazard_description',
        'Hazard description editor',
        '/traveller/hazard',
      );
      await h.tap(find.text('Cancel').last);
      await h.tap(find.text('Photo').first);
      await shot(
        'hazard_photo_sheet',
        'Hazard photo evidence capture',
        '/traveller/hazard',
      );
      await dismiss();
      await h.tap(find.text('Video').first);
      await shot(
        'hazard_video_sheet',
        'Hazard video evidence capture',
        '/traveller/hazard',
      );
      await h.tap(find.text('Use DEMO evidence'));
      getVm().hazardDraft(description: getState().catalog.roadAlertDescription);
      await h.settle();
      await shot(
        'hazard_filled',
        'Hazard report with labeled demo evidence',
        '/traveller/hazard',
      );
      await h.tap(find.byKey(const ValueKey('fixed-hazard-submit')));
      await shot(
        'hazard_success',
        'Hazard report submitted locally',
        '/traveller/hazard',
      );
      await h.tap(find.text('OK').last);
    },
  );

  await h.attempt(module, 'Memory states', '/traveller/memories', () async {
    await h.go('/traveller/memories');
    await shot('memory', 'Add memories', '/traveller/memories');
    await h.tap(find.byKey(const ValueKey('fixed-memory-submit')));
    await shot(
      'memory_validation',
      'Memory required details',
      '/traveller/memories',
    );
    await h.tap(find.text('OK').last);
    await h.tap(find.text('Caption / Description *'));
    FocusManager.instance.primaryFocus?.unfocus();
    await SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
    await h.settle();
    await shot(
      'memory_caption',
      'Memory caption editor',
      '/traveller/memories',
    );
    await h.tap(find.text('Cancel').last);
    await h.tap(find.text('Photo').first);
    await shot(
      'memory_photo_sheet',
      'Memory photo evidence capture',
      '/traveller/memories',
    );
    await h.tap(find.text('Use DEMO evidence'));
    getVm().caption(getState().active!.title);
    getVm().tag('Scenic');
    await h.settle();
    await shot(
      'memory_filled',
      'Memory with caption and demo attachment',
      '/traveller/memories',
    );
    await h.tap(find.byKey(const ValueKey('fixed-memory-submit')));
    await shot(
      'memory_success',
      'Memory submitted locally',
      '/traveller/memories',
    );
    await h.tap(find.text('OK').last);
  });

  await h.attempt(
    module,
    'Trip friends and deviation',
    '/traveller/friends',
    () async {
      await h.go('/traveller/friends');
      await shot('friends', 'Trip friends — all', '/traveller/friends');
      for (final filter in [FriendFilter.nearby, FriendFilter.far]) {
        getVm().friendFilter(filter);
        await h.settle();
        await shot(
          'friends_${filter.name}',
          'Trip friends — ${filter.name}',
          '/traveller/friends',
        );
      }
      final offRoute = getState().members.firstWhere((m) => m.isOffRoute);
      getVm().alert(offRoute.id);
      await h.settle();
      await shot(
        'friend_alert_recorded',
        'Friend deviation — local check-in recorded',
        '/traveller/friends',
      );
    },
  );

  await h.attempt(module, 'Group invitations', '/traveller/invites', () async {
    await h.go('/traveller/invites');
    await shot(
      'invitations',
      'Group invitations and safety',
      '/traveller/invites',
    );
    getVm().invite(getState().catalog.members.first.name);
    await h.settle();
    await shot(
      'invitation_pending',
      'Pending local friend invitation',
      '/traveller/invites',
    );
    getVm().accept(getState().invitations.first.id);
    await h.settle();
    await shot(
      'invitation_accepted',
      'Accepted local friend invitation',
      '/traveller/invites',
    );
    getVm().safetyAlerts(false);
    await lower();
    await shot(
      'safety_alerts_paused',
      'Group safety alerts paused',
      '/traveller/invites',
    );
  });

  await h.attempt(
    module,
    'Switch active trip confirmation',
    '/traveller/plans',
    () async {
      final state = getState();
      final shared = state.catalog.plans.firstWhere(
        (p) => p.ownerId != state.ownerId,
      );
      getVm().edit(shared);
      expect(getVm().saveDraft(), isTrue);
      final copiedId = getState().selectedId!;
      getVm().setTab(PlanTab.mine);
      await h.go('/traveller/plans');
      await h.tap(find.byKey(ValueKey('start-$copiedId')));
      await shot(
        'switch_trip_confirmation',
        'Switch active trip confirmation',
        '/traveller/plans',
      );
      await h.tap(find.text('Cancel').last);
    },
  );

  await h.attempt(
    module,
    'Finish trip summary and completed state',
    '/traveller/finish',
    () async {
      await h.go('/traveller/finish');
      await shot(
        'finish_review',
        'Finish trip summary review',
        '/traveller/finish',
      );
      await lower();
      await shot(
        'finish_review_lower',
        'Finish trip memories and save action',
        '/traveller/finish',
      );
      final id = getState().activeId!;
      expect(getVm().finish(), isTrue);
      await h.go('/traveller/finish?id=$id');
      await shot(
        'finish_completed',
        'Completed trip saved summary',
        '/traveller/finish?id=$id',
      );
      getVm().setTab(PlanTab.completed);
      await h.go('/traveller/plans');
      await shot(
        'completed_plans',
        'Completed plans with saved journey',
        '/traveller/plans',
      );
    },
  );

  h.missing(
    module,
    'Legacy ActiveTripScreen, HazardReportScreen, AddMemoriesScreen',
    'No registered route',
    'These older widget classes remain in traveller_screens.dart but app_router '
        'uses ActiveTripDashboard, FixedHazardReportScreen and FixedAddMemoriesScreen. '
        'Captured the registered replacements; legacy widgets are inaccessible through app navigation.',
  );
}
