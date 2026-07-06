import 'package:collection/collection.dart';
import 'package:common/common.dart';
import 'package:flutter/material.dart';
import 'package:localsend_app/gen/strings.g.dart';
import 'package:localsend_app/model/state/send/send_session_state.dart';
import 'package:localsend_app/provider/device_info_provider.dart';
import 'package:localsend_app/provider/network/send_provider.dart';
import 'package:localsend_app/provider/network/server/server_provider.dart';
import 'package:localsend_app/provider/progress_provider.dart';
import 'package:localsend_app/widget/custom_progress_bar.dart';
import 'package:localsend_app/widget/dialogs/cancel_session_dialog.dart';
import 'package:refena_flutter/refena_flutter.dart';
import 'package:routerino/routerino.dart';

enum InlineSessionKind { receive, send }

/// Compact transfer line + progress bar for the transfer tab (not full-screen).
class InlineSessionProgress extends StatefulWidget {
  final String sessionId;
  final InlineSessionKind kind;

  const InlineSessionProgress({
    required this.sessionId,
    required this.kind,
  });

  @override
  State<InlineSessionProgress> createState() => _InlineSessionProgressState();
}

class _InlineSessionProgressState extends State<InlineSessionProgress> with Refena {
  int _totalBytes = 0;
  final Map<String, int> _sizes = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadTotals());
  }

  void _loadTotals() {
    if (widget.kind == InlineSessionKind.receive) {
      final s = ref.read(serverProvider)?.session;
      if (s?.sessionId == widget.sessionId) {
        final files = s!.files.values.where((f) => f.status != FileStatus.skipped).map((f) => f.file).toList();
        setState(() {
          _sizes
            ..clear()
            ..addEntries(files.map((f) => MapEntry(f.id, f.size)));
          _totalBytes = files.fold(0, (p, f) => p + f.size);
        });
      }
    } else {
      final s = ref.read(sendProvider)[widget.sessionId];
      if (s != null) {
        final files = s.files.values.where((f) => f.status != FileStatus.skipped).map((f) => f.file).toList();
        setState(() {
          _sizes
            ..clear()
            ..addEntries(files.map((f) => MapEntry(f.id, f.size)));
          _totalBytes = files.fold(0, (p, f) => p + f.size);
        });
      }
    }
  }

  SessionStatus? _status() {
    if (widget.kind == InlineSessionKind.receive) {
      final s = ref.read(serverProvider)?.session;
      if (s?.sessionId == widget.sessionId) {
        return s?.status;
      }
      return null;
    }
    return ref.read(sendProvider)[widget.sessionId]?.status;
  }

  Future<void> _onCancel() async {
    final status = _status();
    if (status == null) {
      return;
    }
    if (status == SessionStatus.sending) {
      final ok = await context.pushBottomSheet(() => const CancelSessionDialog());
      if (ok != true) {
        return;
      }
    }
    if (widget.kind == InlineSessionKind.receive) {
      final s = ref.read(serverProvider)?.session;
      if (s != null) {
        if (s.status == SessionStatus.sending) {
          ref.notifier(serverProvider).cancelSession();
        } else {
          ref.notifier(serverProvider).closeSession();
        }
      }
    } else {
      final s = ref.read(sendProvider)[widget.sessionId];
      if (s != null) {
        if (s.status == SessionStatus.sending) {
          ref.notifier(sendProvider).cancelSession(widget.sessionId);
        } else {
          ref.notifier(sendProvider).closeSession(widget.sessionId);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(progressProvider);
    final status = _status();
    if (status == null) {
      return const SizedBox.shrink();
    }

    final progressNotifier = ref.notifier(progressProvider);
    var currBytes = 0;
    for (final entry in _sizes.entries) {
      currBytes += (progressNotifier.getProgress(sessionId: widget.sessionId, fileId: entry.key) * entry.value).round();
    }

    final double progressValue = _totalBytes == 0 ? 0 : (currBytes / _totalBytes).clamp(0.0, 1.0);

    String line;
    if (widget.kind == InlineSessionKind.send) {
      final target = ref.read(sendProvider)[widget.sessionId]?.target.alias ?? '';
      final from = ref.read(deviceFullInfoProvider).alias;
      line = t.transferTab.transferLine(from: from, to: target);
    } else {
      final s = ref.read(serverProvider)?.session;
      final from = s?.senderAlias ?? '';
      final to = ref.read(serverProvider)?.alias ?? ref.read(deviceFullInfoProvider).alias;
      line = t.transferTab.transferLine(from: from, to: to);
    }

    String? statusLine;
    switch (status) {
      case SessionStatus.waiting:
        statusLine = widget.kind == InlineSessionKind.send ? t.sendPage.waiting : t.general.queue;
        break;
      case SessionStatus.finished:
        statusLine = t.general.finished;
        break;
      case SessionStatus.finishedWithErrors:
        statusLine = t.general.error;
        break;
      case SessionStatus.declined:
        statusLine = t.sendPage.rejected;
        break;
      case SessionStatus.recipientBusy:
        statusLine = t.sendPage.busy;
        break;
      default:
        statusLine = null;
    }

    final showDismiss = status == SessionStatus.sending ||
        status == SessionStatus.waiting ||
        status == SessionStatus.finishedWithErrors ||
        status == SessionStatus.declined ||
        status == SessionStatus.recipientBusy;

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(line, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleSmall),
          if (statusLine != null && status != SessionStatus.sending) ...[
            const SizedBox(height: 4),
            Text(statusLine, textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).colorScheme.outline)),
          ],
          const SizedBox(height: 8),
          CustomProgressBar(progress: status == SessionStatus.sending ? progressValue : (status == SessionStatus.finished ? 1.0 : 0), borderRadius: 5),
          if (showDismiss)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _onCancel,
                child: Text(status == SessionStatus.sending ? t.general.cancel : t.general.close),
              ),
            ),
        ],
      ),
    );
  }
}

MapEntry<String, SendSessionState>? activeEmbeddedSendSession(Map<String, SendSessionState> sendMap) {
  for (final status in [SessionStatus.sending, SessionStatus.waiting, SessionStatus.finishedWithErrors, SessionStatus.declined, SessionStatus.recipientBusy]) {
    final entry = sendMap.entries.firstWhereOrNull((e) => e.value.status == status);
    if (entry != null) {
      return entry;
    }
  }
  return null;
}
