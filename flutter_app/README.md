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
- `lib/services` — notifications and platform-specific monetization
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

Android review builds intentionally use Google test ad identifiers. Signed Android builds must provide `REMOVE_ADS_PRODUCT_ID`, `BANNER_AD_UNIT_ID` and `USE_TEST_ADS=false` as Dart defines.

The paid iOS release is ad-free and contains no in-app purchase. Before resolving iOS packages, run `./tool/prepare_ios_ad_free.sh`. This replaces the Android monetization surface and removes both Google Mobile Ads and StoreKit purchase plugins from the iOS dependency graph.
