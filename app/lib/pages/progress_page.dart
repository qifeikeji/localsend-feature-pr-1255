import 'dart:async';

import 'package:collection/collection.dart';
import 'package:common/common.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:localsend_app/gen/strings.g.dart';
import 'package:localsend_app/pages/progress_session_body.dart';
import 'package:localsend_app/provider/network/send_provider.dart';
import 'package:localsend_app/provider/network/server/server_provider.dart';
import 'package:localsend_app/util/incoming_items_handler.dart';
import 'package:localsend_app/util/native/taskbar_helper.dart';
import 'package:refena_flutter/refena_flutter.dart';
import 'package:routerino/routerino.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class ProgressPage extends StatefulWidget {
  final bool showAppBar;
  final bool closeSessionOnClose;
  final String sessionId;

  const ProgressPage({
    required this.showAppBar,
    required this.closeSessionOnClose,
    required this.sessionId,
  });

  @override
  State<ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends State<ProgressPage> with Refena {
  bool _dragIndicator = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        WakelockPlus.enable(); // ignore: discarded_futures
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    unawaited(TaskbarHelper.clearProgressBar());
    try {
      unawaited(WakelockPlus.disable());
    } catch (_) {}
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    final receive = ref.read(serverProvider)?.session;
    final send = ref.read(sendProvider)[widget.sessionId];
    final status = receive?.status ?? send?.status;
    if (status == null || status != SessionStatus.sending) {
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final receiveSession = ref.watch(serverProvider.select((s) => s?.session));
    final sendMap = ref.watch(sendProvider);

    final receiveActive = receiveSession?.status == SessionStatus.sending;
    final receiveId = receiveActive ? receiveSession!.sessionId : null;

    String? sendId;
    if (sendMap[widget.sessionId]?.status == SessionStatus.sending) {
      sendId = widget.sessionId;
    } else {
      sendId = sendMap.entries.firstWhereOrNull((e) => e.value.status == SessionStatus.sending)?.key;
    }
    final sendActive = sendId != null;
    final dual = receiveActive && sendActive;

    if (!receiveActive && !sendActive) {
      return Scaffold(body: Container());
    }

    final title = dual ? t.progressPage.titleReceiving : (receiveActive ? t.progressPage.titleReceiving : t.progressPage.titleSending);

    return WillPopScope(
      onWillPop: _onWillPop,
      child: DropTarget(
        onDragEntered: (_) => setState(() => _dragIndicator = true),
        onDragExited: (_) => setState(() => _dragIndicator = false),
        onDragDone: (event) async {
          setState(() => _dragIndicator = false);
          final queued = await IncomingItemsHandler.handleDroppedFiles(ref, event.files);
          if (queued && mounted) {
            IncomingItemsHandler.showQueuedSnackBar(context);
          }
        },
        child: Scaffold(
          appBar: widget.showAppBar ? AppBar(title: Text(title)) : null,
          body: Stack(
            children: [
              Column(
                children: [
                  if (receiveActive && receiveId != null)
                    Expanded(
                      flex: dual ? 1 : 2,
                      child: ProgressSessionBody(
                        sessionId: receiveId,
                        kind: ProgressSessionKind.receive,
                        compact: dual,
                        closeSessionOnClose: widget.closeSessionOnClose,
                      ),
                    ),
                  if (dual) const Divider(height: 1),
                  if (sendActive && sendId != null)
                    Expanded(
                      flex: dual ? 1 : 2,
                      child: ProgressSessionBody(
                        sessionId: sendId,
                        kind: ProgressSessionKind.send,
                        compact: dual,
                        closeSessionOnClose: widget.closeSessionOnClose,
                      ),
                    ),
                ],
              ),
              if (_dragIndicator)
                Container(
                  color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.9),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.file_download, size: 64),
                      const SizedBox(height: 16),
                      Text(t.sendTab.placeItems, style: Theme.of(context).textTheme.titleMedium),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
