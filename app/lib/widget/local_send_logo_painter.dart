import 'dart:math' as math;

import 'package:flutter/material.dart';

/// LocalSend mark: inner (bright) + outer (dim) petal rings, shared center.
class LocalSendLogoPainter extends CustomPainter {
  final Color innerColor;
  final Color outerColor;

  LocalSendLogoPainter({
    required this.innerColor,
    required this.outerColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Single center for every element — avoids inner/outer drift.
    final center = Offset(size.width / 2, size.height / 2);
    final unit = math.min(size.width, size.height);

    final innerPaint = Paint()..color = innerColor;
    canvas.drawCircle(center, unit * 0.17, innerPaint);

    _drawPetalRing(
      canvas: canvas,
      center: center,
      orbitRadius: unit * 0.28,
      petalWidth: unit * 0.11,
      petalHeight: unit * 0.05,
      paint: innerPaint,
    );

    final outerPaint = Paint()..color = outerColor;
    _drawPetalRing(
      canvas: canvas,
      center: center,
      orbitRadius: unit * 0.40,
      petalWidth: unit * 0.14,
      petalHeight: unit * 0.07,
      paint: outerPaint,
    );
  }

  void _drawPetalRing({
    required Canvas canvas,
    required Offset center,
    required double orbitRadius,
    required double petalWidth,
    required double petalHeight,
    required Paint paint,
  }) {
    const count = 8;
    for (var i = 0; i < count; i++) {
      final angle = -math.pi / 2 + (2 * math.pi * i / count);
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(angle);
      canvas.translate(0, -orbitRadius);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: petalWidth,
            height: petalHeight,
          ),
          Radius.circular(petalHeight / 2),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant LocalSendLogoPainter oldDelegate) {
    return oldDelegate.innerColor != innerColor || oldDelegate.outerColor != outerColor;
  }
}
