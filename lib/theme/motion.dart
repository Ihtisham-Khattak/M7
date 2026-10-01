import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

/// Motion budget (GM-19): the more often an action happens, the less it moves.
///
/// * tab ↔ tab (many times a day): crossfade only, [tab]
/// * pushing / popping a screen: short fade + small shift, [push]
/// * press and toggle feedback: [fast]
/// * everything is ease-out and interruptible; nothing bounces
/// * with the system "remove animations" setting there is no movement at all:
///   state changes still happen, as a short fade ([reducedFade]) or instantly.
class GymMotion {
  GymMotion._();

  static const Duration fast = Duration(milliseconds: 120);
  static const Duration tab = Duration(milliseconds: 160);
  static const Duration push = Duration(milliseconds: 240);
  static const Duration reducedFade = Duration(milliseconds: 100);

  /// Upper bounds the motion tests hold the app to.
  static const Duration maxTab = Duration(milliseconds: 200);
  static const Duration maxPush = Duration(milliseconds: 300);

  static const Curve curve = Curves.easeOutCubic;
  static const double pushShift = 14;

  static bool reduced(BuildContext context) => MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  /// For code that runs before a [BuildContext] can be used (`initState`).
  static bool get platformReduced =>
      WidgetsBinding.instance.platformDispatcher.accessibilityFeatures.disableAnimations;

  static Duration of(BuildContext context, Duration d) => reduced(context) ? Duration.zero : d;
}
