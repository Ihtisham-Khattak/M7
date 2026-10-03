import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../l10n/l10n.dart';
import '../state/fit_state.dart';

/// Tells a screen reader about the rest timer, politely and rarely (GM-20): when the rest
/// starts, when ten seconds are left, and when it is over. The countdown itself is not read
/// out every second.
class RestAnnouncer extends StatefulWidget {
  const RestAnnouncer({super.key, this.announce});

  /// Replaced in tests; defaults to the platform announcement.
  final void Function(String message)? announce;

  @override
  State<RestAnnouncer> createState() => _RestAnnouncerState();
}

class _RestAnnouncerState extends State<RestAnnouncer> {
  int? _last;
  int _doneTick = fit.restDoneTick;
  bool _toldTen = false;

  @override
  void initState() {
    super.initState();
    _last = fit.session?.restRemaining;
    fit.addListener(_check);
  }

  @override
  void dispose() {
    fit.removeListener(_check);
    super.dispose();
  }

  void _say(String message) {
    final custom = widget.announce;
    if (custom != null) return custom(message);
    final view = View.maybeOf(context);
    if (view == null) return;
    SemanticsService.sendAnnouncement(view, message, Directionality.of(context), assertiveness: Assertiveness.polite);
  }

  void _check() {
    if (!mounted) return;
    final now = fit.session?.restRemaining;
    if (fit.restDoneTick != _doneTick) {
      _doneTick = fit.restDoneTick;
      _toldTen = false;
      _say(t.restOverTitle);
    } else if (now != null && _last == null) {
      _toldTen = now <= 10;
      _say(t.restLeftAnnounce(now));
    } else if (now != null && now <= 10 && !_toldTen) {
      _toldTen = true;
      _say(t.restLeftAnnounce(now));
    } else if (now == null) {
      _toldTen = false;
    }
    _last = now;
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
