part of '../progress_screen.dart';

class _LogBodyweightSheet extends StatefulWidget {
  const _LogBodyweightSheet({required this.start});
  final double start;
  @override
  State<_LogBodyweightSheet> createState() => _LogBodyweightSheetState();
}

class _LogBodyweightSheetState extends State<_LogBodyweightSheet> {
  late double _shown = ((fit.toDisplayWeight(widget.start)) * 10).round() / 10;

  @override
  Widget build(BuildContext context) {
    final gc = context.gc;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + MediaQuery.of(context).viewInsets.bottom + MediaQuery.paddingOf(context).bottom),
      decoration: BoxDecoration(
        color: gc.bgRaised,
        border: Border.all(color: gc.border),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(GymRadius.xxl)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SheetHandle(),
          const SizedBox(height: 18),
          Text(t.logBodyweight,
              style: AppTheme.d(14, weight: FontWeight.w600, color: gc.text, letterSpacing: 2)),
          const SizedBox(height: 4),
          Text(t.trackWeight, style: AppTheme.s(13, color: gc.textSecondary)),
          const SizedBox(height: 18),
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              RollingText(_shown.toStringAsFixed(1),
                  style: AppTheme.f(52, weight: FontWeight.w800, color: gc.text, height: 1.1)),
              const SizedBox(width: 6),
              Text(fit.units, style: AppTheme.f(17, weight: FontWeight.w700, color: gc.textSecondary)),
            ],
          ),
          const SizedBox(height: 16),
          RulerPicker(
            value: _shown,
            min: fit.isLb ? 60 : 25,
            max: fit.isLb ? 660 : 300,
            step: 0.1,
            majorEvery: 10,
            label: (v) => '${v.round()}',
            onChanged: (v) => setState(() => _shown = v),
          ),
          const SizedBox(height: 18),
          PrimaryButton(
            label: t.save,
            onTap: () {
              fit.addBodyweight(fit.fromDisplayWeight(_shown));
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

}

void showEditLoggedSheet(BuildContext context, LoggedSession s, LoggedExercise e) {
  final gc = context.gc;
  showAppSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetCtx) => AnimatedBuilder(
      animation: fit,
      builder: (sheetCtx, _) {
        if (!s.exercises.contains(e)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (sheetCtx.mounted) Navigator.of(sheetCtx).pop();
          });
        }
        final repsOnly = fit.isRepsOnly(e.id);
        return Container(
          padding: EdgeInsets.only(bottom: MediaQuery.of(sheetCtx).viewInsets.bottom),
          decoration: BoxDecoration(
            color: gc.bgRaised,
            border: Border.all(color: gc.border),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(GymRadius.xxl)),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SheetHandle(),
                  const SizedBox(height: 18),
                  Text(t.catalogName(e.id, e.name), style: AppTheme.d(20, weight: FontWeight.w700, color: gc.text)),
                  const SizedBox(height: 4),
                  Text(t.editEntryHint, style: AppTheme.s(12, color: gc.textSecondary)),
                  const SizedBox(height: 16),
                  for (int i = 0; i < e.sets.length; i++) ...[
                    _editSetRow(gc, s, e, i, repsOnly),
                    const SizedBox(height: 8),
                  ],
                  const SizedBox(height: 4),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => fit.addLoggedSet(e),
                    child: Container(
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        border: Border.all(color: gc.border),
                        borderRadius: BorderRadius.circular(GymRadius.md),
                      ),
                      child: Text(t.addSet,
                          style: AppTheme.s(13,
                              weight: FontWeight.w600, color: gc.textSecondary, letterSpacing: 1)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  PrimaryButton(label: t.done, onTap: () => Navigator.pop(sheetCtx), height: 52),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}

Widget _editSetRow(GymColors gc, LoggedSession s, LoggedExercise e, int i, bool repsOnly) {
  final set = e.sets[i];
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(color: gc.bgRaised2, borderRadius: BorderRadius.circular(GymRadius.md)),
    child: Row(
      children: [
        SizedBox(
          width: 22,
          child: Text('${i + 1}', style: AppTheme.d(15, weight: FontWeight.w700, color: gc.text)),
        ),
        Expanded(
          child: Column(
            children: [
              Text(t.repsCol,
                  style: AppTheme.s(11, weight: FontWeight.w600, color: gc.textTertiary, letterSpacing: 1)),
              const SizedBox(height: 2),
              StepperControl(
                value: '${set.reps}',
                onDec: () => fit.bumpLoggedReps(e, i, -1),
                onInc: () => fit.bumpLoggedReps(e, i, 1),
                minWidth: 30,
                btnSize: 26,
                gap: 8,
                fontSize: 14,
              ),
            ],
          ),
        ),
        if (!repsOnly)
          Expanded(
            child: Column(
              children: [
                Text(t.weightCol(fit.units.toUpperCase()),
                    style:
                        AppTheme.s(11, weight: FontWeight.w600, color: gc.textTertiary, letterSpacing: 1)),
                const SizedBox(height: 2),
                StepperControl(
                  value: fit.weightValue(set.weight),
                  onDec: () => fit.bumpLoggedWeight(e, i, -1),
                  onInc: () => fit.bumpLoggedWeight(e, i, 1),
                  minWidth: 34,
                  btnSize: 26,
                  gap: 8,
                  fontSize: 14,
                ),
              ],
            ),
          ),
        Semantics(
          button: true,
          label: t.removeSet,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => fit.removeLoggedSet(s, e, i),
            child: SizedBox(
              width: 36,
              height: 40,
              child: Icon(PhosphorIconsRegular.x, size: 14, color: gc.textTertiary),
            ),
          ),
        ),
      ],
    ),
  );
}

void showHeatToneSheet(BuildContext context) {
  showAppSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => const _HeatToneSheet(),
  );
}

class _HeatToneSheet extends StatefulWidget {
  const _HeatToneSheet();

  @override
  State<_HeatToneSheet> createState() => _HeatToneSheetState();
}

class _HeatToneSheetState extends State<_HeatToneSheet> {
  @override
  Widget build(BuildContext context) {
    final gc = context.gc;
    return Container(
      padding: sheetPad(context),
      decoration: BoxDecoration(
        color: gc.bgRaised,
        border: Border.all(color: gc.border),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(GymRadius.xxl)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SheetHandle(),
          const SizedBox(height: 16),
          Text(t.heatToneTitle, style: AppTheme.f(20, color: gc.text)),
          const SizedBox(height: 8),
          Text(t.heatToneHint,
              textAlign: TextAlign.center,
              style: AppTheme.f(12, weight: FontWeight.w500, color: gc.textSecondary)),
          const SizedBox(height: 20),
          for (final tone in kHeatTones)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() => fit.setHeatTone(tone)),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: gc.bgRaised2,
                  borderRadius: BorderRadius.circular(GymRadius.lg),
                  border: Border.all(
                      color: fit.heatTone == tone ? gc.text : Colors.transparent, width: 1.4),
                ),
                child: Row(children: [
                  for (final c in heatRamp(gc, tone))
                    Container(
                      width: 20,
                      height: 20,
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(GymRadius.xs)),
                    ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(t.heatToneName(tone),
                        style: AppTheme.f(14, weight: FontWeight.w600, color: gc.text)),
                  ),
                  if (fit.heatTone == tone) Icon(PhosphorIconsBold.check, size: 16, color: gc.text),
                ]),
              ),
            ),
        ],
      ),
    );
  }
}
