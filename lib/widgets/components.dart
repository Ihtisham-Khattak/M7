import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../theme/app_colors.dart';
import '../theme/tokens.dart';
import 'glass.dart';
import 'ui_kit.dart';

/// The core component set (GM-12). Screens compose these instead of building
/// their own containers; the catalogue lives in DEVELOPMENT_GUIDELINES and
/// `test/components_test.dart` renders every variant.

enum GymButtonKind { primary, secondary, text, destructive }

enum GymButtonSize { regular, compact }

class GymButton extends StatelessWidget {
  const GymButton({
    super.key,
    required this.label,
    required this.onTap,
    this.kind = GymButtonKind.primary,
    this.size = GymButtonSize.regular,
    this.leading,
    this.loading = false,
    this.expand = true,
    this.height,
    this.background,
    this.foreground,
  });

  final String label;

  /// `null` disables the button.
  final VoidCallback? onTap;
  final GymButtonKind kind;
  final GymButtonSize size;
  final Widget? leading;
  final bool loading;
  final bool expand;
  final double? height;
  final Color? background;
  final Color? foreground;

  static const double regularHeight = 56;
  static const double compactHeight = GymSpace.minTarget;

  @override
  Widget build(BuildContext context) {
    final gc = context.gc;
    final (Color bg, Color fg, Color? line) = switch (kind) {
      GymButtonKind.primary => (gc.ember, gc.onEmber, null),
      GymButtonKind.secondary => (gc.bgRaised2, gc.text, null),
      GymButtonKind.text => (Colors.transparent, gc.ember, null),
      GymButtonKind.destructive => (Colors.transparent, gc.danger, gc.danger),
    };
    final fgColor = foreground ?? fg;
    final enabled = onTap != null && !loading;
    final h = height ?? (size == GymButtonSize.regular ? regularHeight : compactHeight);
    final text = Flexible(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(titleCase(label),
            maxLines: 1, style: GymText.button(color: fgColor).copyWith(letterSpacing: 0.2)),
      ),
    );
    return Semantics(
      button: true,
      enabled: enabled,
      child: Opacity(
        opacity: onTap == null ? 0.4 : 1,
        child: Pressable(
          onTap: enabled ? onTap : null,
          child: Container(
            width: expand ? double.infinity : null,
            constraints: BoxConstraints(minHeight: h, minWidth: GymSpace.minTarget),
            padding: const EdgeInsets.symmetric(horizontal: GymSpace.lg),
            decoration: BoxDecoration(
              color: background ?? bg,
              borderRadius: BorderRadius.circular(GymRadius.md),
              border: line == null ? null : Border.all(color: line, width: GymBorder.hairline),
            ),
            child: Row(
              mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (loading) ...[
                  ExcludeSemantics(
                    child: SizedBox(
                      width: GymSpace.lg,
                      height: GymSpace.lg,
                      child: CircularProgressIndicator(strokeWidth: 2, color: fgColor),
                    ),
                  ),
                  const SizedBox(width: GymSpace.sm),
                ] else if (leading != null) ...[
                  ExcludeSemantics(child: leading!),
                  const SizedBox(width: GymSpace.sm),
                ],
                text,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum GymCardKind { flat, raised, glass }

class GymCard extends StatelessWidget {
  const GymCard({
    super.key,
    required this.child,
    this.kind = GymCardKind.flat,
    this.padding = const EdgeInsets.all(GymSpace.lg),
    this.radius = GymRadius.lg,
    this.onTap,
    this.semanticLabel,
    this.borderless = false,
    this.clip = false,
    this.color,
    this.borderColor,
  });

  final Widget child;
  final GymCardKind kind;
  final EdgeInsets padding;
  final double radius;

  /// A card with `onTap` is a button: press feedback and button semantics.
  final VoidCallback? onTap;
  final String? semanticLabel;
  final bool borderless;
  final bool clip;
  final Color? color;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final gc = context.gc;
    final Widget body = switch (kind) {
      GymCardKind.flat => SoftCard(
          radius: radius,
          padding: padding,
          color: color,
          borderColor: borderless ? Colors.transparent : borderColor,
          clip: clip,
          child: child,
        ),
      GymCardKind.raised => Container(
          padding: padding,
          decoration: BoxDecoration(
            color: gc.bgRaised,
            border: borderless ? null : Border.all(color: gc.border),
            borderRadius: BorderRadius.circular(radius),
            boxShadow: GymElevation.raised(gc),
          ),
          child: child,
        ),
      GymCardKind.glass => GlassSurface(radius: radius, padding: padding, child: child),
    };
    if (onTap == null) return body;
    return Semantics(
      button: true,
      label: semanticLabel,
      child: Pressable(onTap: onTap, scale: 0.98, child: body),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.onMore, this.trailing}) : _label = false;

  /// Small uppercase label that introduces a group of settings or fields.
  const SectionHeader.label(this.title, {super.key, this.trailing})
      : onMore = null,
        _label = true;

  final String title;
  final VoidCallback? onMore;
  final Widget? trailing;
  final bool _label;

  @override
  Widget build(BuildContext context) {
    final gc = context.gc;
    final text = _label
        ? Text(title.toUpperCase(),
            style: GymText.caption(color: gc.textTertiary, weight: FontWeight.w700).copyWith(letterSpacing: 1.3))
        : Text(titleCase(title), style: GymText.headline(color: gc.text, weight: FontWeight.w600));
    final row = Row(
      children: [
        Expanded(child: Semantics(header: true, child: text)),
        ?trailing,
        if (onMore != null) Icon(PhosphorIconsBold.caretRight, size: GymSpace.lg, color: gc.textTertiary),
      ],
    );
    if (onMore == null) return row;
    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onMore,
        child: MinTarget(alignment: AlignmentDirectional.centerStart, child: row),
      ),
    );
  }
}

class ListRow extends StatefulWidget {
  const ListRow({
    super.key,
    required this.title,
    this.icon,
    this.leading,
    this.subtitle,
    this.trailing,
    this.chevron = false,
    this.onTap,
    this.destructive = false,
    this.divider = false,
    this.dividerInset = 0,
    this.minHeight = 52,
    this.padding = const EdgeInsets.symmetric(horizontal: GymSpace.lg),
  });

  final String title;
  final IconData? icon;

  /// Replaces [icon] when the row needs its own media (thumbnail, avatar).
  final Widget? leading;
  final String? subtitle;
  final Widget? trailing;
  final bool chevron;
  final VoidCallback? onTap;
  final bool destructive;
  final bool divider;
  final double dividerInset;
  final double minHeight;
  final EdgeInsets padding;

  @override
  State<ListRow> createState() => _ListRowState();
}

class _ListRowState extends State<ListRow> {
  bool _down = false;

  void _set(bool v) {
    if (_down != v && mounted) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final gc = context.gc;
    final tone = widget.destructive ? gc.danger : gc.text;
    final lead = widget.leading ??
        (widget.icon == null
            ? null
            : SizedBox(
                width: GymSpace.xxl,
                child: Icon(widget.icon, size: GymSpace.xl - 1, color: widget.destructive ? gc.danger : gc.textSecondary),
              ));
    final row = Container(
      constraints: BoxConstraints(minHeight: widget.minHeight < GymSpace.minTarget ? GymSpace.minTarget : widget.minHeight),
      padding: widget.padding,
      child: Row(
        children: [
          if (lead != null) ...[lead, const SizedBox(width: GymSpace.md)],
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: GymSpace.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(widget.title,
                      maxLines: widget.subtitle == null ? 2 : 1,
                      overflow: TextOverflow.ellipsis,
                      style: GymText.bodyLarge(color: tone)),
                  if (widget.subtitle != null) ...[
                    const SizedBox(height: GymSpace.xs),
                    Text(widget.subtitle!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GymText.caption(color: gc.textSecondary)),
                  ],
                ],
              ),
            ),
          ),
          if (widget.trailing != null) ...[const SizedBox(width: GymSpace.md), widget.trailing!],
          if (widget.chevron) ...[
            const SizedBox(width: GymSpace.sm),
            ExcludeSemantics(child: Icon(PhosphorIconsRegular.caretRight, size: GymSpace.lg, color: gc.textTertiary)),
          ],
        ],
      ),
    );
    final decorated = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: MediaQuery.maybeDisableAnimationsOf(context) == true ? Duration.zero : const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          color: _down ? gc.bgRaised2.withValues(alpha: 0.6) : Colors.transparent,
          child: row,
        ),
        if (widget.divider)
          Container(
            margin: EdgeInsets.only(left: widget.dividerInset),
            height: GymBorder.hairline,
            color: gc.border.withValues(alpha: 0.6),
          ),
      ],
    );
    if (widget.onTap == null) return decorated;
    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onTapDown: (_) => _set(true),
        onTapUp: (_) => _set(false),
        onTapCancel: () => _set(false),
        child: decorated,
      ),
    );
  }
}
