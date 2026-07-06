import 'package:flutter/material.dart';
import 'package:localsend_app/gen/strings.g.dart';
import 'package:localsend_app/model/cross_file.dart';
import 'package:localsend_app/provider/selection/selected_sending_files_provider.dart';
import 'package:localsend_app/util/file_size_helper.dart';
import 'package:localsend_app/widget/file_thumbnail.dart';
import 'package:refena_flutter/refena_flutter.dart';

/// Lower-panel card listing files queued for sending.
class SendQueueCard extends StatelessWidget {
  final List<CrossFile> files;

  const SendQueueCard({super.key, required this.files});

  @override
  Widget build(BuildContext context) {
    if (files.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    t.receiveTab.queuedPreview,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                TextButton(
                  style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
                  onPressed: () {
                    context.ref.redux(selectedSendingFilesProvider).dispatch(ClearSelectionAction());
                  },
                  child: Text(t.selectedFilesPage.deleteAll),
                ),
              ],
            ),
            Text(
              t.sendTab.selection.files(files: files.length),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              t.sendTab.selection.size(size: files.fold<int>(0, (p, f) => p + f.size).asReadableFileSize),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: defaultThumbnailSize,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: files.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: SmartFileThumbnail.fromCrossFile(files[index]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
