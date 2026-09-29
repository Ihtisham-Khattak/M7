# FEATURES.md — GymMane

What the app actually does, verified against source at commit `9af217e` (v1.3.0+4). Status vocabulary:
**Implemented · Partially implemented · Experimental · Planned · Unknown**. Structure, state and services:
[ARCHITECTURE.md](ARCHITECTURE.md). Persisted shapes: [DATA_MODEL.md](DATA_MODEL.md). Product overview:
[PROJECT_CONTEXT.md](PROJECT_CONTEXT.md). Rules: [DEVELOPMENT_GUIDELINES.md](DEVELOPMENT_GUIDELINES.md).

Feature index:
1. [Onboarding & profile](#1-onboarding--profile) · 2. [Starting a workout](#2-starting-a-workout-train-start-sheet-past-day-logging) · 3. [Live workout session](#3-live-workout-session) · 4. [Finishing, summary & resume](#4-finishing-summary-continue-save-as-routine) · 5. [History & editing logged data](#5-history--editing-logged-data) · 6. [Exercise library](#6-exercise-library) · 7. [Custom exercises, modes & media](#7-custom-exercises-tracking-modes--media) · 8. [Places](#8-places-equipment-profiles) · 9. [Routines & weekly plan](#9-routines-weekly-plan--templates) · 10. [Plan import/export & "Routine with AI"](#10-plan-importexport--routine-with-ai) · 11. [Progress & statistics](#11-progress--statistics) · 12. [PRs & strength curves](#12-personal-records--strength-curves) · 13. [Muscle heat, recovery & focus](#13-muscle-heat-recovery-radar--daily-focus) · 14. [Bodyweight & measurements](#14-bodyweight--body-measurements) · 15. [Progress photos](#15-progress-photo-timeline--compare) · 16. [Journal & snapshots](#16-journal-notes--snapshots-moments) · 17. [Awards](#17-awards--gamification) · 18. [Calculators](#18-calculators-tools) · 19. [Settings](#19-settings--preferences) · 20. [Reminders & notifications](#20-alarms-reminders--live-notification) · 21. [Widgets](#21-home-screen-widgets) · 22. [Backup, export & import](#22-backup-export--import) · 23. [Sharing](#23-sharing-stickers--cards) · 24. [Localization](#24-localization) · 25. [Wear OS](#25-wear-os) · 26. [Not implemented / planned](#26-planned--not-implemented) · 27. [Undocumented-in-README features](#27-features-present-in-code-but-missing-from-or-thin-in-the-readme)

---

## 1. Onboarding & profile

### Purpose
First-run setup and a local "identity" (no account) used for calculators, level and share cards.

### User Flow
`AppShell` shows `OnboardingScreen` until `fit.onboarded` (6 pages, `_last = 5`): welcome page (with short "promise" rows) → name → units (kg/lb) → body (sex/age/height/weight) → goal (weekly sessions) → places/gear → finish. `_finish()` saves the name, creates one `GymPlace` per selected preset (`gym|home|outdoors`), activates the first, then `completeOnboarding()`.
Profile tab (`ProfileScreen`, route `settings`): avatar/banner (image picker, stored as base64 in the profile), handle, badge colour, level, medal shelf, "Snapshots" strip, streak/lifted/trained totals, gear button → Preferences.

### Implementation
`lib/screens/onboarding_screen.dart`, `profile_screen.dart`; `SettingsState.updateProfile/setProfilePhoto/setProfileBanner/setProfileHandle/setProfileBadge/completeOnboarding`; model `lib/models/profile.dart`.

### Business Rules
- Clamps in `updateProfile`: age 10–90, height 100–250 cm, weight 30–250 kg, weekly goal 1–14.
- Default name `kDefaultName = 'InlitX'`; legacy placeholder names `Athlete|Atleta|Name` are rewritten to it on load (`loadFromStore`).
- Handle: only `[A-Za-z0-9_.]` kept; if empty, derived from the display name (`profileHandle`).
- `since` (member-since) is stamped on first load from the earliest session or today.
- Athlete level: `1 + totalSessions ~/ 10` (`athleteLevel`).
- Updating the profile re-seeds calculator inputs (`_seedCalculatorsFromProfile`); logging bodyweight updates `profile.weightKg`.

### Data Used
`Profile` → [DATA_MODEL.md](DATA_MODEL.md) §3 `Profile`.

### Related Components
`ruler_picker.dart`, `body_rulers.dart`, `profile_avatar.dart`, `photo_source_sheet.dart`.

### Dependencies
`image_picker`, `file_picker` (banner from files).

### Edge Cases
Photo/banner bytes are re-encoded into the main JSON blob (large images inflate every save). `resetAllData` returns `onboarded=false`, sending the user back to onboarding.

### Current Status
**Implemented.**

---

## 2. Starting a workout (Train, Start sheet, past-day logging)

### Purpose
Get from "I'm here" to a ready session in as few taps as possible.

### User Flow
- Centre FAB of the nav bar: if a session is parked → resume it; else if today has a planned routine with exercises → start it immediately; else open `StartSheet`. Long-press always opens `StartSheet`.
- `StartSheet`: planned routines for the day, all routines (grouped), "Pick exercises" (`startPicking`), "Choose focus" (`startWorkout`).
- `TrainScreen` step `select`: tap muscles on the front/back body map (13 muscles), or quick-start `warmup`/`cardio` kinds (`startKindWorkout`). `Continue` → step `review`: a pre-selected list (default 6 picks) that can be edited, searched (`trainSearchResults`, max 40) and toggled ("don't suggest" per exercise).
- Home focus card and "Start" use `suggestedFocus`; `startFocusWorkout` pre-selects those muscles.
- Progress `_DaySheet` on a past date opens `showStartSheet(day: date)` → **log a past workout** (session `manual`).

### Implementation
`lib/state/workout_state.dart` (`startWorkout`, `startPicking`, `trainContinue`, `_defaultPicks`, `startKindWorkout`, `reviewExercises`, `startRoutine`, `startSession`, `_beginSession`), `lib/screens/train_screen.dart`, `start_sheet.dart`, `app_shell.dart` (`_play`).

### Business Rules
- Candidate pool = exercises whose primary **or** secondary muscle is selected, `fitsHere` (active Place) and not archived (`getFilteredExercises`).
- Default picks: one exercise per selected muscle (rank favourites → has history → others), then fill to `_pickTarget = 6`; exercises flagged `noSuggest` are excluded.
- Warm-up kind pool = `kWarmupIds`; cardio pool = cardio-mode exercises + `kCardioExtras`; cardio default pick = first cardio exercise that has history.
- Starting a routine uses `routineSets`, `plannedSets`, chains; empty routines do nothing.
- Only one live session: `_backToParked()` re-enters a parked session instead of starting another.
- Past-day sessions: `loggedAt = day at 12:00`, `manual = true`, `logDay` cleared after start.

### Data Used
`fit.sessionPicks`, `selectedMuscles`, `favorites`, `noSuggest`, `routines`, `places`; catalog lists in `exercise_catalog.dart`.

### Related Components
`body_map.dart`, `muscle_radar.dart`, `start_sheet.dart`, `SessionScreen`.

### Dependencies
None external.

### Edge Cases
`startSession` silently does nothing if no exercise ids resolve. Picks that are not in the filtered base are appended (`reviewExercises` "extras").

### Current Status
**Implemented.**

---

## 3. Live workout session

### Purpose
Log sets in real time with rest timing, suggestions and safety against accidental taps.

### User Flow
Route `session`. A 5-second start countdown overlay (`countdownUntil`, disabled for manual sessions or via settings) → per-exercise stage: set rows (reps/weight steppers or ruler pickers, set-type tag, optional RPE/RIR), tick a set → rest timer starts → auto-advance to next exercise after a short delay. Header shows elapsed time, exercise x/y, pause, lock. Operations available in `WorkoutState` / the session UI: add/remove/restore a set, add warm-up sets, change set type, RPE/RIR entry, add/remove/reorder exercises, superset chaining, a "next exercise" button that jumps to the next exercise with undone sets (`goNextPending`), discard, finish. Timed sets: "Start hold" runs a 5 s lead-in then a countdown with beeps and auto-ticks the set. Cardio sets take km + time.
"Step out" (`stepOutOfSession`) pauses and parks the session; a pill above the nav bar resumes it. The session survives app kill and reboot.

### Implementation
State: `WorkoutState` (see [ARCHITECTURE.md](ARCHITECTURE.md) §5). UI: `lib/screens/session_screen.dart` (`SessionScreen`, `_ExerciseStage`, `_LockGuard`, `_HoldToUnlock`, `_Celebrate`), `widgets/timer_panel.dart`, `start_countdown.dart`, `set_kind.dart`, `stopwatch_card.dart` (used on exercise detail). Model: `lib/models/live_session.dart`.

### Business Rules
- **Opening sets** (`_openingSets` / `_workingOpeners`): from the routine plan if present (`_fromPlan`, warm-ups get 50% of first working weight rounded to `weightStep`); otherwise mirror the last logged working sets of that exercise (+ `progressStep` if every previous working set reached the first set's reps — `_progressBump`); otherwise 3×10 at 20 kg (0 for reps-only). Mode exercises use `_modeOpeners` (cardio default 1200 s, time default 30 s ×3). Optional auto warm-up (`warmsUp(id)`): 40%×10, 60%×5, 80%×3 of the top weight rounded to the unit step (`_warmupSpec`), or a half-reps set for bodyweight.
- **Next target** (`nextTarget`): if every previous working set hit the first set's reps → weight + `progressStep` (default one `weightStep`: 2.5 kg / 5 lb), else same weight; reps-only exercises add 1 rep.
- **Editing carry**: changing reps/weight/sec/km on a set propagates to the following *undone, same-kind* sets that still held the old value (`_carry`).
- **Limits**: reps 0–999, weight 0–1000 kg, sec 0–24 h, km 0–1000, routines ≤ 20 planned sets.
- **Rest**: `restFor(exerciseId)` = per-exercise override (15–600 s, 0 = none) else global `restSeconds` (default 90; 0 or 15–600) — cardio defaults to 0. No rest while paused or in manual sessions. Rest can be nudged −15/+15 s (clamped 5–600) from the timer panel (phone and watch) or +15 s from the live notification, or skipped.
- **Auto-advance** (`autoAdvance`, default on; forced on when locked): when all sets of the current exercise are done, wait 900 ms (3.5 s if RPE logging is on and last set lacks RPE) then jump to the next exercise with undone sets. When nothing is pending → auto-finish after 1.5 s (not for manual sessions, only when route is `session`).
- **Supersets**: `linkedNext` chain; ticking a set jumps to the next chain member with undone sets; rest starts when the chain wraps.
- **Lock**: `sessionLocked` disables back/gestures until hold-to-unlock (hardware back only gives a haptic).
- **Pause**: freezes elapsed and the remaining rest (`restFrozen`), cancels the OS alarm; resume re-arms.
- **Effort scale**: `logRpe` toggles per-set RPE; `effortScale` = `rpe` or `rir` (RIR displayed as `10 − rpe`).
- **Keep screen on** while a non-manual session is active (`keepScreenOn`).

### Data Used
`WorkoutSession/SessionExercise/SessionSet` (persisted under `live`, `liveStart`, `liveElapsed`, `livePaused` while unfinished); reads `sessions` history, `routines`, `exerciseRest`, `progressStep`, `autoWarmup`, `repsOnly*`, `modeOverride`.

### Related Components
`RestAlarm`, `Beeper`, `LiveWorkout` + `LiveNotifier.kt` ([§20](#20-alarms-reminders--live-notification)), `ScreenAwake`, wear shell ([§25](#25-wear-os)).

### Dependencies
`audioplayers`, `flutter_local_notifications`, `timezone`.

### Edge Cases
- Removing the last exercise discards the session (`removeSessionExercise` → `discardSession`).
- Reordering clears `linkedNext` around moved items.
- `addExerciseToSession` refuses duplicates.
- If the app returns from background, `syncRest()` re-arms timers from the persisted `restEndsAt`; if rest already elapsed it clears silently.
- `_finishWhenAllDone` is guarded by `route == 'session'`.
- Exercises removed from the catalog/custom list stay in the session (name/primary are snapshots) but cannot be saved into a routine (`_savable` filters unknown ids).

### Current Status
**Implemented.**

---

## 4. Finishing, summary, continue, save-as-routine

### Purpose
Turn a session into history and close the loop with feedback and reuse.

### User Flow
`finishSession` → summary view in the same route: volume, sets, duration, PR count, vs. previous session volume for the same exercises, headline text (`GymL10n.finishHeadline/finishBody` based on PRs/goal/streak), share (`showShareSheet(streak)`), sticker (`showStickerEditor`), "Continue workout" (`continueSession`), "Save as routine" / "Update routine" if the session changed a routine, and Done (`saveAndExit`). Awards celebrate afterwards (not while on `session` route).

### Implementation
`workout_state.dart` (`finishSession`, `_computeSummaryHighlights`, `continueSession`, `saveSessionAsRoutine`, `saveSessionIntoRoutine`, `sessionRoutineChanges`), `session_screen.dart`, `lib/l10n/l10n.dart` (headline extension).

### Business Rules
- Only **done** sets are logged. A `LoggedSession` is created only if at least one set is done; exercises without done sets are omitted.
- Date = `loggedAt ?? now`; `durationSec` = `_elapsedBefore` for manual sessions else `sessionElapsed`.
- Summary volume/sets count **working sets only**.
- PR count in the summary = number of exercises whose best estimated 1RM this session exceeds every earlier session's best (`bestOneRm`).
- `continueSession` removes the just-filed `LoggedSession` (`_filed`) from history and reopens the session.
- Saving into a routine adds new exercises with planned sets from the session and removes exercises the user dropped; per-set planned data (`PlannedSet`) is derived from the session sets.
- After finish: `persistNow()`, widgets refresh, reminder re-sync (skip today), `refreshAwards()`.

### Data Used
`fit.sessions` (append + sort by date), `routines`, `awards`.

### Edge Cases
Manual session + no done sets → nothing logged, `_filed = null`. `summaryVsLast` compares against the most recent earlier session sharing any exercise id.

### Current Status
**Implemented.**

---

## 5. History & editing logged data

### Purpose
Review, fix and manage past workouts.

### User Flow
Progress screen calendar/heatmap → `_DaySheet` for a date: day summary (`daySummary`), list of sessions, delete session, resume a logged session (`resumeLoggedSession`), edit exercise sets (reps/weight steppers, add/remove set, remove exercise), log a workout on that day.

### Implementation
`progress_screen.dart` (`_DaySheet` and editors ~L1266–1700), `stats_state.dart` (`deleteSession`, `deleteLoggedExercise`, `setLoggedReps`, `setLoggedWeight`, `addLoggedSet`, `removeLoggedSet`), `workout_state.dart` (`resumeLoggedSession`).

### Business Rules
- Removing the last set of an exercise removes the exercise; removing the last exercise removes the session.
- `resumeLoggedSession` removes the session from history and re-opens it as a live session with all sets pre-ticked (`manual` if it is not today).
- Edits preserve `kind`, `rpe`, `sec`, `km` (`LoggedSet.copyWith`, GM-05); a set added via `addLoggedSet` copies `kind/sec/km` from the last set but not RPE.

### Data Used
`LoggedSession/LoggedExercise/LoggedSet`.

### Related Components
`test/logged_edit_test.dart`, `test/continue_session_test.dart`.

### Current Status
**Implemented.**

---

## 6. Exercise library

### Purpose
Browse/search a large offline exercise catalogue with animated illustrations and instructions.

### User Flow
Tab "Exercises": search, filters (muscle, difficulty, equipment, favourites, "No kit", "Mine", "Archived"), grouped list by muscle; tap → `ExerciseDetailScreen` (animated 3-frame vector art, steps, similar exercises, next target, last performance, records, notes, rest/progression/warm-up/reps-only/mode toggles, stopwatch, favourite, archive, custom media).

### Implementation
`lib/catalog/exercise_catalog.dart` (`kExercises`: **552** entries; assets: 302 art files), `library_state.dart`, `services/exercise_match.dart` (`exerciseSearch`), `screens/exercises_screen.dart`, `exercise_detail_screen.dart`, `widgets/exercise_art.dart`, `exercise_preview.dart`.

### Business Rules
- Muscles (13): chest, shoulders, biceps, abdomen, obliques, quads, forearm (front); trapezius, back, triceps, glutes, hamstrings, calves (back) — `kMuscles`. Filter chips use 10 (`kFilterMuscles`).
- Equipment ids: Barbell, Dumbbell, Cable, Machine, Bodyweight, Weighted, Band, Kettlebell, Rings, Other. Difficulty: Beginner/Intermediate/Advanced.
- Search matches (a) English or localised name substring, (b) normalised token key (synonym map `db→dumbbell`, `rdl→romanian deadlift`, plural folding…), (c) aliases in `kExerciseAliases`.
- Sorted/grouped by `kMuscles` order; with a muscle filter, exercises whose primary matches come first, then secondary.
- Archive hides an exercise from the library, training pools and suggestions (`isArchived`); "Archived" filter shows only archived.
- `isNoKit(ex)` = Bodyweight and not in `kNeedsKit` (pull-up bars, rings, etc.).
- Art: `art` slug → `assets/art/<slug>.txt`, 3 SVG-path frames animated in a 1560 ms cycle; cache of 32 entries.
- Exercise names/steps are localised through `t.catalogName/catalogSteps` (es, it, zh only; other locales fall back to English). **Screens must call `exerciseName(e)`, never `e.name`, for display.**

### Data Used
`kExercises` (static), `customExercises`, `favorites`, `archived`, `exerciseMedia`, `videoMarks`, `modeOverride`, `notes`.

### Edge Cases
`activeExercise` falls back to the first catalogue entry if the id is unknown. Similar exercises = same primary muscle (first *n*).

### Current Status
**Implemented.** (README: "500+ exercises with animations" — actual 552.)

---

## 7. Custom exercises, tracking modes & media

### Purpose
Let users extend the catalogue and choose how each exercise is measured.

### User Flow
Create from the library or directly from a search with no result; edit name, primary muscle, equipment, difficulty, steps, mode. Attach a photo/GIF/video to *any* exercise (replaces the built-in art); video steps can be pinned to timestamps ("video step marks").

### Implementation
`library_state.dart` (`addCustomExercise`, `updateCustomExercise`, `deleteCustomExercise`, `setExerciseMode`, `attachExerciseMedia`, `clearExerciseMedia`, `setVideoMark`, `toggleRepsOnly`), `services/media_store.dart`, `widgets/exercise_media.dart`, `exercise_preview.dart`, `screens/exercise_detail_screen.dart`.

### Business Rules
- Custom id format: `c<microseconds>-<seq>`. Custom exercises have no `secondary`, no `art`, and are always allowed by Place filtering (`fitsHere` → `isCustom`).
- **Modes**: `''` weight×reps, `'cardio'` (km + time), `'time'` (hold seconds). Effective mode = `modeOverride[id]` (`'weight'` normalises to `''`) → custom exercise's own `mode` → `kExerciseModes[id]` → `''`. Built-ins with mode: running, cycling, rowing, plank holds, stretches, etc.
- **Reps-only** (`isRepsOnly`): explicit `repsOnly`/`repsOnlyOff` wins; otherwise a Bodyweight exercise is reps-only until any weighted set exists in history.
- Media file names are stored (not paths) in `exerciseMedia[id]`; replacing media deletes the old file and clears video marks.
- The background photo reuses the same store with the reserved id `'bg'` (`kBgPhotoId`).

### Data Used
`Exercise` (custom only is persisted, key `custom`), `exerciseMedia`, `videoMarks`, `modeOverride`.

### Edge Cases
See ARCHITECTURE R5 for what deletion leaves behind. Plan import can auto-create custom exercises (`_planExercise(create: true)`) when the plan item carries a muscle.

### Current Status
**Implemented.**

---

## 8. Places (equipment profiles)

### Purpose
Only offer exercises that fit the gear the user has; drive plate maths from a real plate inventory.

### User Flow
Profile/Preferences → Places: add preset (gym/home/outdoors) or custom, toggle equipment, set plate pairs per size and bar weight, choose the active place (tap again to deselect → "All"). Exercises screen shows an active-place chip.

### Implementation
`places_state.dart`, `models/place.dart`, `screens/places_screen.dart`.

### Business Rules
- `gearHere` = place equipment ∪ {Bodyweight}; no active place = everything.
- `fitsHere(ex)` = no active place, or gear contains equipment, or exercise is custom. Applied to library, train pools, recommendations, AI-plan prompt.
- Presets: gym = all equipment, home = Bodyweight/Dumbbell/Kettlebell/Band/Weighted, outdoors = Bodyweight/Band.
- Plate stock (`plates: Map<kg, pairs>`, pairs 1–20; keys matched within 0.05 kg) constrains `platesPerSide`; `bar` clamps 1–60 kg and overrides the default bar (20 kg / 45 lb).
- `alternativesHere` suggests same-muscle exercises that fit (favourites, then bodyweight first).

### Data Used
`fit.places`, `activePlaceId` (`place`).

### Edge Cases
Deleting the active place resets to none. Loading validates that `activePlaceId` still exists.

### Current Status
**Implemented.**

---

## 9. Routines, weekly plan & templates

### Purpose
Reusable workouts with optional per-set targets, scheduled on weekdays.

### User Flow
Routines screen: folders (groups), colours, duplicate, delete, open editor. Editor: add/remove/reorder exercises, set count, per-set plan (reps/weight/kind/time/distance), superset chain toggle, group, colour, day assignment (single, or multiple routines per day when "multi plan" is on). Templates sheet applies one of 8 built-in programs. Home shows today's routine.

### Implementation
`routines_state.dart`, `fit_state.dart (applyTemplate)`, `catalog/program_templates.dart` (Full Body, PPL, Upper/Lower, ABCD, ABCDE, StrongLifts 5×5, Starting Strength, "No Kit"), `screens/routines_screen.dart`, `routine_edit_screen.dart`, `widgets/routine_folder.dart`, `home_folder.dart`.

### Business Rules
- `weeklyPlan: Map<weekday(1=Mon..7=Sun), routineId>`; `planExtras[weekday]` = extra routine ids used only when `multiPlan`.
- `routineOn(day)` returns the *n-th* planned routine where n = number of sessions already logged that day (capped) — so a second workout the same day proposes the second routine.
- Deleting a routine removes it from the plan and promotes the first extra of any day left without a primary.
- `routineSets` = number of working planned sets, else `sets[ex]`, else 3 (cardio 1); `setRoutineSetCount` 1–12; planned sets up to 20.
- Template application: exercise names are resolved with `matchExercise` (unmatched skipped); identical days share one routine; weekdays are auto-assigned **only if the weekly plan was empty**; routines are grouped under the template name. Templates rely on aliases (e.g. "Barbell Squat" → "Barbell Full Squat").
- Duplicating copies exercises, sets, chains, plans, group, colour.
- Chains persist per exercise id; `chainsToNext` is false for the last exercise.

### Data Used
`Routine`, `PlannedSet`, `weeklyPlan`, `planExtras`, `multiPlan`.

### Edge Cases
Removing an exercise from a routine returns an undo closure (`removeRoutineExercise`). Routine ids: `r<micros>-<seq>`.

### Current Status
**Implemented.**

---

## 10. Plan import/export & "Routine with AI"

### Purpose
Move plans between people/tools, including LLMs, without any network access.

### User Flow
- AI screen: builds a prompt (`planRequestText`) containing the user's profile, weekly goal, recent activity, best lifts, the JSON format spec and the list of *available* exercise names for the active place; user copies/shares it, pastes it into any AI, and pastes the answer into `PlanImportSheet` (or shares a JSON file/text into the app via Android VIEW/SEND).
- Import sheet previews (`previewPlan`), optionally schedules the days, and applies (`applyPlan`). Routines can also be exported as JSON (`exportPlanJson`) or summary text (`planSummaryText`).

### Implementation
`services/plan_share.dart` (`parsePlan`, `PlanRoutine/PlanItem/PlanSet`), `fit_state.dart` (`planRequestText`, `importPlan`, `previewPlan`, `applyPlan`, `exportPlanJson`, `planSummaryText`, `_planExercise`, `_plannedFrom`), `screens/ai_plan_screen.dart`, `plan_import_sheet.dart`, `app_shell.dart` (`_offerIncoming`), `MainActivity.kt` (intent handling).

### Business Rules
- Parser is deliberately forgiving: accepts JSON in code fences or embedded in prose, lists/maps, multilingual key aliases (`exercises|ejercicios|…`, `sets|series`, `weight|peso|carga`…), week-based programs (`weeks[]` → groups "Program · Week N"), `unit: lb`, weekday names in several languages or numbers, CSV fallback.
- Export format: `{"gymmane":"plan","v":1,"unit":"kg","routines":[…]}`; weights always kg; set `type` names `normal|warmup|drop|failure|restpause`; `custom{}` block carries custom exercises.
- Apply: exercises resolved by id, else by name (`matchExercise`), else created as custom **only if** the item has a `muscle`; duplicates within a routine dropped; existing identical routine (same name, group, exercise list) is reused, not duplicated; `restSec` only sets a per-exercise rest if none exists; ≤ 20 sets per exercise.
- Import is rejected from the incoming-share path unless onboarded and not mid-session.

### Data Used
`routines`, `customExercises`, `exerciseRest`, `weeklyPlan`.

### Edge Cases
`parsePlan` returns an empty list for unrecognised input (`readable:false`). Missed names are reported to the user.

### Current Status
**Implemented** (copy/paste flow; no LLM integration exists).

---

## 11. Progress & statistics

### Purpose
Show training consistency and load, computed only from logged data.

### User Flow
Home: focus card, week strip with check-ins, today's routine, weekly numbers, recommended exercises, photo-due card, folders (routines/tools/notes), snapshots. Progress: weekly goal ring, streak, 30-day cumulative volume chart with % change, activity heatmap (84 days, 4 levels, selectable colour tone), all-time totals (sessions / sets / time), muscle-split and radar cards, records, strength curves, bodyweight, and entry points to measures and the photo timeline. Profile: level, this-year sessions per month chart, best month, months trained, lifted volume, all-time trained time / sets / lifted, medals.

### Implementation
`stats_state.dart`, `fit_core.dart` (`heatLevel`, `kHeatmapDays = 84`), `screens/home_screen.dart`, `progress_screen.dart`, `widgets/charts.dart`.

### Business Rules
- Volume of a set = `reps × weight` (kg); **warm-ups excluded** everywhere via `workingSets/counts`.
- Weekly window starts on `weekStartDay` (Mon/Sat/Sun). `daysDoneThisWeek` counts days with a session **or** a check-in; `goalPct = daysDone/weeklyTarget`, clamped 0–100; `weeklyTarget` = profile goal (0→4).
- **Streak** (`currentStreak`): consecutive trained/checked-in days ending today (or yesterday if today is empty); days without training are *skipped* only if a weekly plan exists and that weekday is not scheduled (rest days don't break the streak).
- Heatmap load per day = max(1, set count) per session (+1 for check-in), normalised to the max in range → levels 0–4 via `heatLevel` thresholds .25/.5/.75.
- `volumeChangePct` = last 30 days vs the previous 30 (null if previous is 0).
- `trainedSpan`, `liftedSpan` format all-time time/volume with unit-aware units (Profile + share card).
- Getters with no UI caller in `lib/` outside `stats_state.dart` (dead-code candidates, **Unknown** whether intentional): `sessionsByWeekday`, `busiestWeekday`, `averageSession`.
- Manual check-ins are only allowed for today or earlier days of the week and only on days without a session.
- Habit detection (`usualWeekdays`, `usualStartMinute`) looks at the last 120 days.

### Data Used
`sessions`, `checkins`, `weeklyPlan`, `profile.weeklyGoal`, `units`.

### Edge Cases
No sessions → most getters return zero/empty; `busiestWeekday` returns 0 on ties. Stats are recomputed on every access (no caching) — see performance notes in DEVELOPMENT_GUIDELINES §12.

### Current Status
**Implemented.**

---

## 12. Personal records & strength curves

### Purpose
Best performances per exercise and progress of estimated 1RM.

### User Flow
Records list on Progress (`_PrCard`), per-exercise record on exercise detail, "strength" card with an exercise picker showing an e1RM curve, PR count in session summary and "PRs this week".

### Implementation
`workout.dart` (`LoggedSet.oneRm`, `rpePercent`, `PrKind`), `stats_state.dart` (`_record`, `personalRecords`, `exerciseRecord`, `prsThisWeek`, `trackedExercises`, `oneRmSeries`, `recordLabel`), `progress_screen.dart`.

### Business Rules
- **e1RM** = `weight × (1 + reps/30)` (Epley) — unless an RPE (6–10) and reps 1–12 are logged, then `weight / rpePercent` from a 31-entry table (`_rpeTable`, step 0.5 RPE). `reps ≤ 0 → 0`.
- PR kind per exercise = first of `weight, distance, time, reps` with a positive best among *working* sets; record list sorted by kind then (for weight) by e1RM desc.
- `prsThisWeek` counts exercises whose all-time best score (e1RM for weight kind) was achieved this week.
- `trackedExercises` = exercises with ≥ 2 sessions having top weight > 0; `activeStrengthId` defaults to the most-logged.
- Warm-up sets never create records (`test/audit_test.dart`).
- Calculator `rmResult` (tools) uses plain Epley without RPE.

### Data Used
`sessions`.

### Edge Cases
Cardio/time exercises produce distance/time PRs. Imported unknown exercises use ids `imp:<slug>`.

### Current Status
**Implemented.**

---

## 13. Muscle heat, recovery, radar & daily focus

### Purpose
Visualise which muscles were trained, how recovered they are, and suggest what to train.

### User Flow
Progress "muscle map" card (front/back body, heat tone selectable, 7/30-day windows) and radar; Home "focus" card (Push/Pull/Legs suggestion); recommended exercises list; timeline "body" mode.

### Implementation
`stats_state.dart` (`muscleSetsOver`, `muscleHeatOver/Between`, `muscleFatigue`, `muscleRecovery`, `overallRecovery`, `hoursUntilRecovered`, `stillRecovering`, `neglectedMuscles`, `muscleSplit`, `suggestedFocus`, `recommendedExercises`), `widgets/body_map.dart`, `muscle_radar.dart`, `catalog/body_svg.dart`.

### Business Rules
- Sets per muscle: primary muscle gets 1 per working set, each secondary gets 0.5. Target = `12 sets / 7 days` scaled to the window (`weeklySetTarget`); heat = sets/target clamped 0–1.
- **Muscle split** (last 30 days): percentage of *volume* by group (Chest, Back(+traps), Legs, Shoulders, Arms, Core); zero-percent groups hidden.
- **Recovery model**: exponential decay of per-set "effort" (`(rpe−5)/4` clamped .4–1.3 when RPE logged; failure sets 1.2; else 1) with time constant `τ = recoveryHours/3` (36–72 h per muscle); lookback 8 days; fully fatigued at 8 units. Recovered when fatigue ≤ 20% of full.
- `neglectedMuscles(days)`: muscles under one third of the window target (max 3).
- **Focus**: push/pull/legs rotation from the last session's dominant family; if the user habitually trains a family on today's weekday (≥ 2 sessions in 120 days) and it wasn't just done, that wins (`familyOnWeekday`).
- Body hit-testing uses the SVG paths (`muscleAt`); heat colours from ramps `ember|green|blue|mono` by theme luminance.

### Data Used
`sessions`, exercise `secondary` lists from the catalogue (custom exercises have none).

### Edge Cases
Custom exercises contribute only to their primary muscle. Legacy `primary='other'` (imports) is not in `kMuscles`.

### Current Status
**Implemented.**

---

## 14. Bodyweight & body measurements

### Purpose
Track weight and ten circumference/body-fat metrics with per-metric curves.

### User Flow
Progress → log bodyweight sheet (ruler picker), history with delete; Measures screen: pick a metric (neck, shoulders, chest, arm, forearm, waist, hips, thigh, calf, body fat %), add value, see latest/change/sparkline, delete entries.

### Implementation
`stats_state.dart` (`addBodyweight`, `deleteBodyweight`, `latestBodyweight`), `measures_state.dart`, `models/measure.dart`, `screens/measures_screen.dart`, `progress_screen.dart`, `widgets/body_rulers.dart`.

### Business Rules
- Bodyweight entries stored in kg; adding/deleting updates `profile.weightKg` to the latest and reseeds calculators. Multiple entries per day are allowed.
- Measures stored in **cm** (or % for `bodyfat`); unit toggle: `units == 'lb'` ⇒ inches. One value per key per day (adding replaces the same-day entry). Value must be > 0 and key in `kMeasureKeys`.
- `heightLabel` renders feet-inches in imperial.

### Data Used
`bodyweight`, `measures`, `profile`.

### Edge Cases
Unit switch is display-only; stored numbers never change. Changing `units` to lb also switches distance to miles and lengths to inches (single flag).

### Current Status
**Implemented.**

---

## 15. Progress photo timeline & compare

### Purpose
Photo log of the body (front/side/back) with optional reminders and side-by-side comparison.

### User Flow
Timeline screen: add photo per pose for a date (camera/gallery), entries by date, per-entry weight (auto-filled from latest bodyweight) and note, delete; **interval reminder** (off/15/30/60/90 days); "Body" toggle shows the muscle-map timeline (`bodyWindows`) instead of photos. Compare screen: pick two entries and a pose; weight delta and days between shown; export a compare card.

### Implementation
`timeline_state.dart`, `models/progress_shot.dart`, `screens/timeline_screen.dart`, `compare_screen.dart`, `services/progress_reminder.dart`, `widgets/share_cards.dart`.

### Business Rules
- One `ProgressEntry` per calendar day (`entryOn`); poses restricted to `kPoses`; replacing a pose deletes the previous file; removing the last pose deletes the entry.
- `nextPhotoDue` = last entry date + interval; a notification is scheduled for 10:00 that day (only if in the future).
- `bodyWindows`: up to 12 windows of `photoIntervalDays` (30 if 0) walking back from today, showing only windows with sessions (always the first).
- Comparison defaults to first vs last entry.

### Data Used
`shots`, `photoIntervalDays` (`photoEvery`), `bodyTimeline` (`bodyTl`), media files.

### Dependencies
`image_picker`, `flutter_local_notifications`.

### Edge Cases
Entries whose all photos vanish during restore are dropped (`_loadShots(restored:)`).

### Current Status
**Implemented.**

---

## 16. Journal (notes) & snapshots (moments)

### Purpose
Free-text training journal on a calendar (optionally attached to an exercise), and a photo/video "snapshot" strip.

### User Flow
Notes screen: month calendar with kind dots, day list or "all" list, filter by kind, scope to an exercise (opened from exercise detail); Note editor: kind (`note`, `plan`, `done`, `pain`), date, exercise, text (first line = title), media (photos/videos). Snapshots: add photo (camera/gallery) with note; view/delete; shown on Profile and Home.

### Implementation
`notes_state.dart`, `moments_state.dart`, `models/note.dart`, `screens/notes_screen.dart`, `note_edit_screen.dart`, `moments_screen.dart`, `widgets/note_kit.dart`.

### Business Rules
- `saveNote` ignores empty text, normalises `date` to midnight, removes media files dropped in the edit, sets the calendar to the note day.
- `deleteNote` deletes its media files. `deleteMoment` deletes by file name and file.
- Legacy note storages (`exNotes` map, `notes` map) are converted on load.

### Data Used
`notes`, `moments`, media files.

### Current Status
**Implemented.**

---

## 17. Awards & gamification

### Purpose
Motivational medals; can be turned off entirely.

### User Flow
20 medals (bronze→diamond, some with gems) shown on Profile shelf and Awards screen with progress; a full-screen celebration (with a shader-rendered medal and save-image action) appears after an award is earned, delayed 4 s (first) / 6 s (subsequent), never during a session.

### Implementation
`awards_state.dart`, `catalog/awards.dart`, `catalog/medal_look.dart`, `widgets/medal.dart`, `medal_shelf.dart`, `award_celebration.dart`, `screens/awards_screen.dart`, assets `assets/badges/*`.

### Business Rules
Thresholds: firstStep (onboarded), firstWorkout(1 session), firstRoutine(1 routine), firstRecord(1 PR entry); streak 3/7/30/100; workouts 10/50/100/365; volume 1 t/10 t/100 t (kg-based: 1000/10000/100000); sets 100/1000; hours 10/50/100. `refreshAwards` is called on finish, routine creation, check-in, onboarding. Earned awards are permanent (never revoked). With gamification off, newly earned awards are silently marked seen. On load, `refreshAwards(silent: true)` runs and then **every earned-but-unseen award is queued** (`pendingAwards.addAll(unseenAwards)`) when gamification is on — so awards first satisfied by imported/restored data are celebrated on next launch, one at a time.

### Data Used
`awards` (id → earned timestamp), `awardsSeen`.

### Edge Cases
`firstRecord` uses `personalRecords.length`. Streak awards depend on `currentStreak` at evaluation time.

### Current Status
**Implemented.**

---

## 18. Calculators (Tools)

### Purpose
Six offline fitness calculators.

### User Flow
Tools screen → detail screen per tool with steppers/rulers; a result card.

### Implementation
`tools_state.dart`, `screens/tools_screen.dart`, `tool_detail_screen.dart`, `catalog/exercise_catalog.dart` (`kToolMeta`).

### Business Rules
| Tool | Formula |
|---|---|
| 1RM (`rm`) | `w × (1 + reps/30)` (Epley), 1 decimal |
| BMI (`bmi`) | `kg / (m²)`; categories <18.5, <25, <30, else |
| Calories (`cal`) | Mifflin–St Jeor BMR × activity (1.2/1.375/1.55/1.725); macros 30% protein / 40% carbs / 30% fat (÷4/÷4/÷9) |
| Body fat (`bf`) | US-Navy log10 formula (male: waist−neck; female: waist+hip−neck), clamped 3–50% |
| Plates (`plate`) | greedy per-side breakdown using standard sizes (kg 25…1.25 / lb 45…2.5) or the active Place's plate stock; `loadableTotal` |
| Warm-up (`warmup`) | 40%×10, 60%×5, 80%×3, 90%×1 rounded to 2.5 kg / 5 lb |

Inputs are seeded from the profile; plate hint (`plateHint`) is shown in the session for Barbell exercises when target > default bar.

### Current Status
**Implemented.**

---

## 19. Settings & preferences

### Purpose
Configure appearance, behaviour, data and reminders.

### User Flow
Preferences screen (route `preferences`), sections including: language (picker lists `appLanguages`, i.e. all 17 registered locales), theme (system/dark/light), units (kg/lb), first weekday (Mon/Sat/Sun), default rest, alarm style (loud/quiet/vibrate), custom alarm sound (≤ 15 s), keep screen on, start countdown, auto-advance, RPE/RIR logging, gamification switch, home cards (focus / recommended), exercise demo size (large/small/off), background (none/dots/grid/photo + dim 0.3–0.85), heat tone, weekly goal, reminders, photo interval, widgets pinning, export/import/backup/reset, links (repo, Ko-fi), About.

### Implementation
`screens/settings_screen.dart`, `settings_state.dart`.

### Business Rules
- Language: first launch adopts the device language (`_adoptDeviceLanguage` → `resolveLanguage`, incl. `zh_Hant` for Hant/TW/HK/MO); unknown → `en`.
- Rest seconds: `v ≤ 0 → 0`, else clamp 15–600.
- Notification permission: asked lazily when the first rest starts; re-asked at most every 3 days (`_askAgainAfter`); a warning banner deep-links to system settings (`app_settings`).
- `setBgPattern('photo')` requires a stored background photo.

### Data Used
See DATA_MODEL §3 "Settings keys".

### Current Status
**Implemented.**

---

## 20. Alarms, reminders & live notification

### Purpose
Make rest end audibly even with the screen off; nudge training days and photo days; keep a lock-screen workout control.

### User Flow / Implementation
- **Rest alarm** (`RestAlarm`): at rest start schedules an OS notification (`AndroidScheduleMode.alarmClock`) and plays sound/vibration at zero; three styles (`loud` uses alarm audio usage + full-screen intent; `quiet` notification usage; `vibrate` no sound). While the app is foreground it shows an in-app notch toast (`AppShell._restOver`) instead of a system notification.
- **Train reminder** (`TrainReminder`): daily at chosen minute on planned weekdays (or, with "smart reminder", on habitual weekdays at the habitual start time rounded to 15 min); up to 14 upcoming alerts within 28 days; skips today if already trained. Rescheduled after finishing a session, plan changes, setting changes and app start.
- **Photo reminder**: see §15.
- **Live notification** (Android): `LiveWorkout.sync()` mirrors the active, non-manual session (exercise, next set, rest countdown, progress segments, next exercise) with action buttons *Done set / +15 s / Skip rest / Next / Pause·Resume*.

### Business Rules
Exact alarms are used only when `canScheduleExactNotifications()`; else inexact. Manual/complete/absent sessions end the live notification. iOS live-activity path is dead code without an iOS project.

### Dependencies
`flutter_local_notifications`, `timezone`, `audioplayers`, Kotlin `LiveNotifier`.

### Edge Cases
Notification text uses the global `t` at schedule time. `setLanguage` does not reschedule; already-scheduled train/photo reminders keep the old language until the next resync (`main()` re-syncs on every launch; sessions finished, plan/reminder setting changes also call `syncTrainReminder`).

### Current Status
**Implemented (Android).** iOS branches: **Planned/unreachable.**

---

## 21. Home-screen widgets

### Purpose
Glanceable stats on the Android launcher.

### Implementation
Five providers: **Today**, **Week**, **Heatmap**, **Stats**, **Body**. Dart renders `HeatmapWidgetView/StatsWidgetView/BodyWidgetView/TodayWidgetView/WeekWidgetView` (`lib/widgets/home_widget_views.dart`) to PNGs for day and night themes via `HomeWidgetBridge.update()`, called after any data change (`fit.onWidgetsShouldUpdate`) and on app resume. Kotlin providers show the PNG; Today/Week reschedule at midnight and choose plan/rest/idle variants using strings written by Dart (`today_week`, `today_stamp`, `week_done`, …). Pinning is requested from Settings (`_addWidget`).

### Business Rules
Theme images are rendered twice: day = dark palette only if `themePref == 'dark'` else light; night = light palette only if `themePref == 'light'` else dark. So `system` → light image in day mode and dark image in night mode; `dark`/`light` force one palette (Android picks via `layout`/`layout-night`). Heatmap uses 182 days; Body uses a 7-day heat window.

### Edge Cases
If rendering throws, `update()` logs and returns (widgets keep their previous image).

### Current Status
**Implemented (Android).**

---

## 22. Backup, export & import

### Purpose
Full data portability. Formats and internals are in [DATA_MODEL.md](DATA_MODEL.md) §7–8.

### User Flow
Preferences → *Export CSV* (sessions), *Backup* (ZIP with media, shared via system sheet), *Import backup* (ZIP or JSON, file picker; confirmation dialog first), *Import from another app* (CSV / ZIP-with-weights / FitNotes SQLite / openGym JSON; asks kg/lb when ambiguous), *Delete everything* (confirmation).

### Business Rules
- Import from apps merges (de-duplicates) — **backup restore replaces** everything.
- Detection order: openGym JSON → Hevy → Strong → Lyfta → Fitbod → GymMane CSV → FitNotes → generic → bodyweight-only CSVs.
- Warm-up rows/sets are skipped in imports; sets with reps ≤ 0 skipped; imported sets keep only reps, weight and RPE (no set kind/time/distance).
- Unknown exercise names become `imp:<slug>` exercises with a guessed muscle (`guessMuscle`) or `other`.
- Importing weights updates `profile.weightKg` to the latest entry.

### Current Status
**Implemented.**

---

## 23. Sharing (stickers & cards)

### Purpose
Share progress as images without any network.

### User Flow
Session summary → Sticker editor: choose photo (camera/gallery), pan/scale/rotate a stat sticker (colour swatches), export at 1080 px via `share_plus` or save to gallery (`gymmane/gallery`). Share sheet cards: `streak`, `body`, `compare` (`ShareKind`). Award celebration can save the medal image.

### Implementation
`screens/sticker_screen.dart`, `share_sheet.dart`, `widgets/share_cards.dart`, `services/gallery.dart`, `MainActivity.savePng`.

### Current Status
**Implemented.**

---

## 24. Localization

### Purpose
UI and (partially) exercise content in many languages.

### Implementation & Rules
- ARB files (17): ar, de, en, es, fa, fr, it, ja, ko, nl, pl, pt, ru, tr, uk, zh, zh_Hant (`lib/l10n/app_*.arb`). Generated `AppLocalizations` is committed; `fa` is now registered (17 locales after GM-01).
- Missing keys in non-English ARBs are tolerated by Flutter (fallback to English) but `test/i18n_test.dart` requires key parity across shipped languages.
- Exercise names/steps: full maps only for **es, it, zh** (`catalog_*.dart`, registered in `l10n.dart`). `zh_Hant` does not reuse the `zh` maps (exact-code lookup) → English fallback.
- Weekday/month names come from `intl` symbols; never hard-code.
- RTL: Arabic supported by Flutter directionality; nav bar forced LTR.
- Plurals via ICU in ARB.

### Current Status
**Implemented** for 17 locales (Persian registered in GM-01, RTL not device-verified); exercise catalogue translation **Partially implemented** (3 languages).

---

## 25. Wear OS

### Purpose
Standalone workout control on a watch.

### User Flow
On watch devices (`FEATURE_WATCH`) `main()` launches `WearApp` → `WearShell`: paged UI with clock, home (today, weekly ring, streak), routines, session (sets, rest via `TimerPanel`, pause, finish), settings (rest, stepper controls). Rotary crown scrolls (`gymmane/rotary`), screen dims after 15 s idle during a session (`WearDim`, `gymmane/screen dim`).

### Implementation
`lib/wear/wear_app.dart`, `wear_shell.dart` (~41 KB), `test/wear_test.dart`, Kotlin rotary + `isWatch`. Shares `fit`, storage and notifications with the phone build; theme forced dark.

### Edge Cases
The phone-only side effects (`LiveWorkout.sync`, home widgets) are skipped on watch. CI no longer smoke-tests Wear (commit `717a85d`).

### Current Status
**Partially implemented** (README: "In progress").

---

## 26. Planned / not implemented

| Item | Evidence | Status |
|---|---|---|
| iOS app | README "In progress"; Dart branches exist; **no `ios/` project** | Planned |
| Desktop | README "Planned" | Planned |
| Weblate/Crowdin translation pipeline | `crowdin.yml` present; TRANSLATING.md says none | Unknown |
| Cloud sync / accounts / remote AI | Forbidden by project rules | Not planned (by policy) |
| Any experimental feature flag | none found | — |
| Goal-based onboarding, plan generator, exercise taxonomy/impact UI, plan-aware streak | Roadmap cards GM-30…GM-73 (see PROJECT_CONTEXT §10) | Planned |

---

## 27. Features present in code but missing from, or thin in, the README

Exercise **archive**; **video step marks** and exercise preview; per-exercise **rest time**, **progression step** (auto weight bump), **auto warm-up**, **reps-only** and **tracking-mode override**; per-exercise **notes**; **timed-set hold timer** with lead-in and beeps; **session lock** (hold-to-unlock), **pause/park** with pill; **start countdown**; **multi-routine days** (`multiPlan`); **first day of week** choice; **smart reminder** (habit-based); **muscle recovery** model & neglected muscles; **exercise recommendations**; **Fitbod** import and **generic CSV** with multilingual headers; **plan import via Android share/open**; **stopwatch card**; **background photo/pattern/dim** and **heat tone**; **home cards toggles**; **profile banner/badge/handle**; **Wear OS UI**; RIR scale; `restPause` set type; local notification permission banner.

---

## Unknown / Not verified

- Rendering when `bgPattern == 'photo'` but the photo file is missing after `resetAllData`.
- Behaviour on Wear OS hardware, iOS, and Android versions other than the code paths read.
- Correctness of the Android 16 `ProgressStyle` notification branch (no test covers native code).
