enum MuscleGroup { chest, back, shoulders, biceps, triceps, legs, glutes, calves, core, forearms }

const Map<MuscleGroup, List<String>> kGroupMuscles = {
  MuscleGroup.chest: ['chest'],
  MuscleGroup.back: ['back', 'trapezius'],
  MuscleGroup.shoulders: ['shoulders'],
  MuscleGroup.biceps: ['biceps'],
  MuscleGroup.triceps: ['triceps'],
  MuscleGroup.legs: ['quads', 'hamstrings'],
  MuscleGroup.glutes: ['glutes'],
  MuscleGroup.calves: ['calves'],
  MuscleGroup.core: ['abdomen', 'obliques'],
  MuscleGroup.forearms: ['forearm'],
};

MuscleGroup? groupOfMuscle(String muscleId) {
  for (final e in kGroupMuscles.entries) {
    if (e.value.contains(muscleId)) return e.key;
  }
  return null;
}

MuscleGroup? muscleGroupNamed(String name) {
  for (final g in MuscleGroup.values) {
    if (g.name == name) return g;
  }
  return null;
}

enum ExerciseKind { compound, isolation }

enum MovementPattern { push, pull, squat, hinge, carry, rotation, flexion, extension }

class ExerciseMeta {
  const ExerciseMeta(this.kind, [this.pattern]);

  final ExerciseKind kind;
  final MovementPattern? pattern;
}

const Map<String, ExerciseMeta> kExerciseMeta = {};

ExerciseMeta? metaOf(String exerciseId) => kExerciseMeta[exerciseId];
