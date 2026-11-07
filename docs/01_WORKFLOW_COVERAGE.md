# Six Workflows — Screen-by-screen coverage checklist

Sources: `reference/workflows/01..06_*.png` and `reference/wallet/wallet_8_screens.png`. **Review the actual images** while implementing. A box marked `FLOW / NO SCREEN` is an additional planned state, not a screenshot from the original mobile UI ZIP.

## 1. Login -> Home
- [ ] UJ-001 Sign In (login validation, show password, remember me, dropdown EN/TA/SI)
- [ ] UJ-002 Create Account (NO language dropdown)
- [ ] UJ-003 OTP Verification (register AND forgot flows; resend/invalid/expiry)
- [ ] UJ-004 Forgot Password -> OTP -> AUTH-R Reset Password -> Sign In
- [ ] AUTH-E field/login error validation
- [ ] UJ-005 Offline -> Retry / Cancel, preserve user text
- [ ] AUTH-RY Retry successful -> resume
- [ ] AUTH-C Cancel / Back -> safe previous route
- [ ] AUTH-P first-time permission intro ONCE after first newly verified sign-in
- [ ] UJ-006 Map Home / Mode selector (Traveler / Hunter / Game, Profile)

## 2. Home -> Traveller
- [ ] UJ-028 Traveller Map / Landing
- [ ] UJ-029 Create Trip / Route Builder: start/end, dates, ordered stops, add/reorder/delete stops, budget, people, vehicle
- [ ] UJ-030 AI Plan (MOCK suggestion) -> Submit to plans
- [ ] UJ-031 Previous Traveller Plan (MOCK saved sample) -> Use / Edit -> Route Builder
- [ ] UJ-032 My Plans: own/shared/completed, Edit, Add Friends, Start
- [ ] T-A Edit Route / modify itinerary
- [ ] UJ-033 Active Trip / Live Map
- [ ] UJ-034 Nearby Places (filters, map markers, select)
- [ ] UJ-035 Road Alert (details, dismiss, alternative route as MOCK)
- [ ] UJ-036 Report Hazard (type/location/media, submit to MOCK)
- [ ] UJ-037 Memories (photo/video, caption/tags, save)
- [ ] UJ-038 Trip Friends / Member map
- [ ] T-F Group Invite / accept / deviation alert MOCK
- [ ] UJ-039 End Trip / summary -> Completed
- [ ] All trip tools independently open from UJ-033 and return to UJ-033.

## 3. Home -> Location Hunter
- [ ] UJ-007 Hunter Home / current district / leaderboard entry
- [ ] H-GPS location permission/current-district/restricted-zone MOCK checks
- [ ] UJ-008 Add New Place form name/category/GPS/district
- [ ] H-DUP 200m / similar photo / name MOCK duplicate state
- [ ] H-CAM 360 camera demo capture (clearly label if not real 360)
- [ ] UJ-009 360 Video Complete -> preview/retake
- [ ] UJ-010 Form with 360 evidence attached -> Add Normal Photo
- [ ] UJ-011 Live normal camera -> capture/retake
- [ ] UJ-012 Review with BOTH media -> submit
- [ ] UJ-013 My Places / Rewards (pending vs approved)
- [ ] H-ADM Simulated admin decision -> Approve/Reject/Request More (debug/demo only)
- [ ] UJ-014 Hunter leaderboard (monthly/district/all time)

## 4. Home -> Game
- [ ] UJ-015 Game Zone, create/play/leaderboard/my games/how-to/rewards buttons
- [ ] G-C Choose Create/Play
- [ ] UJ-016 Create Setup
- [ ] UJ-017 Add Game Photo (source UI shows gallery option; camera-only decision unresolved)
- [ ] UJ-018 Hint & Rules
- [ ] UJ-019 Review & Publish
- [ ] UJ-020 Published / share / My Games
- [ ] UJ-021 Select District
- [ ] UJ-022 District Challenges / choose place
- [ ] UJ-023 Accept Challenge (creator blocked)
- [ ] UJ-024 Find Place
- [ ] UJ-025 Capture Proof
- [ ] UJ-026 Submit -> G-VERIFY simulated validation
- [ ] UJ-027 Victory (first valid winner only) -> wallet rewards
- [ ] G-OVER Game Over for others after first winner
- [ ] G-W Wallet / Rewards destination
- [ ] G-MY My Games
- [ ] G-LB Game Leaderboard
- [ ] G-RW Rewards Store
- [ ] G-HOW How to Play / Sponsored Games

## 5. Home -> Profile
- [ ] UJ-040 Profile, badges, tabs for game/posts/trips/hunt/wallet
- [ ] UJ-041 Settings menu
- [ ] UJ-042 Change Password (current/new/confirm)
- [ ] UJ-043 Language dropdown English/Tamil/Sinhala
- [ ] UJ-044 Public/Private + Save
- [ ] UJ-045 Trip/Game/Hunter/Hazard/Promotion notifications
- [ ] UJ-046 Help & Support -> FAQ/Contact/Report Problem
- [ ] UJ-047 How to Use -> topics
- [ ] UJ-048 About / Update
- [ ] UJ-049 Delete Account Yes/No (mock clear demo local profile)
- [ ] UJ-050 Logout Cancel/Logout
- [ ] P-DO Cancel/Delete/Logout separate branches
- [ ] P-EDIT edit name/photo/bio and persist locally
- [ ] P-WAL Wallet entry -> W-01

## 6. Profile -> Wallet (LATEST 8-screen reference wins)
- [ ] W-01 My Wallet: HP, RC, lifetime HP, level, redeem/vouchers/history/rules
- [ ] W-02 Redeem Rewards: All, Shopping, Food, Travel, rewards in RC
- [ ] W-03 Confirm Redemption: cost/current/after redemption/cancel/confirm
- [ ] W-04 Request Submitted (Pending), request ID
- [ ] Simulated admin Approve/Reject (NOT a real Admin website)
- [ ] W-05 Approved notice with RC deduction
- [ ] W-06 My Vouchers Active / Used
- [ ] W-07 Voucher Details code + QR + expiry + How to Use
- [ ] Simulate merchant redeem in demo-only UI -> Used
- [ ] W-08 Transaction History All / HP / RC / Vouchers
- [ ] W-RJ Request Rejected, hold released
- [ ] W-LO Insufficient RC, request blocked
- [ ] W-EX Expired / already Used voucher, invalid use
- [ ] W-H History states

## Acceptance definition
A UJ is marked complete only when: (1) screen renders; (2) required fields/buttons are visible; (3) every visible click navigates or acts; (4) Back and errors work; (5) in-flow mutations update subsequent screens; (6) no backend dependency or hardcoded-in-UI dataset; (7) correct module theme and provided background/cards; (8) test and analyze result recorded.
