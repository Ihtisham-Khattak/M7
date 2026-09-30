import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import 'glass.dart';
import 'ui_kit.dart';

AlertDialog appDialog(
  GymColors gc, {
  required Widget title,
  required Widget content,
  required List<Widget> actions,
}) =>
    AlertDialog(
      backgroundColor: gc.bgRaised,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      titlePadding: const EdgeInsets.fromLTRB(GymSpace.xxl, GymSpace.xxl, GymSpace.xxl, 10),
      contentPadding: const EdgeInsets.fromLTRB(GymSpace.xxl, 0, GymSpace.xxl, GymSpace.sm),
      actionsPadding: const EdgeInsets.fromLTRB(GymSpace.lg, 0, GymSpace.lg, GymSpace.md),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(GymRadius.xl)),
      title: title,
      content: content,
      actions: actions,
    );

Widget dialogAction(String label, Color color, VoidCallback onPressed, {bool strong = true}) =>
    TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: GymSpace.lg, vertical: GymSpace.md),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(GymRadius.pill)),
      ),
      child: Text(titleCase(label),
          style: AppTheme.f(GymText.bodySize,
              weight: strong ? FontWeight.w700 : FontWeight.w600, color: color)),
    );

Future<bool> askConfirm(
  BuildContext context, {
  required String title,
  required String body,
  required String confirmLabel,
  String? cancelLabel,
  bool danger = false,
}) async {
  final gc = context.gc;
  final ok = await showAppDialog<bool>(
    context: context,
    builder: (dctx) => appDialog(
      gc,
      title: Text(title, style: AppTheme.f(GymText.headlineSize, weight: FontWeight.w800, color: gc.text)),
      content: Text(body,
          style: AppTheme.f(GymText.labelSize,
              weight: FontWeight.w500, color: gc.textSecondary, height: 1.45)),
      actions: [
        dialogAction(cancelLabel ?? t.cancel, gc.textSecondary, () => Navigator.of(dctx).pop(false),
            strong: false),
        dialogAction(confirmLabel, danger ? gc.danger : gc.accent, () => Navigator.of(dctx).pop(true)),
      ],
    ),
  );
  return ok ?? false;
}

Future<String?> askText(
  BuildContext context, {
  required String title,
  String initial = '',
  String hint = '',
}) async {
  final gc = context.gc;
  final controller = TextEditingController(text: initial)
    ..selection = TextSelection(baseOffset: 0, extentOffset: initial.length);
  final raw = await showAppDialog<String>(
    context: context,
    builder: (dctx) => appDialog(
      gc,
      title: Text(title, style: AppTheme.d(GymText.titleSize, weight: FontWeight.w700, color: gc.text)),
      content: TextField(
        controller: controller,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        style: AppTheme.s(GymText.bodyLargeSize, color: gc.text),
        cursorColor: gc.accent,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppTheme.s(GymText.bodyLargeSize, color: gc.textTertiary),
          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: gc.border)),
          focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: gc.accent)),
        ),
        onSubmitted: (v) => Navigator.of(dctx).pop(v),
      ),
      actions: [
        dialogAction(t.cancel, gc.textSecondary, () => Navigator.of(dctx).pop(), strong: false),
        dialogAction(t.save, gc.accent, () => Navigator.of(dctx).pop(controller.text)),
      ],
    ),
  );
  controller.dispose();
  final text = raw?.trim() ?? '';
  return text.isEmpty ? null : text;
}

Future<double?> askNumber(
  BuildContext context, {
  required String title,
  required String initial,
  required bool decimal,
}) async {
  final gc = context.gc;
  final controller = TextEditingController(text: initial)
    ..selection = TextSelection(baseOffset: 0, extentOffset: initial.length);

  final raw = await showAppDialog<String>(
    context: context,
    builder: (dctx) => appDialog(
      gc,
      title: Text(titleCase(title), style: AppTheme.f(GymText.headlineSize, weight: FontWeight.w800, color: gc.text)),
      content: TextField(
        controller: controller,
        autofocus: true,
        keyboardType: TextInputType.numberWithOptions(decimal: decimal),
        textAlign: TextAlign.center,
        style: AppTheme.f(GymText.displaySize, weight: FontWeight.w800, color: gc.text, height: 1.1),
        cursorColor: gc.accent,
        onSubmitted: (v) => Navigator.of(dctx).pop(v),
        decoration: InputDecoration(
          filled: true,
          fillColor: gc.bgRaised2,
          contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: GymSpace.lg),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(GymRadius.md), borderSide: BorderSide.none),
        ),
      ),
      actions: [
        dialogAction(t.cancel, gc.textSecondary, () => Navigator.of(dctx).pop(), strong: false),
        dialogAction(t.set, gc.accent, () => Navigator.of(dctx).pop(controller.text)),
      ],
    ),
  );
  controller.dispose();

  return double.tryParse((raw ?? '').trim().replaceAll(',', '.'));
}
