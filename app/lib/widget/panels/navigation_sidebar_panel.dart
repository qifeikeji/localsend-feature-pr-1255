import 'package:flutter/material.dart';
import 'package:localsend_app/pages/home_page.dart';
import 'package:localsend_app/provider/settings_provider.dart';
import 'package:localsend_app/widget/desktop_navigation_sidebar.dart';
import 'package:refena_flutter/refena_flutter.dart';

/// Left navigation column with draggable width (handle on the right edge).
class NavigationSidebarPanel extends StatefulWidget {
  final HomeTab currentTab;
  final ValueChanged<int> onTabSelected;

  const NavigationSidebarPanel({
    required this.currentTab,
    required this.onTabSelected,
  });

  @override
  State<NavigationSidebarPanel> createState() => _NavigationSidebarPanelState();
}

class _NavigationSidebarPanelState extends State<NavigationSidebarPanel> with Refena {
  double? _dragWidth;

  static const double _minWidth = 72;
  static const double _maxWidth = 480;

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final width = (_dragWidth ?? settings.navigationPanelWidth).clamp(_minWidth, _maxWidth);
    final extended = width >= 112;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: width,
          child: DesktopNavigationSidebar(
            extended: extended,
            currentTab: widget.currentTab,
            onTabSelected: widget.onTabSelected,
          ),
        ),
        MouseRegion(
          cursor: SystemMouseCursors.resizeColumn,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onHorizontalDragUpdate: (details) {
              setState(() {
                _dragWidth = (width + details.delta.dx).clamp(_minWidth, _maxWidth);
              });
            },
            onHorizontalDragEnd: (_) async {
              final w = _dragWidth;
              if (w != null) {
                await ref.notifier(settingsProvider).setNavigationPanelWidth(w);
              }
              setState(() => _dragWidth = null);
            },
            child: Container(
              width: 4,
              color: Theme.of(context).dividerColor.withOpacity(0.5),
            ),
          ),
        ),
      ],
    );
  }
}
