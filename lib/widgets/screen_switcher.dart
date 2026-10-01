import 'package:flutter/material.dart';

typedef ScreenTransitionBuilder = Widget Function(
  BuildContext context,
  Widget child,
  Animation<double> animation,
  bool incoming,
);

/// Cross-switches between screens like [AnimatedSwitcher], with one difference
/// that matters for the motion budget (GM-19): the duration is read when each
/// transition *starts*, for the screen coming in and the one leaving, so a tab
/// switch is fast even if the screen being left was opened by a slower push.
class ScreenSwitcher extends StatefulWidget {
  const ScreenSwitcher({
    super.key,
    required this.screenKey,
    required this.child,
    required this.duration,
    required this.builder,
    this.inCurve = Curves.linear,
    this.outCurve = Curves.linear,
  });

  final Object screenKey;
  final Widget child;
  final Duration duration;
  final ScreenTransitionBuilder builder;
  final Curve inCurve;
  final Curve outCurve;

  @override
  State<ScreenSwitcher> createState() => _ScreenSwitcherState();
}

class _Entry {
  _Entry(this.id, this.screenKey, this.child, this.controller, this.animation);

  final int id;
  final Object screenKey;
  Widget child;
  final AnimationController controller;
  final Animation<double> animation;
  bool leaving = false;
}

class _ScreenSwitcherState extends State<ScreenSwitcher> with TickerProviderStateMixin {
  final _entries = <_Entry>[];
  int _nextId = 0;

  _Entry _make(double value) {
    final c = AnimationController(vsync: this, duration: widget.duration, value: value);
    final a = CurvedAnimation(parent: c, curve: widget.inCurve, reverseCurve: widget.outCurve);
    return _Entry(_nextId++, widget.screenKey, widget.child, c, a);
  }

  @override
  void initState() {
    super.initState();
    _entries.add(_make(1));
  }

  @override
  void didUpdateWidget(ScreenSwitcher old) {
    super.didUpdateWidget(old);
    final current = _entries.lastWhere((e) => !e.leaving);
    if (current.screenKey == widget.screenKey) {
      current.child = widget.child;
      return;
    }
    current
      ..leaving = true
      ..controller.duration = widget.duration
      ..controller.reverse().whenComplete(() => _retire(current));
    final next = _make(0);
    _entries.add(next);
    next.controller.forward();
  }

  void _retire(_Entry e) {
    if (!mounted || !e.leaving) return;
    setState(() => _entries.remove(e));
    (e.animation as CurvedAnimation).dispose();
    e.controller.dispose();
  }

  @override
  void dispose() {
    for (final e in _entries) {
      (e.animation as CurvedAnimation).dispose();
      e.controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        for (final e in _entries)
          Positioned.fill(
            key: ValueKey(e.id),
            child: widget.builder(context, KeyedSubtree(key: ValueKey(e.screenKey), child: e.child), e.animation, !e.leaving),
          ),
      ],
    );
  }
}
