import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Vector LocalSend mark: center circle + inner petal ring only.
class LocalSendLogoPainter extends CustomPainter {
  final Color color;

  LocalSendLogoPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final unit = size.shortestSide;
    final paint = Paint()..color = color;

    canvas.drawCircle(center, unit * 0.17, paint);

    for (var i = 0; i < 8; i++) {
      final angle = -math.pi / 2 + (2 * math.pi * i / 8);
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(angle);
      canvas.translate(0, -unit * 0.28);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: unit * 0.11,
            height: unit * 0.05,
          ),
          Radius.circular(unit * 0.025),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant LocalSendLogoPainter oldDelegate) => oldDelegate.color != color;
}
