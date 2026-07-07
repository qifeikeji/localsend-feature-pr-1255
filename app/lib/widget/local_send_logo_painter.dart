import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Vector LocalSend mark: concentric center circle + inner/outer petal rings.
class LocalSendLogoPainter extends CustomPainter {
  final Color color;
  final Color outerRingColor;

  LocalSendLogoPainter({
    required this.color,
    Color? outerRingColor,
  }) : outerRingColor = outerRingColor ?? color.withOpacity(0.55);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final unit = size.shortestSide;

    final centerPaint = Paint()..color = color;
    canvas.drawCircle(center, unit * 0.17, centerPaint);

    _drawPetalRing(
      canvas: canvas,
      center: center,
      unit: unit,
      count: 8,
      orbitRadius: unit * 0.28,
      petalWidth: unit * 0.11,
      petalHeight: unit * 0.05,
      paint: Paint()..color = color,
    );

    _drawPetalRing(
      canvas: canvas,
      center: center,
      unit: unit,
      count: 8,
      orbitRadius: unit * 0.40,
      petalWidth: unit * 0.14,
      petalHeight: unit * 0.07,
      paint: Paint()..color = outerRingColor,
    );
  }

  void _drawPetalRing({
    required Canvas canvas,
    required Offset center,
    required double unit,
    required int count,
    required double orbitRadius,
    required double petalWidth,
    required double petalHeight,
    required Paint paint,
  }) {
    for (var i = 0; i < count; i++) {
      final angle = -math.pi / 2 + (2 * math.pi * i / count);
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(angle);
      canvas.translate(0, -orbitRadius);
      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset.zero,
          width: petalWidth,
          height: petalHeight,
        ),
        Radius.circular(petalHeight / 2),
      );
      canvas.drawRRect(rect, paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant LocalSendLogoPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.outerRingColor != outerRingColor;
  }
}
