import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import 'ui_kit.dart';

class ChoiceCard extends StatelessWidget {
  const ChoiceCard({
    super.key,
    required this.title,
    required this.body,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String title;
  final String body;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final gc = context.gc;
    return Semantics(
      button: true,
      selected: selected,
      label: title,
      hint: body,
      excludeSemantics: true,
      onTap: onTap,
      child: Pressable(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          constraints: const BoxConstraints(minHeight: GymSpace.minTarget + GymSpace.lg),
          padding: const EdgeInsets.all(GymSpace.lg),
          decoration: BoxDecoration(
            color: selected ? gc.bgRaised2 : gc.bgRaised,
            borderRadius: BorderRadius.circular(GymRadius.lg),
            border: Border.all(color: selected ? gc.ember : Colors.transparent, width: 1.6),
          ),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 24, color: selected ? gc.ember : gc.textSecondary),
                const SizedBox(width: GymSpace.md),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: GymText.bodyLarge(color: gc.text, weight: FontWeight.w700)),
                    const SizedBox(height: 3),
                    Text(body, style: AppTheme.f(GymText.captionSize, weight: FontWeight.w500, color: gc.textSecondary, height: 1.4)),
                  ],
                ),
              ),
              const SizedBox(width: GymSpace.sm),
              Icon(
                selected ? PhosphorIconsFill.checkCircle : PhosphorIconsRegular.circle,
                size: 22,
                color: selected ? gc.ember : gc.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SelectChip extends StatelessWidget {
  const SelectChip({super.key, required this.label, required this.selected, required this.onTap, this.enabled = true});

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final gc = context.gc;
    return Semantics(
      button: true,
      selected: selected,
      enabled: enabled,
      label: label,
      excludeSemantics: true,
      onTap: enabled ? onTap : null,
      child: Pressable(
        onTap: enabled ? onTap : null,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: GymSpace.minTarget, minWidth: GymSpace.minTarget),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: GymSpace.lg, vertical: GymSpace.sm),
            decoration: BoxDecoration(
              color: selected ? gc.ember : gc.bgRaised,
              borderRadius: BorderRadius.circular(GymRadius.pill),
            ),
            child: Text(
              label,
              style: GymText.body(
                color: selected ? gc.onEmber : (enabled ? gc.text : gc.textTertiary),
                weight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class StepProgress extends StatelessWidget {
  const StepProgress({super.key, required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    final gc = context.gc;
    return Semantics(
      label: '${index + 1} / $count',
      excludeSemantics: true,
      child: Row(
        children: [
          for (var i = 0; i < count; i++)
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                margin: const EdgeInsets.only(right: 6),
                height: 3,
                decoration: BoxDecoration(
                  color: i <= index ? gc.text : gc.bgRaised2,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
