# Kitchen Prep Board — Android

Fresh native **Sage Station** Kotlin/Jetpack Compose skin and workflow baseline for Kitchen Prep Board — Personal Station Workbench.

Authority:
- App ID: `kitchen-prep-board`
- Frozen backend SHA-256: `431414417d83201263951f0f3ed5854d38da88c7ec1b96c8e3d42168e556083b`
- Supplied Sage Station complete-screen-pack SHA-256: `d2c94eb77c8db9d818cce7365f26b03cdeea03492e24611e3872b24355dc19a9`
- UI: Kotlin + Jetpack Compose / Material 3
- Core interaction baseline: local-first; no account/cloud/server dependency

The previous Timeline Pulse/workflow-only repository state is intentionally superseded by this fresh tree.

Release integration still needs the production Room/AlarmManager/AdMob/UMP/Play Billing adapters and full locale resources required by the frozen backend before a store build can be certified.

No push-triggered GitHub Action is included. Pushing source does not automatically consume CI minutes or publish to a store.
