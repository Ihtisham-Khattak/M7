# DEVELOPMENT_GUIDELINES.md — GymMane

The development contract for humans and AI coding agents. Rules are derived from what the codebase
actually does (commit `9af217e`) plus the maintainers' stated rules in `CONTRIBUTING.md`. Where a rule is a
maintainer statement rather than something enforced by code/tests, it says so. Read first:
[PROJECT_CONTEXT.md](PROJECT_CONTEXT.md) → [ARCHITECTURE.md](ARCHITECTURE.md) → the relevant part of
[FEATURES.md](FEATURES.md) and [DATA_MODEL.md](DATA_MODEL.md).

---

## 1. General Development Principles

1. **Two non-negotiables** (`CONTRIBUTING.md`): no accounts / remote user data; no network (no `INTERNET` permission, no analytics). Features that need a server do not belong here.
2. **Offline behaviour must keep working** in airplane mode, including notifications, widgets and import/export.
3. **Statistics come from real logged sets** — never estimated placeholders. Warm-up sets must not affect volume, PRs, muscle sets, or awards.
4. **Reuse before you build**: there is a UI kit (`lib/widgets/ui_kit.dart`, `glass.dart`, `dialogs.dart`, `charts.dart`), a state layer, and helpers for units, dates, matching. Search first.
5. **Small, focused changes**; one topic per PR (maintainer rule). Do not reformat or "clean up" unrelated files — large data files (`exercise_catalog.dart`, `body_svg.dart`, `catalog_*.dart`) are especially conflict-prone.
6. **Source is the truth.** If a doc (including these five files) disagrees with code, fix the doc in the same change.
7. **Backward compatibility of stored data is a hard requirement** — users have years of history in a single JSON blob with no version field ([DATA_MODEL.md](DATA_MODEL.md) §9, §12).

## 2. Code Organization Rules

| Put this… | …here |
|---|---|
| State, business rules, derived statistics | a mixin in `lib/state/` (or a pure function in `lib/services/` if it does not need `fit`) |
| Plain data classes with JSON | `lib/models/` |
| Static data (exercises, templates, SVG paths, id maps) | `lib/catalog/` |
| Platform/IO/notification/import code | `lib/services/` |
| A screen or bottom-sheet flow | `lib/screens/<name>_screen.dart` (one file per screen; private helpers stay in that file) |
| Reusable UI | `lib/widgets/` |
| Colours / text styles | `lib/theme/` |
| Strings | `lib/l10n/*.arb` |
| Native Android | `android/app/src/main/kotlin/com/gymmane/app/` |

- New state goes into the mixin that owns the feature. A new mixin must be added to `FitState`'s `with` list, declared `part of 'fit_state.dart'`, listed as `part` in `fit_state.dart`, and constrained with `on` only to what it needs (see the mixin graph in ARCHITECTURE §5). If you need a hook that a later mixin implements, add a stub to `FitCore` and `@override` it (existing pattern: `refreshAwards`, `syncTrainReminder`, `plateStockKg`, `fitsHere`).
- Do not create a second global state object, a repository layer, or an alternative state library. If a real need arises, discuss in an issue first (maintainer rule for anything big).
- New screens: add the route string handling in `AppShell._screen()`, back behaviour in `FitState.handleBack()`, entry/exit methods in the owning mixin (`goX()` = `pushRoute('x')`, `backFromX()` = `popRoute(fallback: …)`), and `_blurTop`/nav-bar lists in `AppShell` if relevant. Keep `_NavBarState._routes` and `FitCore.showNav` consistent.
- Do not add documentation files. The five root docs are the only technical docs; `README*.md`, `CONTRIBUTING.md`, `TRANSLATING.md`, `CREDITS.md` are existing user/contributor docs.

## 3. Dart / Flutter Conventions

- SDK: Dart `^3.11.5`; Flutter 3.41.x. Use Dart 3 features already in the code (records, `switch` expressions, `if (x case final y?)` patterns, null-aware collection elements `?expr`).
- Lints: `package:flutter_lints` + `prefer_single_quotes`; `require_trailing_commas` is **off**. Formatter `page_width: 110` — run `dart format` (the repo is not wrapped at 80).
- **No comments** in source is the maintainers' house style ("names and structure carry the meaning; the reason for a change goes in the commit message"). Follow it. (Exceptions: none observed in `lib/`.)
- Analysis excludes `lib/l10n/app_localizations*.dart`, `build/**`, `android/**`. Keep `flutter analyze --no-fatal-infos` free of warnings/errors; today only 2 known deprecation infos exist (`onReorder`).
- Prefer `const` constructors and literals; prefer pure functions and small widgets (maintainer rule).
- Use `try { … } catch (_) {}` **only** at boundaries with the OS/plugins/files where failure must not crash the UI (existing pattern). Never swallow errors in pure logic.
- Async in state: fire-and-forget persistence is the norm (`Store.save` is not awaited); do not add awaits inside `notifyListeners` paths.
- Time: use `DateTime.now()` directly (there is no clock abstraction; tests manipulate data instead). For day arithmetic always use `_dayKey`, `shiftDays`, `daysBetween` from `fit_core.dart` (DST-safe) — never `Duration(days:)` on local dates for calendar math.

## 4. Naming Conventions

| Thing | Convention (observed) |
|---|---|
| Files | `snake_case.dart`; screens end in `_screen.dart` (sheet-only files `_sheet.dart`); state mixins `*_state.dart`; services named by role |
| Classes | `UpperCamelCase`; private helpers `_Name` in the same file; mixins `XState` |
| Constants | top-level `kName` (`kExercises`, `kMuscles`, `kPoses`, `kMeasureKeys`) |
| State API verbs | `toggleX`, `setX`, `bumpX(delta)` (stepper change), `addX`, `deleteX`, `openX`/`closeX`, `goX()`/`backFromX()`, `startX`, `syncX`, `refreshX` |
| Formatting helpers | `fooLabel(x)` (with unit text), `fooValue(x)` (number only), `fooShown` (display units) |
| Route ids | lower-kebab strings (`'exercise-detail'`, `'routine-edit'`) |
| JSON keys | very short (`r`,`w`,`d`,`k`,`n`…); document any new key in DATA_MODEL |
| Ids | prefixed + microsecond timestamp + sequence: `c…` custom exercise, `r…` routine, `n…` note, `p…` place, `s…` shot; imported unknown exercise `imp:<slug>` |
| Tests | descriptive English sentences (`test('a heavy warm-up does not become a record', …)`); a few older ones use Spanish descriptions/reasons |
| Weight variables | `…Kg` when canonical kg; `…Shown`/`…Display` when in user units |

## 5. Widget Rules

- Access theme via `final gc = context.gc;`. Use the scales in `lib/theme/tokens.dart` — `GymSpace` (4/8/12/16/20/24/32, `minTarget` 48), `GymRadius` (6/10/12/16/20/24, pill, hair 2), `GymBorder` (1 / 1.6), `GymElevation` (theme-aware `raised`/`overlay`) and `GymText` roles (caption 12, label 13, body 14, bodyLarge 15, title 17, headline 20, display 34) — instead of new literals; `ui_kit.dart`, `dialogs.dart` and `choice.dart` already do (screens are being migrated). Text colors must keep ≥4.5:1 on `bg/bgRaised/bgRaised2` (`test/contrast_test.dart`). Selectable options use `ChoiceCard` / `SelectChip` (`lib/widgets/choice.dart`: 48dp targets, `Semantics(selected)`) and `StepProgress`. Also `AppTheme.f/s/d(...)` remain available. **Do not hard-code colours** except in painters/share cards where the design uses fixed palettes already; do not introduce new fonts.
- Prefer existing components: `SoftCard`, `Pressable`, `PrimaryButton`, `GhostButton`, `RoundBtn`, `SegToggle`, `StepperControl`, `OptionGroup`, `ScreenHeader/ScreenTitle`, `SheetHandle/SheetTitle`, `showAppSheet`, `showAppDialog`, `askConfirm/askText/askNumber`, `showNotchToast`, `GlassSurface`, `Rise/RiseScope` for entrance animation.
- Screens read `fit.*` directly and are rebuilt through `AnimatedBuilder(animation: fit)` at the shell; nested `ListenableBuilder` is used for local rebuilds. Do not cache `fit` values in widget state unless they are edit drafts.
- Business logic does **not** belong in widgets: put calculations in `lib/state` (or `lib/services`) and call them. Widget-level code may do layout, formatting via `fit` helpers, animation and gesture handling.
- Where feasible wrap custom tappable widgets in `Semantics(button: true, label: …)` (pattern used ~85 times); labels come from `t`.
- Layout must survive text scale up to `1.15` (`GymManeApp.maxTextScale`), narrow phones, dark **and** light, RTL (Arabic), and the 3-button vs gesture navigation insets (`_ButtonNavScrim`, bottom padding via `MediaQuery.viewPaddingOf`). The bottom nav bar and parked-session pill occupy space on tab routes (`showNav`).
- Dispose controllers/timers/listeners you create (see `AppShell` for the listener add/remove pattern).
- Wear widgets (`lib/wear/`) have their own components; shared logic must not depend on phone-only widgets.
- Do not use `Navigator.push` for app screens — screens are routes in `fit`. `Navigator` is for dialogs/sheets and `pop` inside them. The only pushed full-screen overlays are viewers/editors that are deliberately outside the route model: `showStickerEditor` (`sticker_screen.dart`), the snapshot viewer (`moments_screen.dart`) and the note-media viewer (`note_kit.dart`), all via `PageRouteBuilder`.

## 6. State Management Rules

- All mutations go through methods on `fit`. A mutator must: (1) change the collections/fields, (2) call `_persist()` (debounced) or `persistNow()` when the change is structural or destructive, (3) call `_refreshWidgets()` if any widget-visible datum changed (sessions, plan, theme, week start, language, check-ins), (4) call `syncTrainReminder()` if plan/reminder/session data affecting it changed, (5) call `refreshAwards()` if it can change an award input (sessions, routines, check-ins, onboarding), (6) end with `notifyListeners()`.
- Never call `_persist()` inside a `_loading` block expecting it to save — it is intentionally a no-op then. Any code that sets `_loading = true` must reset it (prefer `try/finally`; `applyBackup` currently does not — do not copy that).
- Keep transient UI state (filters, drafts, picks) in `fit` only when it must survive screen rebuilds; it is not persisted by design.
- Do not put `await` between state mutation and `notifyListeners()` in new code where avoidable; the session engine relies on synchronous consistency (timers read `session` fields).
- Timer discipline: every `Timer` created in a mixin must be cancelled in the finish/discard/pause/reset paths (`finishSession`, `saveAndExit`, `toggleSessionPause`, `resetAllData`, `dispose`). Follow those lists when adding one.
- Global `t` and `appLanguage` change only through `setAppLanguage`; do not cache `t` in long-lived objects that outlive a language change (notification text is built at schedule time).
- Do not add Provider/Riverpod/BLoC/GetX.

## 7. Business Logic Rules

- Single implementation per rule. Before writing math, look in `stats_state.dart`, `workout_state.dart`, `tools_state.dart`, `models/workout.dart`. Examples: e1RM = `LoggedSet.oneRm` (Epley / RPE table); working sets = `counts`/`workingSets`; streak = `currentStreak`; unit conversion = `FitCore.toDisplayWeight/fromDisplayWeight`.
- Invariants to preserve:
  - Warm-up sets (`SetKind.warmup`) never count toward volume, PRs, set totals, muscle sets or awards.
  - Stored weights are kg, distance km, lengths cm.
  - A session is logged only from **done** sets.
  - Only one live session exists; manual sessions never start rest timers or the live notification.
  - Weekly plan keys are `DateTime.weekday` (1–7), independent of `weekStartDay`.
  - Records for `weight` kind are ranked by e1RM; other kinds by best value.
  - `LoggedSession`s are kept sorted ascending by date after any insert.
- Don't duplicate clamps/limits; reuse existing ones (see DATA_MODEL §10) and put new ones where the mutator is.
- Muscle logic touching secondary muscles must read from `exerciseById(id)?.secondary` (custom exercises have none).
- Exercise matching for anything user-typed or imported must go through `matchExercise`/`exerciseSearch` (aliases + normalisation); do not reimplement string matching.
- If you change a formula that affects historical numbers (PRs, volume, recovery, streak), state it in the PR and add regression tests using fixed data.

## 8. Data / Model Rules

Full detail: [DATA_MODEL.md](DATA_MODEL.md) §9–§12. Checklist when touching persisted data:

1. Add the field to the model with a safe default in `fromJson` and omit-when-default in `toJson`.
2. Wire it in `FitState.toJson`, `loadFromStore`, **and** `applyBackup` (and `resetAllData` if user data). If it references files, also `backup_zip.dart` (build + restore remap) and delete-on-owner-delete logic.
3. Never renumber/reorder enums that are persisted by index (`SetKind`, `NoteKind`); append only. Never rename persisted string ids (`AwardId`, mode ids, pose ids, measure keys).
4. Never delete or change the `id` of a built-in exercise; changing an exercise `name` can break alias/template/import matching (`kExerciseAliases`, `program_templates.dart` match by name).
5. Keep denormalised snapshots (`name`, `primary`) on history records.
6. Keep readers lenient: don't turn optional fields into required casts. If you must migrate, add an explicit shim beside the existing ones and a test.
7. Deleting an entity must also delete its owned media files and think through soft references (routines, plan, notes, per-exercise maps). Prefer extending the existing delete method over a parallel one.
8. New user media: store the basename via `MediaStore`; never store absolute paths; include it in ZIP backup/restore and reset.
9. Everything you add to storage counts against a single SharedPreferences string: don't store binaries in JSON (profile photo/banner already do — do not follow that precedent).

## 9. UI / UX Rules

- Visual language (Kaizan palette, GM-91): sumi ink + warm paper neutrals, **vermilion** as the single brand accent (`ember`: dark `#E8553D` with ink text, light `#B3361F` with white text; also `progress`), kinu/stone neutrals for `accent`/`brass`, muted matcha (`sage`/`success`), indigo (`info`), ochre (`warn`/`streak`), rose-crimson `danger` (kept distinct from vermilion). Use vermilion only for the primary action, selected/active states, key progress and the nav ▶; everything else stays neutral. Heat-map ramps (`ember|green|blue|mono`) were re-derived from the same hues. Dark-first, glass surfaces, Manrope (bundled, OFL; static weights 400-800), Phosphor icons (`PhosphorIconsRegular/Fill/Bold`). Light theme must be legible (`test/polish_test.dart` asserts text-colour readability).
- Typography (GM-92): one family, Manrope, via `AppTheme.f/s/d` or the `GymText` roles (caption, label, body, bodyLarge, button, title, headline, display, **numeric**). Every style enables tabular figures so weights, reps, sets and times line up in columns; use `GymText.numeric(size)` for metrics. Heaviest weight is 800 (900 requests resolve to 800). Manrope covers Latin, Cyrillic, Greek and Vietnamese; Arabic/Persian/CJK/Hangul use the system fallback (as before). Fonts must stay bundled (offline); record any new typeface in CREDITS.md. `test/typography_test.dart` guards the family, licence, digit alignment and real weights.
- Empty, loading and error states exist on data-driven screens (skeleton `shimmer.dart`, empty texts via ARB keys); provide them for new screens. Failures surface as short toasts/snackbars (`showNotchToast`, `_snack`) with a localised message — never raw exceptions.
- Destructive actions require `askConfirm` with localised copy (discard session, reset, restore/import backup, delete).
- Shape language (GM-93): small-to-medium radii. Controls (buttons, search, inputs) `md` 12; cards and list groups `lg` 16; sheets/dialogs/nav `xl` 20; nothing above 24. **Pills (`GymRadius.pill`) are reserved for tags/status chips, switches, progress bars and avatars** — never for buttons. One hairline border (`GymBorder.hairline`) and two shadow levels from `GymElevation` (always theme-derived: lighter in the light theme, never pure black). `test/shape_language_test.dart` fails on any literal radius above 12 other than the pill.
- Blur / glass (GM-93 audit, kept only where it protects legibility; `shape_language_test` allowlists the files): bottom `EdgeBlur` under the nav bar and the top fade when scrolled (`app_shell.dart`, `train_screen`, `routine_edit_screen`); `GlassSurface` for the nav bar and the parked-session pill (they float over scrolling content); the modal barrier blur behind sheets/dialogs (`glass.dart`); the optional, user-chosen blur of a custom background picture (`app_background.dart`, off by default, sigma 0–12); transient overlays — start countdown, snapshot viewer, toast (`start_countdown.dart`, `moments_screen.dart`, `liquid_notch.dart`). The route-transition blur in `app_shell.dart` is decoration and is removed by GM-19. Do not add new blur without extending this list and the test.
- Backgrounds (GM-94): one widget, `AppBackground` (`lib/widgets/app_background.dart`), used by the app shell and onboarding, driven by `fit.bgPattern/bgPhotoPath/bgDim`. Custom photos go through a **readability guard** (`lib/services/background_guard.dart`): the picture is decoded at 48 px, its darkest/brightest 5% luminance is measured, and the scrim is raised above the user's dim level until text, secondary and tertiary text reach 4.5:1 (cap 0.92). Never draw an image behind content without it. The `ancient` mode (GM-95) is a generated washi-paper texture (`lib/widgets/washi_texture.dart`: seeded fibres, flecks and soft mottling, every mark <= 7% alpha, no image assets, no motifs), covered by `test/washi_test.dart` (faint, sparse, deterministic, text keeps 4.5:1 on its extremes). Custom pictures (GM-96) can be zoomed (1–3×), panned (drag in the live `BackgroundPreview`), faded (opacity 0.35–1) and blurred (0–12); the guard measures the picture *as shown* (`blendTones` mixes it toward the page colour by the chosen opacity), so no combination of sliders can push text below 4.5:1 — the overlay rises on its own and the sheet says so. Framing keys reset whenever the picture changes. New modes must keep the persisted `bg` values backward-compatible and be added to `SettingsState.bgPatterns`.
- Motion (GM-19, `lib/theme/motion.dart`): the more often an action happens, the less it moves. Tab ↔ tab = plain crossfade 160 ms (never > 200); push/pop = fade + 14 px shift 240 ms (never > 300); press/toggle feedback 120 ms; always ease-out, nothing bounces, no blur or scale in route transitions. The shell uses `ScreenSwitcher` (reads the duration when each transition starts, so a screen opened by a push still leaves at tab speed) instead of `AnimatedSwitcher`. **Reduced motion** (`MediaQuery.disableAnimations` / `GymMotion.reduced(context)`; `GymMotion.platformReduced` before a context exists): no slide, scale, blur, spin or falling particles anywhere — screens swap with a 100 ms fade, `Pressable` and list rows skip their animation, the nav pill jumps, the award screen shows the medal still, the start countdown has no veil/beat animation, `Rise` entrances are skipped. Use `GymMotion.of(context, duration)` for new implicit animations; `shell_transition_test` enforces the budget and the reduced-motion behaviour.
- Component catalogue (GM-12) — compose these (`lib/widgets/components.dart`, `choice.dart`, `ui_kit.dart`) instead of building containers; `test/components_test.dart` renders every variant in both themes at 1.0× and 1.6× text and checks the 48dp target, button semantics and disabled/loading behaviour. All sizes/radii come from `tokens.dart`.
  | Component | Variants / API | Notes |
  |---|---|---|
  | `GymButton` | `kind`: primary · secondary · text · destructive; `size`: regular 56 · compact 48; `onTap: null` = disabled (40% opacity, announced disabled); `loading` (spinner, ignores taps); `leading`; `expand` | `PrimaryButton` (explicit `height`, SVG icon) and `GhostButton` (secondary, compact) are thin wrappers kept for existing call sites |
  | `GymCard` | `kind`: flat (border) · raised (soft shadow) · glass (`GlassSurface`); `onTap` (button semantics + press), `semanticLabel`, `borderless`, `clip`, `color/borderColor` | `SoftCard` is the flat base; prefer `GymCard` in screens |
  | Chip | `SelectChip` (selectable, 48dp, `selected` semantics) in `choice.dart`; `Pill` for small tags/actions | no new pill-shaped chips (GM-93) |
  | `SectionHeader` | title (+ `onMore` chevron, `trailing`) · `.label` (small uppercase group label) | announced as a header |
  | `ListRow` | `icon` or `leading`, `title`, `subtitle`, `trailing`, `chevron`, `destructive`, `divider(+inset)`, `minHeight` ≥ 48 | tap = soft highlight, button semantics; use inside a `GymCard(padding: zero, clip: true)` for grouped lists |
  | `Pressable` | scale 0.97, 100 ms in / 160 ms out, ease-out; no motion with the system "reduce motion" setting | used by every tappable primitive |
- Gesture safety: long sessions are lock-able; do not add controls that can end/discard a session with a single accidental tap.
- Animations: staggered `Rise` entrances gated to once per day per screen; keep durations in the existing 220–460 ms range; respect `RiseScope.animates`.
- Steppers and rulers are the input idiom for numbers (reps/weight/measures); free keyboard entry uses `askNumber/askText`.
- Numbers shown to the user go through `fit.weightLabel/weightValue/distanceLabel/heightLabel/measureLabel` so kg/lb/mi/in switching works.
- Do not introduce responsive breakpoints or tablet layouts casually — none exist; the app is phone-portrait with a separate Wear UI.

## 10. Localization Rules

- **Every user-visible string goes through `t.<key>`** with an entry in `lib/l10n/app_en.arb` (template) and in **every** other `app_*.arb`. `test/i18n_test.dart` enforces: every ARB file is a registered language; no missing/extra keys in any shipped language; no hard-coded English literals in `Text('…')`, `label:`, `hintText:`, `ScreenTitle('…')`, `title:` under `lib/screens`, `lib/widgets`, `lib/app`; no English weekday/month literals (use `t.weekday`, `t.longDate`, `t.shortDate`, `t.monthName`…). (`lib/wear/` is not scanned by that test but must follow the same rule.)
- After editing any ARB, run `flutter gen-l10n` and **commit the regenerated `lib/l10n/app_localizations*.dart`**. Adding a new language = new `app_<code>.arb` **plus regeneration** (the Persian PR skipped this, leaving `fa` unregistered and one test failing).
- Plurals/ICU in ARB; placeholders keep names; the app name is never translated; "CAPS" strings are UI headers. `@@locale` and `languageName` must be set. Translations are informal-address (TRANSLATING.md).
- Exercise names/steps: display via `exerciseName(e)` / `exerciseSteps(e)` / `t.catalogName(id, fallback)`. Adding a catalogue language = new `lib/l10n/catalog_<code>.dart` maps + registration in `_catalogNames`/`_catalogSteps` in `l10n.dart`. The maps are keyed by exercise id and must not contain ids that don't exist; steps must line up 1:1 with English (`test/i18n_test.dart` for `es`).
- Identifier-like data (muscle ids, equipment ids, difficulty ids, tool ids, place presets, measure keys) are English keys mapped to strings by `GymL10n` (`t.muscle(id)`, `t.equipment(id)`…). Add a case there when adding an id.
- Locale-dependent formats (dates, weekday initials) come from `intl` through `GymL10n`; never format dates manually.
- `zh_Hant` currently gets English exercise names (exact-code lookup) — do not assume script fallback.

## 11. Error Handling

- Boundary code (files, plugins, channels, notifications, audio) catches and degrades: return `null`/`false`, log with `debugPrint`, keep the app usable. Copy that behaviour for new platform calls; guard Android-only calls with `Platform.isAndroid`/`kIsWeb`.
- Parsers for external input (CSV, JSON plans, SQLite, ZIP) must return "unreadable/empty" results instead of throwing, and the UI must show a localised message (`importUnknownFormat`, `importReadFailed`, `backupFailed`…).
- Don't let one bad record break loading: if you add fields to entities read with strict casts, either keep the cast safe or wrap per-item parsing (see ARCHITECTURE R1 — avoid making startup more fragile).
- Long operations that change state destructively (restore, reset, import) must be confirmed first and should be structured so a mid-way failure can't leave `_loading` stuck (use `try/finally`).
- `Store.save` failing is silent; if you add critical persistence, verify via `Store.load` in tests, not by runtime signal.

## 12. Performance Rules

- Statistics getters recompute from all sessions on every call and screens call several per build. Avoid calling O(N·sessions) getters inside per-item list builders; compute once per build or add a cache with clear invalidation. Do not add new heavy getters used on the session screen (rebuilt every second).
- The whole state is serialised on each `_persist()`: batch related mutations; use `_persist()` (debounced) not `persistNow()` inside loops.
- Large lists (`kExercises` 552) are filtered in memory each rebuild; `exercise_match.dart` caches search keys (`_keyCache`) — reuse it.
- Images/media: every `pickImage` call in the repo (7) passes `maxWidth/maxHeight/imageQuality`; keep doing so; profile photo/banner are stored in the JSON blob so keep them downscaled. Video is played from files with `video_player`; dispose controllers.
- Exercise art parsing is cached (32 entries); body-map paths are cached in `svgPath`.
- Home widgets: `HomeWidgetBridge.update()` renders ~9 images × 2 themes; call it through `_refreshWidgets()` only when relevant data changed.
- Keep `AnimatedBuilder(animation: fit)` scopes small in new screens with frequent updates.

## 13. Testing Expectations

### 13.1 Framework and conventions (observed)
- `flutter_test` only (unit + widget tests, no integration_test, no mock library). 55 files in `test/`; **544 tests** (541 pass, 3 skipped, 0 fail) — verified by running `flutter test` after GM-01…05 (+`test/data_safety_test.dart`).
- Tests drive the global singleton: `fit` state is reset by hand in `setUp` (`fit.saveAndExit(); fit.sessions.clear(); …; fit.setUnits('kg')`). Storage uses `SharedPreferences.setMockInitialValues({})` + `Store.instance.init()`. Files use temp dirs via `@visibleForTesting MediaStore.directory`. Platform channels are mocked with `TestDefaultBinaryMessengerBinding…setMockMethodCallHandler`. Widget tests pump `GymManeApp()`/`WearApp()` after setting `fit.route`/`fit.onboarded`.
- Test data fixtures under `test/fixtures/` are **git-ignored** (private real exports), so `fitnotes_backup_test`, `import_real_files_test`, `stats_realdata_test` are skipped on CI/clones (3 skips). Do not add hard dependencies on ignored paths.
- Names are behavioural sentences; several files are named after dated change batches (`requests_18sep_test.dart`, `reddit_requests_test.dart`).

### 13.2 Coverage map (what is verified vs not)

| Area | Implemented | Currently tested (by file) | Not currently tested |
|---|---|---|---|
| Session engine (start, rest, chains, holds, finish, continue, lock) | ✓ | `session_test`, `continue_session_test`, `session_lock_test`, `set_kinds_test`, `rpe_test`, `reps_only_test`, `routine_session_edit_test`, `live_session_test`, `requests_18/19/27sep_test`, `flow_test` | precise timer/notification timing on device |
| Stats, PRs, streak, muscle maps | ✓ | `audit_test`, `checkin_test`, `muscle_map_test`, `progress_order_test`, `stats_realdata_test`(skipped), `units_test` | recovery model beyond a case in `requests_18sep_test`; `sessionsByWeekday`/`averageSession` (unused) |
| Routines, plans, templates | ✓ | `plan_share_test`, `reddit_requests_test`, `editing_test`, `routine_session_edit_test` | template/plan edge cases across all 8 templates |
| Library, aliases, search | ✓ | `catalog_test` (ids/names unique, art files exist with 3 frames, no orphan art), `exercise_alias_test`, `polish_test`, `exercise_notes_test` | secondary-muscle correctness of the 552 entries beyond validation |
| Persistence, reset, backup/restore | ✓ | `persistence_test`, `backup_zip_test`, `backup_complete_test`, `export_test` | corrupted-JSON startup (ARCHITECTURE R1), failed restore mid-way (R2), `heatTone` restore |
| Importers | ✓ | `import_test`, `import_real_files_test`(skipped), `fitnotes_backup_test`(skipped) | SQLite reader without the private fixture |
| Calculators | ✓ | `calculators_test` | — |
| Places / gear | ✓ | `places_test` | plate-stock edge cases in the UI |
| Notes / measures / timeline | ✓ | `exercise_notes_test`, `note_calendar_test`, `measures_test`, `timeline_test`, `timeline_body_test` | photo/video import failure paths |
| Awards / profile | ✓ | `gamification_test`, `profile_test`, `profile_photo_test` | celebration timing |
| i18n | ✓ | `i18n_test` (**currently failing for `fa`**) | RTL layout |
| Shell / navigation / widgets | ✓ | `smoke_test` (visits every route), `route_stack_test`, `shell_*_test`, `scroll_keep_test`, `train_step2_test`, `live_update_test`, `home_widgets_test` | Kotlin code (`MainActivity`, `LiveNotifier`, widget providers) — **no native tests**; `HomeWidgetBridge.update`; `LiveWorkout.sync`; `IncomingShare`; `Beeper` (no references in `test/`) |
| Wear OS | ✓ (partial) | `wear_test` | on-device behaviour; CI smoke test was removed |
| iOS | not buildable | — | everything |

### 13.2b Regression checklist (run before and after any UI restyle)

Automated (all must stay green): `test/golden_path_test.dart` (first launch → Home; planned routine → start from nav → tick every set → finish → shows in Progress; body-map train → review → start), `smoke_test` (every route), `onboarding_test`, `data_safety_test`, `contrast_test`, `i18n_test`, plus the area tests listed in §13.2.

| Area | What must still work | Primary files / tests |
|---|---|---|
| Onboarding | Goal/training/place/(focus)/about steps, Skip, Back keeps answers, never > 6 steps, chips hug their labels | `onboarding_screen.dart`, `onboarding_flow.dart`, `onboarding_test` |
| Home | Today's routine + Start, week strip/check-ins, personalize card (existing users), photo-due nudge, folders | `home_screen.dart`, `golden_path_test` |
| Start paths | Nav ▶ (planned routine / start sheet / parked resume), pick exercises, body-map focus, past-day logging | `app_shell.dart`, `start_sheet.dart`, `train_screen.dart` |
| Session | Tick sets, rest timer + alarm, supersets, set kinds, RPE/RIR, timed holds, pause/park/lock, finish/continue/save-as-routine | `session_screen.dart`, `workout_state.dart`, `session_test`, `set_kinds_test`, `session_lock_test` |
| History | Day sheet, edit/delete sets, resume logged session (type/RPE/time/distance preserved) | `progress_screen.dart`, `logged_edit_test` |
| Library | Search, filters, favourites, archive, custom exercise, media | `exercises_screen.dart`, `exercise_detail_screen.dart`, `library tests` |
| Data | Backup/restore (ZIP+JSON), CSV export/import, reset, schema/migration, corrupt data | `data_safety_test`, `backup_*_test`, `persistence_test` |
| Backgrounds | Every mode (none, grid, dots, ancient, custom photo incl. zoom/opacity/blur extremes) in dark + light stays readable | `app_background.dart`, settings background sheet |
| Platform | Notifications/alarms, live notification, 5 widgets, Wear OS | manual (below), `wear_test`, `home_widgets_test` |

**Not covered by automated tests (do by hand on a device):** Kotlin code (`MainActivity` channels, `LiveNotifier`, widget providers); rest alarm firing with the screen off; the live notification and its actions (Android 16+ ProgressStyle branch and the legacy branch); pinning and updating each home-screen widget in day/night; share-in of plan JSON; save-to-gallery; reminders after reboot; Wear OS hardware; `HomeWidgetBridge.update`, `LiveWorkout.sync`, `IncomingShare`, `Beeper` (no unit tests).

**Reference screenshots.** `test/preview_baseline_test.dart` (git-ignored by the `test/preview_*.dart` rule) renders Onboarding, Home, Progress, Exercises, Exercise detail, Session, Profile and Preferences at 360×780 in dark and light with real fonts and icons: `BASELINE_DIR=build/baseline flutter test test/preview_baseline_test.dart`. Run it before and after a restyle and compare the images. Widget tests must call `loadAppFonts()` from `test/support/fonts.dart`; without it every glyph is a wide placeholder and layouts overflow falsely.

### 13.3 What is expected of a change
- Every meaningful behaviour change adds or updates a test (maintainer rule). Bug fix = a failing test first, when feasible.
- Data-affecting changes: extend `persistence_test`/`backup_*_test` (round-trip through `toJson`→`loadFromStore` and ZIP).
- New route/screen: add it to `smoke_test`'s route list.
- New user-visible strings: `i18n_test` must pass.
- Statistics changes: use deterministic data (fixed dates) — see `audit_test` style.
- Before pushing: `dart format .`, `flutter analyze --no-fatal-infos`, `flutter test` (CI runs the same on PRs). The suite is green; if `i18n_test` reports stale generated localization, run `flutter gen-l10n` and commit — never weaken the test.

## 14. Dependency Rules

- Adding a dependency needs a justification (maintainer + F-Droid reproducible-build context): it must be FOSS, work offline, require no network permission, no Google Play Services, and not add analytics. Check its transitive native code against the F-Droid policy. Never add Firebase/ads/analytics/crash SDKs.
- Prefer the existing stack: `path_drawing` for vector drawing, custom painters for charts, `archive` for ZIP, hand-written parsers for CSV/SQLite.
- CI uses `flutter pub get --enforce-lockfile` for releases: any pubspec change must include the updated `pubspec.lock`. Do not commit incidental lockfile churn from running local commands (running `flutter test` may rewrite `pubspec.lock`; revert it if you did not change dependencies).
- `cupertino_icons` is declared but unused; don't rely on it.
- Plugin API caveats: `flutter_local_notifications 22` (named parameters), `archive 4`, `share_plus 12` (`SharePlus.instance.share(ShareParams(...))`), `file_picker 8`, `home_widget 0.7`. Read the current call sites before upgrading.
- Do not patch plugin sources in the repo. (The release job patches `jni` build-id inside CI only.)

## 15. Platform-Specific Rules

**Android (only shipped platform)**
- Never add `INTERNET` (or `ACCESS_NETWORK_STATE`) to `src/main`. The debug manifest's `INTERNET` is Flutter tooling only.
- Method-channel names and payload keys are duplicated in Dart and Kotlin (ARCHITECTURE §12): change both sides in one commit; keep unknown methods returning `notImplemented`.
- Notification channel ids (`rest_timer`, `rest_timer_quiet`, `rest_timer_vibrate`, `rest_timer_alert`, `train_reminder`, `progress_photo`, `live_workout_v2`) cannot be changed in place — Android caches channel settings; create a new id instead (as `live_workout_v2` did). Notification ids: rest 1001, photo 1002, live 1003, train reminders 1010–1023.
- Exact alarms: permission handling is in `RestAlarm.requestPermission` / `reminderMode`; keep the inexact fallback.
- Widgets: any new widget needs Kotlin provider, `res/xml/*_info.xml`, `layout` + `layout-night`, manifest receiver, a rendered view in `home_widget_views.dart`, keys in `HomeWidgetBridge`, and a `_reload` call.
- Release signing/versioning: `versionCode` per ABI = `flutter.versionCode*10 + {1,2,3}`; F-Droid and CI depend on pubspec `version` only. Bump `pubspec.yaml` `version:` and add `fastlane/metadata/android/en-US/changelogs/<versionCode×10+abi>.txt` when releasing (existing pattern `41/42/43.txt` for `+4`).
- Min SDK 24: gate newer APIs (`Build.VERSION.SDK_INT`) as `MainActivity`/`LiveNotifier` do.

**Wear OS**: same Dart code base; keep phone-only work behind the `_onWatch` checks in `main.dart`; test with `test/wear_test.dart`.

**iOS**: no project exists. Do not add `Platform.isIOS` branches assuming they will run; adding iOS support means creating the `ios/` project (channels `gymmane/live_activity`, app group `group.com.gymmane.app`, widget extension) — out of scope unless requested.

## 16. Git / Change Rules

- Branch from `main`; PRs target `main` (CI: analyze → test → split APK build).
- One topic per PR; description says *what and why*, with a screenshot for visual changes (`CONTRIBUTING.md`). Bug fixes/small changes: PR directly; larger: open an issue first.
- Commit messages carry the reasoning (there are no code comments); recent history uses short imperative sentences and conventional-commit prefixes for translation PRs (`feat(i18n): …`, `fix(i18n): …`).
- Do not commit: build outputs, keystores (`*.jks`, `key.properties`), `test/fixtures`, `doc-personal/`, `tool/`, `fdroid/`, `site/`, and the local AI-agent tooling — `.agents/`, `.claude/` (installed skills, agent settings) and `skills-lock.json` — all git-ignored. They are developer-machine files, not part of the app; never `git add -f` them, and check `git status` for stray copies before committing.
- Before a commit run `git status` and stage only source, tests, ARB + regenerated l10n, and the five core docs. Running `flutter test`/`pub get` can rewrite `pubspec.lock`; revert it unless you changed dependencies.
- Contributions are GPL-3.0; exercise art additions must be CC BY-SA 4.0-compatible and credited in `CREDITS.md`.
- Regenerate, don't hand-edit, generated l10n files.

## 17. AI Coding Agent Rules

### Before modifying code
1. Read PROJECT_CONTEXT → ARCHITECTURE → FEATURES section → DATA_MODEL section (if data is involved).
2. Inspect the existing implementation and **find the owning feature**: which `lib/state/*_state.dart` mixin, which model, which screen(s), which service.
3. Find related models and their `toJson/fromJson`, and whether they are persisted, backed up, and reset.
4. Find how state changes reach persistence (`_persist`/`persistNow`) and widgets (`_refreshWidgets`).
5. Check for reusable components in `lib/widgets/` and helpers in `fit_core.dart`, `ui_kit.dart`, `l10n.dart`.
6. Read the existing tests for that area (see §13.2) and the ARB keys you will need.
7. Consider platform implications: manifest permissions, channels, notification channels, widgets, Wear.
8. For anything touching timers, rest alarms or live notification, read `workout_state.dart` end-to-end and `rest_alarm.dart`.

### Do not
- Rewrite or re-layer the architecture (no Provider/BLoC/Riverpod, no repository layer, no route table migration) without an approved issue.
- Introduce parallel abstractions (a second store, a second unit converter, a second theme system).
- Copy business rules into widgets or duplicate a formula that exists in `lib/state`.
- Hard-code user-facing strings, dates, or numbers with units.
- Add dependencies, permissions, network calls, analytics or telemetry.
- Rename/renumber persisted ids, enum indices, JSON keys or catalogue ids.
- Edit `pubspec.lock`, generated l10n files, or large catalogue/SVG data files except through their intended workflow.
- Remove existing behaviour "while you're there" (e.g. the `restPause` set type, `heatTone`, legacy-data shims).
- Touch unrelated files or reformat them.
- Create documentation files beyond the five root docs; do not add comments to source (house style).
- Weaken/skip tests to get green; do not modify `i18n_test` to hide missing locales.
- Run destructive commands against user data (there is none in the repo), or commit secrets.

### Always
- Reuse the existing architecture, components, and helpers; extend the owning mixin.
- Preserve backward compatibility of stored data and backups; write the shim + test if the format must change.
- Update **all** wiring for a persisted field (model, `toJson`, `loadFromStore`, `applyBackup`, `resetAllData`, ZIP if media).
- Add/adjust tests for behaviour changes; keep the suite deterministic.
- Add ARB keys to **all** language files (English text as placeholder is acceptable only if the parity test still passes and a translator can follow up; prefer real translations for es/it/zh if you can) and regenerate + commit l10n output.
- Keep changes small; verify with `dart format`, `flutter analyze --no-fatal-infos`, `flutter test`; for UI changes run the app (`flutter run`) on an Android device/emulator, in dark and light, and with a non-English locale, when possible. If you could not run the UI, say so.
- Update the affected sections of these five docs when you change architecture, features, data formats or rules.
- Report clearly: what changed, what was verified, what was not.

### Known hazards (read before touching)
| Area | Hazard |
|---|---|
| `FitState.applyBackup` / `importJson` | validated + rolled back (GM-03); keep `_loading` reset in every path and keep returning `bool` |
| `loadFromStore` | defensive per item (GM-02); new loaders must use `_guard/_readAll/_mapOf/_listOf`, never bare casts of stored values |
| Stored format | `schema` version (GM-04): change the format only through `kMigrations`; a newer document sets `storeLocked` (no saving) |
| `resetAllData` | does not reset theme/units/language/rest/alarm/background/photo interval/`gm_*` |
| Method channel names, notification channel/ids, widget provider names | cross-language string contracts |
| `kExerciseAliases`/templates/CSV matching | depend on exercise *names* |
| `lib/l10n` generated files | must be regenerated with ARB changes (`i18n_test` now detects staleness) |
