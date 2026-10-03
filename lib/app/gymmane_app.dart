import 'brand.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../l10n/l10n.dart';
import '../state/fit_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'app_shell.dart';

class GymManeApp extends StatelessWidget {
  const GymManeApp({super.key});

  static const maxTextScale = 2.0;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: fit,
      builder: (context, _) => MaterialApp(
        title: kAppName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: fit.themeMode,
        locale: fit.locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        builder: (context, child) => MediaQuery.withClampedTextScaling(
          maxScaleFactor: maxTextScale,
          child: ReadableWidth(child: _ButtonNavScrim(child: child!)),
        ),
        home: const AppShell(),
      ),
    );
  }
}

class _ButtonNavScrim extends StatelessWidget {
  const _ButtonNavScrim({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final bar = MediaQuery.viewPaddingOf(context).bottom;
    final buttons = MediaQuery.systemGestureInsetsOf(context).left == 0;
    return Stack(
      children: [
        child,
        if (buttons && bar > 0)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: bar,
            child: IgnorePointer(child: ColoredBox(color: context.gc.bg)),
          ),
      ],
    );
  }
}

/// On a tablet or foldable the app keeps phone proportions: content is centred in a column of at
/// most [maxWidth] dp instead of stretching across the screen (GM-21).
class ReadableWidth extends StatelessWidget {
  const ReadableWidth({super.key, required this.child, this.maxWidth = 640});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    if (media.size.width <= maxWidth) return child;
    return ColoredBox(
      color: context.gc.bg,
      child: Center(
        child: SizedBox(
          width: maxWidth,
          child: MediaQuery(data: media.copyWith(size: Size(maxWidth, media.size.height)), child: child),
        ),
      ),
    );
  }
}
