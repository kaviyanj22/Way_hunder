# WAYHUNTER route and screen inventory

Static source audit: 9 November 2026. This document records **intended automation coverage**, not successful captures. Actual PNG availability and capture results belong in [SCREEN_INDEX.md](SCREEN_INDEX.md).

The router registers **76 paths**: **75 non-loading entries**, including the `/` redirect, and one transient `/loading` path. There are **74 non-loading UI route destinations**. Query parameters and local state select variants of those destinations. Every UI route below is referenced by the capture automation; this does not establish that execution succeeded.

Sources audited: `lib/app/app_router.dart`, the Traveller/Hunter/Game/Wallet route lists under each feature's `presentation/providers/`, all public screen classes under the seven feature folders, and `integration_test/modules/*.dart`. Backup files ending in `.bak` are not Dart compilation units and are excluded.

All PNG paths below are relative to `screenshots/`. In the first table, unprefixed filenames share the preceding filename's module directory. Traveller names use `*_slug.png` because its module assigns numeric prefixes at execution; a preceding failure can affect subsequent numbering. Other modules name PNG files explicitly. The capture harness uses real Flutter routes and existing local demo state; camera/Maps availability is determined at execution.

## Auth, Home and global routes

Source files:

- **A** — [`lib/features/auth/presentation/views/auth_screens.dart`](../lib/features/auth/presentation/views/auth_screens.dart)
- **H** — [`lib/features/home/presentation/views/home_screen.dart`](../lib/features/home/presentation/views/home_screen.dart)
- **E** — [`lib/features/home/presentation/views/feature_entry_screen.dart`](../lib/features/home/presentation/views/feature_entry_screen.dart)
- **R** — [`lib/app/app_router.dart`](../lib/app/app_router.dart)

| Registered path | Actual Dart target | Intended captures |
| --- | --- | --- |
| `/` | R: redirect to auth/home/permissions according to auth state; no screen builder | No distinct PNG; destination UI is covered below. |
| `/sign-in` | A: `SignInScreen` | `auth/01_login.png`, `02_login_language.png`, `03_login_missing_fields.png`, `04_login_incorrect.png`, `10_registration_success.png`, `17_reset_success.png`; `profile/18_sign_in_after_logout.png` |
| `/register` | A: `RegisterScreen` | `auth/05_register.png`, `06_register_terms.png`, `07_register_validation.png` |
| `/otp` | A: `OtpScreen` | `auth/08_registration_otp.png`, `09_invalid_otp.png`, `14_recovery_otp.png`; requires an existing registration/recovery flow. |
| `/forgot-password` | A: `ForgotPasswordScreen` | `auth/12_forgot_password.png`, `13_forgot_validation.png` |
| `/reset-password` | A: `ResetPasswordScreen` | `auth/15_reset_password.png`, `16_reset_mismatch.png`; requires verified recovery OTP. |
| `/offline` | A: `OfflineScreen` | `auth/18_offline.png`; requires a pending local auth action. |
| `/connection-restored` | A: `ConnectionRestoredScreen` | `auth/20_connection_restored.png`; requires a pending auth action. |
| `/cancel-auth` | A: `CancelAuthScreen` | `auth/19_cancel_auth.png`; requires a pending auth action. |
| `/permissions` | A: `PermissionsScreen` | `auth/11_permissions.png`; first-time permission introduction. |
| `/home` | H: `HomeScreen` | `home/01_home.png`, `02_home_lower.png`, `03_search.png`, `04_search_empty.png`, `05_advertisement.png` |
| `/leaderboard` | E: `LeaderboardEntryScreen` | `home/08_leaderboard.png` |
| `/notifications` | E: `NotificationsScreen` | `home/06_notifications.png`, `07_notifications_read.png` |

The router's `errorBuilder` is not a registered path. It constructs `FeatureScaffold` with the unavailable-trail message and a Home button. Automation intentionally visits `/missing-screen` for `home/09_unavailable_route.png`.

`/loading` is registered in R as a `Scaffold` containing `CircularProgressIndicator`. It is excluded from PNG capture because the requested export excludes loading screens. This exclusion is also recorded by the automation.

## Traveller

Source files:

- **T** — [`lib/features/traveller/presentation/views/traveller_screens.dart`](../lib/features/traveller/presentation/views/traveller_screens.dart)
- **B** — [`lib/features/traveller/presentation/views/trip_builder_screen.dart`](../lib/features/traveller/presentation/views/trip_builder_screen.dart) (exported by T)
- **D** — [`lib/features/traveller/presentation/views/active_trip_dashboard.dart`](../lib/features/traveller/presentation/views/active_trip_dashboard.dart)
- **F** — [`lib/features/traveller/presentation/views/fixed_trip_forms.dart`](../lib/features/traveller/presentation/views/fixed_trip_forms.dart)
- **S** — [`lib/features/traveller/presentation/views/suggested_trip_detail_screen.dart`](../lib/features/traveller/presentation/views/suggested_trip_detail_screen.dart)

| Registered path | Actual Dart target | Intended captures under `traveller/` |
| --- | --- | --- |
| `/traveller` | T: `TravellerLandingScreen(placeId: ?place)` | `*_landing.png`; actual map/fallback state determined at runtime. |
| `/traveller/create` | B: `TripBuilderScreen` | `*_create_trip_empty.png`, `*_create_trip_validation.png`, `*_date_picker.png`, `*_location_picker.png`, `*_location_no_results.png`, `*_location_map_picker.png`, `*_create_trip_filled.png`, `*_budget_picker.png`, `*_vehicle_picker.png`, `*_people_picker.png`, `*_route_editor_sheet.png`, `*_stop_actions.png`, `*_ai_confirmation.png`, `*_replace_idea_confirmation.png` |
| `/traveller/review` | T: `RouteReviewScreen` | `*_route_review.png`, `*_route_review_controls.png`, `*_route_review_add_stop.png`; T-A route review/edit. |
| `/traveller/ai` | T: `AiTripPlanScreen` | `*_ai_day_plan.png`, `*_ai_stays.png`, `*_ai_budget.png` |
| `/traveller/reuse` | T: `PreviousTravellerPlanScreen` | `*_reuse_segments.png`, `*_reuse_photos.png`, `*_reuse_stays.png`, `*_reuse_notes.png` |
| `/traveller/suggestion/:id` | S: `SuggestedTripDetailScreen(suggestionId: path id)` | Existing catalog suggestion ID: `*_suggestion_overview.png`, `*_suggestion_overview_lower.png`, `*_suggestion_photos.png`, `*_suggestion_stays.png`, `*_suggestion_notes.png`, `*_suggestion_edit.png` |
| `/traveller/plans` | T: `MyPlansScreen` | `*_my_plans.png`, `*_plans_shared.png`, `*_plans_completed.png`, `*_switch_trip_confirmation.png`, `*_completed_plans.png` |
| `/traveller/active` | D: `ActiveTripDashboard` | `*_active_trip.png`, `*_active_trip_progress.png`; an existing demo plan is started first. |
| `/traveller/nearby` | T: `NearbyPlacesScreen` | `*_nearby_on_demand.png`, `*_nearby_all.png`, category variants `*_nearby_hotel.png`, `*_nearby_food.png`, `*_nearby_fuel.png`, `*_nearby_hospital.png`, `*_nearby_attraction.png`, plus `*_nearby_details.png` |
| `/traveller/road-alert` | T: `RoadAlertScreen` | `*_road_alert.png`, `*_road_alert_details.png`, `*_road_alternative.png` |
| `/traveller/hazard` | F: `FixedHazardReportScreen` | `*_hazard.png`, `*_hazard_validation.png`, `*_hazard_types.png`, `*_hazard_description.png`, `*_hazard_photo_sheet.png`, `*_hazard_video_sheet.png`, `*_hazard_filled.png`, `*_hazard_success.png` |
| `/traveller/memories` | F: `FixedAddMemoriesScreen` | `*_memory.png`, `*_memory_validation.png`, `*_memory_caption.png`, `*_memory_photo_sheet.png`, `*_memory_filled.png`, `*_memory_success.png` |
| `/traveller/friends` | T: `TripFriendsScreen` | `*_friends.png`, `*_friends_nearby.png`, `*_friends_far.png`, `*_friend_alert_recorded.png` |
| `/traveller/invites` | T: `GroupInvitationsScreen` | `*_invitations.png`, `*_invitation_pending.png`, `*_invitation_accepted.png`, `*_safety_alerts_paused.png`; T-F invitation flow. |
| `/traveller/finish` | T: `FinishTripScreen(tripId: ?id)` | `*_finish_review.png`, `*_finish_review_lower.png`, `*_finish_completed.png`; completed view uses an existing finished trip ID. |

Date/location/numeric selectors, route editors and evidence sheets are modal UI opened from these routes. Their helper widgets are not additional top-level route screens.

## Hunter

Source files:

- **HS** — [`lib/features/hunter/presentation/views/hunter_start_screens.dart`](../lib/features/hunter/presentation/views/hunter_start_screens.dart)
- **HE** — [`lib/features/hunter/presentation/views/hunter_evidence_screens.dart`](../lib/features/hunter/presentation/views/hunter_evidence_screens.dart)
- **HR** — [`lib/features/hunter/presentation/views/hunter_rewards_screens.dart`](../lib/features/hunter/presentation/views/hunter_rewards_screens.dart)

| Registered path | Actual Dart target | Intended captures under `hunter/` |
| --- | --- | --- |
| `/hunter` | HS: `HunterHomeScreen` | `01_home.png`, `02_search_empty.png` |
| `/hunter/add` | HS: `AddNewPlaceScreen` | `03_add_place.png`, `31_add_validation_error.png`, `04_add_place_details.png` |
| `/hunter/gps` | HS: `HunterGpsScreen` | `05_gps.png`, `06_gps_restricted.png`, `07_duplicate_warning.png`; H-DUP is a validation dialog on this route, not a separate screen route. |
| `/hunter/camera360` | HE: `Hunter360CameraScreen` | `08_camera360.png`, `09_camera360_device.png`, conditional `10_camera360_recording.png`; native video capability is checked at execution, with unavailable status retained. |
| `/hunter/video-complete` | HE: `HunterVideoCompleteScreen` | `11_video_complete.png`, `12_video_preview.png` |
| `/hunter/video-attached` | HS: `AddNewPlaceScreen(videoAttached: true)` | `13_video_attached.png` |
| `/hunter/photo-camera` | HE: `HunterNormalPhotoCameraScreen` | `14_photo_camera.png`, `15_photo_camera_device.png`; actual native result or existing fallback. |
| `/hunter/review` | HE: `HunterReviewScreen` | `16_review.png`, `17_submit_success.png` |
| `/hunter/verification` | HE: `HunterVerificationScreen` | `18_verification_pending.png`, `21_verification_approved.png`, conditional `23_verification_rejected.png` |
| `/hunter/rewards` | HR: `HunterRewardsScreen` | `24_rewards_all.png`, `25_rewards_pending.png`, `26_rewards_approved.png`, `27_rewards_rejected.png` |
| `/hunter/leaderboard` | HR: `HunterLeaderboardScreen` | `28_leaderboard_district.png`, `29_leaderboard_monthly.png`, `30_leaderboard_all_time.png` |
| `/hunter/admin-review` | HR: `HunterAdminDemoScreen` | `19_admin_review.png`, `20_approval_confirmation.png`, conditional `22_rejection_confirmation.png`; local DEMO moderation only. |

## Games

Source files:

- **GZ** — [`lib/features/games/presentation/views/game_zone_screen.dart`](../lib/features/games/presentation/views/game_zone_screen.dart)
- **G** — [`lib/features/games/presentation/views/game_flow_screens.dart`](../lib/features/games/presentation/views/game_flow_screens.dart)

| Registered path | Actual Dart target | Intended captures under `games/` |
| --- | --- | --- |
| `/game` | GZ: `GameZoneScreen` | `01_game_zone.png` |
| `/game/create/setup` | G: `GameSetupScreen` | `02_create_setup.png`, `03_setup_error.png`, `04_create_setup_filled.png` |
| `/game/create/photo` | G: `GamePhotoScreen` | `05_create_photo.png`, `37_creation_photo_missing.png`, `06_create_photo_attached.png` |
| `/game/create/hints` | G: `GameHintsScreen` | `07_create_hints.png`, `38_hint_missing.png`, `08_create_rewards_off.png` |
| `/game/create/review` | G: `GameReviewScreen` | `09_create_review.png` |
| `/game/create/published` | G: `GamePublishedScreen` | `10_create_published.png`; existing publish action supplies the created game. |
| `/game/play` | G: `GamePlayScreen` | `14_play_landing.png` |
| `/game/district` | G: `GameDistrictScreen` | `15_select_district.png` |
| `/game/challenges` | G: `GameChallengesScreen` | `16_challenges.png`, conditional `17_challenges_empty.png` |
| `/game/accept` | G: `GameAcceptScreen` | `12_own_challenge_preview.png`, `18_accept_challenge.png`, `30_challenge_ended.png`, `32_ended_challenge_preview.png` |
| `/game/find` | G: `GameFindScreen` | `19_find_place.png`, `20_second_hint.png`, `21_all_hints.png` |
| `/game/proof` | G: `GameProofScreen` | `22_capture_proof.png`, `23_proof_missing.png`, `24_proof_attached.png` |
| `/game/submit` | G: `GameSubmitScreen` | `25_submit_ready.png`, `26_verification_pending.png` |
| `/game/victory` | G: `GameVictoryScreen` | `28_victory.png`; uses existing local valid-winner simulation. |
| `/game/over` | G: `GameOverScreen` | `13_own_game_blocked.png`, `27_invalid_proof_game_over.png`, `31_another_winner_game_over.png` |
| `/game/my-games` | G: `GameMyGamesScreen` | `11_my_games_created.png`, `29_my_games_completed.png` |
| `/game/leaderboard` | G: `GameLeaderboardScreen` | `33_leaderboard.png` |
| `/game/rewards` | G: `GameRewardsScreen` | `34_rewards_store.png` |
| `/game/how-to-play` | G: `GameHowScreen` | `35_how_to_play.png` |
| `/game/sponsored` | G: `GameSponsoredScreen` | `36_sponsored.png` |

The Game wallet entry G-W navigates to the shared `/wallet` destination listed below; there is no second Game-specific wallet screen. `GamePageSection` in `game_ui.dart` is a reusable layout component, not an unreachable screen.

## Profile and Settings

All three route targets are in [`lib/features/profile/presentation/views/profile_dashboard_screen.dart`](../lib/features/profile/presentation/views/profile_dashboard_screen.dart).

| Registered path | Actual Dart target | Intended captures under `profile/` |
| --- | --- | --- |
| `/profile` | `ProfileDashboardScreen` | `01_profile_posts.png`, `02_profile_games.png`, `03_profile_trips.png`, `04_profile_hunt_places.png`, `05_profile_badges.png` |
| `/profile/edit` | `EditLocalProfileScreen` | `06_edit_profile.png`, `17_edit_profile_name_error.png` |
| `/profile/settings` | `ProfileSettingsScreen` | `07_settings.png`, `08_security_password_info.png`, `09_language_choices.png`, `10_privacy_choices.png`, `11_notification_preferences.png`, `12_help_how_to_use_info.png`, `13_about_version.png`, `14_account_deletion_info.png`, `15_logout_confirmation.png`, `16_settings_after_logout_cancel.png` |

`_NotificationSettingsSheet` is reachable through Settings' Notifications action and is targeted as a modal-sheet capture. Profile's My Wallet tab opens the shared `/wallet` screen.

The source implements Security & Password, Help, About and Delete Account as information dialogs. It does **not** contain a dedicated change-password form, Help hub/FAQ/contact/report destinations, a separate How to Use page, update/What's New UI, or Delete Yes/No/P-DO page. The automation records these reference-only pages as missing rather than fabricating their UI. Language and privacy choices are dialogs on Settings; Logout is a confirmation dialog with Cancel and Log Out.

## Wallet

Source files:

- **WO** — [`lib/features/wallet/presentation/views/wallet_overview_screen.dart`](../lib/features/wallet/presentation/views/wallet_overview_screen.dart)
- **WR** — [`lib/features/wallet/presentation/views/wallet_redemption_screens.dart`](../lib/features/wallet/presentation/views/wallet_redemption_screens.dart)
- **WV** — [`lib/features/wallet/presentation/views/wallet_voucher_screens.dart`](../lib/features/wallet/presentation/views/wallet_voucher_screens.dart)
- **WD** — [`lib/features/wallet/presentation/views/wallet_demo_screen.dart`](../lib/features/wallet/presentation/views/wallet_demo_screen.dart)

| Registered path | Actual Dart target | Intended captures under `wallet/` |
| --- | --- | --- |
| `/wallet` | WO: `WalletOverviewScreen` | `01_overview.png` — W-01 |
| `/wallet/choose` | WR: `WalletRewardsScreen` | `02_choose_voucher.png` — W-02; `04_choose_shopping.png`, `05_choose_food_empty.png`, `06_choose_travel_empty.png` |
| `/wallet/confirm` | WR: `WalletConfirmScreen(offerId: ?offer, intentId: ?intent)` | `16_confirm_redemption.png` — W-03; `03_confirm_no_selection.png`, `11_confirm_insufficient.png` |
| `/wallet/pending` | WR: `WalletPendingScreen(requestId: ?id)` | `17_request_submitted_pending.png` — W-04; `13_seed_request_pending.png`, `14_cancel_request_confirmation.png`, conditional `36_pending_route_after_approval.png` |
| `/wallet/approved` | WR: `WalletApprovedScreen(requestId: ?id)` | `19_request_approved.png` — W-05; `35_unapproved_request_error.png` uses reachable `WalletMissingScreen` branch. |
| `/wallet/vouchers` | WV: `WalletVouchersScreen` | `20_my_vouchers_active.png` — W-06; `07_my_vouchers_empty_active.png`, `08_my_vouchers_used_expired.png` |
| `/wallet/voucher` | WV: `WalletVoucherDetailsScreen(voucherId: ?id)` | `21_voucher_details_qr.png` — W-07; `09_voucher_expired.png`, `10_voucher_used.png`, `22_voucher_how_to_use.png`, conditional `27_new_voucher_used_details.png`, `34_missing_voucher_record.png` |
| `/wallet/history` | WV: `WalletHistoryScreen` | `28_transaction_history.png` — W-08; `29_history_hp.png`, `30_history_rc.png`, `31_history_vouchers.png`, `32_transaction_details.png` |
| `/wallet/rules` | WO: `WalletRulesScreen` | `33_wallet_rules.png` |
| `/wallet/rejected` | WR: `WalletRejectedScreen(requestId: ?id)` | `23_request_rejected.png`, `15_request_cancelled.png` |
| `/wallet/insufficient` | WR: `WalletInsufficientScreen(offerId: ?offer)` | `12_insufficient_rc.png` |
| `/wallet/demo` | WD: `WalletDemoScreen(code: ?code)` | `18_developer_requests.png`, conditional `24_developer_merchant.png`, `25_merchant_invalid_code.png`, `26_merchant_used_success.png`; debug-only route, redirects to `/wallet` in non-debug builds. |

`WalletMissingScreen` in WR has no independent route, but is **reachable** from missing request/voucher and unapproved-request branches. It is targeted through those real routes. W-EX expired/used states are variants of voucher details, not additional registered paths. Approval, rejection and merchant use remain the app's explicit local developer DEMO actions.

## Unreachable historical screen classes

The following six public widget classes remain in current `.dart` source, but have no registered route and no constructor call outside their own declarations in `lib/`, `test/` or `integration_test/`. They cannot be visited through the current app navigation. The automation is configured to record their inaccessibility and target the registered replacements; it does not mount obsolete screens as invented navigation branches.

| Unreachable class | Existing Dart file | Current routed replacement |
| --- | --- | --- |
| `FeatureEntryScreen` | `lib/features/home/presentation/views/feature_entry_screen.dart` | `/traveller` → `TravellerLandingScreen`; `/hunter` → `HunterHomeScreen`; `/game` → `GameZoneScreen` |
| `ProfileEntryScreen` | `lib/features/home/presentation/views/feature_entry_screen.dart` | `/profile` → `ProfileDashboardScreen` |
| `WalletEntryScreen` | `lib/features/home/presentation/views/feature_entry_screen.dart` | `/wallet` → `WalletOverviewScreen` |
| `ActiveTripScreen` | `lib/features/traveller/presentation/views/traveller_screens.dart` | `/traveller/active` → `ActiveTripDashboard` |
| `HazardReportScreen` | `lib/features/traveller/presentation/views/traveller_screens.dart` | `/traveller/hazard` → `FixedHazardReportScreen` |
| `AddMemoriesScreen` | `lib/features/traveller/presentation/views/traveller_screens.dart` | `/traveller/memories` → `FixedAddMemoriesScreen` |

Widget state classes, reusable shells/cards/maps/camera controls and private modal components are not counted as additional standalone screen classes. Native gallery/camera system UI is outside the Flutter route inventory; the app's Flutter camera/evidence views and explicit fallback messages are the intended capture targets.
