import 'dart:async';

import 'package:flutter/material.dart';
import 'package:localsend_app/widget/app_rounded_button_style.dart';
import 'package:localsend_app/widget/lists/receive_history_list_body.dart' show ReceiveHistoryEntryOption;

/// Instant context menu at [globalPosition] (opens to the right and down from the cursor).
Future<ReceiveHistoryEntryOption?> showReceiveHistoryContextMenu(
  BuildContext context,
  Offset globalPosition,
  List<ReceiveHistoryEntryOption> options,
) {
  if (options.isEmpty) {
    return Future.value(null);
  }

  final completer = Completer<ReceiveHistoryEntryOption?>();
  final overlay = Overlay.of(context);
  late OverlayEntry entry;
  var dismissed = false;

  void dismiss([ReceiveHistoryEntryOption? value]) {
    if (!dismissed) {
      dismissed = true;
      entry.remove();
    }
    if (!completer.isCompleted) {
      completer.complete(value);
    }
  }

  entry = OverlayEntry(
    builder: (ctx) {
      final buttonStyle = appToolbarElevatedButtonStyle(ctx);
      return Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () => dismiss(),
              behavior: HitTestBehavior.translucent,
            ),
          ),
          Positioned(
            left: globalPosition.dx,
            top: globalPosition.dy,
            child: Material(
              color: Colors.transparent,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < options.length; i++) ...[
                    if (i > 0) const SizedBox(height: 4),
                    ElevatedButton(
                      style: buttonStyle,
                      onPressed: () => dismiss(options[i]),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(options[i].label),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      );
    },
  );

  overlay.insert(entry);
  return completer.future;
}
