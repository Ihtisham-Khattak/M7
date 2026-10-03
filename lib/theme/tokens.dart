import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_theme.dart';

class GymSpace {
  GymSpace._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;

  static const double pageGutter = xl;
  static const double minTarget = 48;
}

class GymRadius {
  GymRadius._();

  static const double xs = 6;
  static const double sm = 10;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double pill = 100;
  static const double hair = 2;

  static BorderRadius all(double r) => BorderRadius.circular(r);
}

class GymBorder {
  GymBorder._();

  static const double hairline = 1;
  static const double emphasis = 1.6;
}

class GymElevation {
  GymElevation._();

  static const List<BoxShadow> none = [];

  static List<BoxShadow> raised(GymColors gc) => [
        BoxShadow(color: gc.emberShadow.withValues(alpha: gc.emberShadow.a * 0.55), blurRadius: 16, offset: const Offset(0, 5)),
      ];

  static List<BoxShadow> overlay(GymColors gc) => [
        BoxShadow(color: gc.emberShadow.withValues(alpha: gc.emberShadow.a * 0.8), blurRadius: 24, offset: const Offset(0, 10)),
      ];
}

class GymText {
  GymText._();

  static const double microSize = 11;
  static const double captionSize = 12;
  static const double labelSize = 13;
  static const double bodySize = 14;
  static const double bodyLargeSize = 15;
  static const double titleSize = 17;
  static const double headlineSize = 20;
  static const double displaySize = 34;

  static TextStyle caption({Color? color, FontWeight weight = FontWeight.w500}) =>
      AppTheme.f(captionSize, weight: weight, color: color);

  static TextStyle label({Color? color, FontWeight weight = FontWeight.w600}) =>
      AppTheme.f(labelSize, weight: weight, color: color);

  static TextStyle body({Color? color, FontWeight weight = FontWeight.w500}) =>
      AppTheme.f(bodySize, weight: weight, color: color);

  static TextStyle bodyLarge({Color? color, FontWeight weight = FontWeight.w500}) =>
      AppTheme.f(bodyLargeSize, weight: weight, color: color);

  static TextStyle button({Color? color}) => AppTheme.f(bodyLargeSize, weight: FontWeight.w700, color: color);

  static TextStyle title({Color? color, FontWeight weight = FontWeight.w700}) =>
      AppTheme.f(titleSize, weight: weight, color: color);

  static TextStyle headline({Color? color, FontWeight weight = FontWeight.w700}) =>
      AppTheme.f(headlineSize, weight: weight, color: color);

  static TextStyle numeric(double size, {Color? color, FontWeight weight = FontWeight.w700}) =>
      AppTheme.f(size, weight: weight, color: color, height: 1.0);

  static TextStyle display({Color? color, FontWeight weight = FontWeight.w800}) =>
      AppTheme.f(displaySize, weight: weight, color: color);
}
