import 'package:flutter/material.dart';
import 'package:localsend_app/gen/strings.g.dart';
import 'package:localsend_app/model/cross_file.dart';
import 'package:localsend_app/util/file_size_helper.dart';
import 'package:localsend_app/widget/file_thumbnail.dart';

/// Compact preview of files queued for sending (receive tab or elsewhere).
class QueuedSendPreview extends StatelessWidget {
  final List<CrossFile> files;

  const QueuedSendPreview({super.key, required this.files});

  @override
  Widget build(BuildContext context) {
    if (files.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.only(top: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              t.receiveTab.queuedPreview,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              t.sendTab.selection.files(files: files.length),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              t.sendTab.selection.size(size: files.fold<int>(0, (p, f) => p + f.size).asReadableFileSize),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 10),
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
