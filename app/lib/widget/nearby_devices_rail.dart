import 'package:collection/collection.dart';
import 'package:common/common.dart';
import 'package:flutter/material.dart';
import 'package:localsend_app/gen/strings.g.dart';
import 'package:localsend_app/model/send_mode.dart';
import 'package:localsend_app/pages/tabs/send_tab_vm.dart';
import 'package:localsend_app/provider/animation_provider.dart';
import 'package:localsend_app/provider/network/nearby_devices_provider.dart';
import 'package:localsend_app/provider/network/scan_facade.dart';
import 'package:localsend_app/provider/settings_provider.dart';
import 'package:localsend_app/util/device_type_ext.dart';
import 'package:localsend_app/widget/custom_icon_button.dart';
import 'package:localsend_app/widget/rotating_widget.dart';
import 'package:refena_flutter/refena_flutter.dart';

/// Device list shown below [NavigationRail] destinations on desktop/tablet layouts.
class NearbyDevicesRail extends StatelessWidget {
  final bool extended;

  const NearbyDevicesRail({super.key, required this.extended});

  @override
  Widget build(BuildContext context) {
    final vm = context.ref.watch(sendTabVmProvider);
    final devices = vm.nearbyDevices.toList();
    final sendMode = context.ref.watch(settingsProvider.select((s) => s.sendMode));
    final (scanningFavorites, scanningIps) =
        context.ref.watch(nearbyDevicesProvider.select((s) => (s.runningFavoriteScan, s.runningIps)));
    final animations = context.ref.watch(animationProvider);
    final spinning = (scanningFavorites || scanningIps.isNotEmpty) && animations;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
          child: Row(
            children: [
              if (extended)
                Expanded(
                  child: Text(
                    t.sendTab.nearbyDevices,
                    style: Theme.of(context).textTheme.labelLarge,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              RotatingWidget(
                duration: const Duration(seconds: 2),
                spinning: spinning,
                reverse: true,
                child: CustomIconButton(
                  onPressed: () async {
                    context.redux(nearbyDevicesProvider).dispatch(ClearFoundDevicesAction());
                    await context.ref.dispatchAsync(StartSmartScan(forceLegacy: true));
                  },
                  child: const Icon(Icons.sync, size: 20),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 220,
          child: devices.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    t.general.offline,
                    style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.outline),
                    textAlign: TextAlign.center,
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 8),
                  itemCount: devices.length,
                  itemBuilder: (context, index) {
                    final device = devices[index];
                    final favoriteEntry = vm.favoriteDevices.firstWhereOrNull((e) => e.fingerprint == device.fingerprint);
                    final name = favoriteEntry?.alias ?? device.alias;
                    return Tooltip(
                      message: '$name\n${device.ip}',
                      child: InkWell(
                        onTap: () async {
                          if (sendMode == SendMode.multiple) {
                            await vm.onTapDeviceMultiSend(context, device);
                          } else {
                            await vm.onTapDevice(context, device);
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          child: Row(
                            children: [
                              Icon(device.deviceType.icon, size: 22),
                              if (extended) ...[
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
