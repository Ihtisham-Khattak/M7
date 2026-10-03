import 'package:flutter/semantics.dart';
import 'package:flutter/material.dart';

import '../catalog/body_svg.dart';
import '../l10n/l10n.dart';
import '../state/fit_state.dart';
import '../theme/app_colors.dart';
import 'svg_icon.dart';

const double kBodyAspect = bodyViewH / bodyViewW;

String? muscleAt(Offset p) {
  for (final id in muscleFills.keys) {
    final hits = muscleHits[id];
    final probes = (hits != null && hits.isNotEmpty) ? hits : muscleFills[id]!;
    for (final d in probes) {
      if (svgPath(d).contains(p)) return id;
    }
  }
  return null;
}

Color idleMuscle(GymColors gc) => Color.lerp(gc.bgRaised2, gc.textSecondary, 0.32)!;

const Map<String, List<Color>> kHeatRampsDark = {
  'ember': [Color(0xFF5E2A21), Color(0xFF93392A), Color(0xFFC84630), Color(0xFFE8553D)],
  'green': [Color(0xFF2E3F2A), Color(0xFF4A6B3A), Color(0xFF6F9460), Color(0xFF9DB387)],
  'blue': [Color(0xFF2E3C6B), Color(0xFF3C5090), Color(0xFF5E78C4), Color(0xFF93A7DB)],
  'mono': [Color(0xFF3A3835), Color(0xFF5E5B56), Color(0xFF8C8880), Color(0xFFD8D3C9)],
};

const Map<String, List<Color>> kHeatRampsLight = {
  'ember': [Color(0xFFE8AB9C), Color(0xFFDD8B79), Color(0xFFC85A42), Color(0xFF8F2815)],
  'green': [Color(0xFFA9C79A), Color(0xFF7FA66F), Color(0xFF5F8A4E), Color(0xFF365A29)],
  'blue': [Color(0xFFAEBBE0), Color(0xFF8EA2D6), Color(0xFF4F6AB0), Color(0xFF2F4A8A)],
  'mono': [Color(0xFFBDB5A4), Color(0xFF8E8674), Color(0xFF6D6657), Color(0xFF3A352D)],
};

const List<String> kHeatTones = ['ember', 'green', 'blue', 'mono'];

List<Color> heatRamp(GymColors gc, String tone) {
  final table = gc.bg.computeLuminance() < 0.5 ? kHeatRampsDark : kHeatRampsLight;
  return table[tone] ?? table['ember']!;
}

Color heatLevelColor(GymColors gc, int level, {String? tone}) {
  if (level <= 0) return idleMuscle(gc);
  final ramp = heatRamp(gc, tone ?? fit.heatTone);
  return ramp[(level - 1).clamp(0, heatLevels - 1)];
}

Color heatColor(GymColors gc, double v) => heatLevelColor(gc, heatLevel(v));

String heatToken(Map<String, double> intensity) {
  final keys = intensity.keys.toList()..sort();
  return keys.map((k) => '$k${(intensity[k]! * 100).round()}').join(',');
}

class BodyMap extends StatelessWidget {
  const BodyMap({super.key, required this.selected, required this.onToggle});

  final Set<String> selected;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    final gc = context.gc;
    final muscle = idleMuscle(gc);
    final names = (selected.toList()..sort()).map(t.muscle).join(', ');
    return _BodyCanvas(
      onTap: onToggle,
      summary: selected.isEmpty ? t.bodyMapNone : t.bodyMapLabel(names),
      painter: BodyPainter(
        gc: gc,
        token: (selected.toList()..sort()).join(','),
        color: (id) => selected.contains(id) ? gc.ember : muscle,
        picked: selected,
        onPick: onToggle,
        direction: Directionality.of(context),
      ),
    );
  }
}

class BodyHeatMap extends StatelessWidget {
  const BodyHeatMap({super.key, required this.intensity, this.focus, this.onTap});

  final Map<String, double> intensity;
  final String? focus;
  final ValueChanged<String>? onTap;

  String get _token => heatToken(intensity);

  @override
  Widget build(BuildContext context) {
    final gc = context.gc;
    return _BodyCanvas(
      onTap: onTap,
      painter: BodyPainter(
        gc: gc,
        token: _token,
        color: (id) => heatColor(gc, intensity[id] ?? 0),
        outline: focus,
        picked: {?focus},
        onPick: onTap,
        direction: Directionality.of(context),
      ),
    );
  }
}

Color recoveryColor(GymColors gc, double recovered) {
  final v = recovered.clamp(0.0, 1.0);
  final fresh = Color.lerp(idleMuscle(gc), gc.sage, 0.62)!;
  if (v < 0.5) return Color.lerp(gc.danger, gc.warn, v / 0.5)!;
  return Color.lerp(gc.warn, fresh, (v - 0.5) / 0.5)!;
}

class BodyRecoveryMap extends StatelessWidget {
  const BodyRecoveryMap({super.key, required this.recovery, this.focus, this.onTap});

  final Map<String, double> recovery;
  final String? focus;
  final ValueChanged<String>? onTap;

  @override
  Widget build(BuildContext context) {
    final gc = context.gc;
    return _BodyCanvas(
      onTap: onTap,
      painter: BodyPainter(
        gc: gc,
        token: 'r${heatToken(recovery)}',
        color: (id) => recoveryColor(gc, recovery[id] ?? 1),
        outline: focus,
        picked: {?focus},
        onPick: onTap,
        direction: Directionality.of(context),
      ),
    );
  }
}

class BodyHeatArt extends StatelessWidget {
  const BodyHeatArt({super.key, required this.gc, required this.intensity, required this.width});

  final GymColors gc;
  final Map<String, double> intensity;
  final double width;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(width, width * kBodyAspect),
      painter: BodyPainter(
        gc: gc,
        token: heatToken(intensity),
        color: (id) => heatColor(gc, intensity[id] ?? 0),
      ),
    );
  }
}

class _BodyCanvas extends StatelessWidget {
  const _BodyCanvas({required this.painter, this.onTap, this.summary});

  final BodyPainter painter;
  final ValueChanged<String>? onTap;
  final String? summary;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth;
      final scale = w / bodyViewW;
      return Semantics(
        container: true,
        label: summary,
        child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: onTap == null
            ? null
            : (d) {
                final p = Offset(d.localPosition.dx / scale, d.localPosition.dy / scale);
                final id = muscleAt(p);
                if (id != null) onTap!(id);
              },
        child: CustomPaint(size: Size(w, w * kBodyAspect), painter: painter),
      ),
      );
    });
  }
}

class BodyPainter extends CustomPainter {
  BodyPainter({
    required this.gc,
    required this.color,
    required this.token,
    this.outline,
    this.picked = const {},
    this.onPick,
    this.direction = TextDirection.ltr,
  });

  /// Muscles shown as selected to a screen reader, and what a double tap on one does.
  final Set<String> picked;
  final ValueChanged<String>? onPick;
  final TextDirection direction;
  final GymColors gc;
  final Color Function(String id) color;
  final String token;
  final String? outline;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / bodyViewW);

    final bodyMain = gc.bgRaised2;
    final bodyLite = Color.lerp(gc.bgRaised2, gc.textTertiary, 0.14)!;

    void fill(String d, Color c) =>
        canvas.drawPath(svgPath(d), Paint()..color = c..style = PaintingStyle.fill..isAntiAlias = true);

    for (final d in bodyBaseMain) {
      fill(d, bodyMain);
    }
    for (final d in bodyBaseLite) {
      fill(d, bodyLite);
    }
    for (final entry in muscleFills.entries) {
      final c = color(entry.key);
      for (final d in entry.value) {
        fill(d, c);
      }
    }

    final id = outline;
    if (id != null) {
      final stroke = Paint()
        ..color = gc.text
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..isAntiAlias = true;
      for (final d in muscleFills[id] ?? const <String>[]) {
        canvas.drawPath(svgPath(d), stroke);
      }
    }
  }

  @override
  SemanticsBuilderCallback? get semanticsBuilder => onPick == null
      ? null
      : (size) {
          final scale = size.width / bodyViewW;
          final out = <CustomPainterSemantics>[];
          for (final entry in muscleFills.entries) {
            Rect? box;
            for (final d in entry.value) {
              final b = svgPath(d).getBounds();
              box = box == null ? b : box.expandToInclude(b);
            }
            if (box == null) continue;
            final id = entry.key;
            out.add(CustomPainterSemantics(
              key: ValueKey(id),
              rect: Rect.fromLTRB(box.left * scale, box.top * scale, box.right * scale, box.bottom * scale),
              properties: SemanticsProperties(
                label: t.muscle(id),
                textDirection: direction,
                button: true,
                selected: picked.contains(id),
                onTap: () => onPick!(id),
              ),
            ));
          }
          return out;
        };

  @override
  bool shouldRebuildSemantics(BodyPainter old) => old.token != token || old.outline != outline || old.picked != picked;

  @override
  bool shouldRepaint(BodyPainter old) =>
      old.gc != gc || old.token != token || old.outline != outline;
}
