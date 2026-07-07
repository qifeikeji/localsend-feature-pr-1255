import 'package:flutter/material.dart';
import 'package:localsend_app/widget/lists/receive_history_list_body.dart' show ReceiveHistoryEntryOption;

RelativeRect receiveHistoryMenuPositionFromGlobal(BuildContext context, Offset globalPosition) {
  final overlayBox = Overlay.of(context).context.findRenderObject()! as RenderBox;
  final local = overlayBox.globalToLocal(globalPosition);
  return RelativeRect.fromRect(
    Rect.fromLTWH(local.dx, local.dy, 0, 0),
    Offset.zero & overlayBox.size,
  );
}

RelativeRect receiveHistoryMenuPositionBelow(BuildContext anchorContext) {
  final anchorBox = anchorContext.findRenderObject()! as RenderBox;
  final overlayBox = Overlay.of(anchorContext).context.findRenderObject()! as RenderBox;
  final globalTopLeft = anchorBox.localToGlobal(Offset.zero);
  final localTopLeft = overlayBox.globalToLocal(globalTopLeft);
  return RelativeRect.fromRect(
    Rect.fromLTWH(localTopLeft.dx, localTopLeft.dy + anchorBox.size.height, 0, 0),
    Offset.zero & overlayBox.size,
  );
}

Future<ReceiveHistoryEntryOption?> showReceiveHistoryEntryMenu(
  BuildContext context,
  RelativeRect position,
  List<ReceiveHistoryEntryOption> options,
) {
  if (options.isEmpty) {
    return Future.value(null);
  }

  return showMenu<ReceiveHistoryEntryOption>(
    context: context,
    position: position,
    items: [
      for (final option in options)
        PopupMenuItem<ReceiveHistoryEntryOption>(
          value: option,
          child: Text(option.label),
        ),
    ],
  );
}

/// Instant context menu at [globalPosition] (cursor / long-press).
Future<ReceiveHistoryEntryOption?> showReceiveHistoryContextMenu(
  BuildContext context,
  Offset globalPosition,
  List<ReceiveHistoryEntryOption> options,
) {
  return showReceiveHistoryEntryMenu(
    context,
    receiveHistoryMenuPositionFromGlobal(context, globalPosition),
    options,
  );
}
