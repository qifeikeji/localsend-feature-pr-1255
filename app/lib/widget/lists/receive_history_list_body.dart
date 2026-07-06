import 'package:flutter/material.dart';
import 'package:localsend_app/gen/strings.g.dart';
import 'package:localsend_app/model/persistence/receive_history_entry.dart';
import 'package:localsend_app/provider/receive_history_provider.dart';
import 'package:localsend_app/provider/settings_provider.dart';
import 'package:localsend_app/theme.dart';
import 'package:localsend_app/util/file_size_helper.dart';
import 'package:localsend_app/util/native/directories.dart';
import 'package:localsend_app/util/native/open_file.dart';
import 'package:localsend_app/util/native/open_folder.dart';
import 'package:localsend_app/util/native/platform_check.dart';
import 'package:localsend_app/widget/dialogs/file_info_dialog.dart';
import 'package:localsend_app/widget/dialogs/history_clear_dialog.dart';
import 'package:localsend_app/widget/file_thumbnail.dart';
import 'package:path/path.dart' as p;
import 'package:refena_flutter/refena_flutter.dart';

enum ReceiveHistoryEntryOption {
  open,
  openContainingFolder,
  info,
  delete;

  String get label {
    switch (this) {
      case ReceiveHistoryEntryOption.open:
        return t.receiveHistoryPage.entryActions.open;
      case ReceiveHistoryEntryOption.openContainingFolder:
        return t.receiveHistoryPage.entryActions.openContainingFolder;
      case ReceiveHistoryEntryOption.info:
        return t.receiveHistoryPage.entryActions.info;
      case ReceiveHistoryEntryOption.delete:
        return t.receiveHistoryPage.entryActions.deleteFromHistory;
    }
  }
}

class ReceiveHistoryListBody extends StatelessWidget {
  final bool compact;
  final bool showToolbar;

  const ReceiveHistoryListBody({
    super.key,
    this.compact = false,
    this.showToolbar = true,
  });

  Future<void> _openFile(
    BuildContext context,
    ReceiveHistoryEntry entry,
    Dispatcher<ReceiveHistoryService, List<ReceiveHistoryEntry>> dispatcher,
  ) async {
    if (entry.path != null) {
      await openFile(
        context,
        entry.fileType,
        entry.path!,
        onDeleteTap: () => dispatcher.dispatchAsync(RemoveHistoryEntryAction(entry.id)),
      );
    }
  }

  Future<void> _handleOption(
    BuildContext context,
    ReceiveHistoryEntry entry,
    ReceiveHistoryEntryOption option,
    Dispatcher<ReceiveHistoryService, List<ReceiveHistoryEntry>> dispatcher,
  ) async {
    switch (option) {
      case ReceiveHistoryEntryOption.open:
        await _openFile(context, entry, dispatcher);
        break;
      case ReceiveHistoryEntryOption.openContainingFolder:
        if (entry.path != null) {
          await openFolder(p.dirname(entry.path!));
        }
        break;
      case ReceiveHistoryEntryOption.info:
        if (context.mounted) {
          await showDialog(
            context: context,
            builder: (_) => FileInfoDialog(entry: entry),
          );
        }
        break;
      case ReceiveHistoryEntryOption.delete:
        await dispatcher.dispatchAsync(RemoveHistoryEntryAction(entry.id));
        break;
    }
  }

  List<ReceiveHistoryEntryOption> _optionsFor(ReceiveHistoryEntry entry) {
    if (entry.path == null) {
      return [ReceiveHistoryEntryOption.info, ReceiveHistoryEntryOption.delete];
    }
    return ReceiveHistoryEntryOption.values;
  }

  Future<void> _showContextMenu(
    BuildContext context,
    Offset globalPosition,
    ReceiveHistoryEntry entry,
    Dispatcher<ReceiveHistoryService, List<ReceiveHistoryEntry>> dispatcher,
  ) async {
    final options = _optionsFor(entry);
    final overlayBox = Overlay.of(context).context.findRenderObject() as RenderBox;
    final position = RelativeRect.fromRect(
      Rect.fromLTWH(globalPosition.dx, globalPosition.dy, 1, 1),
      Offset.zero & overlayBox.size,
    );
    final selected = await showMenu<ReceiveHistoryEntryOption>(
      context: context,
      position: position,
      items: options
          .map(
            (e) => PopupMenuItem(
              value: e,
              child: Text(e.label),
            ),
          )
          .toList(),
    );
    if (selected != null && context.mounted) {
      await _handleOption(context, entry, selected, dispatcher);
    }
  }

  @override
  Widget build(BuildContext context) {
    final entries = context.watch(receiveHistoryProvider);
    final dispatcher = context.redux(receiveHistoryProvider);
    final hPad = compact ? 8.0 : 15.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showToolbar)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                SizedBox(width: hPad),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.secondaryContainerIfDark,
                    foregroundColor: Theme.of(context).colorScheme.onSecondaryContainerIfDark,
                  ),
                  onPressed: checkPlatform([TargetPlatform.iOS])
                      ? null
                      : () async {
                          final destination = context.read(settingsProvider).destination ?? await getDefaultDestinationDirectory();
                          await openFolder(destination);
                        },
                  icon: const Icon(Icons.folder, size: 18),
                  label: Text(t.receiveHistoryPage.openFolder),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.secondaryContainerIfDark,
                    foregroundColor: Theme.of(context).colorScheme.onSecondaryContainerIfDark,
                  ),
                  onPressed: entries.isEmpty
                      ? null
                      : () async {
                          final result = await showDialog(
                            context: context,
                            builder: (_) => const HistoryClearDialog(),
                          );
                          if (context.mounted && result == true) {
                            await dispatcher.dispatchAsync(RemoveAllHistoryEntriesAction());
                          }
                        },
                  icon: const Icon(Icons.delete, size: 18),
                  label: Text(t.receiveHistoryPage.deleteHistory),
                ),
              ],
            ),
          ),
        if (showToolbar) SizedBox(height: compact ? 12 : 20),
        if (entries.isEmpty)
          Padding(
            padding: EdgeInsets.only(top: compact ? 40 : 100),
            child: Center(
              child: Text(
                t.receiveHistoryPage.empty,
                style: compact ? Theme.of(context).textTheme.titleMedium : Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
            ),
          )
        else
          ...entries.map((entry) {
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: hPad, vertical: compact ? 4 : 8),
              child: GestureDetector(
                onSecondaryTapDown: (details) async {
                  await _showContextMenu(context, details.globalPosition, entry, dispatcher);
                },
                child: InkWell(
                  splashColor: Colors.transparent,
                  splashFactory: NoSplash.splashFactory,
                  highlightColor: Colors.transparent,
                  hoverColor: Colors.transparent,
                  onTap: entry.path != null ? () async => _openFile(context, entry, dispatcher) : null,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FilePathThumbnail(
                        path: entry.path,
                        fileType: entry.fileType,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 3),
                            Text(
                              entry.fileName,
                              style: TextStyle(fontSize: compact ? 14 : 16),
                              maxLines: 1,
                              overflow: TextOverflow.fade,
                              softWrap: false,
                            ),
                            Text(
                              '${entry.timestampString} - ${entry.fileSize.asReadableFileSize} - ${entry.senderAlias}',
                              maxLines: 1,
                              overflow: TextOverflow.fade,
                              softWrap: false,
                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      PopupMenuButton<ReceiveHistoryEntryOption>(
                        iconSize: compact ? 20 : 24,
                        onSelected: (item) async => _handleOption(context, entry, item, dispatcher),
                        itemBuilder: (BuildContext context) {
                          return _optionsFor(entry)
                              .map(
                                (e) => PopupMenuItem<ReceiveHistoryEntryOption>(
                                  value: e,
                                  child: Text(e.label),
                                ),
                              )
                              .toList();
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }
}
