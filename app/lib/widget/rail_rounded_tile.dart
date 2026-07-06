import 'package:flutter/material.dart';
import 'package:localsend_app/widget/app_rounded_button_style.dart';

/// Fixed width for rail icons so tab and device rows align vertically.
const double kRailIconSlotWidth = 28;

/// Outer vertical padding on each [RailRoundedTile] (gap between adjacent tiles is 2× this).
const double kRailTileOuterVerticalPadding = 3;

/// Rounded pill button for the left rail (tabs and nearby devices).
class RailRoundedTile extends StatefulWidget {
  final bool selected;
  final bool extended;
  final IconData icon;
  final String? label;
  final String? subtitle;
  final VoidCallback? onTap;
  final String? tooltip;

  const RailRoundedTile({
    required this.selected,
    required this.extended,
    required this.icon,
    this.label,
    this.subtitle,
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
    final hasSubtitle = widget.extended && widget.subtitle != null && widget.subtitle!.isNotEmpty;
    final verticalPad = hasSubtitle ? 10.0 : 8.0;

    final inner = MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Material(
        color: _backgroundColor(context),
        borderRadius: BorderRadius.circular(kAppRoundedButtonRadius),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(kAppRoundedButtonRadius),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: widget.extended ? 10 : 6, vertical: verticalPad),
            child: Row(
              crossAxisAlignment: hasSubtitle ? CrossAxisAlignment.start : CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: kRailIconSlotWidth,
                  child: Align(
                    alignment: hasSubtitle ? Alignment.topCenter : Alignment.center,
                    child: Icon(widget.icon, size: 22),
                  ),
                ),
                if (widget.extended && widget.label != null)
                  Expanded(
                    child: hasSubtitle
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.label!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 13),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                widget.subtitle!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 11, color: Colors.green),
                              ),
                            ],
                          )
                        : Text(
                            widget.label!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13),
                          ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );

    final tile = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: kRailTileOuterVerticalPadding),
      child: widget.extended
          ? SizedBox(width: double.infinity, child: inner)
          : inner,
    );

    if (widget.tooltip != null) {
      return Tooltip(message: widget.tooltip!, child: tile);
    }
    return tile;
  }
}
