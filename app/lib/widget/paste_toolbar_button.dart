import 'package:flutter/material.dart';
import 'package:localsend_app/util/ui/paste_button_appearance.dart';
import 'package:localsend_app/widget/app_rounded_button_style.dart';

/// Paste action: green semi-transparent gradient.
class PasteToolbarButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget icon;
  final Widget label;
  final double opacity;
  final double gradientSpan;

  const PasteToolbarButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.opacity,
    required this.gradientSpan,
  });

  @override
  State<PasteToolbarButton> createState() => _PasteToolbarButtonState();
}

class _PasteToolbarButtonState extends State<PasteToolbarButton> {
  bool _hovered = false;

  LinearGradient _gradient() {
    return pasteToolbarGradient(
      opacity: widget.opacity,
      gradientSpan: widget.gradientSpan,
      hovered: _hovered && widget.onPressed != null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Material(
        borderRadius: BorderRadius.circular(kAppRoundedButtonRadius),
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: BoxDecoration(
            gradient: _gradient(),
            borderRadius: BorderRadius.circular(kAppRoundedButtonRadius),
          ),
          child: InkWell(
            onTap: widget.onPressed,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconTheme(
                    data: const IconThemeData(color: Colors.white, size: 20),
                    child: widget.icon,
                  ),
                  const SizedBox(width: 8),
                  DefaultTextStyle(
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    child: widget.label,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
