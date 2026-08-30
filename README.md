# Kitchen Prep Board — cross-platform v2.0.0

`main` is the canonical source for the Very Good CLI/Flutter implementation of Kitchen Prep Board on Android and iOS.

The production application lives in [`flutter_app`](flutter_app). It contains:

- the shared local-first workflow, scheduling, timer and catalogue logic;
- the responsive phone/tablet UI used by Android and iOS;
- Android and iOS native runner projects;
- offline atomic-file persistence and timer notification recovery;
- UMP consent, non-personalized banner ads and remove-ads purchase wiring;
- ten launch languages, with Simplified and Traditional Chinese treated as separate locales.

The older Jetpack Compose v1.1.1 implementation remains at the repository root for history. New product work and release builds must use `flutter_app`.

## Build baseline

- Flutter 3.47.1 or newer compatible stable toolchain
- Dart 3.13 or newer compatible toolchain
- Android target SDK 36
- iOS 16+

```bash
cd flutter_app
flutter pub get
flutter analyze
flutter test
flutter build apk --debug --flavor production -t lib/main.dart
flutter build ios --release --no-codesign --flavor production -t lib/main.dart
```

Review builds use Google test ad identifiers. Production ad unit IDs and the platform remove-ads product identifier must be supplied with Dart defines during signed release builds.

See [`VERIFICATION.json`](VERIFICATION.json) for the current validation boundary.
