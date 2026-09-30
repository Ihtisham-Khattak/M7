import 'package:flutter/material.dart';

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

  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 28;
  static const double pill = 100;

  static BorderRadius all(double r) => BorderRadius.circular(r);
}

class GymText {
  GymText._();

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

  static TextStyle display({Color? color, FontWeight weight = FontWeight.w800}) =>
      AppTheme.f(displaySize, weight: weight, color: color);
}
