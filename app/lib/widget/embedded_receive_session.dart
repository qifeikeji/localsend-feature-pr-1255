import 'package:common/common.dart';
import 'package:flutter/material.dart';
import 'package:localsend_app/gen/strings.g.dart';
import 'package:localsend_app/provider/device_info_provider.dart';
import 'package:localsend_app/provider/network/server/server_provider.dart';
import 'package:localsend_app/provider/progress_provider.dart';
import 'package:localsend_app/theme.dart';
import 'package:localsend_app/widget/custom_progress_bar.dart';
import 'package:localsend_app/widget/dialogs/cancel_session_dialog.dart';
import 'package:refena_flutter/refena_flutter.dart';
import 'package:routerino/routerino.dart';

/// Per-file receive progress for the transfer tab upper half (no total progress bar).
class EmbeddedReceiveSession extends StatefulWidget {
  final String sessionId;

  const EmbeddedReceiveSession({required this.sessionId});

  @override
  State<EmbeddedReceiveSession> createState() => _EmbeddedReceiveSessionState();
}

class _EmbeddedReceiveSessionState extends State<EmbeddedReceiveSession> with Refena {
  Future<void> _onCancel() async {
    final session = ref.read(serverProvider)?.session;
    if (session == null || session.sessionId != widget.sessionId) {
      return;
    }
    if (session.status == SessionStatus.sending) {
      final ok = await context.pushBottomSheet(() => const CancelSessionDialog());
      if (ok != true) {
        return;
      }
      ref.notifier(serverProvider).cancelSession();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(progressProvider);
    final serverState = ref.watch(serverProvider);
    final session = serverState?.session;
    if (session == null || session.sessionId != widget.sessionId) {
      return const SizedBox.shrink();
    }
    if (session.status != SessionStatus.sending) {
      return const SizedBox.shrink();
    }

    final progressNotifier = ref.notifier(progressProvider);
    final files = session.files.values.where((f) => f.status != FileStatus.skipped).toList();
    final localAlias = serverState?.alias ?? ref.read(deviceFullInfoProvider).alias;
    final header = t.transferTab.transferLine(from: session.senderAlias, to: localAlias);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Text(header, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleSmall),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            itemCount: files.length,
            itemBuilder: (context, index) {
              final entry = files[index];
              final fileName = entry.desiredName ?? entry.file.fileName;
              final status = entry.status;
              final progress = progressNotifier.getProgress(sessionId: widget.sessionId, fileId: entry.file.id);

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(fileName, maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    if (status == FileStatus.sending)
                      CustomProgressBar(progress: progress)
                    else
                      Text(
                        _fileStatusLabel(status, entry.savedToGallery),
                        style: TextStyle(fontSize: 12, color: _fileStatusColor(context, status)),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.only(right: 8, bottom: 4),
            child: TextButton(onPressed: _onCancel, child: Text(t.general.cancel)),
          ),
        ),
      ],
    );
  }

  String _fileStatusLabel(FileStatus status, bool savedToGallery) {
    if (savedToGallery && status == FileStatus.finished) {
      return t.progressPage.savedToGallery;
    }
    switch (status) {
      case FileStatus.queue:
        return t.general.queue;
      case FileStatus.skipped:
        return t.general.skipped;
      case FileStatus.sending:
        return '';
      case FileStatus.failed:
        return t.general.error;
      case FileStatus.finished:
        return t.general.done;
    }
  }

  Color _fileStatusColor(BuildContext context, FileStatus status) {
    switch (status) {
      case FileStatus.queue:
      case FileStatus.sending:
      case FileStatus.finished:
        return Theme.of(context).colorScheme.primary;
      case FileStatus.skipped:
        return Colors.grey;
      case FileStatus.failed:
        return Theme.of(context).colorScheme.warning;
    }
  }
}
