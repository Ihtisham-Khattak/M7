part of '../session_screen.dart';

extension _SessionKindSheet on SessionScreen {
  Widget _plateRow(BuildContext context, GymColors gc, SessionExercise ex) {
    final exercise = fit.exerciseById(ex.id);
    if (exercise == null || ex.sets.isEmpty) return const SizedBox.shrink();
    final next = ex.sets.firstWhere((s) => !s.done, orElse: () => ex.sets.last);
    final hint = fit.plateHint(exercise.equipment, next.weight);
    if (hint == null) return const SizedBox.shrink();

    return Semantics(
      button: true,
      label: t.toolTitle('plate'),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => showPlateSheet(context, fit.toDisplayWeight(next.weight)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(SessionScreen._rowPad, 8, SessionScreen._rowPad, 0),
          child: Row(
            children: [
              Icon(PhosphorIconsRegular.circlesThree, size: 13, color: gc.textTertiary),
              const SizedBox(width: 7),
              Expanded(
                child: Text(t.platesPerSide(hint),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.f(11.5, weight: FontWeight.w500, color: gc.textTertiary)),
              ),
              const SizedBox(width: 6),
              Icon(PhosphorIconsRegular.caretRight, size: 12, color: gc.textTertiary),
            ],
          ),
        ),
      ),
    );
  }

  Color _kindColor(GymColors gc, SetKind kind) => setKindColor(gc, kind);

  String _kindLabel(SetKind kind) => setKindLabel(kind);

  Widget _setBadge(GymColors gc, int exIdx, int j, SessionSet st) {
    final sets = fit.session?.exercises[exIdx].sets ?? const <SessionSet>[];
    var working = 0;
    for (var i = 0; i <= j && i < sets.length; i++) {
      if (sets[i].counts) working++;
    }
    final tag = setKindTag(st.kind);
    final base = st.kind == SetKind.warmup
        ? tag
        : tag.isEmpty
            ? '$working'
            : '$working·$tag';
    final text = st.rpe == null || fit.logRpe ? base : '$base${fit.effortTag(st.rpe!)}';
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Text(text,
          maxLines: 1,
          softWrap: false,
          style: AppTheme.f(16, weight: FontWeight.w700, color: _kindColor(gc, st.kind))),
    );
  }

  Future<void> _kindSheet(BuildContext context, int exIdx, int j, SetKind current) async {
    final gc = context.gc;
    await showAppSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheet) => StatefulBuilder(
        builder: (sheet, setSheet) {
          final live = fit.session?.exercises[exIdx].sets[j];
          final kindNow = live?.kind ?? current;
          return Container(
            padding: sheetPad(sheet),
            decoration: BoxDecoration(
              color: gc.bgRaised,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SheetHandle(),
                  const SizedBox(height: 18),
                  Text(t.setType,
                      style: AppTheme.f(12,
                          weight: FontWeight.w600, color: gc.textSecondary, letterSpacing: 0.4)),
                  const SizedBox(height: 12),
                  for (final kind in SetKind.values) ...[
                    if (kind != SetKind.values.first) const SizedBox(height: 8),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => setSheet(() => fit.setSetKind(exIdx, j, kind)),
                      child: Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: kind == kindNow ? gc.bgRaised2 : Colors.transparent,
                          borderRadius: BorderRadius.circular(GymRadius.md),
                          border:
                              Border.all(color: kind == kindNow ? _kindColor(gc, kind) : gc.border),
                        ),
                        child: Row(children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration:
                                BoxDecoration(color: _kindColor(gc, kind), shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(_kindLabel(kind),
                                style: AppTheme.f(14, weight: FontWeight.w600, color: gc.text)),
                          ),
                          if (kind == kindNow)
                            Icon(PhosphorIconsBold.check, size: 14, color: _kindColor(gc, kind)),
                        ]),
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  Text(t.setTypeHint, style: AppTheme.f(11.5, weight: FontWeight.w500, color: gc.textTertiary, height: 1.4)),
                  const SizedBox(height: 18),
                  PrimaryButton(label: t.done, onTap: () => Navigator.of(sheet).pop()),
                  const SizedBox(height: 4),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      Navigator.of(sheet).pop();
                      _deleteSet(context, exIdx, j);
                    },
                    child: SizedBox(
                      height: 48,
                      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(PhosphorIconsRegular.trash, size: 16, color: gc.danger),
                        const SizedBox(width: 8),
                        Text(t.deleteSet,
                            style: AppTheme.f(14, weight: FontWeight.w600, color: gc.danger)),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
  Widget _miniStepper(
    GymColors gc,
    String value,
    VoidCallback dec,
    VoidCallback inc,
    double minW, {
    required void Function(BuildContext) onEdit,
  }) {
    Widget b(String g, String semantic, VoidCallback t) => Semantics(
          button: true,
          label: semantic,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: t,
            child: SizedBox(
              width: 32,
              height: GymSpace.minTarget,
              child: Center(
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(color: gc.bgRaised2, borderRadius: BorderRadius.circular(GymRadius.xs)),
                  alignment: Alignment.center,
                  child: Text(g, style: TextStyle(color: gc.text, fontSize: 17, height: 1)),
                ),
              ),
            ),
          ),
        );
    return Builder(
      builder: (context) => FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            b('–', t.decrease, dec),
            const SizedBox(width: 2),
            GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onEdit(context),
            child: Container(
              constraints: BoxConstraints(minWidth: minW < 28 ? 28 : minW, minHeight: GymSpace.minTarget),
              alignment: Alignment.center,
              child: RollingText(value,
                  style: AppTheme.f(15, weight: FontWeight.w700, color: gc.text)),
            ),
          ),
          const SizedBox(width: 2),
          b('+', t.increase, inc),
        ],
        ),
      ),
    );
  }

  Future<void> _ruler(
    BuildContext context, {
    required String title,
    required double value,
    required double max,
    required double step,
    required void Function(double) onSave,
    int majorEvery = 10,
    String unit = '',
    String Function(double)? format,
  }) async {
    final v = await askRuler(context,
        title: title,
        value: value,
        min: 0,
        max: max,
        step: step,
        unit: unit,
        majorEvery: majorEvery,
        format: format,
        tickLabel: format);
    if (v != null) onSave(v);
  }
}
