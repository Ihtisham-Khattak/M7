import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../theme/app_colors.dart';
import '../theme/tokens.dart';
import 'components.dart';
import 'shimmer.dart';

/// Calm, short states (GM-13): one icon from the existing set, one line of title, one line of
/// guidance, one action. No illustrations or emoji.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.body,
    this.actionLabel,
    this.onAction,
    this.child,
    this.compact = false,
  });

  final IconData icon;
  final String title;
  final String? body;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// Extra content between the text and the action (e.g. a row of presets).
  final Widget? child;

  /// Less vertical space, for sheets and inline use.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final gc = context.gc;
    final pad = compact ? GymSpace.lg : GymSpace.xxxl;
    return Semantics(
      container: true,
      label: [title, ?body].join('. '),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: GymSpace.xxl, vertical: pad),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ExcludeSemantics(child: Icon(icon, size: compact ? 28 : 36, color: gc.textTertiary)),
            const SizedBox(height: GymSpace.md),
            Text(title,
                textAlign: TextAlign.center,
                style: GymText.title(color: gc.text, weight: FontWeight.w600)),
            if (body != null) ...[
              const SizedBox(height: GymSpace.sm),
              Text(body!,
                  textAlign: TextAlign.center,
                  style: GymText.body(color: gc.textSecondary).copyWith(height: 1.45)),
            ],
            if (child != null) ...[const SizedBox(height: GymSpace.lg), child!],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: GymSpace.lg),
              GymButton(
                label: actionLabel!,
                onTap: onAction,
                kind: GymButtonKind.secondary,
                size: GymButtonSize.compact,
                expand: false,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Quiet placeholder rows while something loads. Uses the existing shimmer, no spinner.
class LoadingSkeleton extends StatelessWidget {
  const LoadingSkeleton({super.key, this.rows = 3, this.rowHeight = 56, this.semanticLabel});

  final int rows;
  final double rowHeight;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      liveRegion: semanticLabel != null,
      child: ExcludeSemantics(
        child: Column(
          children: [
            for (var i = 0; i < rows; i++) ...[
              if (i > 0) const SizedBox(height: GymSpace.sm),
              SizedBox(height: rowHeight, width: double.infinity, child: Shimmer(radius: GymRadius.md)),
            ],
          ],
        ),
      ),
    );
  }
}

/// A failure that stays where it happened: message, and a way to try again when there is one.
class InlineError extends StatelessWidget {
  const InlineError({super.key, required this.message, this.actionLabel, this.onAction});

  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final gc = context.gc;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          liveRegion: true,
          label: message,
          child: ExcludeSemantics(
            child: Row(
              children: [
                Icon(PhosphorIconsRegular.warningCircle, size: 18, color: gc.warn),
                const SizedBox(width: GymSpace.sm),
                Expanded(child: Text(message, style: GymText.label(color: gc.textSecondary))),
              ],
            ),
          ),
        ),
        if (actionLabel != null && onAction != null)
          GymButton(
            label: actionLabel!,
            onTap: onAction,
            kind: GymButtonKind.text,
            size: GymButtonSize.compact,
            expand: false,
          ),
      ],
    );
  }
}
