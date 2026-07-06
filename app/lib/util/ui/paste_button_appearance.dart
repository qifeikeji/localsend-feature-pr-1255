import 'package:flutter/material.dart';

/// Green semi-transparent gradient shared by the paste toolbar button and selected rail tabs.
LinearGradient pasteToolbarGradient({
  required double opacity,
  required double gradientSpan,
  bool hovered = false,
}) {
  final span = gradientSpan.clamp(0.0, 1.0);
  final alpha = opacity.clamp(0.1, 0.95);
  final light = Color.lerp(Colors.greenAccent, Colors.green, 0.35)!.withOpacity(alpha);
  final dark = Color.lerp(light, const Color(0xFF1B5E20), span)!;
  final hoverBoost = hovered ? 0.5 : 0.0;
  final c1 = Color.lerp(light, Colors.white, hoverBoost * 0.35)!;
  final c2 = Color.lerp(dark, Colors.white, hoverBoost * 0.35)!;
  return LinearGradient(
    colors: [c1, c2],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}
