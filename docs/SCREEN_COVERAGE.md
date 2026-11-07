# Screen inventory and implementation coverage

Current Wallet completion update (6 November 2026): W-01 through W-08 and Wallet error/debug states are implemented as real widgets. Profile and Game use the same `/wallet` route and authoritative Riverpod wallet. See `WALLET_IMPLEMENTATION.md` for routes, files, ledger behavior and verification. Unrelated module source and original artwork remain unchanged in this Wallet task.

Historical Traveller completion: UJ-028 through UJ-039, T-A and T-F are implemented as real screens. `/traveller` opens `TravellerLandingScreen`, not `FeatureEntryScreen`. See `TRAVELLER_IMPLEMENTATION.md`. Phase/deferred entries outside Wallet below retain their earlier milestone inventory; they are not a fresh audit of those modules.

Inventory recorded before implementation. Phase 1 implements Auth/Home and explicit navigable entry previews only. Auth/Home routes and files below are implemented and verified by the Flutter test suite. Later-phase routes/files remain reservations, not claims of completed screens. All original designs and six authoritative flows remain required for later phases.

The six flow PNGs are navigation authorities. The corresponding original screen/panel mappings are recorded below. `FLOW / NO SCREEN` states require original Flutter UI in their scheduled phase, not the diagram pasted into the app. Later-phase file paths are reservations and may be consolidated when implemented.

## 01 Auth and Home

| State | Reference screen | Route | Dart target | Controls and destinations | Status |
|---|---|---|---|---|---|
| UJ-001 | Sign In | /sign-in | lib/features/auth/presentation/views/auth_screens.dart — SignInScreen | Email/password; visibility; remember; login-only language dropdown; sign in → permissions/Home; register; forgot; demo offline | Implemented; tests passed |
| UJ-002 | Create Account | /register | lib/features/auth/presentation/views/auth_screens.dart — RegisterScreen | Photo; name/email/phone/password/confirm/terms; submit → OTP; cancel/back; no language dropdown | Implemented; tests passed |
| UJ-003 | OTP | /otp | lib/features/auth/presentation/views/auth_screens.dart — OtpScreen | Six digits; invalid/expired; registration → Sign In; recovery → reset; resend; back preserves drafts | Implemented; tests passed |
| UJ-004 | Forgot Password | /forgot-password | lib/features/auth/presentation/views/auth_screens.dart — ForgotPasswordScreen | Email; Send local OTP; back | Implemented; tests passed |
| UJ-005 | Offline | /offline | lib/features/auth/presentation/views/auth_screens.dart — OfflineScreen | Explicit demo offline; Retry → restored → resume; Cancel → confirmation; preserve inputs | Implemented; tests passed |
| UJ-006 | Home | /home | lib/features/home/presentation/views/home_screen.dart | Exactly three unchanged full graphic buttons → Traveller/Hunter/Game; search; ad; notifications; profile; footer | Implemented; tests passed |
| AUTH-R | Reset Password | /reset-password | lib/features/auth/presentation/views/auth_screens.dart — ResetPasswordScreen | New/confirm, visibility; Save → Sign In; verified recovery required | Implemented; tests passed |
| AUTH-E | Inline errors | auth forms | lib/features/auth/presentation/views/auth_screens.dart | Required/duplicate/incorrect/invalid/expired states | Implemented; tests passed |
| AUTH-RY | Connection restored | /connection-restored | lib/features/auth/presentation/views/auth_screens.dart — ConnectionRestoredScreen | Resume original pending action exactly once; Stay Here | Implemented; tests passed |
| AUTH-C | Cancel/Back | /cancel-auth | lib/features/auth/presentation/views/auth_screens.dart — CancelAuthScreen | Go Back preserving drafts; Stay Here; no duplicate submission | Implemented; tests passed |
| AUTH-P | First-time permissions | /permissions | lib/features/auth/presentation/views/auth_screens.dart — PermissionsScreen | Location; camera; notifications; continue/skip; persisted once; denied/unsupported fallback | Implemented; tests passed |

## 02 Traveller

| State | Reference screen | Route | Dart target | Controls and destinations | Status |
|---|---|---|---|---|---|
| UJ-028 | Landing | /traveller | lib/features/traveller/presentation/views/traveller_screens.dart — TravellerLandingScreen | Fixed flexible Sri Lanka Google Map; Create New Trip; My Plans; back/profile; four-icon footer; background-only blur | Implemented; landing layout/navigation/camera tests passed |
| UJ-029 | Route builder | /traveller/create | lib/features/traveller/presentation/views/trip_builder_screen.dart — TripBuilderScreen | Fixed Trip Basics; separate date calendars; searchable/map locations; ordered stop chips and route editor; live mini-map; two Use/Edit Idea cards; budget/vehicle/people; AI Trip Plane; Submit Trip → My Plans; fixed footer | Functional UI implemented; 55 tests passed; approved image path pending |
| UJ-030 | AI plan | /traveller/ai | lib/features/traveller/presentation/views/traveller_screens.dart — AiTripPlanScreen | Local mock itinerary; edit; submit | Implemented; Traveller tests passed |
| UJ-031 | Previous traveller segments | /traveller/reuse | lib/features/traveller/presentation/views/traveller_screens.dart — PreviousTravellerPlanScreen | Choose ordered segments; use/edit plan | Implemented; Traveller tests passed |
| UJ-032 | My Plans | /traveller/plans | lib/features/traveller/presentation/views/traveller_screens.dart — MyPlansScreen | My/shared/completed tabs; edit; friends; start | Implemented; Traveller tests passed |
| UJ-033 | Active Trip | /traveller/active | lib/features/traveller/presentation/views/traveller_screens.dart — ActiveTripScreen | Map; nearby; alerts; hazard; memories; friends; end | Implemented; Traveller tests passed |
| UJ-034 | Nearby on demand | /traveller/nearby | lib/features/traveller/presentation/views/traveller_screens.dart — NearbyPlacesScreen | Category filter; details; back to active | Implemented; Traveller tests passed |
| UJ-035 | Road Alert | /traveller/road-alert | lib/features/traveller/presentation/views/traveller_screens.dart — RoadAlertScreen | Details; demo alternate; resume | Implemented; Traveller tests passed |
| UJ-036 | Hazard | /traveller/hazard | lib/features/traveller/presentation/views/traveller_screens.dart — HazardReportScreen | Evidence; description; submit to active | Implemented; Traveller tests passed |
| UJ-037 | Memories | /traveller/memories | lib/features/traveller/presentation/views/traveller_screens.dart — AddMemoriesScreen | Photo/video; caption; tags; post to active | Implemented; Traveller tests passed |
| UJ-038 | Friends | /traveller/friends | lib/features/traveller/presentation/views/traveller_screens.dart — TripFriendsScreen | Live demo markers; filters; deviation alert; invites | Implemented; Traveller tests passed |
| UJ-039 | Finish | /traveller/finish | lib/features/traveller/presentation/views/traveller_screens.dart — FinishTripScreen | Summary; save to completed plans | Implemented; Traveller tests passed |
| T-A | Review/edit route | /traveller/review | lib/features/traveller/presentation/views/traveller_screens.dart — RouteReviewScreen | Edit/reorder/add/remove; save/continue | Implemented; Traveller tests passed |
| T-F | Invites | /traveller/invites | lib/features/traveller/presentation/views/traveller_screens.dart — GroupInvitationsScreen | Invite/accept; return active | Implemented; Traveller tests passed |

## 03 Hunter

| State | Reference screen | Route | Dart target | Controls and destinations | Status |
|---|---|---|---|---|---|
| UJ-007 | Hunter landing | /hunter | lib/features/hunter/presentation/views/hunter_home_screen.dart | Current district/GPS; add; discoveries; leaderboard; profile | Deferred Phase 3 |
| UJ-008 | Add New Place | /hunter/add | lib/features/hunter/presentation/views/add_place_screen.dart | Name/category/location; checks; 360 camera; cancel | Deferred Phase 3 |
| UJ-009 | 360 Complete | /hunter/360-complete | lib/features/hunter/presentation/views/video_complete_screen.dart | Play/retake; add normal photo | Deferred Phase 3 |
| UJ-010 | Video attached | /hunter/attached | lib/features/hunter/presentation/views/evidence_screen.dart | Retake 360; normal photo | Deferred Phase 3 |
| UJ-011 | Live Photo | /hunter/photo | lib/features/hunter/presentation/views/photo_screen.dart | Capture/switch/retake; back | Deferred Phase 3 |
| UJ-012 | Review | /hunter/review | lib/features/hunter/presentation/views/review_screen.dart | Photo/video; edit; retake; submit | Deferred Phase 3 |
| UJ-013 | Rewards/My Places | /hunter/rewards | lib/features/hunter/presentation/views/rewards_screen.dart | Pending/verified; badges/achievements | Deferred Phase 3 |
| UJ-014 | Leaderboard | /hunter/leaderboard | lib/features/hunter/presentation/views/leaderboard_screen.dart | District/month/all-time | Deferred Phase 3 |
| H-CAM | 360 evidence | /hunter/camera360 | lib/features/hunter/presentation/views/camera360_screen.dart | Permission; supported capture or explicit mock; complete | Deferred Phase 3 |
| H-GPS | GPS/restricted zone | /hunter/location-check | lib/features/hunter/presentation/views/location_check_screen.dart | Denied/settings/retry; mock validity | Deferred Phase 3 |
| H-DUP | Duplicate check | /hunter/duplicate-check | lib/features/hunter/presentation/views/duplicate_check_screen.dart | Demo 200m/name/image; block/retry | Deferred Phase 3 |
| H-ADM | Review status | /hunter/status | lib/features/hunter/presentation/views/submission_status_screen.dart | Pending; manual demo approve/reject; reward only approved | Deferred Phase 3 |

## 04 Game

| State | Reference screen | Route | Dart target | Controls and destinations | Status |
|---|---|---|---|---|---|
| UJ-015 | Game Zone | /game | lib/features/games/presentation/views/game_zone_screen.dart | Create/play; sponsored; my games; LB; how; rewards; wallet | Deferred Phase 4 |
| UJ-016 | Setup | /game/create | lib/features/games/presentation/views/game_setup_screen.dart | Title/district/type/reward; continue | Deferred Phase 4 |
| UJ-017 | Location photo | /game/create/photo | lib/features/games/presentation/views/game_photo_screen.dart | Camera/gallery; retake/use; explicit policy | Deferred Phase 4 |
| UJ-018 | Hint/rules | /game/create/rules | lib/features/games/presentation/views/game_rules_screen.dart | Hint/instructions/reward; continue | Deferred Phase 4 |
| UJ-019 | Review/publish | /game/create/review | lib/features/games/presentation/views/game_review_screen.dart | Edit; publish | Deferred Phase 4 |
| UJ-020 | Published | /game/create/published | lib/features/games/presentation/views/game_published_screen.dart | My Game; share local demo; Game Zone | Deferred Phase 4 |
| UJ-021 | District | /game/play | lib/features/games/presentation/views/district_screen.dart | Map/select; continue | Deferred Phase 4 |
| UJ-022 | Challenges | /game/challenges | lib/features/games/presentation/views/challenges_screen.dart | Preview/select district challenge | Deferred Phase 4 |
| UJ-023 | Accept | /game/challenge | lib/features/games/presentation/views/challenge_screen.dart | Accept; not now; reject own game | Deferred Phase 4 |
| UJ-024 | Find place | /game/find | lib/features/games/presentation/views/find_place_screen.dart | Hint; found place | Deferred Phase 4 |
| UJ-025 | Proof | /game/proof | lib/features/games/presentation/views/proof_screen.dart | Capture/retake/use | Deferred Phase 4 |
| UJ-026 | Submit | /game/submit | lib/features/games/presentation/views/submit_screen.dart | Review; local demo verification | Deferred Phase 4 |
| UJ-027 | Complete | /game/victory | lib/features/games/presentation/views/victory_screen.dart | Mock award; rewards; zone | Deferred Phase 4 |
| G-C | Choose create/play | /game | lib/features/games/presentation/views/game_zone_screen.dart | Independent branches | Deferred Phase 4 |
| G-VERIFY | Demo verification | /game/verify | lib/features/games/presentation/views/verification_screen.dart | Local simulation only | Deferred Phase 4 |
| G-VICTORY | First-winner simulation | /game/victory | lib/features/games/presentation/views/victory_screen.dart | One mock win per game | Deferred Phase 4 |
| G-OVER | Game over | /game/over | lib/features/games/presentation/views/game_over_screen.dart | Own game/already won/invalid; zone | Deferred Phase 4 |
| G-W | Wallet | /wallet | lib/features/wallet/presentation/views/wallet_overview_screen.dart — WalletOverviewScreen | Game Rewards Open My Wallet; shared Game/Hunter reward credits; Back returns to Game Rewards | Implemented; shared reward and navigation tests passed |
| G-HOW | How/sponsored | /game/how | lib/features/games/presentation/views/how_to_play_screen.dart | Rules/sponsored; back | Deferred Phase 4 |
| G-LB | Leaderboard | /game/leaderboard | lib/features/games/presentation/views/leaderboard_screen.dart | This game/month/all-time | Deferred Phase 4 |
| G-MY | My Games | /game/my | lib/features/games/presentation/views/my_games_screen.dart | Created/joined/finished; view | Deferred Phase 4 |
| G-RW | Rewards store | /game/rewards | lib/features/games/presentation/views/rewards_store_screen.dart | Browse; canonical wallet | Deferred Phase 4 |

## 05 Profile

| State | Reference screen | Route | Dart target | Controls and destinations | Status |
|---|---|---|---|---|---|
| UJ-040 | Profile | /profile | lib/features/profile/presentation/views/profile_screen.dart | Games/posts/trips/hunts/badges; edit; wallet; settings | Deferred Phase 5 |
| UJ-041 | Settings | /profile/settings | lib/features/profile/presentation/views/settings_screen.dart | Password/language/privacy/notifications/help/about/delete/logout | Deferred Phase 5 |
| UJ-042 | Security/password | /profile/settings/security | lib/features/profile/presentation/views/security_screen.dart | Old/new/confirm; eyes; save | Deferred Phase 5 |
| UJ-043 | Language dropdown | /profile/settings/language | lib/features/profile/presentation/views/language_screen.dart | English/Tamil/Sinhala; save | Deferred Phase 5 |
| UJ-044 | Privacy | /profile/settings/privacy | lib/features/profile/presentation/views/privacy_screen.dart | Public/private; save | Deferred Phase 5 |
| UJ-045 | Notifications | /profile/settings/notifications | lib/features/profile/presentation/views/notifications_screen.dart | Trip/game/hunter/hazard/promotions toggles | Deferred Phase 5 |
| UJ-046 | Help/support | /profile/settings/help | lib/features/profile/presentation/views/help_screen.dart | How; FAQ/contact/report; back | Deferred Phase 5 |
| UJ-047 | How to use | /profile/settings/how | lib/features/profile/presentation/views/how_to_use_screen.dart | Getting started/modules/wallet topics | Deferred Phase 5 |
| UJ-048 | About | /profile/settings/about | lib/features/profile/presentation/views/about_screen.dart | Version; what new; demo update | Deferred Phase 5 |
| UJ-049 | Delete confirmation | /profile/settings/delete | lib/features/profile/presentation/views/delete_account_screen.dart | Yes delete local account → Sign In; No → settings | Deferred Phase 5 |
| UJ-050 | Logout confirmation | /profile/settings/logout | lib/features/profile/presentation/views/logout_screen.dart | Log out → Sign In; cancel | Deferred Phase 5 |
| P-DO | No/cancel | settings confirmation | lib/features/profile/presentation/views/confirmation_dialog.dart | Preserve session/preferences | Deferred Phase 5 |
| P-EDIT | Edit profile | /profile/edit | lib/features/profile/presentation/views/edit_profile_screen.dart | Photo/name/bio; save refreshes Home | Deferred Phase 5 |
| P-WAL | Wallet entry | /wallet | lib/features/wallet/presentation/views/wallet_overview_screen.dart — WalletOverviewScreen | Profile My Wallet tab/card; canonical eight-screen wallet; Back returns to Profile | Implemented; Profile entry tests passed |
| P-MISS | Help destination | /profile/settings/support | lib/features/profile/presentation/views/support_screen.dart | FAQ/contact/report topic details | Deferred Phase 5 |

## 06 Wallet

| State | Reference screen | Route | Dart target | Controls and destinations | Status |
|---|---|---|---|---|---|
| W-01 | Overview | /wallet | lib/features/wallet/presentation/views/wallet_overview_screen.dart — WalletOverviewScreen | HP/posted RC/lifetime/level; available/reserved; redeem; vouchers; history; rules; latest request; failed-save retry | Implemented; widget/state tests passed |
| W-02 | Choose voucher | /wallet/choose | lib/features/wallet/presentation/views/wallet_redemption_screens.dart — WalletRewardsScreen | All/Shopping/Food/Travel; three Thyaga demo offers; honest empty-category reset; select | Implemented; widget tests passed |
| W-03 | Confirm | /wallet/confirm?offer=&intent= | lib/features/wallet/presentation/views/wallet_redemption_screens.dart — WalletConfirmScreen | Responsive voucher; required/total/reserved/available/after approval; fixed Cancel/Confirm; separate shortfall and pending-request links; idempotent confirmation | Implemented; unchanged 9 Wallet widget tests and 18-case layout probe passed |
| W-04 | Request Pending | /wallet/pending?id= | lib/features/wallet/presentation/views/wallet_redemption_screens.dart — WalletPendingScreen | Unique ID; RC hold without posted deduction or voucher; Back to Wallet; stale link reflects decision | Implemented; widget/state tests passed |
| W-05 | Approved | /wallet/approved?id= | lib/features/wallet/presentation/views/wallet_redemption_screens.dart — WalletApprovedScreen | Only after separate demo decision; one stock assignment/debit; View My Vouchers | Implemented; widget/state tests passed |
| W-06 | My Vouchers | /wallet/vouchers | lib/features/wallet/presentation/views/wallet_voucher_screens.dart — WalletVouchersScreen | Active/Used tabs; Used includes expired records; issue/expiry/status; details; empty state | Implemented; widget tests passed |
| W-07 | Details QR/code | /wallet/voucher?id= | lib/features/wallet/presentation/views/wallet_voucher_screens.dart — WalletVoucherDetailsScreen | Identifier QR; nonredeemable demo label; full-code clipboard; dates/status; expandable How to Use; separate debug merchant link | Implemented; QR painter/clipboard/expiry/widget tests passed |
| W-08 | History | /wallet/history | lib/features/wallet/presentation/views/wallet_voucher_screens.dart — WalletHistoryScreen | Actual ledger; All/HP/RC/Vouchers filters; linked requests/vouchers and reward information | Implemented; widget/state tests passed |
| W-RJ | Rejected | /wallet/rejected?id= | lib/features/wallet/presentation/views/wallet_redemption_screens.dart — WalletRejectedScreen | Reason; release hold without RC debit; choose again; Back | Implemented; widget/state tests passed |
| W-LO | Insufficient RC | /wallet/insufficient?offer= | lib/features/wallet/presentation/views/wallet_redemption_screens.dart — WalletInsufficientScreen | Required/available/shortfall; choose another; Wallet; confirmation blocked | Implemented; widget/state tests passed |
| W-EX | Expired/used | /wallet/voucher?id= | lib/features/wallet/presentation/views/wallet_voucher_screens.dart — WalletVoucherDetailsScreen | Dates/status; no active QR; expiry timer and resume refresh; one-use merchant guard | Implemented; widget/state tests passed |
| W-H | History alias | /wallet/history | lib/features/wallet/presentation/views/wallet_voucher_screens.dart — WalletHistoryScreen | Same W-08; no ninth main screen | Implemented |
| W-RULES | Supporting rules | /wallet/rules | lib/features/wallet/presentation/views/wallet_overview_screen.dart — WalletRulesScreen | Local balance/reservation/expiry rules; debug testing link only in debug mode | Implemented; widget tests passed |
| W-DEMO | Supporting developer tools | /wallet/demo | lib/features/wallet/presentation/views/wallet_demo_screen.dart — WalletDemoScreen | Separate labeled Requests approval/rejection and Merchant one-use simulation; invalid/used/expired feedback; disabled in release | Implemented; widget/state tests passed |

Sources: docs/flows/01_login_to_home.png through 06_wallet_vouchers.png; docs/original_screens (35 originals); docs/hunter_separated and docs/settings_separated; docs/wallet/wallet_eight_screen_reference.png. Shared Sign In/Home are counted only in Auth. Wallet remains exactly eight main screens.

## Reference image index

Every original is listed here so its controls remain traceable even when its feature is deferred. Paths in the next table are relative to `docs/original_screens/`.

| Original source image | Inventory state(s) |
|---|---|
| `login/Screenshot 2026-11-04 221741.png` | UJ-001 Sign In |
| `login/Wayhunder Create Account Screen.png` | UJ-002 Create Account |
| `login/ChatGPT Image Nov 4, 2026, 10_21_27 PM-3.png` | UJ-003 OTP |
| `login/Screenshot 2026-11-04 221935.png` | UJ-004 Forgot Password |
| `login/ChatGPT Image Nov 4, 2026, 10_21_28 PM-4.png` | UJ-005 Offline |
| `login/Screenshot 2026-11-03 101551 (1).png` | UJ-006 Home |
| `hunder/WhatsApp Image 2026-11-03 at 1.40.37 PM.jpeg` | Combined montage: shared UJ-001/UJ-006 and Hunter UJ-007–014 |
| `game/Wayhunter_Game_Module_User_Journey_One_Image (1).jpg` | Game create/play journey montage UJ-015–027 |
| `game/WhatsApp Image 2026-11-03 at 4.20.46 PM.jpeg` | UJ-015 Game Zone |
| `game/WhatsApp Image 2026-11-03 at 4.20.45 PM.jpeg` | UJ-016 Setup |
| `game/WhatsApp Image 2026-11-03 at 4.20.44 PM (1).jpeg` | UJ-017 Photo; includes visible Gallery option |
| `game/WhatsApp Image 2026-11-03 at 4.20.44 PM.jpeg` | UJ-018 Hint & Rules |
| `game/WhatsApp Image 2026-11-03 at 4.20.42 PM.jpeg` | UJ-019 Review & Publish |
| `game/WhatsApp Image 2026-11-03 at 4.20.40 PM.jpeg` | UJ-020 Published |
| `game/WhatsApp Image 2026-11-03 at 4.20.54 PM.jpeg` | UJ-021 Select District |
| `game/WhatsApp Image 2026-11-03 at 4.20.52 PM (1).jpeg` | UJ-022 District Challenges |
| `game/WhatsApp Image 2026-11-03 at 4.20.52 PM.jpeg` | UJ-023 Accept Challenge |
| `game/WhatsApp Image 2026-11-03 at 4.20.51 PM.jpeg` | UJ-024 Find the Place |
| `game/WhatsApp Image 2026-11-03 at 4.20.50 PM.jpeg` | UJ-025 Capture Proof |
| `game/WhatsApp Image 2026-11-03 at 4.20.49 PM.jpeg` | UJ-026 Submit Challenge |
| `game/WhatsApp Image 2026-11-03 at 4.20.48 PM.jpeg` | UJ-027 Challenge Complete / G-VICTORY |
| `traveller/create/Wayhunter Traveller_ Neon Adventure Map.png` | UJ-028 Traveller landing |
| `traveller/create/Wayhunter_Create_New_Trip_Screen.png` | UJ-029 Route builder |
| `traveller/create/Wayhunter_AI_Trip_Plan_Screen.png` | UJ-030 AI Plan |
| `traveller/create/Jaffna Heritage Trail Trip Planner.png` | UJ-031 Previous Traveller Plan |
| `traveller/create/Wayhunter Traveller_ My Plans.png` | UJ-032 My Plans |
| `traveller/on trip/Wayhunter Active Trip Map UI.png` | UJ-033 Active Trip |
| `traveller/on trip/Wayhunter Nearby Places Map.png` | UJ-034 Nearby Places |
| `traveller/on trip/report/Screenshot 2026-11-04 002231.png` | UJ-035 Road Alert |
| `traveller/on trip/report/Neon Wayhunter Hazard Report Form.png` | UJ-036 Hazard |
| `traveller/on trip/memo/Wayhunter Add Memories Screen.png` | UJ-037 Memories |
| `traveller/on trip/frds/Trip Friends Live Journey Map.png` | UJ-038 Friends |
| `traveller/after/Wayhunter Traveller Finish Trip Dashboard.png` | UJ-039 Finish Trip |
| `profile/Neon Travel Explorer Profile.png` | UJ-040 Profile |
| `profile/Wayhunter Traveller Settings UI Montage.png` | UJ-041–050 Settings and account actions |

The following paths are relative to `docs/` and map every separated panel:

| Cropped/source panel | Inventory state(s) |
|---|---|
| `hunter_separated/01_sign_in.png` | Shared UJ-001 |
| `hunter_separated/02_app_home.png` | Shared UJ-006 |
| `hunter_separated/03_hunter_home.png` | UJ-007 |
| `hunter_separated/04_add_new_place.png` | UJ-008 |
| `hunter_separated/05_video360_complete.png` | UJ-009 |
| `hunter_separated/06_video_attached.png` | UJ-010 |
| `hunter_separated/07_normal_photo_camera.png` | UJ-011 |
| `hunter_separated/08_review_new_place.png` | UJ-012 |
| `hunter_separated/09_rewards_my_places.png` | UJ-013 |
| `hunter_separated/10_hunter_leaderboard.png` | UJ-014 |
| `settings_separated/01_settings_home.png` | UJ-041 |
| `settings_separated/02_security_password.png` | UJ-042 |
| `settings_separated/03_language_dropdown.png` | UJ-043 |
| `settings_separated/04_privacy.png` | UJ-044 |
| `settings_separated/05_notifications.png` | UJ-045 |
| `settings_separated/06_help_support.png` | UJ-046 |
| `settings_separated/07_how_to_use.png` | UJ-047 |
| `settings_separated/08_about.png` | UJ-048 |
| `settings_separated/09_delete_account.png` | UJ-049 |
| `settings_separated/10_logout.png` | UJ-050 |
| `wallet/wallet_eight_screen_reference.png` | W-01→W-08 in displayed order; authoritative Wallet layout |

Flow-only states: F1 `AUTH-R/E/RY/C/P`; F2 `T-A/T-F`; F3 `H-CAM/H-ADM/H-GPS/H-DUP`; F4 `G-C/G-VERIFY/G-VICTORY/G-OVER/G-W/G-HOW/G-LB/G-MY/G-RW`; F5 `P-DO/P-EDIT/P-WAL/P-MISS`; F6 `W-RJ/W-LO/W-EX/W-H`. These derive from the corresponding `docs/flows/01` through `06` diagrams, without an original standalone screenshot.

Runtime artwork for UJ-006: unchanged `assets/images/backgrounds/home_background.png` and `assets/images/buttons/traveller_button.png`, `hunter_button.png`, `game_button.png`. The duplicate `assets/images/home_buttons/` set is retained. Original full graphics already contain labels/arrows and receive no duplicate text overlay.

## Phase 1 entry-preview boundaries

Traveller now embeds the reusable `lib/features/traveller/presentation/widgets/traveller_map.dart` inside the completed landing and trip workflows, backed by typed repositories, `MockData` and Riverpod ViewModels. Landing starts at Jaffna; active/review views add approximate route points and member markers. Native permission is requested only through Enable my location, with denied/blocked/GPS-off/unsupported fallbacks. Home artwork and Maps secrets remain unchanged; only Traveller routing was replaced and expanded. Secrets continue through Google's Secrets Gradle Plugin and ignored `android/secrets.properties`, with safe `android/local.defaults.properties`.

| Runtime route | Actual Dart target | Scope |
|---|---|---|
| `/traveller` and all fourteen Traveller paths | `lib/features/traveller/presentation/views/traveller_screens.dart` | Actual map landing, planning, active journey, independent tools and completion; no Traveller phase preview |
| `/hunter`, `/game` | `lib/features/home/presentation/views/feature_entry_screen.dart` | Existing entry previews retained outside the Traveller-only task |
| `/profile`, `/leaderboard` | Historical Phase 1 entry targets | Outside this Wallet update; earlier inventory is retained for context |
| `/wallet` and its eight-screen journey | `lib/features/wallet/presentation/providers/wallet_routes.dart` | Current completed Wallet widgets; supporting rules, error states and isolated debug tools; no reachable Wallet phase preview |
| `/notifications` | `lib/features/home/presentation/views/feature_entry_screen.dart` — NotificationsScreen | Home support screen; local updates and Mark all as read update badge state |
| `/loading` | `lib/app/app_router.dart` | Preference initialization; auth guard then selects Sign In/Permissions/Home |

## Historical Phase 1 validation ledger

Final verification: `flutter analyze` exit 0, `No issues found! (ran in 15.8s)`; standard `flutter test` exit 0, `23 passed`; `flutter build apk --debug` exit 0 and produced `build/app/outputs/flutter-apk/app-debug.apk` (406.0s Gradle build). Native runtime/device checks remain outstanding. See `PHASE_1_IMPLEMENTATION.md` for the complete delivery ledger.

`flutter test` completed with exit code **0** and **23 tests passed** (`+23: All tests passed!`). This is Flutter unit/widget validation with injected storage/services; it does not claim a native Android smoke test or APK build.

| Test file | Count | Evidence |
|---|---|---|
| `test/auth/auth_view_model_test.dart` | 7 | Central demo credentials; wrong credentials; registration/terms/duplicate account; invalid/expired OTP and resend cooldown; verified recovery/password change; offline cancel/resume once; remembered email/language; once-only new-account permissions |
| `test/auth/auth_flow_test.dart` | 3 | Actual form → registration OTP → Sign In → permissions → Home and subsequent sign-in skip; recovery forms and password reset → Home; offline registration Retry/Resume → OTP and simulated Android Back → preserved registration draft |
| `test/widget_test.dart` | 5 | Signed-out route guards and recovery deep links; original Home image taps → module entries → Home; local search result route; notification read state; sign-out Cancel/Confirm; small viewport and keyboard layouts |
| `test/core/native_fallback_test.dart` | 8 | Native Maps configuration boolean without exposing key; absent key/plugin/platform-error fallback and retry; unsupported platform; denied/unavailable camera and notification permission feedback; optional settings; typed in-memory preference storage |

Auth UJ-001–006 and AUTH-R/E/RY/C/P are implemented in the actual files listed above. Local registration/password changes live in the mock repository for the current launch; remembered email, language and permission-introduction flags use harmless local preferences. There is no live email/SMS/authentication. Profile photo picking is optional with an honest unavailable fallback; actual Android camera/gallery behavior still requires a device.

The exact analysis/test/build ledger is recorded in `docs/PHASE_1_IMPLEMENTATION.md`. The debug APK compiled successfully. No native Android device/emulator is currently attached. Native Maps tiles, GPS, camera and notification permission dialogs require Android verification with a restricted developer Maps key. The missing-key path is tested and remains usable. Later-phase workflows remain deferred even when their entry routes are reachable.


## Current Traveller verification

`flutter analyze`: exit 0, No issues found (2.8s). Standard `flutter test`: exit 0, 37 passed. Android debug build: exit 0, built build/app/outputs/flutter-apk/app-debug.apk (62.3s). The Traveller suite includes 7 existing map/native-boundary tests, 3 journey state/repository tests, and 4 end-to-end/layout widget tests. All 14 screens render at 320 pixels, with full Home → create → save → start → finish and independent branch interactions tested. Auth/Home regressions continue to pass. See TRAVELLER_IMPLEMENTATION.md for the complete current scope and session/native limitations.

### Landing refinement verification — 5 November 2026

UJ-028 now has a fixed non-scrolling layout, a flexible native Google Map initially fitted once to the full Sri Lankan island, two electric-blue actions to the existing Create Trip/My Plans screens, the fixed four-icon footer and sigma-5 blur on the original background only. Other destination screens and Maps key configuration were preserved.

Final `flutter analyze --no-pub`: exit 0, No issues found (2.3s). Final `flutter test --no-pub --reporter expanded`: exit 0, **44 passed**. Seven new landing tests cover small/landscape viewports, safe insets, larger text, fixed controls, blur isolation, routes and the single native bounds update. Android debug build/install/launch also passed. Live tiles on the Android 17 emulator showed the complete island; pan/zoom, both destination buttons, Android Back and fixed footer were exercised successfully, with no app runtime error entries. See `TRAVELLER_IMPLEMENTATION.md` for changed files and evidence paths.

## Home module-entry regression fix — 6 November 2026

Reproduced `demo login opens original Home images and every module entry returns Home` with `flutter test test/widget_test.dart --reporter expanded`. The assertion at `test/widget_test.dart:176`, `expect(tester.takeException(), isNull)`, caught four Game Zone layout errors before reaching the Game Back action: the stats row overflowed horizontally by 52 pixels, both Create/Play action cards overflowed vertically by 20 pixels, and the sponsor card overflowed vertically by 11 pixels. The test already checked actual module screens and the correct Back tooltips; its expectations were current.

Updated only `lib/features/games/presentation/views/game_zone_screen.dart`: each score now has a bounded Expanded/FittedBox allocation, action titles fit on one line, and the full sponsor caption fits within its width. Existing card dimensions, colors, copy, actions and routes were preserved. The unchanged test now verifies all three Home image entries and their Back actions successfully. Test-file, router, Home source and original image hashes match their pre-fix values.

Verification results:

- `flutter test test/widget_test.dart --reporter expanded`: exit **0**, **5 passed** after the fix.
- `flutter test test/widget_test.dart`: exit **0**, **5 passed**.
- `flutter test`: exit **0**, **64 passed**, none skipped or removed.
- `flutter analyze`: exit **1**, **31 informational lint findings** in untouched files (30 missing-brace style notices and one async BuildContext notice). No finding references the changed Game Zone file. Unrelated files were preserved as requested.
- `flutter analyze lib/features/games/presentation/views/game_zone_screen.dart --no-pub`: exit **0**, **No issues found**.

Changed files for this fix: `lib/features/games/presentation/views/game_zone_screen.dart`, `docs/SCREEN_COVERAGE.md`. Logs: `.codex_review/widget_navigation_repro.log`, `widget_navigation_final_test.log`, `widget_navigation_full_test.log`, `widget_navigation_analyze.log` and `widget_navigation_scoped_analyze.log`.

## Current Wallet verification — 6 November 2026

The approved `docs/wallet/wallet_eight_screen_reference.png` now maps to the eight distinct W-01 through W-08 widgets above. Supporting rules/debug/error states are not additional main Wallet screens. The old Wallet entry-preview class remains in its existing file but is no longer routed.

- `flutter test`: exit **0**, **86 passed**, including **22 new Wallet tests**. Existing tests were not removed, disabled or weakened.
- `flutter analyze`: exit **1**, **30 pre-existing info notices** in untouched Game/Hunter/Profile/Traveller code (29 brace-style notices and one async BuildContext notice), **zero errors and warnings**.
- Scoped analysis of Wallet, app router, MockData and Wallet tests: exit **0**, **No issues found**.
- All eight real-font captures were visually reviewed. Layouts at 390 × 844, 320 × 640 and 320 × 568 passed without rendering exceptions and retain fixed headers/footers.
- Android debug build: exit **0**, **39.2 seconds** Gradle time. Android emulator checks passed for Profile entry, request/hold, separate demo approval, voucher QR/clipboard, one-use merchant simulation, history/filter, process-restart persistence and Android Back to Profile. No app-error entries were returned by the final log check. Physical Android hardware was not tested.
- Original background, Android manifest and baseline unrelated feature source hashes remain unchanged. No Maps key, backend, new dependency or platform configuration was added.

See `WALLET_IMPLEMENTATION.md` for the complete created/modified file list, connected routes, demo walkthrough, retained emulator state, test evidence and prototype limits.

### Confirmation overflow fix — 6 November 2026

W-03 now uses its actual available body constraints instead of a fixed 625/710-pixel `WalletFit` design height. The original approach scaled after layout; wrapped balance labels, added Total/Reserved rows and insufficient-RC controls could exceed the inner Column's height before that scale was applied. Increasing the fixed height did not make those children responsive. The current source reproduced 36-pixel overflows at 320 × 640 and 320 × 568, plus an absent shortfall action when a pending request existed.

`WalletConfirmScreen` now allocates viewport-based flexible voucher, balance and message/action sections, uses a compact horizontal voucher on shorter phones, fits complete balance labels/values on one line, and pins Cancel/Confirm outside those sections. Sections measure natural content without a fixed internal height; nothing is clipped or omitted and the page does not scroll. Both shortfall and pending-request actions are available for insufficient balances. The shared header/footer, `WalletFit`, ledger, router, other Wallet screens and all existing tests are unchanged.

- Required `flutter test test/wallet/wallet_flow_test.dart --reporter expanded`: exit **0**, **9 passed**.
- `flutter test`: exit **0**, **88 passed**, no unrelated failures.
- `flutter analyze`: exit **1**, one existing informational `use_build_context_synchronously` notice at `profile_dashboard_screen.dart:712`; zero errors or warnings. The changed Wallet Dart file analyzes cleanly (exit **0**).
- Additional ignored diagnostic probe: **18 passed** with the default test font and **18 passed** with Roboto. It covers all three offers at 390 × 844, 320 × 640 and 320 × 568, with/without pending reservations, visible fields/actions/header/footer, disabled insufficient confirmation, shortfall navigation and Cancel. Real-font captures were inspected for small and large phones.
- Hash comparison across `lib/`, `test/` and `assets/` confirms only `wallet_redemption_screens.dart` changed. Its content before Confirm and from Pending onward is unchanged (apart from normalized line endings). No existing test was edited, skipped or weakened.

Evidence is in `.codex_review/wallet_overflow_repro.log`, `wallet_overflow_fixed_test.log`, `wallet_overflow_analyze.log`, `wallet_overflow_scoped_analyze.log`, `wallet_overflow_full_test.log`, `wallet_confirm_matrix.log`, `wallet_confirm_visual.log`, and `wallet-confirm-*.png`.
