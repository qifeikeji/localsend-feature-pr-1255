import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:localsend_app/widget/app_rounded_button_style.dart';

/// Frosted-glass lower send panel overlay on the transfer tab.
class TransferLowerGlassPanel extends StatelessWidget {
  final double opacity;
  final double brightness;
  final int tintArgb;
  final Widget child;

  const TransferLowerGlassPanel({
    required this.opacity,
    this.brightness = 0,
    this.tintArgb = 0,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    const radius = kAppRoundedButtonRadius;
    final scheme = Theme.of(context).colorScheme;

    final baseTint = tintArgb == 0 ? scheme.surface : Color(tintArgb);
    var fill = baseTint.withOpacity(opacity.clamp(0.15, 0.95));
    if (brightness > 0) {
      fill = Color.lerp(fill, Colors.white, brightness.clamp(0.0, 0.85))!;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: scheme.outlineVariant.withOpacity(0.45)),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// iOS-style switch row matching settings tab boolean entries.
class SettingsStyleSwitchRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const SettingsStyleSwitchRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: theme.textTheme.bodyMedium),
        const SizedBox(width: 8),
        Switch(
          value: value,
          onChanged: onChanged,
          activeTrackColor: theme.colorScheme.primary,
          activeColor: theme.colorScheme.onPrimary,
          inactiveThumbColor: theme.colorScheme.outline,
          inactiveTrackColor: theme.colorScheme.surface,
        ),
      ],
    );
  }
}
