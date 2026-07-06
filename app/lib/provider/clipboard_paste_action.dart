import 'package:flutter/material.dart';
import 'package:localsend_app/util/incoming_items_handler.dart';
import 'package:refena_flutter/refena_flutter.dart';

class PasteFromClipboardAction extends AsyncGlobalAction {
  final BuildContext context;

  PasteFromClipboardAction({required this.context});

  @override
  Future<void> reduce() async {
    final queued = await IncomingItemsHandler.handleClipboard(ref, context);
    if (!queued) {
      return;
    }
    IncomingItemsHandler.navigateAfterQueue(ref, context: context.mounted ? context : null);
  }
}
