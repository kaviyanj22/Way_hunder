# Traveller implementation

The Home Traveller image now opens the actual Traveller Map Landing screen. Auth, original Home artwork and existing Android Maps secret configuration were preserved. Hunter and Game routes are unchanged.

## Completed screens and routes

Views are real widgets in `lib/features/traveller/presentation/views/traveller_screens.dart` and `trip_builder_screen.dart`, registered by `presentation/providers/traveller_routes.dart`.

| Reference | Screen class | Route | Working actions |
|---|---|---|---|
| UJ-028 | TravellerLandingScreen | /traveller | Fixed Sri Lanka native map/fallback, Create New Trip, My Plans, back/profile, four-icon footer |
| UJ-029 | TripBuilderScreen | /traveller/create | Fixed name/separate dates, search/map start/end/intermediate stops, add/edit/remove/reorder, two Use/Edit Idea cards, budget/vehicle/people, AI Trip Plane, Submit Trip, fixed footer |
| UJ-030 | AiTripPlanScreen | /traveller/ai | Deterministic local itinerary, day/stay/budget tabs, edit, save |
| UJ-031 | PreviousTravellerPlanScreen | /traveller/reuse | Original-inspired overview/media/stay/note tabs, choose connected ordered segments, reuse/edit |
| UJ-032 | MyPlansScreen | /traveller/plans | Mine/shared/completed tabs, edit/reuse, start/resume, invites, completed summary |
| UJ-033 | ActiveTripScreen | /traveller/active | Native map, approximate demo polyline/stops, simulated progress, independent tools, edit route, end |
| UJ-034 | NearbyPlacesScreen | /traveller/nearby | Load only on explicit action, category filtering, details dialog, return active |
| UJ-035 | RoadAlertScreen | /traveller/road-alert | Demo alert details, estimated alternate-route display, original route, resume |
| UJ-036 | HazardReportScreen | /traveller/hazard | Type/reason, up to five photo/video or labeled demo attachments, remove, local submit/cancel |
| UJ-037 | AddMemoriesScreen | /traveller/memories | Camera/gallery/silent-video or labeled demo attachment, caption/tags, remove/post, trip memories |
| UJ-038 | TripFriendsScreen | /traveller/friends | Demo member markers, all/nearby/far filters, >500 m off-route feedback, local check-in alert |
| UJ-039 | FinishTripScreen | /traveller/finish | Journey summary, memory/report counts, keep travelling, save completed, specific completed summary via ?id= |
| T-A | RouteReviewScreen | /traveller/review | Add/change/remove/reorder stops, map review, save, return details; active route edits preserve the journey |
| T-F | GroupInvitationsScreen | /traveller/invites | Name validation, local invite/accept, joined members, safety-alert switch, return plans/friends |

## Architecture and files

- Reused the existing `TripPlan`, `TripDraft`, typed Traveller catalog/repository, local storage and working `TravellerMap`/location ViewModel.
- Domain: `domain/entities/trip.dart` and `domain/repositories/traveller_repository.dart`.
- Data: `data/repositories/mock_traveller_repository.dart` consumes only `MockData` and persists per-user saved plans through `LocalDemoStorage`.
- Presentation: `presentation/providers/traveller_providers.dart`, `presentation/viewmodels/traveller_view_model.dart`, `presentation/views/traveller_screens.dart`, and `presentation/providers/traveller_routes.dart`.
- Updated `presentation/widgets/traveller_map.dart` to accept route points and extra member markers while preserving key/platform and runtime-location handling.
- Shared Traveller UI: `lib/core/widgets/module_scaffold.dart`, `evidence_capture.dart`, and `lib/core/services/evidence_service.dart`. The camera uses the existing camera/image_picker packages and never opens on screen load.
- Integration: `lib/app/app_router.dart` registers Traveller routes; `feature_entry_screen.dart` delegates any legacy Traveller construction to the actual landing. Home itself was not rewritten.
- Added nearby/date/member-coordinate fixtures to the existing centralized `lib/core/mock/mock_data.dart`.
- Tests: `test/traveller/traveller_view_model_test.dart`, `traveller_flow_test.dart`, existing `traveller_map_test.dart`, and retained Home/auth/native regressions.

## Working journey and state

Create → choose dates → add multiple stops → reorder/remove → save → My Plans → Start → Active Trip → Finish → Completed. Optional AI and previous-segment branches return to editing/saving, without forcing either method. Only one journey can be active; Resume retains its progress. Completed summaries identify their own trip even while another trip is active.

Nearby data is not loaded when starting a trip or opening Active Trip. Its button loads local suggestions on demand. Hazards, road alerts, memories and friends each return independently to Active Trip. Invalid forms display feedback without losing inputs. Cancel retains the trip draft in the existing ViewModel.

Plans, dates, stops and planned/active/completed status persist per account in local preferences. Current progress, media, hazards, invitations and safety controls are session state retained while navigating. No backend or real messaging exists.

## Full-module milestone verification (before landing refinement)

- `flutter analyze`: exit 0, **No issues found! (ran in 2.8s)**.
- Standard `flutter test`: exit 0, **37 passed**. This includes 14 Traveller map/domain/widget tests and all previous auth/Home/native regression tests.
- Tests execute the Home image-button journey, date picker, three-stop reorder/save/start/finish, completed summary alongside another active trip, independent nearby/alert/hazard/memory/friend/invitation branches, optional AI/reuse branches, persisted plans, and rendering all 14 screens at 320 pixels.
- Captures of the actual landing/builder/active layouts were inspected with real fonts. Native map views are mocked in widget tests; screenshots intentionally show the tested missing-key fallback rather than claiming live tiles.
- Original Home background and Home screen hashes remain unchanged. Native Maps credentials/configuration were not edited for this task.
- `flutter build apk --debug`: exit 0, **Built build/app/outputs/flutter-apk/app-debug.apk**; Gradle completed in 62.3s.

Prototype limitations: AI, route lines, places, friend positions, progress, road alerts and invitations are explicitly local demonstrations. Route lines are straight estimated segments, not verified road Directions. Trip-stop context is labeled as demo, not claimed to be an accurate GPS fix. Device camera/location permission and live Google Maps tiles still require Android device smoke validation. Missing camera/GPS/key support offers an explicit fallback and does not prevent the trip journey.

## Traveller landing refinement — 5 November 2026

The landing uses a dedicated non-scrolling SafeArea/Column layout. The Google Map expands into the remaining space; the two electric-blue trip buttons and the existing four-destination bottom navigation stay fixed. The header contains Back, WAYHUNTER and Profile, followed by Traveller Map. Explanatory cards, paragraphs, location controls and extra trip actions were removed from this screen.

`TravellerMap(landing: true)` delegates to the map-only `TravellerIslandMap`. Existing trip maps, location repositories and Riverpod providers keep their previous behavior. The landing honors already-granted location state without requesting access or recentering on the device. Sri Lanka camera bounds live in `MockData`: southwest (5.85, 79.50), northeast (9.95, 82.20). After native creation and a positive laid-out viewport size, a single padded `CameraUpdate.newLatLngBounds` is sent. Rebuilds, resizing, panning and zooming do not refit the camera.

The original background asset is wrapped alone in `ImageFiltered` with sigma 5, with a subtle dark gradient above it. Text, native map, buttons, icons and footer are outside the filter. Create New Trip opens `/traveller/create` and resets a new draft through the existing ViewModel; My Plans opens `/traveller/plans`. Neither destination screen was redesigned. Auth, Home, Hunter, Game, router definitions and Android Maps configuration were not edited.

Final verification:

- `flutter analyze --no-pub`: exit 0, **No issues found! (ran in 2.3s)**.
- `flutter test --no-pub --reporter expanded`: exit 0, **44 tests passed**.
- Seven new landing tests cover 390×844, 320×568, 320×480 and 640×360 with safe insets; larger text; no page scroll; fixed clickable controls/footer; original-image-only blur; existing routes; and one SDK bounds update after valid layout, with no reset after dragging/resizing.
- Real-font landing render inspected. Home/auth/original-background/Traveller-route hashes match the pre-change values.
- `flutter run --debug -d emulator-5554 --no-pub --no-resident`: exit 0; debug APK built (20.1s Gradle), installed and launched on Android 17 / API 37.
- Native emulator smoke check passed: demo sign-in → original Home Traveller image → landing with live Google Maps tiles showing the whole island, including Jaffna and Matara. Pan and zoom changed the map without resetting it; header/button bounds stayed identical and all four footer items remained visible. Both main buttons opened the existing Create New Trip form and saved My Plans tabs; Android Back returned to the landing. No Flutter/Android runtime error entries were reported for the app process.
- Native captures: `.codex_review/landing_android_island.png`, `landing_android_panned.png`, `landing_android_final.png`. The emulator was left on the finished Traveller landing.

Changed files in this refinement:

- `lib/features/traveller/presentation/views/traveller_screens.dart`
- `lib/features/traveller/presentation/widgets/traveller_map.dart`
- `lib/features/traveller/presentation/widgets/traveller_island_map.dart` (new)
- `lib/core/mock/mock_data.dart`
- `test/widget_test.dart`
- `test/traveller/traveller_landing_test.dart` (new)
- `pubspec.yaml`, `pubspec.lock` (declare the already-resolved Maps platform interface as a direct dev dependency for native-controller tests)
- `docs/SCREEN_COVERAGE.md`, `docs/TRAVELLER_IMPLEMENTATION.md`

No additional Maps setup is required for the tested emulator. Physical-device smoke testing remains separate from this emulator verification.

## Create Trip rebuild — 5 November 2026

`/traveller/create` now opens the dedicated fixed-layout `trip_builder_screen.dart`, re-exported by the existing screens library. Functional controls include separate calendars, searchable/mock and map-selected locations, ordered stop chips and transactional route editing, two suggested plans, compact travel details, AI confirmation and direct Submit Trip → My Plans. The old Review Route/Save Trip actions on this page are replaced by the requested AI Trip Plane/Submit Trip actions. The existing review and previous-plan screens remain reachable. Other Traveller screen classes and the fixed landing were preserved.

Final analyzer: exit 0, no issues (2.9s). Final full test suite: exit 0, **55 passed**. Native emulator checks confirmed live preview/maps selection, date constraints and submission with all selected stops saved in My Plans. The requested approved reference image is missing, and the owner has not yet supplied the alternative path they selected. Final visual comparison therefore remains pending. Full functionality, file inventory, evidence and device-size limits: `CREATE_TRIP_REDESIGN.md`.
