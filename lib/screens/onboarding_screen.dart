import '../app/brand.dart';
import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../catalog/exercise_meta.dart';
import '../l10n/l10n.dart';
import '../models/training_profile.dart';
import '../services/onboarding_flow.dart';
import '../state/fit_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import '../widgets/app_background.dart';
import '../widgets/body_rulers.dart';
import '../widgets/choice.dart';
import '../widgets/entrance.dart';
import '../widgets/ui_kit.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, this.personalize = false});

  final bool personalize;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _page = PageController();
  late final TextEditingController _name = TextEditingController();
  int _index = 0;
  final Map<String, Set<String>> _places = {};

  List<OnboardingStep> get _steps => visibleSteps(
        OnboardingAnswers(goal: fit.training.goal, experience: fit.training.experience),
        welcome: !widget.personalize,
      );

  OnboardingStep get _current => _steps[_index.clamp(0, _steps.length - 1)];

  @override
  void initState() {
    super.initState();
    if (widget.personalize) fit.personalizeBack = _stepBack;
  }

  @override
  void dispose() {
    if (widget.personalize && fit.personalizeBack == _stepBack) fit.personalizeBack = null;
    _page.dispose();
    _name.dispose();
    super.dispose();
  }

  bool _stepBack() {
    if (_index == 0) return false;
    _go(_index - 1);
    return true;
  }

  void _go(int i) {
    _page.animateToPage(i, duration: const Duration(milliseconds: 260), curve: Curves.easeOut);
  }

  void _onPage(int i) => setState(() => _index = i);

  bool get _canAdvance => switch (_current) {
        OnboardingStep.goal => fit.training.goal != null,
        OnboardingStep.training => fit.training.experience != null,
        _ => true,
      };

  void _next() {
    if (!_canAdvance) return;
    FocusManager.instance.primaryFocus?.unfocus();
    if (_index >= _steps.length - 1) {
      _finish();
    } else {
      _go(_index + 1);
    }
  }

  void _finish() {
    final typed = _name.text.trim();
    if (typed.isNotEmpty) fit.updateProfile(name: typed);
    String? first;
    for (final preset in kPlacePresets) {
      final gear = _places[preset];
      if (gear == null) continue;
      final known = fit.places.any((p) => p.name == t.placePresetName(preset));
      if (widget.personalize && known) continue;
      final id = fit.addPlace(t.placePresetName(preset), equipment: {...gear, 'Bodyweight'});
      if (id.isNotEmpty) first ??= id;
    }
    if (first != null && (!widget.personalize || fit.activePlaceId.isEmpty)) fit.setActivePlace(first);
    final chosen = kPlacePresets.where(_places.containsKey);
    if (chosen.isNotEmpty) fit.setTrainingSetting(chosen.first);
    fit.completeOnboarding();
    if (widget.personalize) fit.popRoute();
  }

  Widget _in(int order, Widget child) => Rise(index: order, child: child);

  @override
  Widget build(BuildContext context) {
    final gc = context.gc;
    final steps = _steps;
    return PopScope(
      canPop: widget.personalize || _index == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !widget.personalize) _stepBack();
      },
      child: Scaffold(
        backgroundColor: gc.bg,
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: [
            Positioned.fill(child: _Glow(gc)),
            Positioned.fill(child: AppBackground(
          pattern: fit.bgPattern,
          photo: fit.bgPhotoPath,
          dim: fit.bgDim,
          zoom: fit.bgZoom,
          dx: fit.bgDx,
          dy: fit.bgDy,
          opacity: fit.bgOpacity,
          blur: fit.bgBlur,
        )),
            SafeArea(
              child: Column(
                children: [
                  _topBar(gc, steps.length),
                  Expanded(
                    child: PageView.builder(
                      controller: _page,
                      onPageChanged: _onPage,
                      itemCount: steps.length,
                      itemBuilder: (_, i) => KeyedSubtree(key: ValueKey(steps[i]), child: _pageFor(gc, steps[i], i)),
                    ),
                  ),
                  _bottomBar(gc, steps.length),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pageFor(GymColors gc, OnboardingStep step, int i) => switch (step) {
        OnboardingStep.welcome => _welcome(gc),
        OnboardingStep.goal => _goalStep(gc, i),
        OnboardingStep.training => _trainingStep(gc, i),
        OnboardingStep.place => _placeStep(gc, i),
        OnboardingStep.focus => _focusStep(gc, i),
        OnboardingStep.about => _aboutStep(gc, i),
      };

  int _stepNumber(int i) => widget.personalize ? i + 1 : i;

  int get _stepTotal => widget.personalize ? _steps.length : _steps.length - 1;

  Widget _topBar(GymColors gc, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(GymSpace.xxl, GymSpace.lg, GymSpace.lg, 0),
      child: Row(
        children: [
          Expanded(child: StepProgress(count: count, index: _index)),
          const SizedBox(width: 10),
          Semantics(
            button: true,
            label: t.skip2,
            excludeSemantics: true,
            onTap: _finish,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _finish,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: GymSpace.minTarget, minWidth: GymSpace.minTarget),
                child: Center(child: Text(t.skip2, style: GymText.label(color: gc.textSecondary))),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomBar(GymColors gc, int count) {
    final last = _index >= count - 1;
    return Padding(
      padding: const EdgeInsets.fromLTRB(GymSpace.xxl, GymSpace.sm, GymSpace.xxl, 22),
      child: Row(
        children: [
          if (_index > 0)
            Semantics(
              button: true,
              label: MaterialLocalizations.of(context).backButtonTooltip,
              excludeSemantics: true,
              onTap: _stepBack,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _stepBack,
                child: Container(
                  width: 56,
                  height: 56,
                  margin: const EdgeInsets.only(right: GymSpace.md),
                  decoration: BoxDecoration(color: gc.bgRaised, shape: BoxShape.circle),
                  child: Icon(PhosphorIconsBold.arrowLeft, size: 18, color: gc.textSecondary),
                ),
              ),
            ),
          Expanded(
            child: Opacity(
              opacity: _canAdvance ? 1 : 0.4,
              child: PrimaryButton(
                label: last ? (widget.personalize ? t.done : t.welcomeStart) : t.next,
                onTap: _next,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _step(
    GymColors gc, {
    required int index,
    required String title,
    required String why,
    required Widget child,
  }) {
    return LayoutBuilder(
      builder: (context, box) => SingleChildScrollView(
        padding: const EdgeInsets.all(GymSpace.xl),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: box.maxHeight - 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _in(
                0,
                Padding(
                  padding: const EdgeInsets.only(left: GymSpace.xs),
                  child: _label(gc, t.onbStep(_stepNumber(index), _stepTotal)),
                ),
              ),
              const SizedBox(height: 10),
              _in(
                1,
                Semantics(
                  header: true,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: GymSpace.xs),
                    child: Text(title, style: AppTheme.f(30, weight: FontWeight.w800, color: gc.text, height: 1.12)),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              _in(
                2,
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: GymSpace.xs),
                  child: Text(why, style: GymText.label(color: gc.textSecondary, weight: FontWeight.w500).copyWith(height: 1.45)),
                ),
              ),
              const SizedBox(height: 26),
              _in(3, child),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(GymColors gc, String text) => Text(text.toUpperCase(),
      style: AppTheme.f(10.5, weight: FontWeight.w700, color: gc.textTertiary, letterSpacing: 1.3));

  Widget _group(GymColors gc, List<Widget> rows) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: gc.bgRaised, borderRadius: BorderRadius.circular(GymRadius.lg)),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0)
              Divider(height: 1, thickness: 1, indent: 16, endIndent: 16, color: gc.border.withValues(alpha: 0.6)),
            rows[i],
          ],
        ],
      ),
    );
  }

  Widget _rowIcon(GymColors gc, IconData icon, {Color? color}) => Padding(
        padding: const EdgeInsets.only(right: 14),
        child: SizedBox(width: 22, child: Icon(icon, size: 19, color: color ?? gc.textSecondary)),
      );

  Widget _welcome(GymColors gc) {
    return LayoutBuilder(
      builder: (context, box) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: box.maxHeight - 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _in(
                0,
                const Center(child: KaizanMark(size: 120)),
              ),
              const SizedBox(height: 26),
              _in(
                1,
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(t.welcomeKicker.toUpperCase(),
                      style: AppTheme.f(10.5, weight: FontWeight.w700, color: gc.textTertiary, letterSpacing: 1.6)),
                ),
              ),
              const SizedBox(height: 8),
              _in(
                2,
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const KaizanWordmark(size: 34),
                      const SizedBox(height: 10),
                      Text(t.tagline, style: AppTheme.f(15, weight: FontWeight.w500, color: gc.textSecondary)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _in(
                3,
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(t.welcomeBlurb,
                      style: AppTheme.f(14.5, weight: FontWeight.w500, color: gc.textSecondary, height: 1.5)),
                ),
              ),
              const SizedBox(height: 22),
              _in(
                4,
                _group(gc, [
                  _promise(gc, PhosphorIconsRegular.gift, t.freeForever, t.freeForeverWhy),
                  _promise(gc, PhosphorIconsRegular.wifiSlash, t.fullyOffline, t.fullyOfflineWhy),
                  _promise(gc, PhosphorIconsRegular.export, t.yoursToTake, t.yoursToTakeWhy),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _promise(GymColors gc, IconData icon, String title, String why) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(padding: const EdgeInsets.only(top: 1), child: _rowIcon(gc, icon)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTheme.f(14.5, weight: FontWeight.w600, color: gc.text)),
                  const SizedBox(height: 3),
                  Text(why,
                      style: AppTheme.f(12.5, weight: FontWeight.w500, color: gc.textSecondary, height: 1.4)),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _bodyRow(GymColors gc, IconData icon, String label, Widget control) => ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 58),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              _rowIcon(gc, icon),
              Expanded(
                child: Text(sentenceCase(label),
                    style: AppTheme.f(14.5, weight: FontWeight.w500, color: gc.text)),
              ),
              const SizedBox(width: 12),
              control,
            ],
          ),
        ),
      );

  Widget _valueRow(GymColors gc, IconData icon, String label, String value,
      Future<void> Function(BuildContext) edit) {
    return Semantics(
      button: true,
      label: sentenceCase(label),
      value: value,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => edit(context).then((_) => _up(() {})),
        child: _bodyRow(
          gc,
          icon,
          label,
          Row(mainAxisSize: MainAxisSize.min, children: [
            Text(value, style: AppTheme.f(15.5, weight: FontWeight.w700, color: gc.text)),
            const SizedBox(width: 8),
            Icon(PhosphorIconsBold.caretRight, size: 13, color: gc.textTertiary),
          ]),
        ),
      ),
    );
  }

  Widget _goalStep(GymColors gc, int i) {
    final goal = fit.training.goal;
    return _step(
      gc,
      index: i,
      title: t.onbGoalQTitle,
      why: t.onbGoalQWhy,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ChoiceCard(
            icon: PhosphorIconsRegular.personSimpleRun,
            title: t.goalLeanTitle,
            body: t.goalLeanBody,
            selected: goal == TrainingGoal.leanAesthetic,
            onTap: () => _up(() => fit.setTrainingGoal(TrainingGoal.leanAesthetic)),
          ),
          const SizedBox(height: GymSpace.md),
          ChoiceCard(
            icon: PhosphorIconsRegular.barbell,
            title: t.goalStrengthTitle,
            body: t.goalStrengthBody,
            selected: goal == TrainingGoal.muscleStrength,
            onTap: () => _up(() => fit.setTrainingGoal(TrainingGoal.muscleStrength)),
          ),
        ],
      ),
    );
  }

  String _experienceTitle(Experience e) => switch (e) {
        Experience.beginner => t.expBeginner,
        Experience.intermediate => t.expIntermediate,
        Experience.advanced => t.expAdvanced,
      };

  String _experienceHint(Experience e) => switch (e) {
        Experience.beginner => t.expBeginnerHint,
        Experience.intermediate => t.expIntermediateHint,
        Experience.advanced => t.expAdvancedHint,
      };

  String _minutesLabel(int m) => m >= kSessionMinutes.last ? t.minutesPlus(m) : t.minutesOption(m);

  Widget _trainingStep(GymColors gc, int i) {
    final level = fit.training.experience;
    final days = fit.trainingDays;
    final minutes = fit.training.sessionMinutes;
    return _step(
      gc,
      index: i,
      title: t.onbTrainTitle,
      why: t.onbTrainWhy,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(padding: const EdgeInsets.only(left: GymSpace.xs, bottom: GymSpace.sm), child: _label(gc, t.expLabel)),
          for (final e in Experience.values) ...[
            ChoiceCard(
              title: _experienceTitle(e),
              body: _experienceHint(e),
              selected: level == e,
              onTap: () => _up(() => fit.setTrainingExperience(e)),
            ),
            const SizedBox(height: GymSpace.sm),
          ],
          const SizedBox(height: GymSpace.md),
          Padding(padding: const EdgeInsets.only(left: GymSpace.xs, bottom: GymSpace.sm), child: _label(gc, t.daysLabel)),
          Wrap(
            spacing: GymSpace.sm,
            runSpacing: GymSpace.sm,
            children: [
              for (final d in kDayChoices)
                SelectChip(label: '$d', selected: d == days, onTap: () => _up(() => fit.setTrainingDays(d))),
            ],
          ),
          const SizedBox(height: GymSpace.xl),
          Padding(padding: const EdgeInsets.only(left: GymSpace.xs, bottom: GymSpace.sm), child: _label(gc, t.minutesLabel)),
          Wrap(
            spacing: GymSpace.sm,
            runSpacing: GymSpace.sm,
            children: [
              for (final m in kSessionMinutes)
                SelectChip(
                  label: _minutesLabel(m),
                  selected: m == minutes,
                  onTap: () => _up(() => fit.setSessionMinutes(m)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _focusStep(GymColors gc, int i) {
    final picked = fit.training.focus;
    final full = picked.length >= kMaxFocusGroups;
    return _step(
      gc,
      index: i,
      title: t.onbFocusTitle,
      why: t.onbFocusWhy,
      child: Wrap(
        spacing: GymSpace.sm,
        runSpacing: GymSpace.sm,
        children: [
          for (final g in MuscleGroup.values)
            SelectChip(
              label: t.groupLabel(g),
              selected: picked.contains(g.name),
              enabled: picked.contains(g.name) || !full,
              onTap: () => _up(() => fit.toggleFocusGroup(g.name)),
            ),
        ],
      ),
    );
  }

  Widget _aboutStep(GymColors gc, int i) {
    final p = fit.profile;
    return _step(
      gc,
      index: i,
      title: t.onbAboutTitle,
      why: t.onbAboutWhy,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              for (final u in const ['kg', 'lb']) ...[
                if (u == 'lb') const SizedBox(width: GymSpace.sm),
                SelectChip(label: u, selected: fit.units == u, onTap: () => _up(() => fit.setUnits(u))),
              ],
              const SizedBox(width: GymSpace.md),
              Expanded(
                child: Text(t.onbUnitsTitle, style: GymText.label(color: gc.textSecondary, weight: FontWeight.w500)),
              ),
            ],
          ),
          const SizedBox(height: GymSpace.lg),
          if (!widget.personalize)
            _group(gc, [
              Padding(
                padding: const EdgeInsets.only(left: GymSpace.lg, right: GymSpace.sm),
                child: Row(
                  children: [
                    _rowIcon(gc, PhosphorIconsRegular.userCircle),
                    Expanded(
                      child: TextField(
                        controller: _name,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.done,
                        style: GymText.title(color: gc.text),
                        cursorColor: gc.accent,
                        decoration: InputDecoration(
                          hintText: t.onbNameHint,
                          hintStyle: GymText.title(color: gc.textTertiary, weight: FontWeight.w600),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: GymSpace.lg),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ]),
          if (!widget.personalize) const SizedBox(height: GymSpace.lg),
          _group(gc, [
            _bodyRow(
              gc,
              PhosphorIconsRegular.genderIntersex,
              t.sexLabel,
              SegToggle([
                SegOption(t.male, p.sex == 'male', () => _up(() => fit.updateProfile(sex: 'male'))),
                SegOption(t.female, p.sex == 'female', () => _up(() => fit.updateProfile(sex: 'female'))),
              ]),
            ),
            _valueRow(gc, PhosphorIconsRegular.cake, t.ageLabel, '${p.age}', editAge),
            _valueRow(gc, PhosphorIconsRegular.ruler, t.heightLabel, fit.heightLabel(p.heightCm), editHeight),
            _valueRow(gc, PhosphorIconsRegular.scales, t.weightLabel, fit.weightLabel(p.weightKg), editBodyWeight),
          ]),
        ],
      ),
    );
  }

  static const _placeIcons = {
    'gym': PhosphorIconsRegular.barbell,
    'home': PhosphorIconsRegular.house,
    'outdoors': PhosphorIconsRegular.tree,
  };

  Widget _placeStep(GymColors gc, int i) {
    return _step(
      gc,
      index: i,
      title: t.onbPlaceTitle,
      why: t.onbPlaceWhy,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _group(gc, [for (final preset in kPlacePresets) _placeRow(gc, preset)]),
          AnimatedSize(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: _places.isEmpty
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final preset in kPlacePresets)
                          if (_places[preset] case final gear?) ...[
                            Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: _label(
                                  gc,
                                  _places.length > 1
                                      ? '${t.placePresetName(preset)} · ${t.onbPlaceGear}'
                                      : t.onbPlaceGear),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (final e in gearChoices(preset))
                                    Pill(
                                      label: t.equipment(e),
                                      bg: gear.contains(e) ? gc.ember : gc.bgRaised,
                                      fg: gear.contains(e) ? gc.onEmber : gc.textSecondary,
                                      onTap: () => setState(() {
                                        if (!gear.remove(e)) gear.add(e);
                                      }),
                                      hPad: 14,
                                      vPad: 8,
                                      fontSize: 12.5,
                                    ),
                              ],
                            ),
                            const SizedBox(height: 18),
                          ],
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _placeRow(GymColors gc, String preset) {
    final on = _places.containsKey(preset);
    final gear = {...?(_places[preset] ?? kPlacePresetGear[preset]), 'Bodyweight'};
    final n = fit.allExercises.where((e) => gear.contains(e.equipment)).length;
    return Semantics(
      button: true,
      selected: on,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() {
          if (_places.remove(preset) == null) {
            _places[preset] = {...?kPlacePresetGear[preset]}..remove('Bodyweight');
          }
        }),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              _rowIcon(gc, _placeIcons[preset]!, color: on ? gc.ember : null),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.placePresetName(preset),
                        style: AppTheme.f(14.5,
                            weight: on ? FontWeight.w800 : FontWeight.w600, color: on ? gc.ember : gc.text)),
                    const SizedBox(height: 2),
                    Text(t.exerciseCount(n),
                        style: AppTheme.f(12, weight: FontWeight.w500, color: gc.textSecondary)),
                  ],
                ),
              ),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: on ? 1 : 0,
                child: Icon(PhosphorIconsFill.checkCircle, size: 18, color: gc.ember),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _up(VoidCallback action) {
    action();
    setState(() {});
  }
}

class _Glow extends StatelessWidget {
  const _Glow(this.gc);

  final GymColors gc;

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0.9, -0.85),
              radius: 1.1,
              colors: [gc.ember.withValues(alpha: 0.12), gc.bg.withValues(alpha: 0)],
            ),
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(-0.9, 0.9),
                radius: 1.0,
                colors: [gc.brass.withValues(alpha: 0.07), gc.bg.withValues(alpha: 0)],
              ),
            ),
            child: const SizedBox.expand(),
          ),
        ),
      );
}
