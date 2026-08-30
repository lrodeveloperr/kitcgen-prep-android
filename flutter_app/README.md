# Kitchen Prep Board Flutter app

This is the canonical Android and iOS application built from the Very Good CLI Flutter structure.

## Source map

- `lib/main.dart` — application entry point and localization setup
- `lib/application` — app controller and state transitions
- `lib/catalogue` — preloaded kitchen catalogue
- `lib/data` — atomic offline persistence
- `lib/domain` — board, task, scheduling and timer logic
- `lib/features` — responsive Kitchen Prep Board UI
- `lib/l10n` — ten-language localized strings, including both Chinese scripts
- `lib/services` — notifications, consent, ads and purchases
- `android` — Android runner and platform configuration
- `ios` — iOS runner and platform configuration

## Verify

```bash
flutter pub get
flutter analyze
flutter test
```

## Review builds

```bash
flutter build apk --debug --flavor production -t lib/main.dart
flutter build ios --release --no-codesign --flavor production -t lib/main.dart
```

Review builds intentionally use Google test ad identifiers. Signed store builds must provide `REMOVE_ADS_PRODUCT_ID`, `BANNER_AD_UNIT_ID` and `USE_TEST_ADS=false` as Dart defines.
