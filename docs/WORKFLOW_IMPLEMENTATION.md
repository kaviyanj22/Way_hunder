# Complete workflow implementation ledger

Latest scope correction: the user explicitly requested **Traveller only**. Traveller is implemented and verified in `TRAVELLER_IMPLEMENTATION.md`. Work on Hunter, Game, Profile and Wallet is not being continued in this task. Earlier partial data/model files are retained, with their existing routes unchanged.

## Inspection before implementation

Auth UJ-001..006 and AUTH-R/E/RY/C/P are implemented and tested. Home artwork/buttons and the Android Google Maps Secrets configuration are working and must be preserved.

Traveller has a real reusable Jaffna map and permission state; its entry is still a preview. Trip builder, planning branches, saved/active/completed trips and active-trip tools are missing.

Hunter and Game currently route to generic entry previews. Their evidence, moderation, create/play, winner and rewards workflows are missing.

Profile, Wallet and Leaderboard are entry previews. Profile settings and the eight-screen wallet workflow are missing. Local notifications already work.

`docs/ui_reference/` is absent. The available 35 originals in `docs/original_screens/`, Hunter/Settings separated panels, wallet montage, six authoritative flow maps and existing `.codex_review` contact sheets are the visual references. `docs/SCREEN_COVERAGE.md` already inventories every reference/state before coding.

## Implementation plan

Replace all three mode entry routes with actual feature landings and implement their complete bounded modules in parallel. Implement shared camera evidence and module navigation widgets, then Profile/Settings and a single wallet ledger shared with Hunter/Game rewards. Preserve auth/Home and existing native Maps configuration. All seeded application content remains in MockData; mutable state lives in Riverpod and appropriate local preferences.

After each integrated module, run flutter analyze and flutter test, fix issues, and record real results. No module is complete merely because routes exist. Native camera/Maps/GPS unsupported states must keep the clearly labeled demo flows usable.

## Completion and evidence

Implementation in progress. Final files, routes, interactions, test results and limitations will be recorded here and in SCREEN_COVERAGE.md.
