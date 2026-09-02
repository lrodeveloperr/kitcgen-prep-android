# Ocean Pearl design QA

Reference sources:

- Grocery Benefits glossy pearl canvas, normalized to the 430 × 932 phone viewport.
- PressBench four-destination bottom navigation and Ocean Pearl tokens.

Implementation captures:

- `Ocean-Pearl-Visual-QA/ocean_pearl_home.png` — Kitchen Home shell and bottom bar.
- `Ocean-Pearl-Visual-QA/ocean_pearl_phone.png` — active live-board workflow.

## Visible comparison

The Grocery reference, Home capture and live-board capture were inspected together
at the same 430 × 932 viewport.

- P0: none.
- P1: none.
- P2: none.
- P3: CI uses Flutter's Ahem test font, so text appears as metric-preserving blocks
  in golden captures. Production fonts and layout metrics are unaffected.

The implementation consistently carries the pearl canvas, 24 px white cards,
cool borders and shadows, blue primary controls, restrained semantic colors,
coherent bracket logo and four-item PressBench navigation.

## Functional verification

- Flutter analyzer: passed.
- Unit, interaction and scaling tests: passed.
- All four bottom destinations: passed.
- 11 phone/tablet/orientation viewports: passed.
- 1.8× text scaling on phone and tablet: passed.
- Minimum 44 px interaction targets: passed.
- Production iOS compilation: passed.

Final result: passed
