import 'package:flutter/material.dart';

@immutable
class GymColors extends ThemeExtension<GymColors> {
  const GymColors({
    required this.pageBg,
    required this.bg,
    required this.bgRaised,
    required this.bgRaised2,
    required this.border,
    required this.navBg,
    required this.text,
    required this.textSecondary,
    required this.textTertiary,
    required this.ember,
    required this.emberDeep,
    required this.onEmber,
    required this.emberSoft,
    required this.emberShadow,
    required this.accent,
    required this.accentSoft,
    required this.brass,
    required this.sage,
    required this.sageSoft,
    required this.mutedFill,
    required this.heatEmpty,
    required this.info,
    required this.warn,
    required this.danger,
    required this.success,
    required this.progress,
    required this.streak,
  });

  final Color pageBg;
  final Color bg;
  final Color bgRaised;
  final Color bgRaised2;
  final Color border;
  final Color navBg;
  final Color text;
  final Color textSecondary;
  final Color textTertiary;
  final Color ember;
  final Color emberDeep;
  final Color onEmber;
  final Color emberSoft;
  final Color emberShadow;
  final Color accent;
  final Color accentSoft;
  final Color brass;
  final Color sage;
  final Color sageSoft;
  final Color mutedFill;
  final Color heatEmpty;
  final Color info;
  final Color warn;
  final Color danger;
  final Color success;
  final Color progress;
  final Color streak;

  static const dark = GymColors(
    pageBg: Color(0xFF0D0C0B),
    bg: Color(0xFF11100E),
    bgRaised: Color(0xFF1B1917),
    bgRaised2: Color(0xFF282522),
    border: Color(0xFF3B3733),
    navBg: Color(0xD911100E),
    text: Color(0xFFF3EFE8),
    textSecondary: Color(0xFFB9B2A7),
    textTertiary: Color(0xFF9A9387),
    ember: Color(0xFFE8553D),
    emberDeep: Color(0xFFC9432C),
    onEmber: Color(0xFF15110F),
    emberSoft: Color(0x24E8553D),
    emberShadow: Color(0x80000000),
    accent: Color(0xFFCDBFA9),
    accentSoft: Color(0x29CDBFA9),
    brass: Color(0xFFA89880),
    sage: Color(0xFF9DB387),
    sageSoft: Color(0x299DB387),
    mutedFill: Color(0xFF2A2724),
    heatEmpty: Color(0xFF23211E),
    info: Color(0xFF93A7DB),
    warn: Color(0xFFE0B15A),
    danger: Color(0xFFE56A82),
    success: Color(0xFF86BA8E),
    progress: Color(0xFFE8553D),
    streak: Color(0xFFE3A857),
  );

  static const light = GymColors(
    pageBg: Color(0xFFFBF8F3),
    bg: Color(0xFFF4EFE6),
    bgRaised: Color(0xFFFFFDF9),
    bgRaised2: Color(0xFFEAE3D6),
    border: Color(0xFFD8CFBF),
    navBg: Color(0xF2FBF8F3),
    text: Color(0xFF1B1713),
    textSecondary: Color(0xFF4B443B),
    textTertiary: Color(0xFF6B6357),
    ember: Color(0xFFB3361F),
    emberDeep: Color(0xFF8F2815),
    onEmber: Color(0xFFFFFFFF),
    emberSoft: Color(0x1FB3361F),
    emberShadow: Color(0x1F1B1713),
    accent: Color(0xFF6E5B3E),
    accentSoft: Color(0x1F6E5B3E),
    brass: Color(0xFF75654A),
    sage: Color(0xFF4A6B3A),
    sageSoft: Color(0x1F4A6B3A),
    mutedFill: Color(0xFFE6DFD2),
    heatEmpty: Color(0xFFE3DCCE),
    info: Color(0xFF2F4A8A),
    warn: Color(0xFF87590C),
    danger: Color(0xFFAE233D),
    success: Color(0xFF2E6B43),
    progress: Color(0xFFB3361F),
    streak: Color(0xFF8F5300),
  );

  @override
  GymColors copyWith({
    Color? pageBg,
    Color? bg,
    Color? bgRaised,
    Color? bgRaised2,
    Color? border,
    Color? navBg,
    Color? text,
    Color? textSecondary,
    Color? textTertiary,
    Color? ember,
    Color? emberDeep,
    Color? onEmber,
    Color? emberSoft,
    Color? emberShadow,
    Color? accent,
    Color? accentSoft,
    Color? brass,
    Color? sage,
    Color? sageSoft,
    Color? mutedFill,
    Color? heatEmpty,
    Color? info,
    Color? warn,
    Color? danger,
    Color? success,
    Color? progress,
    Color? streak,
  }) {
    return GymColors(
      pageBg: pageBg ?? this.pageBg,
      bg: bg ?? this.bg,
      bgRaised: bgRaised ?? this.bgRaised,
      bgRaised2: bgRaised2 ?? this.bgRaised2,
      border: border ?? this.border,
      navBg: navBg ?? this.navBg,
      text: text ?? this.text,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      ember: ember ?? this.ember,
      emberDeep: emberDeep ?? this.emberDeep,
      onEmber: onEmber ?? this.onEmber,
      emberSoft: emberSoft ?? this.emberSoft,
      emberShadow: emberShadow ?? this.emberShadow,
      accent: accent ?? this.accent,
      accentSoft: accentSoft ?? this.accentSoft,
      brass: brass ?? this.brass,
      sage: sage ?? this.sage,
      sageSoft: sageSoft ?? this.sageSoft,
      mutedFill: mutedFill ?? this.mutedFill,
      heatEmpty: heatEmpty ?? this.heatEmpty,
      info: info ?? this.info,
      warn: warn ?? this.warn,
      danger: danger ?? this.danger,
      success: success ?? this.success,
      progress: progress ?? this.progress,
      streak: streak ?? this.streak,
    );
  }

  @override
  GymColors lerp(GymColors? other, double t) {
    if (other == null) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    return GymColors(
      pageBg: c(pageBg, other.pageBg),
      bg: c(bg, other.bg),
      bgRaised: c(bgRaised, other.bgRaised),
      bgRaised2: c(bgRaised2, other.bgRaised2),
      border: c(border, other.border),
      navBg: c(navBg, other.navBg),
      text: c(text, other.text),
      textSecondary: c(textSecondary, other.textSecondary),
      textTertiary: c(textTertiary, other.textTertiary),
      ember: c(ember, other.ember),
      emberDeep: c(emberDeep, other.emberDeep),
      onEmber: c(onEmber, other.onEmber),
      emberSoft: c(emberSoft, other.emberSoft),
      emberShadow: c(emberShadow, other.emberShadow),
      accent: c(accent, other.accent),
      accentSoft: c(accentSoft, other.accentSoft),
      brass: c(brass, other.brass),
      sage: c(sage, other.sage),
      sageSoft: c(sageSoft, other.sageSoft),
      mutedFill: c(mutedFill, other.mutedFill),
      heatEmpty: c(heatEmpty, other.heatEmpty),
      info: c(info, other.info),
      warn: c(warn, other.warn),
      danger: c(danger, other.danger),
      success: c(success, other.success),
      progress: c(progress, other.progress),
      streak: c(streak, other.streak),
    );
  }
}

extension GymColorsX on BuildContext {
  GymColors get gc => Theme.of(this).extension<GymColors>()!;
}
