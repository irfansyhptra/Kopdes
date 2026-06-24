import 'package:flutter/material.dart';

/// Draws the KOPDES house mark progressively, like a pen tracing an
/// SVG path. [roofProgress] controls the roof stroke (left -> apex ->
/// right), [wallsProgress] controls the wall + door strokes, and
/// [poleProgress] controls the flagpole growing bottom -> top.
///
/// Using PathMetric.extractPath gives a true "drawing" effect without
/// needing a video or a pre-baked GIF, and is cheap enough to run at
/// 60 FPS on mid-range Android devices since the path itself is tiny
/// (a handful of line segments).
class HousePathPainter extends CustomPainter {
  HousePathPainter({
    required this.roofProgress,
    required this.wallsProgress,
    required this.poleProgress,
    this.color = const Color(0xFFFF385C),
  });

  final double roofProgress; // 0..1
  final double wallsProgress; // 0..1
  final double poleProgress; // 0..1
  final Color color;

  // ViewBox is logical 200x220, matching assets/svg/kopdes_logo.svg
  // so the painter and the static SVG asset stay visually identical.
  static const Size viewBox = Size(200, 220);

  Path get _roofPath => Path()
    ..moveTo(20, 100)
    ..lineTo(100, 20)
    ..lineTo(180, 100);

  Path get _wallsPath => Path()
    ..moveTo(40, 100)
    ..lineTo(40, 180)
    ..lineTo(160, 180)
    ..lineTo(160, 100)
    ..moveTo(85, 180)
    ..lineTo(85, 140)
    ..lineTo(115, 140)
    ..lineTo(115, 180);

  Path get _polePath => Path()
    ..moveTo(100, 20)
    ..lineTo(100, -20);

  Path _partialPath(Path source, double progress) {
    if (progress <= 0) return Path();
    final metrics = source.computeMetrics().toList();
    final totalLength = metrics.fold<double>(0, (sum, m) => sum + m.length);
    final targetLength = totalLength * progress.clamp(0.0, 1.0);

    final result = Path();
    var consumed = 0.0;
    for (final metric in metrics) {
      if (consumed >= targetLength) break;
      final remaining = targetLength - consumed;
      final take = remaining.clamp(0.0, metric.length);
      result.addPath(metric.extractPath(0, take), Offset.zero);
      consumed += metric.length;
    }
    return result;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / viewBox.width;
    final scaleY = size.height / viewBox.height;
    canvas.save();
    canvas.scale(scaleX, scaleY);

    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final poleStrokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    if (roofProgress > 0) {
      canvas.drawPath(_partialPath(_roofPath, roofProgress), strokePaint);
    }
    if (wallsProgress > 0) {
      final wallPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = wallsProgress < 0.8 ? 10 : 8
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(_partialPath(_wallsPath, wallsProgress), wallPaint);
    }
    if (poleProgress > 0) {
      // Pole grows bottom -> top, so we draw from the *end* of the
      // path (ground level, y=20) upward by reversing extraction.
      final metric = _polePath.computeMetrics().first;
      final length = metric.length * poleProgress.clamp(0.0, 1.0);
      final partial = metric.extractPath(metric.length - length, metric.length);
      canvas.drawPath(partial, poleStrokePaint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant HousePathPainter oldDelegate) {
    return oldDelegate.roofProgress != roofProgress ||
        oldDelegate.wallsProgress != wallsProgress ||
        oldDelegate.poleProgress != poleProgress;
  }
}
