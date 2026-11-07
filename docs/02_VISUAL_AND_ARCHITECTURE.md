# Wayhunter UI/assets & mobile architecture

## Assets shipped (use these exact image files)

- `assets/images/backgrounds/home_background.png` — the PROVIDED full-height scenic waterfall/bridge image.
- `assets/images/home_buttons/traveller_button.png` — cyan Traveler banner (contains its own text and arrow icon).
- `assets/images/home_buttons/hunter_button.png` — gold Hunter banner (contains its own text and arrow icon).
- `assets/images/home_buttons/game_button.png` — purple Game banner (contains its own text and arrow icon).
- Reference workflow diagrams: `reference/workflows/*.png` (NOT runtime assets).
- Original wallet eight-panel montage: `reference/wallet/wallet_8_screens.png` (NOT runtime UI screenshot); recreate each as Flutter widgets.
- To recreate other UJs precisely, put the separately supplied `UI_DESIGN(1).zip` in `reference/original_UI_DESIGN.zip` and inspect the individual source UI screenshots; six workflow composites alone are insufficient for pixel-exact designs.

## UI direction
- Baseline layout size: mobile 390 x 844 logical px, responsive to smaller/larger sizes.
- Home = safe area overlay on `Image.asset(...home_background.png, fit: BoxFit.cover)` with dark gradient for legibility.
- Home buttons = `Image.asset` assets, aspect ratio preserved, `InkWell` overlay; do not put a second Text('Traveler') over the existing baked-in labels.
- Module screen scaffold uses the same scenic image as a background when appropriate, translucent dark `Container` panels, optional `BackdropFilter` applied only in clipped bounded areas.
- Common glass: dark navy `#0F172A` opacity .50-.74, white foreground, readable high-contrast hint text.
- Traveller = `#06B6D4` cyan / `#0284C7` blue, Hunter = `#F59E0B` gold, Game = `#8B5CF6` purple; contextual module button focus/glow.
- Profile/Wallet continue dark glass plus cyan primary actions. Never recolor the supplied PNG cards; they are already thematically colored.
- Material semantics/touch targets, status bar inset, bottom navigation, keyboard-safe scrolling, meaningful error/empty/loading states, no clipped text.

## Feature-first + Clean Architecture + MVVM with Riverpod
```
lib/
  main.dart
  app/
    app.dart
    router/app_router.dart
    theme/app_theme.dart
  core/
    mock/mock_data.dart                 # ALL initial hardcoded sample data here ONLY
    map/map_service.dart                # google_maps_flutter
    location/device_location_service.dart  # geolocator
    storage/local_settings.dart
    widgets/glass_card.dart
    widgets/wayhunter_background.dart
    widgets/module_theme_scope.dart
    errors/app_failure.dart
  shared/domain/entities/{user,place,district}.dart
  features/
    authentication/
    home/
    traveller/
    location_hunter/
    games/
    profile/
    wallet/
    notifications/
    advertisements/
```
Each feature contains:
```
features/<feature>/
  presentation/views/              # Screen widgets
  presentation/viewmodels/         # Riverpod Notifier/AsyncNotifier
  presentation/providers/          # provider wiring (DI)
  presentation/widgets/            # reusable within feature
  domain/entities/                  # typed models
  domain/repositories/              # abstract repository contracts
  domain/usecases/                  # complex rules only
  data/repositories/                # mock implementation from MockData
  data/models/                      # if needed
```

## Important boundaries
- No network backend. The repository interfaces make replacing the mock with an API implementation later easy.
- Seed data in one `MockData` file. Mutable state in mock repositories/Riverpod; persist non-sensitive demo data with shared_preferences only if needed.
- Maps map tiles and GPS may be real. Other places, weather, transport, route suggestions, user/group positions, winner verification, OTP and voucher redemption are mock. Make that clear in the demo.
- `google_maps_flutter` shows a map, markers and manually supplied polylines. It does not automatically compute real road routes. Avoid using an unrestricted Routes REST key inside the app.
- `qr_flutter` can encode a DEMO code locally. No real merchant or voucher codes/partnership are connected.
