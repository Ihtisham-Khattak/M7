/// Rules behind the "Today's focus" card on Home (GM-16), kept pure so they can be tested.
///
/// Until the plan generator exists (GM-52/53) the focus has no stored duration or muscle
/// title, so both are derived from what the routine already holds.
library;

/// Average time one working set takes, excluding the rest after it.
const int kSecondsPerSet = 45;

/// Estimated duration of a workout in minutes, rounded to the nearest 5 (never below 5).
/// Every set costs [kSecondsPerSet] plus the rest configured for its exercise.
/// Returns 0 when there is nothing to do.
int estimateWorkoutMinutes(Iterable<({int sets, int restSeconds})> exercises) {
  var seconds = 0;
  for (final e in exercises) {
    if (e.sets <= 0) continue;
    seconds += e.sets * (kSecondsPerSet + (e.restSeconds < 0 ? 0 : e.restSeconds));
  }
  if (seconds <= 0) return 0;
  final rounded = (seconds / 60 / 5).round() * 5;
  return rounded < 5 ? 5 : rounded;
}

/// The muscle groups a routine trains most, by number of exercises (ties keep the order in
/// which they first appear), at most [max] of them. Empty ids are ignored.
List<String> leadingMuscles(Iterable<String> primaries, {int max = 2}) {
  final counts = <String, int>{};
  for (final id in primaries) {
    if (id.isEmpty) continue;
    counts[id] = (counts[id] ?? 0) + 1;
  }
  final order = counts.keys.toList();
  order.sort((a, b) {
    final byCount = counts[b]!.compareTo(counts[a]!);
    return byCount != 0 ? byCount : order.indexOf(a).compareTo(order.indexOf(b));
  });
  return order.take(max).toList();
}
