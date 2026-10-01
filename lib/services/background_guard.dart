import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' show Color;

const double kMaxScrim = 0.92;

double _toLinear(double c) => c <= 0.03928 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();

double _toSrgb(double l) => l <= 0.0031308 ? l * 12.92 : 1.055 * math.pow(l, 1 / 2.4).toDouble() - 0.055;

double relativeLuminance(double r, double g, double b) =>
    0.2126 * _toLinear(r) + 0.7152 * _toLinear(g) + 0.0722 * _toLinear(b);

double luminanceOf(Color c) => relativeLuminance(c.r, c.g, c.b);

double contrastOfLuminances(double a, double b) {
  final hi = math.max(a, b), lo = math.min(a, b);
  return (hi + 0.05) / (lo + 0.05);
}

typedef ImageTones = ({double dark, double bright});

const ImageTones kUnknownTones = (dark: 0.0, bright: 1.0);

ImageTones analyzeTones(Uint8List rgba, {double percentile = 0.95}) {
  final pixels = rgba.length ~/ 4;
  if (pixels == 0) return kUnknownTones;
  final lums = List<double>.filled(pixels, 0);
  for (var i = 0; i < pixels; i++) {
    final a = rgba[i * 4 + 3] / 255;
    final r = rgba[i * 4] / 255, g = rgba[i * 4 + 1] / 255, b = rgba[i * 4 + 2] / 255;
    lums[i] = relativeLuminance(r * a + (1 - a) * 0.5, g * a + (1 - a) * 0.5, b * a + (1 - a) * 0.5);
  }
  lums.sort();
  final lo = lums[((pixels - 1) * (1 - percentile)).round()];
  final hi = lums[((pixels - 1) * percentile).round()];
  return (dark: lo, bright: hi);
}

double _compositeLuminance(double imageLuminance, Color scrim, double alpha) {
  final v = _toSrgb(imageLuminance.clamp(0.0, 1.0));
  double mix(double s) => v * (1 - alpha) + s * alpha;
  return relativeLuminance(mix(scrim.r), mix(scrim.g), mix(scrim.b));
}

double minScrimAlpha({
  required double imageLuminance,
  required Color text,
  required Color scrim,
  double target = 4.5,
}) {
  final textL = luminanceOf(text);
  bool ok(double a) => contrastOfLuminances(textL, _compositeLuminance(imageLuminance, scrim, a)) >= target;
  if (ok(0)) return 0;
  if (!ok(kMaxScrim)) return kMaxScrim;
  var lo = 0.0, hi = kMaxScrim;
  for (var i = 0; i < 24; i++) {
    final mid = (lo + hi) / 2;
    if (ok(mid)) {
      hi = mid;
    } else {
      lo = mid;
    }
  }
  return hi;
}

ImageTones blendTones(ImageTones tones, Color under, double opacity) {
  if (opacity >= 1) return tones;
  double mix(double y) => _compositeLuminance(y, under, 1 - opacity);
  return (dark: mix(tones.dark), bright: mix(tones.bright));
}

double readableScrim({
  required ImageTones tones,
  required Iterable<Color> texts,
  required Color scrim,
  double target = 4.5,
}) {
  var alpha = 0.0;
  for (final text in texts) {
    for (final l in [tones.dark, tones.bright]) {
      alpha = math.max(alpha, minScrimAlpha(imageLuminance: l, text: text, scrim: scrim, target: target));
    }
  }
  return alpha;
}

double compositeContrast({
  required double imageLuminance,
  required Color text,
  required Color scrim,
  required double alpha,
}) =>
    contrastOfLuminances(luminanceOf(text), _compositeLuminance(imageLuminance, scrim, alpha));
