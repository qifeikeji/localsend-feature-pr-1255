import 'package:flutter/material.dart';
import 'package:localsend_app/gen/strings.g.dart';
import 'package:routerino/routerino.dart';

/// Simple color picker for the send lower glass panel tint.
class SendPanelColorPickerDialog extends StatefulWidget {
  final Color initialColor;

  const SendPanelColorPickerDialog({required this.initialColor});

  static Future<Color?> open(BuildContext context, Color initial) {
    return showDialog<Color>(
      context: context,
      builder: (_) => SendPanelColorPickerDialog(initialColor: initial),
    );
  }

  @override
  State<SendPanelColorPickerDialog> createState() => _SendPanelColorPickerDialogState();
}

class _SendPanelColorPickerDialogState extends State<SendPanelColorPickerDialog> {
  late Color _color;

  static const _presets = [
    Color(0xFF9E9E9E),
    Color(0xFF607D8B),
    Color(0xFF795548),
    Color(0xFF3F51B5),
    Color(0xFF009688),
    Color(0xFF4CAF50),
    Color(0xFF8BC34A),
    Color(0xFFFFC107),
    Color(0xFFFF5722),
    Color(0xFFE91E63),
    Color(0xFF9C27B0),
    Color(0xFF212121),
  ];

  @override
  void initState() {
    super.initState();
    _color = widget.initialColor;
  }

  void _setHsl(void Function(HSLColor hsl) fn) {
    setState(() {
      _color = fn(HSLColor.fromColor(_color)).toColor();
    });
  }

  @override
  Widget build(BuildContext context) {
    final hsl = HSLColor.fromColor(_color);

    return AlertDialog(
      title: Text(t.settingsTab.receive.sendLowerPanelColor),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 48,
              decoration: BoxDecoration(
                color: _color,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _presets.map((c) {
                return GestureDetector(
                  onTap: () => setState(() => _color = c),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _color.value == c.value ? Theme.of(context).colorScheme.primary : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Text(t.settingsTab.receive.sendLowerPanelColorHue, style: Theme.of(context).textTheme.labelSmall),
            Slider(
              value: hsl.hue,
              min: 0,
              max: 360,
              onChanged: (v) => _setHsl((h) => h.withHue(v)),
            ),
            Text(t.settingsTab.receive.sendLowerPanelColorSaturation, style: Theme.of(context).textTheme.labelSmall),
            Slider(
              value: hsl.saturation,
              min: 0,
              max: 1,
              onChanged: (v) => _setHsl((h) => h.withSaturation(v)),
            ),
            Text(t.settingsTab.receive.sendLowerPanelColorLightness, style: Theme.of(context).textTheme.labelSmall),
            Slider(
              value: hsl.lightness,
              min: 0,
              max: 1,
              onChanged: (v) => _setHsl((h) => h.withLightness(v)),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => context.pop(), child: Text(t.general.cancel)),
        ElevatedButton(
          onPressed: () => context.pop(_color),
          child: Text(t.general.confirm),
        ),
      ],
    );
  }
}
