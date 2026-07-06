import 'package:flutter/material.dart';
import 'package:localsend_app/gen/strings.g.dart';
import 'package:localsend_app/provider/settings_provider.dart';
import 'package:localsend_app/theme.dart';
import 'package:localsend_app/widget/lists/receive_history_list_body.dart';
import 'package:refena_flutter/refena_flutter.dart';

class ReceiveHistoryPanel extends StatefulWidget {
  const ReceiveHistoryPanel({super.key});

  @override
  State<ReceiveHistoryPanel> createState() => _ReceiveHistoryPanelState();
}

class _ReceiveHistoryPanelState extends State<ReceiveHistoryPanel> with Refena {
  double? _dragWidth;

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final width = (_dragWidth ?? settings.historyPanelWidth).clamp(200.0, 480.0);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        MouseRegion(
          cursor: SystemMouseCursors.resizeColumn,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onHorizontalDragUpdate: (details) {
              setState(() {
                _dragWidth = (width - details.delta.dx).clamp(200.0, 480.0);
              });
            },
            onHorizontalDragEnd: (_) async {
              final w = _dragWidth;
              if (w != null) {
                await ref.notifier(settingsProvider).setHistoryPanelWidth(w);
              }
              setState(() => _dragWidth = null);
            },
            child: Container(
              width: 4,
              color: Theme.of(context).dividerColor.withOpacity(0.5),
            ),
          ),
        ),
        SizedBox(
          width: width,
          child: Material(
            color: Theme.of(context).cardColorWithElevation,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 4, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          t.receiveHistoryPage.title,
                          style: Theme.of(context).textTheme.titleMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                        onPressed: () async {
                          await ref.notifier(settingsProvider).setHistoryPanelVisible(false);
                        },
                        icon: const Icon(Icons.close, size: 20),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: const ReceiveHistoryListBody(compact: true),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
