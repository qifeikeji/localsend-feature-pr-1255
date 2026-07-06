import 'package:flutter/material.dart';

/// Rounded pill button for the left rail (tabs and nearby devices).
class RailRoundedTile extends StatefulWidget {
  final bool selected;
  final bool extended;
  final IconData icon;
  final String? label;
  final VoidCallback? onTap;
  final String? tooltip;

  const RailRoundedTile({
    required this.selected,
    required this.extended,
    required this.icon,
    this.label,
    this.onTap,
    this.tooltip,
  });

  @override
  State<RailRoundedTile> createState() => _RailRoundedTileState();
}

class _RailRoundedTileState extends State<RailRoundedTile> {
  bool _hovered = false;

  Color _backgroundColor(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Color base = Color.lerp(scheme.surfaceContainerHighest, Colors.white, 0.2)!;
    if (widget.selected) {
      base = Color.lerp(base, scheme.primaryContainer, 0.35)!;
    }
    if (_hovered && widget.onTap != null) {
      base = Color.lerp(base, Colors.white, 0.12)!;
    }
    return base;
  }

  @override
  Widget build(BuildContext context) {
    final child = MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Material(
        color: _backgroundColor(context),
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: widget.extended ? 10 : 6, vertical: 8),
            child: Row(
              mainAxisAlignment: widget.extended ? MainAxisAlignment.center : MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(widget.icon, size: 22),
                if (widget.extended && widget.label != null) ...[
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      widget.label!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      child: widget.tooltip != null
          ? Tooltip(message: widget.tooltip!, child: child)
          : child,
    );
  }
}
