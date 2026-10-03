part of '../session_screen.dart';

void showAddToSessionSheet(BuildContext context) {
  final gc = context.gc;
  final search = TextEditingController();
  showAppSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: gc.bgRaised,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(GymRadius.xxl))),
    builder: (sheetCtx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(sheetCtx).viewInsets.bottom),
      child: StatefulBuilder(
        builder: (sheetCtx, setSheet) {
          final q = search.text.trim();
          final list = q.isEmpty ? fit.sessionSuggestions() : fit.trainSearchResults(q);
          return SafeArea(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(sheetCtx).size.height * 0.82),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(t.addExercise,
                            style: AppTheme.f(15, weight: FontWeight.w700, color: gc.text, letterSpacing: 0.4)),
                        const SizedBox(height: 14),
                        SearchField(
                          controller: search,
                          hint: t.searchExercises,
                          color: gc.bgRaised2,
                          onChanged: (_) => setSheet(() {}),
                        ),
                        const SizedBox(height: 12),
                        Text(q.isEmpty ? t.suggested.toUpperCase() : t.results.toUpperCase(),
                            style: AppTheme.f(11,
                                weight: FontWeight.w700, color: gc.textTertiary, letterSpacing: 1.5)),
                      ],
                    ),
                  ),
                  Flexible(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
                      shrinkWrap: true,
                      children: [
                        if (list.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            child: Text(t.noMatches, style: AppTheme.f(13, weight: FontWeight.w500, color: gc.textSecondary)),
                          ),
                        for (final ex in list) _addRow(sheetCtx, gc, ex),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 18),
                    child: GhostButton(
                      label: t.newExercise,
                      icon: PhosphorIconsRegular.plus,
                      onTap: () {
                        Navigator.pop(sheetCtx);
                        showCreateExerciseSheet(context, initialName: q, onCreated: fit.addExerciseToSession);
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ),
  );
}

Widget _addRow(BuildContext sheetCtx, GymColors gc, Exercise ex) {
  final already = fit.inSession(ex.id);
  return Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: ExerciseCard(
      exercise: ex,
      dimmed: already,
      onTap: already
          ? null
          : () {
              fit.addExerciseToSession(ex.id);
              Navigator.pop(sheetCtx);
            },
      onLongPress: () => showExercisePreview(sheetCtx, ex),
      onThumbTap: () => showExercisePreview(sheetCtx, ex),
      trailing: Icon(already ? PhosphorIconsRegular.check : PhosphorIconsRegular.plus, size: 16, color: gc.textSecondary),
    ),
  );
}

void showSessionOverview(BuildContext context) {
  final gc = context.gc;
  showAppSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheet) => AnimatedBuilder(
      animation: fit,
      builder: (sheet, _) {
        final s = fit.session;
        if (s == null || s.complete) return const SizedBox.shrink();
        return Container(
          padding: sheetPad(sheet),
          constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(sheet).height * 0.86),
          decoration: BoxDecoration(
            color: gc.bgRaised,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(GymRadius.xxl)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SheetHandle(),
              const SizedBox(height: 18),
              Text(titleCase(t.workoutOverview),
                  style: AppTheme.f(20, weight: FontWeight.w800, color: gc.text)),
              const SizedBox(height: 4),
              Text('${t.exerciseCount(s.exercises.length)} · ${fit.elapsedLabel}',
                  style: AppTheme.f(12, weight: FontWeight.w500, color: gc.textSecondary)),
              const SizedBox(height: 16),
              Flexible(
                child: ReorderableListView.builder(
                  shrinkWrap: true,
                  buildDefaultDragHandles: false,
                  itemCount: s.exercises.length,
                  onReorder: fit.reorderSessionExercise,
                  proxyDecorator: (child, _, _) => Material(color: Colors.transparent, child: child),
                  itemBuilder: (context, i) => _overviewRow(sheet, gc, s, i),
                ),
              ),
              const SizedBox(height: 6),
              Text(t.dragToReorder,
                  textAlign: TextAlign.center,
                  style: AppTheme.f(11, weight: FontWeight.w500, color: gc.textTertiary)),
            ],
          ),
        );
      },
    ),
  );
}

Widget _overviewRow(BuildContext sheet, GymColors gc, WorkoutSession s, int i) {
  final e = s.exercises[i];
  final def = fit.exerciseById(e.id);
  final done = e.sets.where((st) => st.done).length;
  final all = e.sets.isNotEmpty && done == e.sets.length;
  final current = i == s.currentIndex;
  final linked = e.linkedNext || (i > 0 && s.exercises[i - 1].linkedNext);
  return Container(
    key: ObjectKey(e),
    margin: const EdgeInsets.only(bottom: 8),
    decoration: BoxDecoration(
      color: current ? gc.bgRaised2 : Colors.transparent,
      borderRadius: BorderRadius.circular(GymRadius.lg),
      border: Border.all(
          color: current ? gc.ember.withValues(alpha: 0.6) : gc.border.withValues(alpha: 0.6)),
    ),
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        fit.goToExercise(i);
        Navigator.of(sheet).pop();
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 4, 8),
        child: Row(children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: all ? gc.sage : (current ? gc.ember : gc.bgRaised2),
              shape: BoxShape.circle,
            ),
            child: all
                ? SvgPathIcon(Ic.checkBold, size: 12, color: Colors.white)
                : Text('${i + 1}',
                    style: AppTheme.f(11,
                        weight: FontWeight.w700, color: current ? gc.onEmber : gc.textSecondary)),
          ),
          const SizedBox(width: 10),
          if (def != null) ...[
            SizedBox(width: 40, child: ExerciseMedia(ex: def, height: 40, radius: 10, bordered: false)),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.catalogName(e.id, e.name),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.f(14, weight: FontWeight.w600, color: gc.text)),
                const SizedBox(height: 2),
                Row(children: [
                  Text(t.setsDoneOf(done, e.sets.length),
                      style: AppTheme.f(11,
                          weight: FontWeight.w500, color: all ? gc.sage : gc.textSecondary)),
                  if (current) ...[
                    Text(' · ', style: AppTheme.f(11, color: gc.textTertiary)),
                    Text(t.nowLabel,
                        style: AppTheme.f(11, weight: FontWeight.w700, color: gc.ember)),
                  ],
                  if (linked) ...[
                    const SizedBox(width: 6),
                    Icon(PhosphorIconsRegular.link, size: 12, color: gc.brass),
                  ],
                ]),
              ],
            ),
          ),
          ReorderableDragStartListener(
            index: i,
            child: SizedBox(
              width: 40,
              height: 44,
              child: Icon(PhosphorIconsRegular.dotsSixVertical, size: 18, color: gc.textTertiary),
            ),
          ),
        ]),
      ),
    ),
  );
}

void showExerciseHistorySheet(BuildContext context, String exerciseId) {
  final gc = context.gc;
  final history = fit.exerciseHistory(exerciseId).take(8).toList();
  final ex = fit.exerciseById(exerciseId);
  showAppSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheet) => Container(
      padding: sheetPad(sheet),
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(sheet).height * 0.8),
      decoration: BoxDecoration(
        color: gc.bgRaised,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(GymRadius.xxl)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SheetHandle(),
            const SizedBox(height: 18),
            Text(ex == null ? '' : exerciseName(ex),
                style: AppTheme.f(20, weight: FontWeight.w800, color: gc.text)),
            const SizedBox(height: 4),
            Text(titleCase(t.history),
                style: AppTheme.f(12, weight: FontWeight.w500, color: gc.textSecondary)),
            const SizedBox(height: 14),
            if (history.isEmpty)
              Text(t.noHistory, style: AppTheme.f(13, weight: FontWeight.w500, color: gc.textSecondary)),
            for (var i = 0; i < history.length; i++)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  border: i < history.length - 1
                      ? Border(bottom: BorderSide(color: gc.border.withValues(alpha: 0.55)))
                      : null,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 92,
                      child: Text(t.shortDate(history[i].date),
                          style: AppTheme.f(13, weight: FontWeight.w600, color: gc.text)),
                    ),
                    Expanded(
                      child: Text(fit.setsSummary(history[i].ex.sets),
                          style: AppTheme.f(12,
                              weight: FontWeight.w500, color: gc.textSecondary, height: 1.4)),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

void _showLockHint(BuildContext context) {
  HapticFeedback.heavyImpact();
  showNotchToast(
    context,
    t.screenLocked,
    subtitle: t.lockedHint,
    icon: PhosphorIconsFill.fingerprint,
    accent: context.gc.accent,
  );
}
