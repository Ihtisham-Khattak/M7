part of '../progress_screen.dart';

void showDaySheet(BuildContext context, DateTime date) => showAppSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _DaySheet(date: date),
    );

class _DaySheet extends StatelessWidget {
  const _DaySheet({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(animation: fit, builder: (context, _) => _body(context));
  }

  Widget _body(BuildContext context) {
    final gc = context.gc;
    final s = fit.daySummary(date);
    return Container(
      decoration: BoxDecoration(
        color: gc.bgRaised,
        border: Border.all(color: gc.border),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        padding: sheetPad(context),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SheetHandle(),
            const SizedBox(height: 18),
            Text(t.longDate(date),
                style: AppTheme.d(20, weight: FontWeight.w700, color: gc.text)),
            const SizedBox(height: 14),
            if (s == null)
              EmptyState(icon: PhosphorIconsRegular.moon, title: t.restDay, compact: true)
            else ...[
              Row(children: [
                Expanded(child: _stat(gc, t.exercisesCaps, '${s.exercises}')),
                const SizedBox(width: 10),
                Expanded(child: _stat(gc, t.setsCaps, '${s.sets}')),
                const SizedBox(width: 10),
                Expanded(child: _stat(gc, t.volume, fit.volumeLabel(s.volume))),
                if (s.durationSec > 0) ...[
                  const SizedBox(width: 10),
                  Expanded(child: _stat(gc, t.timeCaps, '${s.durationSec ~/ 60}m')),
                ],
              ]),
              const SizedBox(height: 16),
              Text(t.tapToEdit, style: AppTheme.s(11, color: gc.textTertiary)),
              const SizedBox(height: 10),
              for (final logged in fit.sessionsOn(date)) ...[
                _sessionHeader(context, gc, logged),
                for (final ex in [...logged.exercises]) _loggedRow(context, gc, logged, ex),
                const SizedBox(height: 6),
              ],
            ],
            if (!fit.isSessionActive && !_isFuture) ...[
              const SizedBox(height: 14),
              GhostButton(
                label: t.logWorkoutAction,
                icon: PhosphorIconsRegular.plus,
                onTap: () {
                  Navigator.of(context).pop();
                  showStartSheet(context, day: date);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  bool get _isFuture {
    final now = DateTime.now();
    return date.isAfter(DateTime(now.year, now.month, now.day, 23, 59));
  }

  Widget _sessionHeader(BuildContext context, GymColors gc, LoggedSession s) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${t.setCount(s.setCount)} · ${fit.volumeLabel(s.volume)}',
              style: AppTheme.s(11, weight: FontWeight.w600, color: gc.textTertiary, letterSpacing: 1),
            ),
          ),
          Semantics(
            button: true,
            label: t.deleteWorkout,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _confirmDeleteWorkout(context, s),
              child: SizedBox(
                width: 40,
                height: 36,
                child: Icon(PhosphorIconsRegular.trash, size: 16, color: gc.textTertiary),
              ),
            ),
          ),
          if (!fit.isSessionActive)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _confirmResume(context, s),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: gc.emberSoft,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(PhosphorIconsFill.play, size: 11, color: gc.ember),
                  const SizedBox(width: 6),
                  Text(t.continueWorkout,
                      style: AppTheme.d(11, weight: FontWeight.w700, color: gc.ember, letterSpacing: 1)),
                ]),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteWorkout(BuildContext context, LoggedSession s) async {
    final ok = await askConfirm(
      context,
      title: t.deleteWorkout,
      body: t.deleteWorkoutBody,
      confirmLabel: t.delete,
      danger: true,
    );
    if (!ok) return;
    fit.deleteSession(s);
    if (context.mounted && fit.sessionsOn(date).isEmpty) Navigator.of(context).pop();
  }

  Future<void> _confirmResume(BuildContext context, LoggedSession s) async {
    final ok = await askConfirm(
      context,
      title: t.continueWorkout,
      body: t.continueWorkoutBody,
      confirmLabel: t.continueWorkout,
    );
    if (!ok || !context.mounted) return;
    Navigator.of(context).pop();
    fit.resumeLoggedSession(s);
  }

  Widget _loggedRow(BuildContext context, GymColors gc, LoggedSession s, LoggedExercise e) {
    final detail = e.sets.map((x) => '${fit.weightValue(x.weight)}×${x.reps}').join(' · ');
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(color: gc.accent, shape: BoxShape.circle),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.catalogName(e.id, e.name), style: AppTheme.s(13, weight: FontWeight.w600, color: gc.text)),
                const SizedBox(height: 2),
                Text(detail, style: AppTheme.s(11, color: gc.textSecondary)),
              ],
            ),
          ),
          Semantics(
            button: true,
            label: '${t.editEntry} ${t.catalogName(e.id, e.name)}',
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => showEditLoggedSheet(context, s, e),
              child: SizedBox(
                width: 40,
                height: 44,
                child: Icon(PhosphorIconsRegular.pencilSimple, size: 16, color: gc.textTertiary),
              ),
            ),
          ),
          Semantics(
            button: true,
            label: '${t.deleteCaps} ${t.catalogName(e.id, e.name)}',
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _confirmDelete(context, s, e),
              child: SizedBox(
                width: 40,
                height: 44,
                child: Icon(PhosphorIconsRegular.trash, size: 16, color: gc.textTertiary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, LoggedSession s, LoggedExercise e) async {
    final ok = await askConfirm(
      context,
      title: t.deleteEntry,
      body: t.deleteEntryBody(t.catalogName(e.id, e.name)),
      confirmLabel: t.delete,
    );
    if (ok) fit.deleteLoggedExercise(s, e);
  }

  Widget _stat(GymColors gc, String label, String value) {
    Widget fit1(Widget child) =>
        FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: child);
    return SoftCard(
      radius: GymRadius.md,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          fit1(Text(label,
              maxLines: 1,
              softWrap: false,
              style: AppTheme.s(9, weight: FontWeight.w600, color: gc.textSecondary, letterSpacing: 1))),
          const SizedBox(height: 4),
          fit1(Text(value,
              maxLines: 1, softWrap: false, style: AppTheme.d(17, weight: FontWeight.w700, color: gc.text))),
        ],
      ),
    );
  }
}
