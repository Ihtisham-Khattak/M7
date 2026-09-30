import '../catalog/exercise_catalog.dart';
import '../models/training_profile.dart';

enum OnboardingStep { welcome, goal, training, place, focus, about }

class OnboardingAnswers {
  const OnboardingAnswers({this.goal, this.experience});

  final TrainingGoal? goal;
  final Experience? experience;
}

bool asksFocus(OnboardingAnswers a) {
  if (a.goal == null) return false;
  return a.goal == TrainingGoal.leanAesthetic || (a.experience ?? Experience.beginner) != Experience.beginner;
}

List<OnboardingStep> visibleSteps(OnboardingAnswers a, {bool welcome = true}) => [
      if (welcome) OnboardingStep.welcome,
      OnboardingStep.goal,
      OnboardingStep.training,
      OnboardingStep.place,
      if (asksFocus(a)) OnboardingStep.focus,
      OnboardingStep.about,
    ];

const List<int> kDayChoices = [2, 3, 4, 5, 6];

const Map<String, List<String>> _gearChoices = {
  'home': ['Dumbbell', 'Barbell', 'Kettlebell', 'Band', 'Weighted', 'Rings'],
  'outdoors': ['Band', 'Weighted', 'Rings'],
};

List<String> gearChoices(String preset) =>
    _gearChoices[preset] ?? [for (final e in kFilterEquipment) if (e != 'Bodyweight') e];
