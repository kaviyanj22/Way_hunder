# Codex staged build plan — never request all 6 workflows in one step

After unpacking into an existing `flutter create` project, open project in VS Code with Codex IDE extension, or launch `codex` from PowerShell in the same folder. Ensure Codex reads `AGENTS.md` and the workflow images.

## PHASE 0 — Setup + compile baseline
Ask Codex:
> Read AGENTS.md, docs/01_WORKFLOW_COVERAGE.md, docs/02_VISUAL_AND_ARCHITECTURE.md and examine all assets/reference images. Inspect Flutter SDK version and existing app. Implement only project foundation: dependencies, `MaterialApp.router`, GoRouter, ProviderScope, theme tokens, reusable cinematic background/glass components, mock seed wiring, correct pubspec assets, placeholder routes. Use the exact user-supplied images. Do not implement whole features yet. Run `flutter pub get`, `flutter analyze`, `flutter test`, fix findings, and report changed files.

## PHASE 1 — Authentication + Home
> Implement UJ-001..006 plus AUTH-R, AUTH-E, AUTH-RY, AUTH-C, AUTH-P. Sign In/Sign Up/OTP/Reset/Offline/first-time permissions; Home with actual traveller/hunter/game PNG button assets, genuine navigation. Login language dropdown only. Use MockData demo account. Validate fields; preserve form on offline retry. Do not alter other modules. Test and report.

## PHASE 2 — Traveller
> Implement UJ-028..039 plus T-A and T-F exactly from flow 02. Theme blue/cyan and glass. Real Google Maps widget + device GPS only; all places, trips, AI plans, friends, weather, hazard markers and route suggestions are seeded mock data. Create/edit/reorder stops, save/list plans, start/finish trip, nearby, hazard, memory and group tool branches. Avoid claiming actual multi-user GPS or AI. Add tests and run analyze.

## PHASE 3 — Hunter
> Implement UJ-007..014 plus H-CAM, H-GPS, H-DUP, H-ADM exactly from flow 03. Theme gold. Camera can capture real normal photo; 360 capture must be labeled DEMO unless actual 360 hardware/plugin supported. District, restricted-zone and duplicate checks mocked, stored through repo. Submission Pending then approve/reject debug simulation, points only after approval, leaderboard. Validate retake/back and data retention. Test.

## PHASE 4 — Game
> Implement UJ-015..027 plus G-C, G-VERIFY, G-OVER, G-W, G-MY, G-LB, G-RW, G-HOW exactly from flow 04. Theme purple. Full Create Game and Play Game branches; active district map with mock circles/places; no creator self-play; first verified winner only; losing entrants see Game Over. Award mock HP/RC to mock wallet. Do not claim physical proof verification. Test.

## PHASE 5 — Profile + Settings
> Implement UJ-040..050 plus P-DO, P-EDIT, P-WAL exactly from flow 05; profile details, badges/tabs, photo/name editing, password, EN/TA/SI dropdown, privacy Public/Private, notifications, help, about, delete Yes/No and logout confirmation; all persistence local and demo account only. Profile->Wallet navigation works. Test.

## PHASE 6 — Wallet / Voucher
> Implement exactly W-01..W-08 plus W-RJ, W-LO, W-EX, W-H from reference/wallet/wallet_8_screens.png + flow 06. W-01 HP/RC/lifetime/level, W-02 catalog/category, W-03 confirm, W-04 Pending, simulated admin Approve/Reject (debug only), W-05 Approved RC deduction, W-06 Active/Used vouchers, W-07 demo code/QR/expiry, W-08 ledger filters. Hold RC on request, commit debit only on approval, release on rejection, prevent duplicate use. Visual fidelity to actual wallet image. Test.

## PHASE 7 — Full QA
> Compare every UJ item in docs/01_WORKFLOW_COVERAGE.md to existing routes/views. Do not mark unimplemented branches as done. Run flutter analyze/test and available integration tests. Check maps on Android physical device separately, since Chrome/Windows desktop cannot validate camera/GPS/Android map key. Check aspect ratios, safe area, full-screen images, glass readability, module colors and back navigation. Produce docs/IMPLEMENTATION_STATUS.md with passed/blocked items. Do not add a backend.

## Response requested after each task
Changed files, completed UJs, map/demo limitations, analyze/test output, unimplemented routes, and concise next phase.
