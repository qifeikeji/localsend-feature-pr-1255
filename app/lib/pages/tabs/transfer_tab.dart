import 'package:common/common.dart';
import 'package:flutter/material.dart';
import 'package:localsend_app/gen/strings.g.dart';
import 'package:localsend_app/model/send_mode.dart';
import 'package:localsend_app/pages/home_page.dart';
import 'package:localsend_app/pages/receive_history_page.dart';
import 'package:localsend_app/pages/tabs/receive_tab_vm.dart';
import 'package:localsend_app/pages/tabs/send_tab_vm.dart';
import 'package:localsend_app/provider/animation_provider.dart';
import 'package:localsend_app/provider/clipboard_paste_action.dart';
import 'package:localsend_app/provider/network/send_provider.dart';
import 'package:localsend_app/provider/network/server/server_provider.dart';
import 'package:localsend_app/provider/selection/selected_sending_files_provider.dart';
import 'package:localsend_app/provider/settings_provider.dart';
import 'package:localsend_app/provider/ui/home_tab_provider.dart';
import 'package:localsend_app/util/ip_helper.dart';
import 'package:localsend_app/widget/custom_icon_button.dart';
import 'package:localsend_app/widget/embedded_receive_session.dart';
import 'package:localsend_app/widget/inline_session_progress.dart';
import 'package:localsend_app/widget/list_tile/device_list_tile.dart';
import 'package:localsend_app/widget/local_send_logo.dart';
import 'package:localsend_app/widget/rotating_widget.dart';
import 'package:localsend_app/widget/send_queue_card.dart';
import 'package:refena_flutter/refena_flutter.dart';
import 'package:routerino/routerino.dart';
import 'package:collection/collection.dart';

class TransferTab extends StatelessWidget {
  const TransferTab();

  @override
  Widget build(BuildContext context) {
    return ViewModelBuilder(
      provider: sendTabVmProvider,
      init: (context, ref) {
        ref.dispatchAsync(SendTabInitAction(context));
      },
      builder: (context, sendVm) {
        final vm = context.ref.watch(receiveTabVmProvider);
        final ref = context.ref;
        final queuedFiles = ref.watch(selectedSendingFilesProvider);
        final receiveSession = ref.watch(serverProvider.select((s) => s?.session));
        final sendMap = ref.watch(sendProvider);
        final sendEntry = activeEmbeddedSendSession(sendMap);

        final receiveSending = receiveSession?.status == SessionStatus.sending;
        final isDesktop = MediaQuery.sizeOf(context).width >= 800;
        final historyPanelVisible = ref.watch(settingsProvider.select((s) => s.historyPanelVisible));
        final showMobileDevices = MediaQuery.sizeOf(context).width < 700;

        return Stack(
          children: [
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (isDesktop && !historyPanelVisible)
                        Tooltip(
                          message: t.receiveTab.showHistoryPanel,
                          child: CustomIconButton(
                            onPressed: () async {
                              await ref.notifier(settingsProvider).setHistoryPanelVisible(true);
                            },
                            child: const Icon(Icons.view_sidebar),
                          ),
                        ),
                      if (!isDesktop || !historyPanelVisible)
                        CustomIconButton(
                          onPressed: () async {
                            await context.push(() => const ReceiveHistoryPage());
                          },
                          child: const Icon(Icons.history),
                        ),
                      CustomIconButton(
                        onPressed: vm.toggleAdvanced,
                        child: const Icon(Icons.info),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: receiveSending && receiveSession != null
                      ? EmbeddedReceiveSession(sessionId: receiveSession.sessionId)
                      : _ReceiveIdleSection(vm: vm),
                ),
                const Divider(height: 1),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (queuedFiles.isNotEmpty) SendQueueCard(files: queuedFiles),
                                if (sendEntry != null)
                                  InlineSessionProgress(
                                    sessionId: sendEntry.key,
                                    kind: InlineSessionKind.send,
                                  )
                                else if (queuedFiles.isEmpty)
                                  Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Text(
                                      t.receiveTab.sendSectionHint,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: Theme.of(context).colorScheme.outline),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        Center(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              await ref.dispatchAsync(PasteFromClipboardAction(context: context));
                            },
                            icon: const Icon(Icons.paste),
                            label: Text(t.receiveTab.paste),
                          ),
                        ),
                        if (showMobileDevices) ...[
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(t.sendTab.nearbyDevices, style: Theme.of(context).textTheme.titleSmall),
                          ),
                          SizedBox(
                            height: 140,
                            child: ListView(
                              children: sendVm.nearbyDevices.map((device) {
                                final fav = sendVm.favoriteDevices.firstWhereOrNull((e) => e.fingerprint == device.fingerprint);
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: DeviceListTile(
                                    device: device,
                                    isFavorite: fav != null,
                                    nameOverride: fav?.alias,
                                    onFavoriteTap: () async => sendVm.onToggleFavorite(device),
                                    onTap: () async {
                                      if (sendVm.sendMode == SendMode.multiple) {
                                        await sendVm.onTapDeviceMultiSend(context, device);
                                      } else {
                                        await sendVm.onTapDevice(context, device);
                                      }
                                    },
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                        const SizedBox(height: 4),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Center(
                    child: vm.quickSaveSettings
                        ? ElevatedButton(
                            onPressed: () async => vm.onSetQuickSave(context, false),
                            child: Text('${t.general.quickSave}: ${t.general.on}'),
                          )
                        : TextButton(
                            onPressed: () async => vm.onSetQuickSave(context, true),
                            child: Text('${t.general.quickSave}: ${t.general.off}'),
                          ),
                  ),
                ),
              ],
            ),
            if (vm.showAdvanced)
              Positioned(
                top: 48,
                right: 12,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${t.receiveTab.infoBox.alias}: ${vm.serverState?.alias ?? '-'}'),
                        Text('${t.receiveTab.infoBox.port}: ${vm.serverState?.port ?? '-'}'),
                        ...vm.localIps.map((ip) => Text('${t.receiveTab.infoBox.ip}: $ip')),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ReceiveIdleSection extends StatelessWidget {
  final ReceiveTabVm vm;

  const _ReceiveIdleSection({required this.vm});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Consumer(builder: (context, ref) {
              final animations = ref.watch(animationProvider);
              final activeTab = ref.watch(homeTabProvider);
              return RotatingWidget(
                duration: const Duration(seconds: 15),
                spinning: vm.serverState != null && animations && activeTab == HomeTab.transfer,
                child: const LocalSendLogo(withText: false),
              );
            }),
            const SizedBox(height: 12),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(vm.serverState?.alias ?? vm.aliasSettings, style: const TextStyle(fontSize: 36)),
            ),
            Text(
              vm.serverState == null ? t.general.offline : vm.localIps.map((ip) => '#${ip.visualId}').toSet().join(' '),
              style: const TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
