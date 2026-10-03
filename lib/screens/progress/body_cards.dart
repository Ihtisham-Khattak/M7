part of '../progress_screen.dart';

extension _ProgressBodyCards on ProgressScreen {
  Widget _timelineCard(GymColors gc) {
    final pair = fit.comparePair;
    final last = fit.lastEntry;
    final left = fit.daysUntilPhoto;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: fit.goTimeline,
      child: SoftCard(
        radius: GymRadius.lg,
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(color: gc.accentSoft, shape: BoxShape.circle),
                  child: Icon(PhosphorIconsBold.clockCounterClockwise, size: 16, color: gc.accent),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(t.timeline,
                      style: AppTheme.d(14, weight: FontWeight.w600, color: gc.text, letterSpacing: 1)),
                ),
                if (last != null && left != null)
                  Text(fit.photoDue ? t.photoDueNow : t.photoNextIn(left),
                      style: AppTheme.s(11,
                          weight: FontWeight.w600,
                          color: fit.photoDue ? gc.accent : gc.textTertiary)),
                const SizedBox(width: 8),
                Icon(PhosphorIconsRegular.caretRight, size: 15, color: gc.textTertiary),
              ],
            ),
            const SizedBox(height: 16),
            if (last == null)
              Text(t.timelineHint, style: AppTheme.s(13, color: gc.textSecondary, height: 1.5))
            else if (pair == null)
              Row(
                children: [
                  SizedBox(width: 66, child: _shotThumb(gc, last)),
                  const SizedBox(width: 12),
                  Expanded(child: _track(gc, [last.date], last.date, last.date, null)),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 66,
                    child: AspectRatio(
                      aspectRatio: 0.78,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(GymRadius.md),
                          border: Border.all(color: gc.border, width: 1.4),
                        ),
                        child: Icon(PhosphorIconsRegular.plus, size: 16, color: gc.textTertiary),
                      ),
                    ),
                  ),
                ],
              )
            else
              Row(
                children: [
                  SizedBox(width: 66, child: _shotThumb(gc, pair.from)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _track(
                      gc,
                      [for (final e in fit.timelineAsc) e.date],
                      pair.from.date,
                      pair.to.date,
                      t.daysApart(fit.compareDays),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(width: 66, child: _shotThumb(gc, pair.to)),
                ],
              ),
            if (last != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  SizedBox(
                    width: 66,
                    child: Text(t.shortDate((pair?.from ?? last).date),
                        textAlign: TextAlign.center,
                        style: AppTheme.s(11, weight: FontWeight.w600, color: gc.textTertiary)),
                  ),
                  Expanded(
                    child: Text(pair == null ? t.compareNeedTwo : t.photoCount(fit.shotCount),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.s(11, weight: FontWeight.w500, color: gc.textTertiary)),
                  ),
                  SizedBox(
                    width: 66,
                    child: pair == null
                        ? null
                        : Text(t.shortDate(pair.to.date),
                            textAlign: TextAlign.center,
                            style: AppTheme.s(11, weight: FontWeight.w600, color: gc.textTertiary)),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _track(GymColors gc, List<DateTime> dates, DateTime from, DateTime to, String? label) {
    final span = to.difference(from).inMinutes.abs();
    final spots = [
      for (final d in dates)
        if (!d.isBefore(from) && !d.isAfter(to)) span == 0 ? 0.0 : d.difference(from).inMinutes / span,
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.d(13, weight: FontWeight.w700, color: gc.text)),
          const SizedBox(height: 8),
        ],
        SizedBox(
          height: 14,
          child: CustomPaint(
            size: const Size(double.infinity, 14),
            painter: _TrackPainter(spots, gc.accent, gc.border, gc.bgRaised, open: label == null),
          ),
        ),
      ],
    );
  }

  Widget _shotThumb(GymColors gc, ProgressEntry entry) {
    final name = entry.media.isEmpty ? null : entry.media.first;
    final path = name == null ? null : MediaStore.pathFor(name);
    return AspectRatio(
      aspectRatio: 0.78,
      child: Container(
        decoration: BoxDecoration(
          color: gc.bgRaised2,
          borderRadius: BorderRadius.circular(GymRadius.md),
          border: Border.all(color: gc.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: path == null
            ? Icon(PhosphorIconsRegular.imageSquare, size: 16, color: gc.textTertiary)
            : Image.file(File(path), fit: BoxFit.cover, gaplessPlayback: true,
                errorBuilder: (_, _, _) =>
                    Icon(PhosphorIconsRegular.imageSquare, size: 16, color: gc.textTertiary)),
      ),
    );
  }

  Widget _measuresCard(GymColors gc) {
    final tracked = fit.trackedMeasures;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: fit.goMeasures,
      child: SoftCard(
        radius: GymRadius.lg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(t.measures,
                      style: AppTheme.d(14,
                          weight: FontWeight.w600, color: gc.text, letterSpacing: 1)),
                ),
                Icon(PhosphorIconsRegular.caretRight, size: 15, color: gc.textTertiary),
              ],
            ),
            const SizedBox(height: 12),
            if (tracked.isEmpty)
              Text(t.measuresHint, style: AppTheme.s(13, color: gc.textSecondary, height: 1.5))
            else
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final key in tracked.take(6)) _measureChip(gc, key),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _measureChip(GymColors gc, String key) {
    final latest = fit.latestMeasure(key)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: gc.bgRaised2,
        borderRadius: BorderRadius.circular(GymRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.measureName(key),
              style: AppTheme.s(11, weight: FontWeight.w600, color: gc.textTertiary)),
          const SizedBox(height: 3),
          Text(fit.measureLabel(key, latest.value),
              style: AppTheme.d(15, weight: FontWeight.w700, color: gc.text)),
        ],
      ),
    );
  }
}
