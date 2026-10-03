part of '../session_screen.dart';

extension _SessionSummary on SessionScreen {
  Widget _complete(BuildContext context, GymColors gc) {
    final prs = fit.gamification ? fit.summaryPrs : 0;
    final streak = fit.currentStreak;
    final goalHit = fit.goalPct >= 100;
    final vsLast = fit.summaryVsLast;
    final vol = fit.summaryVolumeKg;
    final sets = fit.session?.summarySets ?? 0;

    return _Celebrate(
      active: sets > 0 && fit.gamification,
      child: Padding(
        padding: const EdgeInsets.only(top: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Rise(index: 0, child: _finishHero(gc, prs: prs, streak: streak, goalHit: goalHit)),
            const SizedBox(height: 18),
            Rise(
              index: 1,
              child: Row(children: [
                Expanded(child: _sumCard(gc, t.duration, fit.summaryDurationLabel)),
                const SizedBox(width: 10),
                Expanded(child: _countUp(sets.toDouble(), (v) => _sumCard(gc, t.setsCaps, '${v.round()}'))),
                const SizedBox(width: 10),
                Expanded(child: _countUp(vol, (v) => _sumCard(gc, t.volume, fit.volumeLabel(v)))),
              ]),
            ),
            const SizedBox(height: 10),
            Rise(
              index: 2,
              child: vsLast != null && vsLast > 0 ? _vsLastCard(gc, vol, vsLast) : _firstTimeCard(gc),
            ),
            const SizedBox(height: 18),
            Rise(
              index: 3,
              child: Row(children: [
                Expanded(child: PrimaryButton(label: t.done, onTap: fit.saveAndExit)),
                const SizedBox(width: 10),
                Semantics(
                  button: true,
                  label: t.share,
                  child: GestureDetector(
                    onTap: () => showShareSheet(context, initial: ShareKind.streak),
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(color: gc.bgRaised, shape: BoxShape.circle),
                      child: Icon(PhosphorIconsRegular.shareNetwork, size: 20, color: gc.text),
                    ),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 10),
            Rise(
              index: 4,
              child: GhostButton(
                label: t.keepTraining,
                icon: PhosphorIconsRegular.arrowCounterClockwise,
                onTap: fit.continueSession,
              ),
            ),
            if (sets > 0 && fit.sessions.isNotEmpty) ...[
              const SizedBox(height: 10),
              Rise(
                index: 5,
                child: GhostButton(
                  label: t.stickerOpen,
                  icon: PhosphorIconsRegular.imageSquare,
                  onTap: () => showStickerEditor(context, fit.sessions.last, prs: prs),
                ),
              ),
            ],
            if (fit.sessionRoutine == null || fit.sessionEditedRoutine) ...[
              const SizedBox(height: 10),
              Rise(
                index: 6,
                child: GhostButton(
                  label: fit.sessionRoutine == null ? t.saveAsRoutine : t.saveToRoutine,
                  icon: PhosphorIconsRegular.listChecks,
                  onTap: () => _saveRoutine(context),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _saveRoutine(BuildContext context) async {
    final accent = context.gc.sage;
    final routine = fit.sessionRoutine;
    if (routine != null) {
      if (!await _confirmRoutineChanges(context, routine) || !context.mounted) return;
      fit.saveSessionIntoRoutine();
      showNotchToast(context, t.routineUpdated, icon: PhosphorIconsFill.listChecks, accent: accent);
      return;
    }
    final name = await askText(context, title: t.routineName, initial: t.newRoutineName);
    if (name == null || !context.mounted || fit.saveSessionAsRoutine(name).isEmpty) return;
    showNotchToast(context, t.savedAsRoutine, icon: PhosphorIconsFill.listChecks, accent: accent);
  }

  Future<bool> _confirmRoutineChanges(BuildContext context, Routine routine) async {
    final gc = context.gc;
    final changes = fit.sessionRoutineChanges;
    Widget row(IconData icon, Color color, String text) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(color: color.withValues(alpha: 0.16), shape: BoxShape.circle),
              child: Icon(icon, size: 13, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(text,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.f(14, weight: FontWeight.w600, color: gc.text)),
            ),
          ]),
        );
    final ok = await showAppDialog<bool>(
      context: context,
      builder: (dctx) => appDialog(
        gc,
        title: Text(t.saveChangesTitle(fit.routineTitle(routine)),
            style: AppTheme.f(20, weight: FontWeight.w800, color: gc.text)),
        content: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(dctx).height * 0.45),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.saveChangesBody,
                    style: AppTheme.f(13, weight: FontWeight.w500, color: gc.textSecondary, height: 1.45)),
                const SizedBox(height: 12),
                for (final e in changes.added) row(PhosphorIconsBold.plus, gc.sage, exerciseName(e)),
                for (final e in changes.removed) row(PhosphorIconsBold.minus, gc.danger, exerciseName(e)),
                if (changes.reordered) row(PhosphorIconsBold.arrowsDownUp, gc.brass, t.routineOrderChanged),
              ],
            ),
          ),
        ),
        actions: [
          dialogAction(t.cancel, gc.textSecondary, () => Navigator.of(dctx).pop(false), strong: false),
          dialogAction(t.save, gc.accent, () => Navigator.of(dctx).pop(true)),
        ],
      ),
    );
    return ok ?? false;
  }

  Widget _countUp(double to, Widget Function(double v) builder) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: to),
        duration: const Duration(milliseconds: 1100),
        curve: Curves.easeOutCubic,
        builder: (context, v, _) => builder(v),
      );

  Widget _finishHero(GymColors gc, {required int prs, required int streak, required bool goalHit}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(GymRadius.xl),
      child: Container(
        decoration: BoxDecoration(
          color: gc.bgRaised,

          borderRadius: BorderRadius.circular(GymRadius.xl),
        ),
        child: Stack(
          children: [
            Positioned(
              left: -45,
              bottom: -45,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(color: gc.accentSoft, shape: BoxShape.circle),
              ),
            ),
            Positioned(
              right: -14,
              top: -6,
              bottom: -6,
              child: Opacity(
                opacity: 0.45,
                child: Image.asset('assets/img/runner.png', fit: BoxFit.fitHeight),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text(t.sessionComplete.toUpperCase(),
                        style: AppTheme.f(11, weight: FontWeight.w600, color: gc.brass, letterSpacing: 1.4)),
                    if (prs > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration:
                            BoxDecoration(color: gc.accentSoft, borderRadius: BorderRadius.circular(GymRadius.pill)),
                        child: Text(t.prCount(prs),
                            style: AppTheme.f(11, weight: FontWeight.w700, color: gc.accent)),
                      ),
                    ],
                  ]),
                  const SizedBox(height: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 210),
                    child: Text(t.finishHeadline(prs: prs, streak: streak, goalHit: goalHit),
                        style: AppTheme.f(28, weight: FontWeight.w700, color: gc.text, height: 1.05)),
                  ),
                  const SizedBox(height: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 230),
                    child: Text(t.finishBody(prs: prs, streak: streak, goalHit: goalHit),
                        style: AppTheme.f(13, weight: FontWeight.w500, color: gc.textSecondary, height: 1.35)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _vsLastCard(GymColors gc, double now, double before) {
    final diff = now - before;
    final up = diff >= 0;
    final pct = ((diff / before) * 100).round();
    return SoftCard(
      radius: GymRadius.lg,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(children: [
        SvgPathIcon(Ic.trendUp, size: 16, color: up ? gc.sage : gc.textTertiary),
        const SizedBox(width: 12),
        Expanded(
          child: Text(t.vsLastTime,
              style: AppTheme.f(11, weight: FontWeight.w600, color: gc.textSecondary, letterSpacing: 0.4)),
        ),
        Text('${up ? '+' : ''}$pct%',
            style: AppTheme.f(15, weight: FontWeight.w700, color: up ? gc.sage : gc.textSecondary)),
      ]),
    );
  }

  Widget _firstTimeCard(GymColors gc) {
    return SoftCard(
      radius: GymRadius.lg,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(children: [
        SvgPathIcon(Ic.flame, size: 16, color: gc.accent),
        const SizedBox(width: 12),
        Expanded(child: Text(t.firstTime, style: AppTheme.f(13, weight: FontWeight.w500, color: gc.textSecondary))),
      ]),
    );
  }

  Widget _sumCard(GymColors gc, String label, String value) {
    return SoftCard(
      radius: GymRadius.lg,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FitText(label,
              style: AppTheme.f(11, weight: FontWeight.w600, color: gc.textSecondary, letterSpacing: 0.4)),
          const SizedBox(height: 4),
          FitText(value, style: AppTheme.f(17, weight: FontWeight.w700, color: gc.text)),
        ],
      ),
    );
  }
}
