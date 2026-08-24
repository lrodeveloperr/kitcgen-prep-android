# Kitchen Prep Board — Android v1.1.1

`main` is the current combined Jetpack Compose UI + executable local Android backend source.

Backend contract SHA-256: `431414417d83201263951f0f3ed5854d38da88c7ec1b96c8e3d42168e556083b`.

## v1.1.1 fixes

- `BootCompletedReceiver` and `ClockChangeReceiver` are exported for system timer-recovery broadcasts; the internal alarm receiver remains non-exported.
- Starting a replacement board archives every open `DRAFT`, `READY`, `ACTIVE`, or `PAUSED` board and cancels live timers first.
- Duplicate-board reuse selects the latest finished board and remaps dependencies, prep gaps, and task resource requirements.
- Full local-data deletion includes shifts and resources.
- Resource scheduling uses bounded forward conflict scanning rather than the old 512-attempt behavior; a 600-task capacity-1 regression test is included.
- Task-start outcomes are explicit and surfaced to the UI.
- Undo returns terminal tasks through `BLOCKED` before dependency recomputation.
- Latest finished-board lookup is a DAO query.
- Duplicate failure stays on Home with a clear user message.

## Build baseline

- Android Gradle Plugin 9.3.1
- Gradle 9.5.0 compatible installation required
- JDK 17
- compileSdk 37 / targetSdk 36 / minSdk 23

Typical local commands:

```bash
gradle :app:testDebugUnitTest
gradle :app:assembleDebug
```

The project intentionally does not include a fabricated Gradle wrapper binary. Production AdMob IDs, live Play subscription configuration, and final policy/support URLs must be supplied before release.

See `VERIFICATION.json` for the validation boundary. A full Android SDK/Gradle build was unavailable in the packaging environment; focused Kotlin semantic/regression validation passed.
