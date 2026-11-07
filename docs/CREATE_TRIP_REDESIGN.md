# Create New Trip implementation — 5 November 2026

The functional Create Trip rebuild is implemented at `/traveller/create`. The requested approved reference, `docs/ui_reference/create_new_trip_reference.png`, is absent from the workspace. The owner chose to provide another local path; that path has not yet been supplied. Final comparison against the approved image remains pending. The implementation follows the written section order and controls, using the existing project architecture and original scenic asset.

## Working screen

`TripBuilderScreen` now lives in `lib/features/traveller/presentation/views/trip_builder_screen.dart` and is re-exported by `traveller_screens.dart`, preserving existing imports and router registrations.

- Fixed SafeArea/LayoutBuilder layout, with a proportionally scaled Column and no main-page scroll view. Original background is blurred at sigma 5 and darkened behind cyan-bordered navy glass cards.
- Back, WAYHUNTER header, Profile and the existing four-destination Home/Traveller/Leaderboard/Profile footer.
- Trip Basics: editable name with the requested placeholder, separate Flutter Start Date and End Date calendars, and validation. End Date disables days before Start Date; changing Start Date preserves an existing End Date and reports an invalid range.
- Route Builder: Start Location, Add Place, Add Stop and End Location beside a live Google Maps SDK preview. Search includes the existing mock cities and places. The picker can also select a coordinate on a native map.
- Numbered route chips support location editing and a menu for moving earlier/later and removing intermediate stops. The expanded route editor supports drag reorder, arrow controls, editing and adding/removing stops. Cancel/Back restores its incoming draft; Apply Route keeps edits.
- Add Stop inserts immediately before End and retains all other stops. Endpoint changes affect only their endpoint. Native map markers and the labeled, dashed mock polyline update from Riverpod draft state. These lines are estimates, not verified road Directions.
- Suggested Trip Plans: Jaffna Heritage Trail and Northern & Hill Country Loop. Both reuse existing ordered trip fixtures, with metadata centralized in MockData. Use Idea loads the route and travel details; existing user inputs trigger a replacement confirmation. Trip name and dates are preserved. Edit Idea opens a transactional route editor and returns the edited idea to Create Trip. The section's history icon preserves entry to the existing Previous Traveller Plan screen.
- Travel Details: budget presets/custom positive finite LKR amount, vehicle selector and positive whole-number people count, in one compact row.
- AI Trip Plane: purple/cyan/green gradient action, confirmation before filling missing values, preservation of entered route/details, local-only itinerary generation, and the existing `/traveller/ai` destination. A single entered start stop is preserved when completing a suggested route. Invalid date ranges are rejected.
- Submit Trip: cyan/green gradient action, domain validation, existing mock repository/local storage save, duplicate-tap protection while saving, then `/traveller/plans`. The new plan appears in My Plans.

## Data and scope

The existing Traveller ViewModel, typed repository, TripDraft and TripPlan remain in use. TripSuggestion metadata, vehicle choices and budget choices are added only in `lib/core/mock/mock_data.dart`. Location search is local. User-selected map coordinates are stored with their plan and restored by the existing local repository, including when editing or showing an active route. Existing saved plans without coordinate metadata remain compatible.

Home, authentication, Hunter, Game, Profile, Wallet, routing configuration, API key configuration and original image files were not edited. The Traveller landing and all Traveller view classes from RouteReviewScreen onward compare unchanged against the pre-task source. The retained shared stop editor's options were extended to accept the same mock places and map-selected stops as the new form.

## Verification

- Final `flutter analyze --no-pub`: exit **0**, **No issues found! (ran in 2.9s)**.
- Final `flutter test --no-pub --reporter expanded`: exit **0**, **55 passed**.
- Nine new Create Trip widget tests cover fixed layout at 390×844, 320×640, 320×568 and 640×360; keyboard/footer geometry; larger text; searchable mock places; editing/removing/reordering/retaining stops; transactional suggestion edits; travel-detail validation; AI confirmation and preservation; submission; and coordinate selection with ordered SDK markers/polyline updates.
- Two additional Traveller state/repository tests cover separate date validation, endpoint preservation, reuse of suggestion fixtures, AI preservation of a single entered stop, and map-coordinate persistence/restoration.
- The complete existing Home → Traveller → Create → Submit → My Plans → Start → Active → Finish journey and other Traveller branches pass. Existing auth, Home, landing, Maps and native-boundary regression tests pass.
- Real-font widget render inspected at `.codex_review/create-trip-filled.png`.
- Final `flutter run --debug -d emulator-5554 --no-pub --no-resident`: exit **0**; Android debug build (21.6s Gradle), install and launch passed. Native checks exercised both calendars, confirmed November 9 was disabled after selecting November 10 as Start, loaded a suggested plan into the live map, selected a coordinate on a map, inserted it before End, and submitted successfully to My Plans. The saved local trip contains all six ordered stops, the selected coordinate, dates, vehicle, people and budget. After relaunching the final build, that trip restored from local storage and opened correctly in Create Trip for editing. The emulator was left on this filled Create Trip page. App-process runtime error checks reported no Flutter/Android errors.
- Native evidence includes `.codex_review/create_android_blank.png`, `create_android_map_picker.png`, `create_android_coordinate_added.xml`, `create_android_saved_visible.xml`, `create_android_restored.xml` and `create_android_final.png`. Native previews are actual Google Maps SDK surfaces; widget-test map surfaces are injected fakes.

## Device and asset limits

- Portrait phones at least approximately 360×740 logical pixels are recommended for comfortable use of this dense, fixed design. Smaller portrait sizes and landscape fit without RenderFlex overflow but scale text and touch controls down substantially. Popups and expanded editors provide larger controls and may scroll internally.
- The main form limits system text scaling to 1.25 to retain the fixed composition. Modal selectors/calendars use their normal layout. The keyboard overlays the lower page while typing; the footer keeps its original position and returns unobscured after keyboard dismissal.
- Up to four stop chips appear directly. With more stops, the first three and a `+N` action open the complete route editor; no stops are removed or truncated in state.
- Project assets contain the original scenic/button images and no traveller portraits. Suggestion thumbnails reuse the scenic asset; initials avatars are used until portrait assets are available. No replacement background or button image was generated.
- Approved-reference matching remains pending the owner's new image path. No additional Maps key setup was needed on the tested emulator.

## Modified files

Created:

- `lib/features/traveller/presentation/views/trip_builder_screen.dart`
- `lib/features/traveller/presentation/widgets/trip_location_picker.dart`
- `lib/features/traveller/presentation/widgets/trip_route_map.dart`
- `test/traveller/trip_builder_test.dart`
- `docs/CREATE_TRIP_REDESIGN.md`

Updated:

- `lib/core/mock/mock_data.dart`
- `lib/features/traveller/domain/entities/trip.dart`
- `lib/features/traveller/data/repositories/mock_traveller_repository.dart`
- `lib/features/traveller/presentation/viewmodels/traveller_view_model.dart`
- `lib/features/traveller/presentation/views/traveller_screens.dart`
- `test/traveller/traveller_view_model_test.dart`
- `test/traveller/traveller_flow_test.dart`
- `docs/SCREEN_COVERAGE.md`
- `docs/TRAVELLER_IMPLEMENTATION.md`
