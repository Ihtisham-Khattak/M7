part of '../progress_screen.dart';

class _StrengthCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final gc = context.gc;
    final tracked = fit.trackedExercises;
    final id = fit.activeStrengthId;

    return SoftCard(
      radius: GymRadius.lg,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.strength1rm,
              style: AppTheme.f(11, weight: FontWeight.w600, color: gc.textTertiary, letterSpacing: 0.9)),
          const SizedBox(height: 14),
          if (id == null)
            Text(t.strengthEmpty, style: AppTheme.s(13, color: gc.textSecondary))
          else
            ..._chart(context, gc, id, tracked),
        ],
      ),
    );
  }

  List<Widget> _chart(
    BuildContext context,
    GymColors gc,
    String id,
    List<({String id, String name, int sessions})> tracked,
  ) {
    final history = fit.exerciseHistory(id).reversed.toList();
    final recent = history.length > 24 ? history.sublist(history.length - 24) : history;
    final series = [for (final h in recent) (h.ex.bestOneRm * 10).round() / 10];
    final first = series.first, last = series.last;
    final delta = last - first;
    final up = delta >= 0;
    final name = tracked.firstWhere((e) => e.id == id, orElse: () => tracked.first).name;
    final pickable = tracked.length > 1;

    return [
      Semantics(
        button: pickable,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: pickable ? () => _pick(context, id, tracked) : null,
          child: Row(
            children: [
              _PrThumb(id: id, size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Text(t.catalogName(id, name),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.f(15, weight: FontWeight.w700, color: gc.text)),
              ),
              if (pickable) ...[
                const SizedBox(width: 8),
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(color: gc.bgRaised2, shape: BoxShape.circle),
                  child: Icon(PhosphorIconsBold.caretDown, size: 13, color: gc.textSecondary),
                ),
              ],
            ],
          ),
        ),
      ),
      const SizedBox(height: 16),
      Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          RichText(
            text: TextSpan(
              text: fit.weightValue(last),
              style: AppTheme.d(34, weight: FontWeight.w800, color: gc.text),
              children: [
                TextSpan(
                    text: ' ${fit.units}',
                    style: AppTheme.d(15, weight: FontWeight.w700, color: gc.textSecondary)),
              ],
            ),
          ),
          const Spacer(),
          if (delta.abs() >= 0.1)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                    color: up ? gc.sageSoft : gc.accentSoft, borderRadius: BorderRadius.circular(GymRadius.pill)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(up ? PhosphorIconsBold.trendUp : PhosphorIconsBold.trendDown,
                      size: 12, color: up ? gc.sage : gc.accent),
                  const SizedBox(width: 4),
                  Text('${up ? '+' : ''}${fit.weightLabel(delta)}',
                      style: AppTheme.s(11, weight: FontWeight.w700, color: up ? gc.sage : gc.accent)),
                ]),
              ),
            ),
        ],
      ),
      const SizedBox(height: 12),
      TrendChart(values: [for (final v in series) fit.toDisplayWeight(v)], height: 96, scale: fmt),
      const SizedBox(height: 8),
      Row(
        children: [
          Text(t.shortDate(recent.first.date),
              style: AppTheme.s(11, weight: FontWeight.w600, color: gc.textTertiary)),
          const Spacer(),
          Text(t.sessionCount(series.length),
              style: AppTheme.s(11, weight: FontWeight.w600, color: gc.textTertiary)),
          const Spacer(),
          Text(t.shortDate(recent.last.date),
              style: AppTheme.s(11, weight: FontWeight.w600, color: gc.textTertiary)),
        ],
      ),
    ];
  }

  void _pick(BuildContext context, String current, List<({String id, String name, int sessions})> tracked) {
    showAppSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheet) {
        final gc = sheet.gc;
        return Container(
          padding: sheetPad(sheet),
          constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(sheet).height * 0.8),
          decoration: BoxDecoration(
            color: gc.bgRaised,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(GymRadius.xxl)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SheetHandle(),
              const SizedBox(height: 16),
              SheetTitle(sentenceCase(t.strength1rm)),
              const SizedBox(height: 14),
              Flexible(
                child: OptionGroup(
                  [
                    for (final e in tracked)
                      OptionItem(
                        t.catalogName(e.id, e.name),
                        leading: _PrThumb(id: e.id, size: 34),
                        detail: t.sessionCount(e.sessions),
                        selected: e.id == current,
                        onTap: () {
                          fit.setStrengthExercise(e.id);
                          Navigator.of(sheet).pop();
                        },
                      ),
                  ],
                  scroll: true,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PrThumb extends StatelessWidget {
  const _PrThumb({required this.id, this.size = 44});

  final String id;
  final double size;

  @override
  Widget build(BuildContext context) {
    final gc = context.gc;
    final ex = fit.exerciseById(id);
    return SizedBox(
      width: size,
      height: size,
      child: ex == null
          ? Container(
              decoration: BoxDecoration(color: gc.bgRaised2, borderRadius: BorderRadius.circular(size * 0.28)),
              child: Icon(PhosphorIconsRegular.barbell, size: size * 0.45, color: gc.textTertiary),
            )
          : ExerciseMedia(ex: ex, height: size, radius: size * 0.28, bordered: false),
    );
  }
}

class _PrCard extends StatefulWidget {
  const _PrCard(this.prs);

  final List<PersonalRecord> prs;

  @override
  State<_PrCard> createState() => _PrCardState();
}

class _PrCardState extends State<_PrCard> {
  static const _shown = 5;
  bool _all = false;

  @override
  Widget build(BuildContext context) {
    final gc = context.gc;
    final prs = widget.prs;
    final rows = _all ? prs : prs.take(_shown).toList();
    final hidden = prs.length - rows.length;
    return SoftCard(
      radius: GymRadius.lg,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(PhosphorIconsFill.trophy, size: 14, color: gc.accent),
            const SizedBox(width: 7),
            Expanded(
              child: Text(t.personalRecords,
                  style: AppTheme.f(11, weight: FontWeight.w600, color: gc.textTertiary, letterSpacing: 0.9)),
            ),
            Text('${prs.length}', style: AppTheme.f(12, weight: FontWeight.w700, color: gc.textSecondary)),
          ]),
          const SizedBox(height: 8),
          AnimatedSize(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: Column(
              children: [
                for (var i = 0; i < rows.length; i++) _row(gc, rows[i], i, i < rows.length - 1 || hidden > 0),
              ],
            ),
          ),
          if (prs.length > _shown)
            Semantics(
              button: true,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => setState(() => _all = !_all),
                child: SizedBox(
                  height: 44,
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    if (!_all)
                      Text('+$hidden',
                          style: AppTheme.f(12, weight: FontWeight.w700, color: gc.textSecondary)),
                    const SizedBox(width: 6),
                    AnimatedRotation(
                      turns: _all ? 0.5 : 0,
                      duration: const Duration(milliseconds: 240),
                      child: Icon(PhosphorIconsBold.caretDown, size: 13, color: gc.textSecondary),
                    ),
                  ]),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _row(GymColors gc, PersonalRecord pr, int rank, bool border) {
    final medal = rank < 3 ? [gc.brass, gc.textSecondary, gc.accent][rank] : null;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: BoxDecoration(
        border: border ? Border(bottom: BorderSide(color: gc.border.withValues(alpha: 0.6))) : null,
      ),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              _PrThumb(id: pr.id),
              if (medal != null)
                Positioned(
                  right: -4,
                  top: -4,
                  child: Container(
                    width: 18,
                    height: 18,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: medal,
                      shape: BoxShape.circle,
                      border: Border.all(color: gc.bgRaised, width: 2),
                    ),
                    child: Text('${rank + 1}', style: AppTheme.f(11, weight: FontWeight.w800, color: gc.bgRaised)),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.catalogName(pr.id, pr.name),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.s(14, weight: FontWeight.w600, color: gc.text, height: 1.25)),
                const SizedBox(height: 3),
                Text(fit.recordDetail(pr),
                    style: AppTheme.s(11, weight: FontWeight.w500, color: gc.textTertiary)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(fit.recordLabel(pr), style: AppTheme.d(20, weight: FontWeight.w800, color: gc.text)),
        ],
      ),
    );
  }
}
