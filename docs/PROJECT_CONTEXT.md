# PROJECT_CONTEXT.md — GymMane

Entry point for AI coding agents. Everything here was derived from the source at commit `9af217e`
(version `1.3.0+4`). Where existing docs and code disagree, **code wins**; discrepancies are listed in
§8.3. Companion documents: [ARCHITECTURE.md](ARCHITECTURE.md) · [FEATURES.md](FEATURES.md) ·
[DATA_MODEL.md](DATA_MODEL.md) · [DEVELOPMENT_GUIDELINES.md](DEVELOPMENT_GUIDELINES.md).

---

## 1. Project Identity

| Item | Value | Source |
|---|---|---|
| Name | **Kaizan** — tagline "Soft but not weak." (GM-90). Formerly GymMane: the package (`gymmane`), application id, prefs key `gymmane_v1`, backup entry `gymmane.json`, class names and the repository keep the old spelling so updates and old backups work. Display name lives in `lib/app/brand.dart` (`kAppName`), the manifest label, the ARB files and Play metadata | `pubspec.yaml`, `AndroidManifest.xml`, `lib/app/brand.dart` |
| Application id | `com.gymmane.app` | `android/app/build.gradle.kts` |
| Version | `1.3.0+4` (versionCode is multiplied by 10 + ABI code 1/2/3 per split APK) | `pubspec.yaml`, `build.gradle.kts` |
| Purpose | Offline, ad-free gym workout logger: pick muscles on a body map, log sets, watch stats grow | `README.md`, `pubspec.yaml` |
| Product type | Single-user native-feeling mobile app built with Flutter. No backend, no accounts | code (no network code) |
| Target users | Recreational lifters who want a private logger; also people migrating from Hevy / Strong / Lyfta / Fitbod / FitNotes / openGym | `lib/services/workout_import.dart` |
| Author / maintainer | InlitX (`github.com/InlitX/GymMane`); community-contributed translations | `README.md`, git log |
| Licence | Code GPL-3.0; exercise art CC BY-SA 4.0 (Workout Guide / Everkinetic); Manrope font SIL OFL | `LICENSE`, `CREDITS.md` |
| Distribution | F-Droid (reproducible build), IzzyOnDroid, OpenAPK, Obtainium, GitHub Releases | `README.md`, `.github/workflows/build-apk.yml` |

### Platform support (verified)

| Platform | State | Evidence |
|---|---|---|
| Android phone | **Implemented, shipped.** minSdk 24 (Android 7.0), targetSdk/compileSdk 36 | `android/app/build.gradle.kts` |
| Wear OS | **Partially implemented / beta.** A separate UI (`lib/wear/`) is launched when `PackageManager.FEATURE_WATCH` is true; README labels it "In progress" | `lib/main.dart`, `lib/wear/*`, `MainActivity.kt` (`gymmane/device`) |
| iOS | **Not buildable from this repo.** There is **no `ios/` directory** (only `.metadata` lists it). Dart code has iOS branches (`Platform.isIOS` in `rest_alarm.dart`, `live_workout.dart`, `home_widget_bridge.dart`) but no native counterpart exists here. README: "In progress" | `ls`, `.metadata`, grep |
| Desktop / Web | **Planned / absent.** No platform folders | `README.md` |

## 2. Product Vision

GymMane tries to be the **private, zero-friction gym log**: the primary workflow is *tap muscles on an
anatomical body map → get a suggested session → tick sets → rest timer rings itself*. Progress features
(volume, streaks, PRs, muscle heat maps, photos, measurements, medals) are computed **only from the
sets the user logged** ("Statistics must be computed from real logged sets, never estimated or faked" —
`CONTRIBUTING.md`, consistent with the code in `lib/state/stats_state.dart`). Data portability is a
first-class concern: full ZIP backup, CSV export, and importers for six other apps.

## 3. Core Capabilities (all verified in code — details in [FEATURES.md](FEATURES.md))

- Workout logging: body-map picker, routine start, manual pick, past-day logging, live session with rest timer, supersets, set types, RPE/RIR, timed and cardio exercises, warm-up generator, progressive-overload suggestion.
- Library: 552 built-in exercises with 3-frame vector animations, filters, favourites, archive, custom exercises, per-exercise photo/GIF/video, per-exercise notes and rest time.
- Routines: groups, colours, duplicate, weekly schedule (optionally several per day), 8 built-in program templates, JSON plan import/export, "Routine with AI" (copy/paste, no network).
- Progress: volume, streak, weekly goal, PRs, e1RM curves, heat-map, muscle split/radar/recovery, bodyweight, 10 body measurements, progress-photo timeline (+ compare, + body-map timeline), 20 medals, sticker/share cards.
- Tools: 6 calculators (1RM, BMI, calories/macros, body fat, plates, warm-up).
- Journal (notes on a calendar, with media), "Snapshots" (moments), Places (equipment profiles + plate inventory).
- Data: ZIP backup/restore (with media), JSON backup, CSV export, CSV/SQLite/JSON importers.
- Platform integrations: rest-alarm notifications, live workout notification (Android), 5 home-screen widgets, incoming share/open of plan JSON, save-to-gallery, Wear OS UI.
- 17 ARB files, all registered (fa fixed by GM-01), light/dark/system theme, kg/lb.

## 4. Technology Stack (only what the code uses)

| Layer | Technology | How it is actually used |
|---|---|---|
| Language / SDK | Dart `^3.11.5`, Flutter (CI pins `3.41.9`) | `pubspec.yaml`, workflow `FLUTTER_VERSION` |
| UI | Flutter + Material 3 (`useMaterial3`) with a fully custom look (glass surfaces, custom painters); Manrope font; Phosphor icons | `lib/theme/*`, `lib/widgets/*` |
| State | One hand-rolled `ChangeNotifier` singleton `fit` (`FitState`), split via `part`/`mixin` files. **No Provider/Riverpod/BLoC** | `lib/state/fit_state.dart` |
| Navigation | A `String route` + back-stack inside `FitState`; `AppShell` switches screens with `AnimatedSwitcher`. `Navigator` is used only for dialogs/sheets and three full-screen overlay viewers/editors | `lib/state/fit_core.dart`, `lib/app/app_shell.dart` |
| Persistence | `shared_preferences`: **one JSON string** under key `gymmane_v1` (+ a few `gm_*` string keys); media as files in `<documents>/exercise_media`; alarm sound in `<documents>/alarm` | `lib/services/local_store.dart`, `media_store.dart`, `alarm_store.dart` |
| Serialization | Hand-written `toJson`/`fromJson` with short keys; no codegen, no `json_serializable` | `lib/models/*` |
| Localization | `flutter gen-l10n` (ARB, template `app_en.arb`), generated files **are committed**; extra hand-written catalog maps for exercise names/steps (es, it, zh) | `l10n.yaml`, `lib/l10n/*` |
| Notifications / alarms | `flutter_local_notifications` + `timezone`; `audioplayers` for sound; custom Kotlin `LiveNotifier` for the live-workout notification | `lib/services/rest_alarm.dart`, `train_reminder.dart`, `progress_reminder.dart`, `android/.../LiveNotifier.kt` |
| Home widgets | `home_widget`: Flutter widgets are rendered to PNG (`renderFlutterWidget`) and bound by Kotlin `AppWidgetProvider`s | `lib/services/home_widget_bridge.dart`, `lib/widgets/home_widget_views.dart` |
| Files / media | `file_picker`, `image_picker`, `share_plus`, `path_provider`, `video_player`, `url_launcher`, `app_settings` | screens + services |
| Backup / import | `archive` (ZIP); hand-written CSV parser; **hand-written SQLite reader** (no sqlite package) for FitNotes | `lib/services/*` |
| Vector art | `path_drawing` parses SVG path strings from `assets/art/*.txt` (3 frames each) | `lib/widgets/exercise_art.dart` |
| Charts | Custom `CustomPainter`s (no chart library) | `lib/widgets/charts.dart` |
| Shaders | 2 fragment shaders (`medal.frag`, `edge_fade.frag`) | `pubspec.yaml`, `lib/widgets/medal.dart` |
| Tests | `flutter_test` only; no mocking package | `test/*` |
| CI | GitHub Actions `build-apk.yml`: analyze → test → split-ABI release build; manual dispatch publishes a signed release | `.github/workflows/build-apk.yml` |
| Local agent tooling | `.agents/`, `.claude/`, `skills-lock.json` (installed design/animation skills) are git-ignored and never shipped | `.gitignore` |
| Translations tooling | `crowdin.yml` exists, but `TRANSLATING.md` says there is no translation website yet | see §8.3 |

Declared but unused: `cupertino_icons` (no `CupertinoIcons` reference anywhere in `lib/`).

## 5. Architectural Principles (verified)

1. **Offline-first, no network.** Release manifest declares no `INTERNET` permission and removes `ACCESS_NETWORK_STATE` (`tools:node="remove"`). `INTERNET` appears only in `android/app/src/debug/AndroidManifest.xml` (Flutter default for debug tooling). No HTTP client exists in `lib/`. The only outbound action is `url_launcher` opening links externally (`about_screen.dart`, `settings_screen.dart`).
2. **No accounts / no telemetry.** No auth, analytics, crash reporting or remote config code exists.
3. **Local data ownership.** Everything lives in app-private storage; `android:allowBackup="false"` (Android's cloud backup is disabled on purpose). Users move data only through explicit export/share.
4. **Single source of truth.** `fit` (global `FitState`) owns all mutable app state. Screens read it directly.
5. **Derived stats, not stored stats.** Streaks, PRs, volume, recovery, awards progress are recomputed from `sessions` on demand (`stats_state.dart`); the only stored derived data is `awards` (earned timestamps).
6. **Canonical units.** Weight is stored in **kg**, distance in **km**, lengths in **cm**; conversion to lb/mi/in happens only at display/entry (`fit_core.dart`, `measures_state.dart`).
7. **Every user-visible string is localised** through `t.<key>` (enforced by `test/i18n_test.dart`).
8. **No source comments** as house style (`CONTRIBUTING.md`); the code follows it.
9. **Resilience over strictness in the UI layer:** platform-channel and file failures are caught and swallowed (`try { … } catch (_) {}` is pervasive) so a missing capability never crashes the app.

## 6. Important Constraints (must respect)

- Never add `INTERNET`, analytics, accounts, ads or any server dependency (`CONTRIBUTING.md` "Two rules that never bend"). Do not add the permission to the main manifest.
- Persisted formats have **no version field**; compatibility relies on tolerant `fromJson` defaults. Any change to a persisted key needs a backward-compatible reader ([DATA_MODEL.md](DATA_MODEL.md) §9).
- `fit` is a process-wide singleton and tests mutate it directly; do not introduce constructor-injected state without a migration plan.
- Weight values in models are always kg. Never store display units.
- Exercise `id`s are referenced from sessions, routines, favourites, media, notes, backups and the openGym mapping (`opengym_ids.dart`) — never renumber or delete built-in exercises in `kExercises`.
- `applicationId`, notification channel ids, method-channel names (`gymmane/*`) and widget provider class names are wired across Dart and Kotlin; renaming one side breaks the app silently.
- Release builds are **reproducible for F-Droid**: CI pins the Flutter version, uses `--enforce-lockfile`, patches jni build-id, and forbids passing `--build-name/--build-number`. Do not change the release job casually.
- Generated l10n files (`lib/l10n/app_localizations*.dart`) are **committed** and must be regenerated (`flutter gen-l10n`) whenever an ARB file is added or a key changes.
- Max text scale is clamped to `2.0` (`GymManeApp.maxTextScale`, GM-20); core screens are tested at 200 %. Tap targets are ≥ 48 dp (see ARCHITECTURE, Accessibility).

## 7. Important Terminology

| Term | Meaning in this codebase |
|---|---|
| `fit` / `FitState` | The global app-state singleton (`lib/state/fit_state.dart`). |
| Session (live) | `WorkoutSession` (`lib/models/live_session.dart`): the in-progress workout. Only one may exist. Persisted under `live*` keys while unfinished. |
| Logged session | `LoggedSession` (`lib/models/workout.dart`): a finished workout in `fit.sessions`. |
| Manual session | A session created via "log on a past day" (`WorkoutSession.manual == true`): noon timestamp on the chosen day, no countdown, no rest timer, no live notification. |
| Working set | Any set whose `SetKind != warmup` (`counts == true`). Only working sets count toward volume, PRs, muscle sets, set counts. |
| SetKind | `normal, warmup, drop, failure, restPause` — persisted as the enum **index** (order matters!). |
| Mode | Exercise tracking mode: `''` (weight×reps), `'cardio'` (km + time), `'time'` (seconds hold). Ids in `kExerciseModes`, overridable per exercise (`modeOverride`). |
| Reps-only | Bodyweight exercise logged without weight (`repsOnly`/`repsOnlyOff` overrides + heuristic). |
| Superset / chain | `linkedNext` on `SessionExercise`, `chained` in `Routine`; ticking a set jumps to the next exercise in the chain. |
| Planned set | `PlannedSet`: per-set template inside a routine (`Routine.plan`). |
| Place | `GymPlace`: named equipment profile (+ plate stock, bar weight). Filters what exercises are offered. |
| Moment / Snapshot | Free photo with optional note (`Moment`, in `moments_state.dart`). Distinct from progress photos. |
| Progress entry / shot | `ProgressEntry`: dated body-photo entry with up to 3 poses (`front`, `side`, `back`). |
| Timeline | The progress-photo timeline; `bodyTimeline` toggles an alternate muscle-map rendering per time window (`BodyWindow`). |
| Check-in | A manually ticked day (string `YYYY-M-D` in `fit.checkins`) that counts as "trained" for streak/goal/heatmap. |
| Award / medal | One of 20 `AwardId`s; earned timestamps in `fit.awards`. Gamification can be switched off. |
| Ember / accent / brass / sage | Theme colour tokens in `GymColors` (`lib/theme/app_colors.dart`). |
| Parked session | An unfinished session while the user navigates elsewhere; shown as a pill above the nav bar. |
| Catalog | The static exercise database `kExercises` (`lib/catalog/exercise_catalog.dart`); "catalog names/steps" are the translation maps. |
| openGym | Another open-source gym app whose backup format GymMane imports (`kOpenGymIds` maps its ids to local ids). |
| AI plan | Copy a generated text prompt → paste into any external AI → paste answer back → parsed as a plan. No API is called. |

## 8. Current State

### 8.1 Status matrix

| Area | Status |
|---|---|
| Android phone app, all features in §3 | **Implemented** |
| Wear OS UI (`lib/wear`) | **Partially implemented** (own shell with rotary input, screen dimming, session run; README: in progress; CI smoke test for Wear was dropped — commit `717a85d`) |
| iOS | **Partially implemented in Dart only; not buildable** (no `ios/`); README: in progress |
| Live workout notification (Android 16 `ProgressStyle` branch + legacy branch) | **Implemented** (`LiveNotifier.kt`) |
| Persian (fa) | **Implemented** — registered after regenerating localization (GM-01); RTL not yet device-verified |
| Crowdin translation workflow | **Unknown** — `crowdin.yml` present; docs say none exists |
| Desktop | **Planned** (README only) |
| AI-generated plans | **Implemented as copy/paste flow**, not an integration |
| Experimental / planned features in code | None flagged as experimental in code. README roadmap items = Wear OS, iOS, Desktop only |

### 8.2 Tests (measured on this checkout)

`flutter test` → after the P0 fixes (GM-01…05): **541 passed, 3 skipped, 0 failed**. Before them it was 519 passed, 3 skipped, 1 failed (523 total); that failure was
`test/i18n_test.dart › every ARB file in lib/l10n ships as a language of the app` (`fa`). The 3 skips
need `test/fixtures/` which is git-ignored. `flutter analyze` → 2 infos (`onReorder` deprecated in
`routine_edit_screen.dart:287`, `session_screen.dart:1662`).

### 8.3 Documentation ↔ code discrepancies

| Claim | Reality |
|---|---|
| README: "16 languages" | Now 17 (Persian was unregistered until GM-01 regenerated the l10n classes). README still says 16. |
| README/`pubspec` description: "Android and iOS" | No `ios/` folder. |
| CONTRIBUTING: "350+ tests" | 523 tests (519 pass). |
| README: "Set types (warm-up, working, drop set, to failure)" | Enum also has `restPause`. |
| TRANSLATING.md: "There is no Weblate or Crowdin yet" | `crowdin.yml` is in the repo root. |
| README "Photos, videos and notes stay in the app's own storage" | True (`getApplicationDocumentsDirectory()/exercise_media`), but the **profile photo and banner are stored as base64 inside the main JSON blob**, not as files. |
| `flutter_launcher_icons.min_sdk_android: 21` | Actual `minSdk = 24`. |
| `.metadata` lists `ios` and `web` platforms | Neither folder exists. |

## 9. AI Agent Quick Start

```
Before changing code:
1. Read PROJECT_CONTEXT.md            (this file)
2. Read ARCHITECTURE.md               (where things live, how state flows)
3. Read the relevant section of FEATURES.md
4. Read the relevant section of DATA_MODEL.md (mandatory if you touch any persisted field)
5. Follow DEVELOPMENT_GUIDELINES.md   (rules, tests, localisation, git)

House rules from the owner: tell them BEFORE installing any new package or tool and wait for a yes
(DEVELOPMENT_GUIDELINES §14); do not build an APK unless they ask for one.
```

Fast orientation:

| I need to… | Go to |
|---|---|
| Change how a workout behaves | `lib/state/workout_state.dart` (+ `lib/models/live_session.dart`, `lib/screens/session_screen.dart`) |
| Change a statistic / PR / streak | `lib/state/stats_state.dart` |
| Change routines / weekly plan | `lib/state/routines_state.dart` |
| Add/alter a persisted field | model in `lib/models/`, then `toJson`/`loadFromStore`/`applyBackup` in `lib/state/fit_state.dart` |
| Add a setting | `lib/state/settings_state.dart` + `_loadToggles` + `toJson` + `lib/screens/settings_screen.dart` + ARB keys |
| Add an importer | `lib/services/workout_import.dart` (`detectFormat`, `_formats`) + `test/import_test.dart` |
| Add a screen | new file in `lib/screens/`, route string handling in `fit_core.dart`/`fit_state.dart handleBack`, case in `AppShell._screen()` |
| Add a string | `lib/l10n/app_en.arb` → all other ARBs → `flutter gen-l10n` |
| Run checks | `flutter analyze --no-fatal-infos && flutter test` |

Verify claims yourself before relying on them: this document set was generated by static reading plus one
`flutter test` / `flutter analyze` run; nothing was run on a device.

## 10. Product Roadmap (PLANNED — none of this is implemented)

Direction: a simple, motivating, personalized, offline-first app — *user simplicity > feature quantity*.
Tracked as 61 cards (`GM-01…GM-86`, labels `P0-Critical…P3-Low` + category labels) in the Todoist project
"Workout" (id `6hff3gw3Vm2M6h8R`), section **Backlog**. Todoist has no dependency links, so each card lists
"blocked by" keys.

| Phase | Theme | Cards |
|---|---|---|
| 0 | Foundations & discovery: green baseline, data safety (loadFromStore, restore, schema version, history-edit fidelity), regression checklist, offline guards, perf baseline | GM-01…GM-08 |
| 1 | Design system & UI/UX: tokens, AA contrast, components, workout-first Home, navigation, motion, accessibility, responsive | GM-10…GM-21 |
| 2 | Onboarding: `TrainingProfile`, goal (Lean Aesthetic / Muscle & Strength), conditional questions, plan-ready summary, existing-user migration | GM-30…GM-36 |
| 3 | Exercise intelligence: taxonomy + curated `ExerciseMeta`, context-aware filters, primary/secondary impact (no invented %), detail redesign, substitutions | GM-40…GM-50 |
| 4 | Personalized plans: rules table, deterministic generator, apply as routines/weeklyPlan, plan view, edit/regenerate | GM-51…GM-56 |
| 5 | Workout tracking: preview, streamlined session, completion, plan linkage, partial workouts, screen splits | GM-60…GM-65 |
| 6 | Motivation: longest streak + badge, weekly plan completion, milestones, gentle messaging | GM-70…GM-73 |
| 7 | QA & stabilization: offline, accessibility, migrations, performance, localization, persistence port, docs | GM-80…GM-86 |

Progress (Testing, unmerged): GM-01…05 (data safety), GM-11 (contrast + semantic colors), GM-30…34, GM-36, GM-40, GM-84 (questionnaire: goal/experience/days/duration/place/focus, `TrainingProfile`, taxonomy schema, Home opt-in card). Partially done: GM-10 (tokens exist; only `ui_kit`/`dialogs`/`choice` migrated), GM-12 (only `ChoiceCard`/`SelectChip`/`StepProgress`). Not started: everything else, incl. the plan generator — the questionnaire currently stores answers but does not yet change what the app suggests.

**Kaizan redesign brief (PLANNED, not implemented).** The owner plans to rebrand the app as *Kaizan — "Soft but not weak."* with a calm, premium, Japanese-*inspired* (not themed) look: vermilion/sumi/washi/matcha/indigo palette, mature typography with tabular numerals, small-to-medium radii, five background modes (none, grid, dots, ancient washi texture, custom upload with readability guard), calm completion feedback (no confetti), Home built around "Today's Focus". It is tracked as GM-90…GM-101 plus Kaizan sections appended to the existing UI cards. Constraints recorded there: keep `applicationId com.gymmane.app`, prefs key and backup entry name (old backups must import); keep navigation structure unless a usability problem is shown; no business-logic or data-model changes for styling; the brief mentions login, marketing screens and workout generation, which do not exist in the app today. Today's code still uses the GymMane name, Nunito, a terracotta accent, pill-shaped controls, glass blur in 6 files and `Confetti`.

Audit facts behind the roadmap (verified): the exercise data has no compound/isolation, movement-pattern,
goal or impact data (only `primary`, `secondary` 0–3, equipment, difficulty, steps); onboarding has no physique
goal/experience/duration; a "plan" is already representable as routines + `weeklyPlan` (so generation can reuse
storage, history and reminders); text tiers fail AA contrast (dark tertiary 3.45:1, light 3.48:1); reduced motion
is only honoured in `liquid_notch.dart`; text scale is clamped at 1.15; Home stacks ~8 sections.
The installed design skills (`.agents/skills/`) are web-oriented (the taste skill excludes "multi-step product
UI"); only their transferable principles (contrast checks, motion budget, reduced motion, press feedback) are used.
