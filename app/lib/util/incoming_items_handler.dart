import 'dart:io';

import 'package:common/common.dart';
import 'package:cross_file/cross_file.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:localsend_app/gen/strings.g.dart';
import 'package:localsend_app/pages/home_page.dart';
import 'package:localsend_app/provider/network/server/server_provider.dart';
import 'package:localsend_app/provider/selection/selected_sending_files_provider.dart';
import 'package:localsend_app/provider/ui/home_tab_provider.dart';
import 'package:localsend_app/util/determine_image_type.dart';
import 'package:localsend_app/util/native/cross_file_converters.dart';
import 'package:localsend_app/util/receive_ui_state.dart';
import 'package:pasteboard/pasteboard.dart';
import 'package:refena_flutter/refena_flutter.dart';

/// Handles drag-and-drop and clipboard content for the send queue.
class IncomingItemsHandler {
  /// Adds dropped files or a directory to the send queue. Returns true if anything was queued.
  static Future<bool> handleDroppedFiles(Ref ref, List<XFile> files) async {
    if (files.isEmpty) {
      return false;
    }

    if (files.length == 1 && Directory(files.first.path).existsSync()) {
      await ref.redux(selectedSendingFilesProvider).dispatchAsync(AddDirectoryAction(files.first.path));
      return true;
    }

    await ref.redux(selectedSendingFilesProvider).dispatchAsync(AddFilesAction(
          files: files,
          converter: CrossFileConverters.convertXFile,
        ));
    return true;
  }

  /// Reads clipboard (files, text, image). Returns true if anything was queued.
  static Future<bool> handleClipboard(Ref ref, BuildContext context) async {
    final pathFiles = <String>[];
    for (final file in await Pasteboard.files()) {
      pathFiles.add(file);
    }
    if (pathFiles.isNotEmpty) {
      await ref.redux(selectedSendingFilesProvider).dispatchAsync(AddFilesAction(
            files: pathFiles.map((e) => XFile(e)).toList(),
            converter: CrossFileConverters.convertXFile,
          ));
      return true;
    }

    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && data!.text!.isNotEmpty) {
      ref.redux(selectedSendingFilesProvider).dispatch(AddMessageAction(message: data.text!));
      return true;
    }

    final pasteboardText = await Pasteboard.text;
    if (pasteboardText != null && pasteboardText.isNotEmpty) {
      ref.redux(selectedSendingFilesProvider).dispatch(AddMessageAction(message: pasteboardText));
      return true;
    }

    final image = await Pasteboard.image;
    if (image != null) {
      final now = DateTime.now();
      final fileName =
          'clipboard_${now.year}-${now.month.twoDigitString}-${now.day.twoDigitString}_${now.hour.twoDigitString}-${now.minute.twoDigitString}.${determineImageType(image)}';
      ref.redux(selectedSendingFilesProvider).dispatch(AddBinaryAction(
            bytes: image,
            fileType: FileType.image,
            fileName: fileName,
          ));
      return true;
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(t.general.noItemInClipboard),
      ));
    }
    return false;
  }

  static void showQueuedSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(t.receiveTab.itemsQueued),
    ));
  }

  /// After files are queued: switch to receive tab when idle so the queue is visible.
  static void navigateAfterQueue(Ref ref, {BuildContext? context, bool snackBarIfStaying = false}) {
    final server = ref.read(serverProvider);
    if (isReceiveUiIdle(server)) {
      ref.redux(homeTabProvider).dispatch(SetHomeTabAction(HomeTab.receive));
      return;
    }
    if (snackBarIfStaying && context != null && context.mounted && ref.read(homeTabProvider) == HomeTab.receive) {
      showQueuedSnackBar(context);
    }
  }
}

extension on int {
  String get twoDigitString => toString().padLeft(2, '0');
}
