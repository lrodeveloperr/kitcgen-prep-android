# Kitchen Prep Board — Locked Product Workflow and Logic

Status: **LOCKED FOR IMPLEMENTATION**  
Version: **2.0.0**  
Locked: **2026-08-29**

## 1. Purpose and authority

This document is the single authoritative product-flow and interaction-logic checkpoint for the next implementation. It intentionally does **not** select a Flutter repository, visual skin, colour system, typography, illustration style, or component library.

When an older HTML prototype, Android screen, UI note, or sample flow conflicts with this document, this workflow wins. Existing backend safety rules remain binding unless this document explicitly simplifies only their user-facing presentation.

The implementation sequence is:

1. Preserve and repair the domain logic.
2. Implement this locked workflow.
3. Run adversarial logic and common-denominator tests.
4. Select one commercially licensed Flutter template that supports phone and tablet layouts.
5. Bind the verified logic to the selected presentation.
6. Test iOS and Android phones and tablets before store deployment.

## 2. Product promise

Kitchen Prep Board helps a person see:

- what needs attention now;
- what is waiting;
- what comes next;
- what is complete; and
- what quantities still need preparation.

It is a local-first organizational aid. It does not prove food safety, doneness, allergen control, storage safety, safe temperature, or freedom from cross-contamination.

## 3. Non-negotiable interaction rules

1. Open directly to a truthful Home screen. There is no onboarding tour or language-selection screen.
2. Show one dominant action on each screen.
3. Minimize taps, typing, repeated confirmation, and explanatory text.
4. Autosave every meaningful change.
5. Preserve work through Back, app backgrounding, process death, rotation, restart, and device reboot where technically possible.
6. Use immediate Undo for ordinary reversible mistakes.
7. Ask for confirmation only when an action is destructive, affects dependent work, hides an active board, cancels timers, or is difficult to reverse.
8. Hide advanced controls until requested.
9. Never use fake first-run boards, progress, timers, recent history, or sample user data.
10. Now, Waiting, Next, and Done summaries are informational only. They are not buttons, links, swipe targets, or deep links.
11. Task actions live in a separate focused action area.
12. User-authored text is never silently translated, rewritten, or replaced.
13. No visual implementation may introduce a control without a defined action, state, error result, and recovery path.
14. The application remains usable offline. Billing, advertising, or consent failures cannot block the core workflow.
15. Mobile presentation is light mode and icons only. No runtime food photography or decorative food illustration is required by this contract.

## 4. Navigation

### Phone

Persistent bottom navigation contains exactly:

1. Home
2. Boards
3. New
4. Settings

### Tablet

The same four destinations appear in a left navigation rail. Navigation meaning and order do not change between phone and tablet.

There is no duplicate top-right Settings control.

### Navigation protection

- Leaving a screen never loses autosaved work.
- Attempting to create a replacement while a board is active or paused must not hide that board.
- If navigation would cancel timers or archive work, explain the exact consequence before committing.
- Returning to the application restores the most useful recoverable state and states when it was last saved.

## 5. Canonical end-to-end flow

### 5.1 Launch and recovery

1. Detect the supported device/app language and region.
2. Load local state.
3. Reconcile all active timers against persisted deadlines.
4. If an active or paused board exists, show Home with one dominant **Continue** action.
5. If a recoverable draft exists, show **Continue draft**.
6. Otherwise show a truthful empty Home with **Start board**.
7. If recovery found expired timers, show one concise attention summary.
8. If a prior operation was interrupted, resume it idempotently or return to the last safe editable step with a plain Retry action. Never restore a permanent spinner.

### 5.2 Home

Home contains, in priority order:

1. active or paused board, when present;
2. one dominant Start/Continue action;
3. informational Now/Waiting/Next/Done counts for the active board;
4. recent or frequently reused boards/templates;
5. secondary creation methods under a concise **More** section.

When there is no real data, Home states **No board yet**. It does not display demonstration content as if it belongs to the user.

### 5.3 Start board

The shortest default path is:

1. Tap **Start board**.
2. Use the last appropriate mode and recent defaults.
3. Open grocery/task selection immediately.

Optional creation sources remain available without competing with the primary path:

- start fresh;
- reuse a named recent board;
- use a named template;
- paste task text;
- accept shared text;
- store a reference URL.

The user must see the exact board/template name, date, and task count before reuse. “Latest” alone is not sufficient identification.

A localized editable board title is generated automatically. The user is never forced to type a title.

### 5.4 Active-board protection

If shared text or another creation request arrives while a board is active or paused, show:

- **Add to current**
- **Save for later**
- **Cancel**

Never create a newer draft that hides an active board while its timers continue.

A shared payload is consumed once. Rotation, recreation, or process restart must not create a duplicate board from the same share event.

### 5.5 Mode

The two domain modes remain:

- Home
- Station

The interface defaults to the last-used appropriate mode. The distinction is expressed in one short question:

**Track Have, Par and Need?**

- No = Home
- Yes = Station

There is no redundant mode-confirmation screen.

### 5.6 Grocery and ingredient selection

This is a primary commercial workflow and a release-critical feature.

#### Screen structure

1. Search field at the top.
2. Recent and frequently used items.
3. Clear grocery categories.
4. Filtered grocery list.
5. Persistent selected count.
6. One dominant **Add selected (N)** action.

#### Category model

Initial neutral categories are:

- Produce
- Meat & Poultry
- Seafood
- Dairy & Eggs
- Bakery & Grains
- Pantry
- Frozen
- Beverages
- Herbs & Spices
- Other

Category selection helps browsing but is never mandatory. With no category selected, search covers the complete catalogue.

#### Search behavior

Filtering begins immediately as the user types. Search must account for:

- regional names;
- translated names;
- synonyms;
- singular and plural forms;
- accents and diacritics;
- common punctuation differences;
- common misspellings;
- alternate scripts or transliterations where quality can be verified.

If a selected category produces no match, offer **Search all**. If no catalogue item matches, offer **Add custom item** using the typed text.

#### Selection behavior

- One tap selects or deselects an item.
- Selecting an item does not open a quantity form.
- The user may select multiple items before adding.
- Back, interruption, or rotation preserves selection.
- A clear selected-items view allows removal without restarting.
- Recent and frequently used items reorder locally based on the user’s own activity.
- No account, network request, or analytics is required.

#### Catalogue rules

The bundled catalogue contains copyright-safe generic groceries, ingredients, units, categories, and verified regional aliases. It excludes branded catalogues and proprietary product descriptions.

Each item has one stable canonical ID. Localized and regional display names map to that ID. User-created custom items remain distinct and preserve exactly what the user entered.

### 5.7 Station quantities

Station mode uses the culturally simple terms:

- **Have**
- **Par**
- **Need**

Logic:

`Need = max(Par - Have, 0)`

Rules:

1. Have defaults to zero when appropriate and a saved zero remains visibly zero.
2. Par is prefilled from the selected template, recent verified history, or a safe empty state.
3. Need calculates immediately and is not typed by the user.
4. If Have exceeds Par, show the surplus plainly.
5. Units come from localized, searchable choices; custom units remain available.
6. Users can apply a unit to multiple selected items.
7. Values autosave. There are no per-row Save buttons.
8. Changing Have or its unit resets the verified state.
9. Values must be finite and non-negative.
10. Decimal entry follows the selected locale.
11. Missing values are summarized before continuing.
12. The user may explicitly continue without quantities.
13. Par may persist in a reusable template; Have and verification reset for a new board/shift.
14. Have/Par/Need is not an inventory ledger.

### 5.8 Task creation and review

Selected groceries may populate the prep list without forcing immediate details. Pasted/shared text is split into non-empty editable draft tasks while preserving the original source exactly.

The review screen supports simple inline changes:

- task name;
- optional duration or no timer;
- task type;
- add;
- delete;
- duplicate;
- reorder.

Advanced options sit under **More**:

- dependency (“After…”);
- resource requirement;
- priority.

Heuristic durations and classifications are labelled **Suggested** and remain editable. The application never presents a guessed cooking time as measured fact.

Common bullets and numbering may be recognized for display, but the source text remains recoverable. Exact duplicates, meaningless lines, very large pastes, or unusually long entries receive concise review warnings.

### 5.9 Timing

The common interface exposes:

- **Start now**
- **Ready at**

Ready at uses a full localized date-and-time selection. A past clock time is never silently moved to tomorrow; the complete interpreted date is shown before commitment.

The underlying engine may retain COOK_NOW, READY_BY, and SERVE_AT states. Serve At is shown only when it produces a genuinely distinct schedule or service workflow; otherwise it must not create a redundant user choice.

Rules:

1. Display the board target timezone.
2. Detect impossible targets.
3. Show the earliest achievable finish and lateness before starting.
4. Never describe a target as guaranteed.
5. Automatic suggestions cannot exceed resource capacity.
6. Missing/unavailable resources produce an editable correction screen, not an uncaught error.
7. Dependency cycles produce a named correction path.
8. Process death during construction reruns safely or returns to Timing with Retry.

### 5.10 Ready review

Ready shows only decision-relevant information:

- recommended first task;
- suggested start and finish;
- expected board finish;
- late/conflict warnings;
- number of tasks and active timers;
- concise Edit routes.

The dominant action is **Start board**.

Starting a board does not silently start every timer. The user starts the focused task explicitly.

### 5.11 Live board

The top summary displays informational counts:

- Now
- Waiting
- Next
- Done

These summaries are never interactive.

A separate focused task area displays:

- task name;
- quantity when relevant;
- remaining or overdue time;
- dependency/resource warning when relevant;
- one dominant action;
- secondary actions under More.

Common actions:

- Start
- Complete
- Check
- Add time
- Move to top
- Skip
- Undo

Rules:

1. Timer display derives continuously from the persisted deadline.
2. Expiry means **Attention required**, never Done or food-safe.
3. Complete and Skip produce immediate Undo.
4. Skipping a task that unlocks dependents or cancels an active timer requires explicit consequence text.
5. Undo clears/rebuilds timing history correctly and explains effects on already-started dependents.
6. Adding time is labelled with units, such as **+1 min**.
7. Timer controls are hidden when no timer exists.
8. Done is collapsed by default when long.
9. When Now is empty, show the recommended next start outside the informational summary.
10. All interactive targets meet platform accessibility sizing.

### 5.12 Pause and resume

The user-facing action is **Pause new tasks**, not an ambiguous global Pause.

Existing timer deadlines continue. This consequence appears beside the control and is confirmed the first time.

While paused, the user may still check, complete, skip, or extend already-running work. Starting new work is disabled until Resume.

Resume recomputes suggestions from current reality without rewriting user-authored task text.

### 5.13 Out, waste, and handoff

At completion, optional concise fields may capture:

- Made
- Out/Used
- Waste

These fields are skippable and remain separate from whether a task is Done.

For unfinished work, **Hand off** creates a local summary and optional note. It does not require an account or named recipient. The user explicitly chooses whether active timers continue or stop.

### 5.14 Finish

If every task is terminal, show one dominant **Close completed board** action.

If work remains, show:

- **Continue**
- **Hand off**
- **Close with N unfinished**

Closing incomplete work does not mark remaining tasks Done.

After closure, state the exact result:

- Completed and saved on this device; or
- Closed with N unfinished tasks.

Provide a short Undo window where safe.

### 5.15 Boards and templates

Boards contains:

- Active
- Drafts
- Completed
- Closed incomplete
- Templates

The user can open a named record, duplicate it, archive/delete it, or save it as a template where allowed.

Duplication preserves:

- task names and order;
- suggested/accepted durations;
- dependencies;
- resource requirements;
- Par targets;
- mode.

Duplication resets:

- task statuses;
- active/expired timers;
- actual timestamps;
- Have values;
- verification;
- Out/Used/Waste;
- live handoff state.

Template creation is idempotent or clearly names duplicates. Templates support open, rename, duplicate, and delete.

### 5.16 Settings

Settings is prioritized by commercial value and immediate utility:

1. Remove ads / subscription status
2. Timer alerts
3. Keep screen awake
4. Language — System default
5. Region — Automatic
6. Units and temperature
7. Data and privacy
8. Help and About
9. Delete local data

Unavailable settings are hidden, not shown as developer-facing disabled placeholders.

Billing displays the store-provided localized price and state. Purchase success, pending, cancellation, unavailability, offline state, and retry are visible. Core use remains available regardless.

Delete actions name the exact data removed and what remains. A full wipe includes boards, tasks, dependencies, resources, shifts, timers, templates, observations, preferences, and applicable local catalogue history while treating store subscriptions separately.

## 6. Localization

### Launch languages

The interface supports these ten commercially useful languages:

1. English
2. Spanish
3. Portuguese
4. French
5. German
6. Italian
7. Arabic
8. Japanese
9. Korean
10. Chinese

Chinese includes verified Simplified and Traditional script packs. Material regional overrides may be supplied for Spanish, Portuguese, French, and other languages without duplicating the entire interface unnecessarily.

### Resolution

1. Follow the system/app preferred language when supported.
2. Follow the device region for regional names, units, dates, numbers, and catalogue ranking.
3. Fall back to English when no supported language matches.
4. Settings allows independent language and region override.
5. Manual choices persist and apply immediately.
6. No language-selection onboarding is shown.
7. User-authored grocery, task, and note text is never translated automatically.

### Language quality

- Interface wording is neutral and broadly understood across each language.
- Grocery/catalogue terminology includes verified regional aliases.
- No release may contain stray English outside intentionally user-authored or source text.
- Timers, notifications, errors, billing, privacy, accessibility labels, plurals, dates, quantities, and units are all localized.
- Arabic is fully RTL.
- Layout testing includes German expansion, Arabic RTL, Chinese scripts, locale decimals, and maximum text size.
- Cultural culinary QA is required; literal machine translation alone is insufficient.

## 7. Text and tap budgets

### Text

- Screen heading: normally no more than four words.
- Primary button: normally one to three words.
- Supporting explanation: at most one short sentence when needed.
- Do not repeat an explanation already conveyed by the control or state.
- Place safety, error, and consequence text contextually rather than in an onboarding tour.
- Use labelled icons; do not rely on unfamiliar symbol-only controls.

### Taps

Target common-path budgets:

- Continue active board: one tap.
- Select a recent/frequent grocery: one tap after opening the picker.
- Select by category: category, then item.
- Add multiple selections: one final batch action.
- Complete a focused task: one tap, followed by optional Undo.
- Extend a timer by a preset: one tap.
- Close a fully completed board: one tap.
- Change language: Settings, Language, choice.

Routine common actions should normally remain within three interactions. Extra confirmation is reserved for consequential actions.

## 8. Persistence and recovery

Autosave applies to:

- board title and mode;
- grocery selections;
- typed search/custom items where committed;
- raw task input;
- task edits and order;
- Have/Par/unit/verification;
- timing selection;
- notes and handoff;
- task and timer transitions;
- language, region, and utility preferences.

Recovery rules:

1. Deadline timestamps are authoritative across process death and reboot.
2. Foreground entry reconciles timers, not only billing.
3. Notification denial never prevents local expiry state.
4. Exact-alarm denial falls back safely and explains possible delay.
5. Reboot/clock/timezone changes reconcile deadlines and surface missed attention.
6. Relative timers and absolute ready/service times are not conflated.
7. Interrupted schedule construction is idempotent.
8. Only one visible active/paused board may own active timers.
9. New/replacement operations cannot silently orphan open work.
10. User messages are typed, one-shot events with correct success/warning/error tone.

## 9. Error and empty states

Every action has an explicit success, empty, error, or recovery result.

Required cases include:

- no board;
- no recent/template;
- empty task input;
- no grocery match;
- invalid custom quantity/unit;
- duplicate or unusually large paste;
- dependency cycle;
- unavailable/insufficient resource;
- impossible target;
- notification denied;
- exact alarm unavailable;
- timer expired while away;
- offline billing;
- product unavailable;
- purchase pending/cancelled/failed;
- interrupted build;
- active-board share conflict;
- delete confirmation;
- import/export unavailable, if those features remain excluded.

Errors appear on the destination where the user can correct them. They are never rendered as success messages or silently discarded.

## 10. Responsive and accessibility rules

1. One state contract drives phone and tablet.
2. Compact, medium, and expanded layouts change arrangement, not meaning.
3. Forms do not stretch into unreadably wide tablet fields.
4. Large text causes stacking/reflow rather than clipping.
5. Controls do not depend on colour alone.
6. Icon-only controls have accessible names and state descriptions.
7. Switches expose labels and checked state.
8. Countdown and attention changes are announced appropriately without excessive repetition.
9. Touch targets meet iOS and Android platform guidance.
10. The primary action remains reachable without scrolling through an unbounded Done list.

## 11. Acceptance gates before template selection

The workflow is not ready for a Flutter template until all are true:

- every normal, alternate, empty, error, interruption, undo, duplicate, archive, delete, timer, billing, locale, and recovery path is mapped;
- the impatient-user test passes;
- the older first-time-user test passes;
- no action is inert;
- no active board can be hidden with running timers;
- typed work survives interruption;
- foreground countdowns update continuously;
- notification denial has a clear recovery experience;
- Have/Par/Need autosaves and restores zero correctly;
- grocery selection meets the tap budget;
- all ten languages pass completeness and overflow checks;
- Arabic RTL and tablet layouts pass;
- the current Android logic has executable regression coverage for critical transitions;
- no unverified visual or runtime claim is labelled as passed.

## 12. Explicitly deferred

This checkpoint does not choose or implement:

- a Flutter repository;
- a UI skin;
- fonts, colours, shadows, radii, or illustration;
- iOS-specific billing or notification adapters;
- store screenshots or listings;
- production ad identifiers;
- final legal/support URLs.

Those decisions follow only after this workflow and its logic pass the acceptance gates.
