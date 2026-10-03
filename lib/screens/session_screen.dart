import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../l10n/l10n.dart';
import '../models/exercise.dart';
import '../models/live_session.dart';
import '../models/workout.dart';
import '../state/fit_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import '../widgets/celebration.dart';
import '../widgets/dialogs.dart';
import '../widgets/entrance.dart';
import '../widgets/exercise_card.dart';
import '../widgets/exercise_media.dart';
import '../widgets/exercise_preview.dart';
import '../widgets/glass.dart';
import '../widgets/liquid_notch.dart';
import '../widgets/set_kind.dart';
import '../widgets/share_cards.dart';
import '../widgets/rest_announcer.dart';
import '../widgets/rolling_text.dart';
import '../widgets/ruler_picker.dart';
import '../widgets/svg_icon.dart';
import '../widgets/timer_panel.dart';
import '../widgets/ui_kit.dart';
import 'exercises_screen.dart';
import 'tool_detail_screen.dart';
import 'share_sheet.dart';
import 'sticker_screen.dart';

part 'session/set_rows.dart';
part 'session/live_bar.dart';
part 'session/kind_sheet.dart';
part 'session/controls.dart';
part 'session/summary.dart';
part 'session/sheets.dart';
part 'session/stage.dart';

class SessionScreen extends StatelessWidget {
  const SessionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gc = context.gc;
    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        clipBehavior: Clip.none,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: fit.isSessionComplete ? _complete(context, gc) : _active(context, gc),
      ),
    );
  }

  Widget _active(BuildContext context, GymColors gc) {
    final s = fit.session!;
    final ex = fit.currentExercise;
    final exIdx = s.currentIndex;
    final def = fit.exerciseById(ex?.id ?? '') ?? fit.allExercises.first;
    final repsOnly = ex != null && fit.isRepsOnly(ex.id);
    final locked = fit.sessionLocked && !s.manual;
    final demo = ex == null ? 'off' : fit.demoSize;
    final mode = ex == null ? '' : fit.modeOf(ex.id);
    final second = _secondAction(gc, ex, exIdx, mode, repsOnly);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const RestAnnouncer(),
        s.manual ? _manualBar(gc, s) : _liveBar(gc, locked),
        const SizedBox(height: 14),
        _progressStrip(context, gc, s, locked),
        const SizedBox(height: 16),
        _ExerciseStage(
          index: exIdx,
          haptic: true,
          autoMoves: fit.autoMoves,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (demo == 'small')
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _exerciseHeader(context, gc, ex)),
                    const SizedBox(width: 14),
                    SizedBox(
                      width: 104,
                      child: _guard(
                        locked,
                        GestureDetector(
                          onTap: () => showExercisePreview(context, def),
                          child: ExerciseMedia(ex: def, height: 104, radius: 18, live: true),
                        ),
                      ),
                    ),
                  ],
                )
              else
                _exerciseHeader(context, gc, ex),
              if (demo == 'large') ...[
                const SizedBox(height: 14),
                _guard(
                  locked,
                  GestureDetector(
                    onTap: () => showExercisePreview(context, def),
                    child: ExerciseMedia(ex: def, height: 170, live: true),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 18),
        AnimatedSize(
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: fit.holding && fit.holdEx == exIdx
              ? Padding(padding: const EdgeInsets.only(bottom: 16), child: _holdCard(gc))
              : s.restRemaining != null
                  ? Padding(padding: const EdgeInsets.only(bottom: 16), child: _restCard(gc, s))
                  : const SizedBox(width: double.infinity),
        ),
        _ExerciseStage(
          index: exIdx,
          child: Container(
            padding: const EdgeInsets.fromLTRB(_cardPad, 16, _cardPad, 16),
            decoration: BoxDecoration(
              color: gc.bgRaised,
              borderRadius: BorderRadius.circular(GymRadius.lg),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(_rowPad, 0, _rowPad, 10),
                  child: _setsHeader(gc, mode, repsOnly),
                ),
                for (int j = 0; j < (ex?.sets.length ?? 0); j++) ...[
                  _swipeToDelete(context, gc, exIdx, j, ex!.sets[j], locked,
                      _setRow(gc, exIdx, j, ex.sets[j], repsOnly, locked)),
                ],
                if (!repsOnly && mode.isEmpty && ex != null) _guard(locked, _plateRow(context, gc, ex)),
                const SizedBox(height: 10),
                _guard(
                  locked,
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: _rowPad),
                    child: Row(
                      children: [
                        Expanded(child: _dashedAction(gc, t.addSet, () => fit.addSet(exIdx))),
                        if (second != null) ...[
                          const SizedBox(width: 8),
                          Expanded(child: second),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 22),
        _guard(
          locked,
          Row(
          children: [
            Expanded(
              child: GhostButton(
                label: t.addExercise,
                icon: PhosphorIconsRegular.plus,
                onTap: () => showAddToSessionSheet(context),
              ),
            ),
            const SizedBox(width: 10),
            Semantics(
              button: true,
              label: t.addNote,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => fit.openNoteEditor(exerciseId: ex?.id ?? ''),
                child: Container(
                  width: 46,
                  height: 46,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(GymRadius.md),
                  ),
                  child: Icon(PhosphorIconsRegular.notePencil, size: 17, color: gc.ember),
                ),
              ),
            ),
          ],
          ),
        ),
        const SizedBox(height: 16),
        Row(children: [
          _circleBtn(gc, Ic.chevronLeft, fit.prevExercise, enabled: !locked && exIdx > 0),
          const SizedBox(width: 10),
          Expanded(child: _mainAction(gc, ex, exIdx, s.exercises.length, locked)),
          const SizedBox(width: 10),
          _circleBtn(gc, Ic.chevronRightBold, fit.nextExercise,
              enabled: !locked && exIdx < s.exercises.length - 1),
        ]),
        const SizedBox(height: 10),
        _guard(
          locked,
          Wrap(alignment: WrapAlignment.center, crossAxisAlignment: WrapCrossAlignment.center, children: [
            if (ex != null && s.exercises.length > 1) ...[
              _textAction(gc, t.dropExerciseAction,
                  () => _confirmDrop(context, exIdx, t.catalogName(ex.id, ex.name))),
              Container(width: 1, height: 12, color: gc.border),
            ],
            _textAction(gc, t.finishSession, fit.finishSession),
          ]),
        ),
      ],
    );
  }

  Widget? _secondAction(GymColors gc, SessionExercise? ex, int exIdx, String mode, bool repsOnly) {
    if (mode == 'cardio') return null;
    if (ex != null && repsOnly) {
      return _dashedAction(gc, t.addWeightAction.toUpperCase(), () => fit.toggleRepsOnly(ex.id));
    }
    if (mode.isNotEmpty) return null;
    if (fit.hasWarmup(exIdx)) {
      return _dashedAction(gc, t.removeWarmup.toUpperCase(), () => fit.removeWarmupSets(exIdx));
    }
    return _dashedAction(gc, t.addWarmup, () => fit.addWarmupSets(exIdx));
  }

  Widget _exerciseHeader(BuildContext context, GymColors gc, SessionExercise? ex) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (fit.inSuperset) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: gc.bgRaised2, borderRadius: BorderRadius.circular(100)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(PhosphorIconsRegular.link, size: 11, color: gc.brass),
              const SizedBox(width: 5),
              Text(t.superset,
                  style: AppTheme.f(10.5, weight: FontWeight.w700, color: gc.brass, letterSpacing: 0.5)),
            ]),
          ),
          const SizedBox(height: 8),
        ],
        Text(ex == null ? '' : t.catalogName(ex.id, ex.name),
            style: AppTheme.f(26, weight: FontWeight.w700, color: gc.text)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(color: gc.emberSoft, borderRadius: BorderRadius.circular(100)),
          child: Text(muscleLabel(ex?.primary ?? ''),
              style: AppTheme.f(12, weight: FontWeight.w600, color: gc.ember)),
        ),
        if (ex != null && fit.lastSummaryFor(ex.id) != null) ...[
          const SizedBox(height: 10),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => showExerciseHistorySheet(context, ex.id),
            child: Row(children: [
              Text(t.last,
                  style: AppTheme.f(11, weight: FontWeight.w600, color: gc.textTertiary, letterSpacing: 0.4)),
              const SizedBox(width: 8),
              Flexible(
                child: Text(fit.lastSummaryFor(ex.id)!,
                    style: AppTheme.f(12, weight: FontWeight.w600, color: gc.textSecondary)),
              ),
              const SizedBox(width: 4),
              Icon(PhosphorIconsRegular.caretRight, size: 11, color: gc.textTertiary),
            ]),
          ),
          if (fit.nextTargetLabel(ex.id) != null) _nextRow(gc, ex.id),
        ],
      ],
    );
  }

  Widget _progressStrip(BuildContext context, GymColors gc, WorkoutSession s, bool locked) {
    final n = s.exercises.length;
    return Semantics(
      button: true,
      label: t.workoutOverview,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: locked ? null : () => showSessionOverview(context),
        child: MinTarget(
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
              Expanded(
                child: Text(fit.sessionProgressLabel,
                    style: AppTheme.f(12, weight: FontWeight.w600, color: gc.textSecondary, letterSpacing: 0.4)),
              ),
              if (!locked)
                Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(PhosphorIconsRegular.listBullets, size: 14, color: gc.textSecondary),
                  const SizedBox(width: 5),
                  Text(t.allExercisesShort,
                      style: AppTheme.f(11.5, weight: FontWeight.w600, color: gc.textSecondary)),
                ]),
            ]),
            const SizedBox(height: 9),
            Row(children: [
              for (var i = 0; i < n; i++) ...[
                if (i > 0) SizedBox(width: n > 12 ? 2 : 4),
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 320),
                    curve: Curves.easeOutCubic,
                    height: i == s.currentIndex ? 6 : 4,
                    decoration: BoxDecoration(
                      color: _stripColor(gc, s, i),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ],
            ]),
          ],
        ),
        ),
      ),
    );
  }

  Color _stripColor(GymColors gc, WorkoutSession s, int i) {
    final sets = s.exercises[i].sets;
    final done = sets.isNotEmpty && sets.every((st) => st.done);
    if (i == s.currentIndex) return done ? gc.sage : gc.ember;
    if (done) return gc.sage;
    if (sets.any((st) => st.done)) return Color.lerp(gc.bgRaised2, gc.sage, 0.45)!;
    return gc.bgRaised2;
  }

  Widget _swipeToDelete(BuildContext context, GymColors gc, int exIdx, int j, SessionSet st,
      bool locked, Widget child) {
    if (locked) return child;
    return Dismissible(
      key: ObjectKey(st),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 2),
        padding: const EdgeInsets.only(right: 18),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: gc.danger.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(GymRadius.md),
        ),
        child: Icon(PhosphorIconsRegular.trash, size: 18, color: gc.danger),
      ),
      onDismissed: (_) => _deleteSet(context, exIdx, j),
      child: child,
    );
  }

  void _deleteSet(BuildContext context, int exIdx, int j) {
    final gone = fit.removeSet(exIdx, j);
    if (gone == null) return;
    HapticFeedback.mediumImpact();
    showNotchToast(
      context,
      t.setDeleted,
      icon: PhosphorIconsFill.trash,
      accent: context.gc.danger,
      action: t.undo,
      onTap: () => fit.insertSet(exIdx, j, gone),
      duration: const Duration(milliseconds: 3200),
    );
  }

  Widget _guard(bool locked, Widget child) => _LockGuard(locked: locked, child: child);

  void _setLock(bool on) {
    if (fit.sessionLocked == on) return;
    HapticFeedback.mediumImpact();
    fit.toggleSessionLock();
  }

  Widget _nextRow(GymColors gc, String id) {
    final target = fit.nextTarget(id)!;
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.nextTime,
              style: AppTheme.f(11, weight: FontWeight.w600, color: gc.brass, letterSpacing: 0.4)),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                text: fit.nextTargetLabel(id),
                style: AppTheme.f(12,
                    weight: FontWeight.w600, color: target.up ? gc.ember : gc.textSecondary),
                children: [
                  if (!target.up)
                    TextSpan(
                        text: ' · ${t.nextHold}',
                        style: AppTheme.f(11.5, weight: FontWeight.w400, color: gc.textTertiary)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDrop(BuildContext context, int exIdx, String name) async {
    final ok = await askConfirm(
      context,
      title: t.dropExercise,
      body: t.dropExerciseBody(name),
      confirmLabel: t.drop,
    );
    if (ok) fit.removeSessionExercise(exIdx);
  }

  static const _numCol = 32.0;
  static const _checkCol = 48.0;
  static const _gap = 4.0;
  static const _tightGap = 3.0;
  static const _effortCol = 36.0;
  static const _cardPad = 8.0;
  static const _rowPad = 8.0;






}
