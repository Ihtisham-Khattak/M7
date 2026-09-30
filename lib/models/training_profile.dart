enum TrainingGoal { leanAesthetic, muscleStrength }

enum Experience { beginner, intermediate, advanced }

const List<int> kSessionMinutes = [30, 45, 60, 75];

const int kMaxFocusGroups = 3;

T? _named<T extends Enum>(List<T> values, Object? raw) {
  if (raw is! String) return null;
  for (final v in values) {
    if (v.name == raw) return v;
  }
  return null;
}

int _nearestMinutes(num raw) {
  var best = kSessionMinutes.first;
  for (final m in kSessionMinutes) {
    if ((m - raw).abs() < (best - raw).abs()) best = m;
  }
  return best;
}

class TrainingProfile {
  TrainingProfile({
    this.goal,
    this.experience,
    this.sessionMinutes = 45,
    this.setting = '',
    List<String>? focus,
  }) : focus = focus ?? [];

  TrainingGoal? goal;
  Experience? experience;
  int sessionMinutes;
  String setting;
  final List<String> focus;

  bool get isSet => goal != null;

  Map<String, dynamic> toJson() => {
        if (goal != null) 'g': goal!.name,
        if (experience != null) 'x': experience!.name,
        'm': sessionMinutes,
        if (setting.isNotEmpty) 's': setting,
        if (focus.isNotEmpty) 'f': focus,
      };

  factory TrainingProfile.fromJson(Map<String, dynamic> j) {
    final minutes = j['m'];
    final setting = j['s'];
    final focus = j['f'];
    return TrainingProfile(
      goal: _named(TrainingGoal.values, j['g']),
      experience: _named(Experience.values, j['x']),
      sessionMinutes: minutes is num ? _nearestMinutes(minutes) : 45,
      setting: setting is String ? setting : '',
      focus: focus is List ? focus.whereType<String>().take(kMaxFocusGroups).toList() : null,
    );
  }
}
