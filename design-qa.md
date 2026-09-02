# Command Rail design QA

Reference: selected Command Rail concept (430 × 932 comparison viewport)

Implementation capture: `Command-Rail-Visual-QA/command_rail_phone.png` from the release workflow

## Visible comparison

- P0: none
- P1: none
- P2: none
- P3: the test renderer substitutes its deterministic Ahem glyphs for production text, but the production iOS compile uses the platform font stack. Component bounds, hierarchy, spacing, color roles, icon placement, cards, task lanes, timer controls, and safe-area behavior match the selected direction.

## Functional verification

- Primary task action, pause/resume, adjust-time sheet, reorder/skip controls, board controls, and navigation callbacks are exercised by the widget suite.
- Layout contract passes at 320×568, 360×640, 375×667, 390×844, 430×932, 600×960, 768×1024, 834×1194, 1024×1366, 1280×800, and 844×390.
- Large-text checks pass at 1.8× on narrow phone, modern phone, and tablet widths.
- Minimum interactive targets are 44 logical pixels.

Final result: passed
