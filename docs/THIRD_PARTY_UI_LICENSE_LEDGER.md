# Kitchen Prep Board — Third-Party UI Licence Ledger

Status: APPROVED INPUTS FOR COMMERCIAL BUILD
Updated: 2026-09-02

This ledger is the gate for third-party UI/component reuse in Kitchen Prep Board. No third-party code, assets, fonts, icons, screenshots, illustrations, or template files may be incorporated unless the licence is recorded here and permits the intended commercial distribution.

## Approved for code/component reuse

### ColorlibHQ / kite-flutter-admin-dashboard
- Source: https://github.com/ColorlibHQ/kite-flutter-admin-dashboard
- Licence: MIT
- Commercial use: Yes.
- Attribution requirement: MIT copyright/licence notice must be retained for copied/substantial source portions.
- Kitchen use: layout/responsive-pattern reference and selectively adapted component code only. Do not import admin-specific product concepts.

### Widle-Studio / Grocery-App
- Source: https://github.com/Widle-Studio/Grocery-App
- Licence: MIT
- Commercial use: Yes.
- Attribution requirement: MIT copyright/licence notice must be retained for copied/substantial source portions.
- Kitchen use: grocery catalogue/search/category/selection interaction reference and selectively adapted code. No bundled product imagery or branding is to be reused.

### chulwoo-park / timelines
- Source: https://github.com/chulwoo-park/timelines
- Licence: MIT
- Commercial use: Yes.
- Attribution requirement: MIT copyright/licence notice retained in third-party notices.
- Kitchen use: timeline rendering primitives for Now / Waiting / Next / Done workflow.

### settings_ui
- Upstream/package: settings_ui Flutter package
- Licence: Apache License 2.0
- Commercial use: Yes.
- Attribution requirement: retain Apache 2.0 licence/NOTICE obligations for distributed source portions/package.
- Kitchen use: native-adaptive Settings presentation only.

## Inspiration only — no code/assets copied

The following products may be used as UX/interaction benchmarks only. Their code, assets, screenshots, icons, copy, brand elements, proprietary visual assets, or other protected expression must not be copied:

- Things 3 — hierarchy, typography restraint, low-chrome interaction benchmark.
- Structured — timeline/workflow comprehension benchmark.
- Bring! — fast grocery selection/search benchmark.
- AnyList — autocomplete/category/selection-efficiency benchmark.

All Kitchen implementations inspired by these products must be independently written and visually differentiated.

## Marketplace templates — NOT approved for code reuse by default

### Freshko / CodeCanyon
- Marketplace: Envato/CodeCanyon.
- Current item page distinguishes licences for end products where users are charged.
- Kitchen is monetized; therefore the low-cost/default licence must not be assumed sufficient.
- Status: VISUAL REFERENCE ONLY unless the owner purchases and records the appropriate licence for a charged end product.

### TaskFlowX / other CodeCanyon UI kits
- Status: VISUAL REFERENCE ONLY unless the exact purchased licence is reviewed and recorded here before code reuse.

## Build rules

1. Prefer custom Kitchen components over wholesale template imports.
2. Never copy third-party food/product imagery into the app.
3. Never copy proprietary icons/logos/brand assets.
4. Keep a `THIRD_PARTY_NOTICES` file for any MIT/Apache code actually reused.
5. Record file-level provenance when a substantial third-party source file is adapted.
6. If licence wording is ambiguous, treat the source as inspiration only.
7. App Store/Play Store binaries must be buildable without any unlicensed marketplace asset.
