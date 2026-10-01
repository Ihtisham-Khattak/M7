import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/tokens.dart';
import 'app_background.dart';
import 'ui_kit.dart';

class BackgroundPreview extends StatelessWidget {
  const BackgroundPreview({
    super.key,
    required this.pattern,
    required this.photo,
    required this.dim,
    required this.zoom,
    required this.dx,
    required this.dy,
    required this.opacity,
    required this.blur,
    required this.onMove,
    this.title = 'Today',
    this.line = 'Push day · 1 exercise',
  });

  final String pattern;
  final String? photo;
  final double dim;
  final double zoom;
  final double dx;
  final double dy;
  final double opacity;
  final double blur;
  final void Function(double dx, double dy) onMove;
  final String title;
  final String line;

  @override
  Widget build(BuildContext context) {
    final gc = context.gc;
    return Center(
      child: SizedBox(
        width: 168,
        child: AspectRatio(
          aspectRatio: 9 / 16,
          child: LayoutBuilder(
            builder: (context, box) => GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanUpdate: (d) => onMove(
                dx - d.delta.dx / (box.maxWidth / 2),
                dy - d.delta.dy / (box.maxHeight / 2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(GymRadius.lg),
                child: DecoratedBox(
                  decoration: BoxDecoration(color: gc.bg, border: Border.all(color: gc.border)),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      AppBackground(
                        pattern: pattern,
                        photo: photo,
                        dim: dim,
                        zoom: zoom,
                        dx: dx,
                        dy: dy,
                        opacity: opacity,
                        blur: blur,
                      ),
                      Padding(
                        padding: const EdgeInsets.all(GymSpace.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title.toUpperCase(), style: GymText.caption(color: gc.textTertiary, weight: FontWeight.w700)),
                            const SizedBox(height: GymSpace.xs),
                            Text(title, style: GymText.title(color: gc.text)),
                            const SizedBox(height: GymSpace.md),
                            SoftCard(
                              radius: GymRadius.md,
                              padding: const EdgeInsets.all(GymSpace.md),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(line, style: GymText.caption(color: gc.textSecondary)),
                                  const SizedBox(height: GymSpace.sm),
                                  Container(
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: gc.ember,
                                      borderRadius: BorderRadius.circular(GymRadius.sm),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
