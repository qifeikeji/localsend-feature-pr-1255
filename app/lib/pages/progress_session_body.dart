import 'dart:async';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:common/common.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:localsend_app/gen/strings.g.dart';
import 'package:localsend_app/provider/network/send_provider.dart';
import 'package:localsend_app/provider/network/server/server_provider.dart';
import 'package:localsend_app/provider/progress_provider.dart';
import 'package:localsend_app/provider/settings_provider.dart';
import 'package:localsend_app/theme.dart';
import 'package:localsend_app/util/file_size_helper.dart';
import 'package:localsend_app/util/file_speed_helper.dart';
import 'package:localsend_app/util/native/open_file.dart';
import 'package:localsend_app/util/native/open_folder.dart';
import 'package:localsend_app/util/native/platform_check.dart';
import 'package:localsend_app/util/ui/nav_bar_padding.dart';
import 'package:localsend_app/widget/custom_progress_bar.dart';
import 'package:localsend_app/widget/dialogs/cancel_session_dialog.dart';
import 'package:localsend_app/widget/dialogs/error_dialog.dart';
import 'package:localsend_app/widget/file_thumbnail.dart';
import 'package:refena_flutter/refena_flutter.dart';
import 'package:routerino/routerino.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

enum ProgressSessionKind { receive, send }

class ProgressSessionBody extends StatefulWidget {
  final String sessionId;
  final ProgressSessionKind kind;
  final bool compact;
  final bool closeSessionOnClose;

  const ProgressSessionBody({
    required this.sessionId,
    required this.kind,
    this.compact = false,
    required this.closeSessionOnClose,
  });

  @override
  State<ProgressSessionBody> createState() => _ProgressSessionBodyState();
}

class _ProgressSessionBodyState extends State<ProgressSessionBody> with Refena {
  int _totalBytes = double.maxFinite.toInt();
  int _lastRemainingTimeUpdate = 0;
  String? _remainingTime;
  List<FileDto> _files = [];
  Set<String> _selectedFiles = {};
  int _finishCounter = 3;
  Timer? _finishTimer;
  bool _advanced = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadFiles());
  }

  void _loadFiles() {
    setState(() {
      if (widget.kind == ProgressSessionKind.receive) {
        final receiveSession = ref.read(serverProvider)?.session;
        if (receiveSession != null && receiveSession.sessionId == widget.sessionId) {
          _files = receiveSession.files.values.map((f) => f.file).toList();
          _selectedFiles = receiveSession.files.values.where((f) => f.status != FileStatus.skipped).map((f) => f.file.id).toSet();
        }
      } else {
        final sendSession = ref.read(sendProvider)[widget.sessionId];
        if (sendSession != null) {
          _files = sendSession.files.values.map((f) => f.file).toList();
          _selectedFiles = sendSession.files.values.where((f) => f.status != FileStatus.skipped).map((f) => f.file.id).toSet();
        }
      }
      _totalBytes = _files.where((f) => _selectedFiles.contains(f.id)).fold(0, (prev, curr) => prev + curr.size);
    });
  }

  @override
  void dispose() {
    _finishTimer?.cancel();
    super.dispose();
  }

  SessionStatus? _status() {
    if (widget.kind == ProgressSessionKind.receive) {
      final s = ref.read(serverProvider)?.session;
      if (s?.sessionId == widget.sessionId) {
        return s?.status;
      }
      return null;
    }
    return ref.read(sendProvider)[widget.sessionId]?.status;
  }

  Future<void> _exit() async {
    final status = _status();
    if (status == null) {
      return;
    }
    final result = status == SessionStatus.sending ? await context.pushBottomSheet(() => const CancelSessionDialog()) : true;
    if (!result) {
      return;
    }
    if (widget.kind == ProgressSessionKind.receive) {
      final receiveSession = ref.read(serverProvider)?.session;
      if (receiveSession != null) {
        if (receiveSession.status == SessionStatus.sending) {
          ref.notifier(serverProvider).cancelSession();
        } else {
          ref.notifier(serverProvider).closeSession();
        }
      }
    } else {
      final sendState = ref.read(sendProvider)[widget.sessionId];
      if (sendState != null) {
        if (sendState.status == SessionStatus.sending) {
          ref.notifier(sendProvider).cancelSession(widget.sessionId);
        } else {
          ref.notifier(sendProvider).closeSession(widget.sessionId);
        }
      }
    }
    if (mounted && widget.closeSessionOnClose) {
      final receiveActive = ref.read(serverProvider)?.session?.status == SessionStatus.sending;
      final sendActive = ref.read(sendProvider).values.any((s) => s.status == SessionStatus.sending);
      if (!receiveActive && !sendActive) {
        context.popUntilRoot();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final progressNotifier = ref.watch(progressProvider);
    final receiveSession = widget.kind == ProgressSessionKind.receive ? ref.watch(serverProvider)?.session : null;
    if (widget.kind == ProgressSessionKind.receive && receiveSession?.sessionId != widget.sessionId) {
      return const SizedBox.shrink();
    }
    final sendSession = widget.kind == ProgressSessionKind.send ? ref.watch(sendProvider)[widget.sessionId] : null;

    final status = receiveSession?.status ?? sendSession?.status;
    if (status == null) {
      return const SizedBox.shrink();
    }

    final currBytes = _files.fold<int>(
        0, (prev, curr) => prev + ((progressNotifier.getProgress(sessionId: widget.sessionId, fileId: curr.id) * curr.size).round()));

    final title = widget.kind == ProgressSessionKind.receive ? t.progressPage.titleReceiving : t.progressPage.titleSending;
    final startTime = receiveSession?.startTime ?? sendSession?.startTime;
    final endTime = receiveSession?.endTime ?? sendSession?.endTime;
    final int? speedInBytes;
    if (startTime != null && currBytes >= 500 * 1024) {
      speedInBytes = getFileSpeed(start: startTime, end: endTime ?? DateTime.now().millisecondsSinceEpoch, bytes: currBytes);
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now - _lastRemainingTimeUpdate >= 1000) {
        _remainingTime = getRemainingTime(bytesPerSeconds: speedInBytes, remainingBytes: _totalBytes - currBytes);
        _lastRemainingTimeUpdate = now;
      }
    } else {
      speedInBytes = null;
    }

    final listBottom = widget.compact ? 120.0 : 150.0 + getNavBarPadding(context);

    return Stack(
      children: [
        ListView.builder(
          padding: EdgeInsets.only(top: 8, bottom: listBottom, left: 15, right: 15),
          itemCount: _files.length + 2,
          itemBuilder: (context, index) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    if (checkPlatformWithFileSystem() && receiveSession != null)
                      Text(
                        receiveSession.destinationDirectory,
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.fade,
                      ),
                  ],
                ),
              );
            }
            if (index == 1) {
              final errorMessage = sendSession?.errorMessage;
              if (errorMessage == null) {
                return Container();
              }
              return SelectableText(errorMessage, style: TextStyle(color: Theme.of(context).colorScheme.warning));
            }

            final file = _files[index - 2];
            final fileName = receiveSession?.files[file.id]?.desiredName ?? file.fileName;
            final fileStatus = receiveSession?.files[file.id]?.status ?? sendSession!.files[file.id]!.status;
            final savedToGallery = receiveSession?.files[file.id]?.savedToGallery ?? false;
            final String? filePath;
            if (receiveSession != null && fileStatus == FileStatus.finished && !savedToGallery) {
              filePath = receiveSession.files[file.id]!.path;
            } else if (sendSession != null) {
              filePath = sendSession.files[file.id]!.path;
            } else {
              filePath = null;
            }
            final errorMessage = receiveSession?.files[file.id]?.errorMessage ?? sendSession?.files[file.id]?.errorMessage;
            final thumbnail = sendSession?.files[file.id]?.thumbnail;
            final asset = sendSession?.files[file.id]?.asset;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  SmartFileThumbnail(bytes: thumbnail, asset: asset, path: filePath, fileType: file.fileType),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(fileName, maxLines: 1, overflow: TextOverflow.fade),
                        if (fileStatus == FileStatus.sending)
                          CustomProgressBar(progress: progressNotifier.getProgress(sessionId: widget.sessionId, fileId: file.id))
                        else
                          Text(savedToGallery ? t.progressPage.savedToGallery : fileStatus.label, style: TextStyle(color: fileStatus.getColor(context), fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(status.getLabel(remainingTime: _remainingTime ?? '-'), style: TextStyle(fontSize: widget.compact ? 14 : 18)),
                    const SizedBox(height: 4),
                    CustomProgressBar(progress: _totalBytes == 0 ? 0 : currBytes / _totalBytes, borderRadius: 5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: _exit,
                          child: Text(status == SessionStatus.sending ? t.general.cancel : t.general.done),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

extension _FileStatusProgress on FileStatus {
  String get label {
    switch (this) {
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

  Color getColor(BuildContext context) {
    switch (this) {
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

extension _SessionStatusProgress on SessionStatus {
  String getLabel({required String remainingTime}) {
    switch (this) {
      case SessionStatus.sending:
        return t.progressPage.total.title.sending(time: remainingTime);
      case SessionStatus.finished:
        return t.general.finished;
      case SessionStatus.finishedWithErrors:
        return t.progressPage.total.title.finishedError;
      case SessionStatus.canceledBySender:
        return t.progressPage.total.title.canceledSender;
      case SessionStatus.canceledByReceiver:
        return t.progressPage.total.title.canceledReceiver;
      default:
        return '';
    }
  }
}
