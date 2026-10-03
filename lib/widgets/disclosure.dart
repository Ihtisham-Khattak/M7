import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../services/local_store.dart';
import '../theme/app_colors.dart';
import '../theme/motion.dart';
import '../theme/tokens.dart';
import 'ui_kit.dart';

/// A titled group that opens and closes (GM-18). The open/closed choice is remembered between
/// launches, the header is announced as an expandable button, and what is inside stays in the
/// tree while closed so opening it costs nothing and nothing jumps when data arrives.
class Disclosure extends StatefulWidget {
  const Disclosure({
    super.key,
    required this.id,
    required this.title,
    required this.child,
    this.summary,
    this.initiallyOpen = false,
  });

  final String id;
  final String title;

  /// One line shown next to the title while closed (e.g. "3 records").
  final String? summary;
  final Widget child;
  final bool initiallyOpen;

  @override
  State<Disclosure> createState() => _DisclosureState();
}

class _DisclosureState extends State<Disclosure> {
  late bool _open = _read();

  String get _key => 'disclosure_${widget.id}';

  bool _read() {
    try {
      final saved = Store.instance.note(_key);
      return saved == null || saved.isEmpty ? widget.initiallyOpen : saved == '1';
    } catch (_) {
      return widget.initiallyOpen;
    }
  }

  void _toggle() {
    setState(() => _open = !_open);
    try {
      Store.instance.setNote(_key, _open ? '1' : '0');
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final gc = context.gc;
    final reduced = GymMotion.reduced(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          button: true,
          expanded: _open,
          label: widget.title,
          excludeSemantics: true,
          onTap: _toggle,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _toggle,
            child: MinTarget(
              alignment: AlignmentDirectional.centerStart,
              child: Row(
                children: [
                  Expanded(
                    child: Text(widget.title, style: GymText.headline(color: gc.text, weight: FontWeight.w600)),
                  ),
                  if (!_open && widget.summary != null) ...[
                    Flexible(
                      child: Text(widget.summary!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GymText.caption(color: gc.textTertiary)),
                    ),
                    const SizedBox(width: GymSpace.sm),
                  ],
                  AnimatedRotation(
                    turns: _open ? 0.5 : 0,
                    duration: reduced ? Duration.zero : GymMotion.fast,
                    child: Icon(PhosphorIconsBold.caretDown, size: GymSpace.lg, color: gc.textTertiary),
                  ),
                ],
              ),
            ),
          ),
        ),
        AnimatedSize(
          duration: reduced ? Duration.zero : GymMotion.tab,
          curve: GymMotion.curve,
          alignment: Alignment.topCenter,
          child: _open
              ? Padding(padding: const EdgeInsets.only(top: GymSpace.sm), child: widget.child)
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}
