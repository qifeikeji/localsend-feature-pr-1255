import 'package:common/common.dart';
import 'package:flutter/material.dart';
import 'package:localsend_app/gen/strings.g.dart';
import 'package:localsend_app/model/persistence/color_mode.dart';
import 'package:localsend_app/model/send_mode.dart';
import 'package:localsend_app/model/state/settings_state.dart';
import 'package:localsend_app/provider/persistence_provider.dart';
import 'package:refena_flutter/refena_flutter.dart';

final settingsProvider = NotifierProvider<SettingsService, SettingsState>((ref) {
  return SettingsService(ref.read(persistenceProvider));
});

class SettingsService extends PureNotifier<SettingsState> {
  final PersistenceService _persistence;

  SettingsService(this._persistence);

  @override
  SettingsState init() => SettingsState(
        showToken: _persistence.getShowToken(),
        alias: _persistence.getAlias(),
        theme: _persistence.getTheme(),
        colorMode: _persistence.getColorMode(),
        locale: _persistence.getLocale(),
        port: _persistence.getPort(),
        multicastGroup: _persistence.getMulticastGroup(),
        destination: _persistence.getDestination(),
        saveToGallery: _persistence.isSaveToGallery(),
        saveToHistory: _persistence.isSaveToHistory(),
        quickSave: _persistence.isQuickSave(),
        autoFinish: _persistence.isAutoFinish(),
        minimizeToTray: _persistence.isMinimizeToTray(),
        launchAtStartup: _persistence.isLaunchAtStartup(),
        autoStartLaunchMinimized: _persistence.isAutoStartLaunchMinimized(),
        https: _persistence.isHttps(),
        sendMode: _persistence.getSendMode(),
        saveWindowPlacement: _persistence.getSaveWindowPlacement(),
        enableAnimations: _persistence.getEnableAnimations(),
        deviceType: _persistence.getDeviceType(),
        deviceModel: _persistence.getDeviceModel(),
        shareViaLinkAutoAccept: _persistence.getShareViaLinkAutoAccept(),
        historyPanelWidth: _persistence.getHistoryPanelWidth(),
        historyPanelVisible: _persistence.getHistoryPanelVisible(),
        knownDeviceIps: _persistence.getKnownDeviceIps(),
        sendLowerPanelOpacity: _persistence.getSendLowerPanelOpacity(),
        navigationPanelWidth: _persistence.getNavigationPanelWidth(),
        syncSidePanelWidths: _persistence.getSyncSidePanelWidths(),
        pasteButtonOpacity: _persistence.getPasteButtonOpacity(),
        pasteButtonGradientSpan: _persistence.getPasteButtonGradientSpan(),
      );

  Future<void> setAlias(String alias) async {
    await _persistence.setAlias(alias);
    state = state.copyWith(
      alias: alias,
    );
  }

  Future<void> setTheme(ThemeMode theme) async {
    await _persistence.setTheme(theme);
    state = state.copyWith(
      theme: theme,
    );
  }

  Future<void> setColorMode(ColorMode mode) async {
    await _persistence.setColorMode(mode);
    state = state.copyWith(
      colorMode: mode,
    );
  }

  Future<void> setLocale(AppLocale? locale) async {
    await _persistence.setLocale(locale);
    state = state.copyWith(
      locale: locale,
    );
  }

  Future<void> setPort(int port) async {
    await _persistence.setPort(port);
    state = state.copyWith(
      port: port,
    );
  }

  Future<void> setMulticastGroup(String group) async {
    await _persistence.setMulticastGroup(group);
    state = state.copyWith(
      multicastGroup: group,
    );
  }

  Future<void> setDestination(String? destination) async {
    await _persistence.setDestination(destination);
    state = state.copyWith(
      destination: destination,
    );
  }

  Future<void> setSaveToGallery(bool saveToGallery) async {
    await _persistence.setSaveToGallery(saveToGallery);
    state = state.copyWith(
      saveToGallery: saveToGallery,
    );
  }

  Future<void> setSaveToHistory(bool saveToHistory) async {
    await _persistence.setSaveToHistory(saveToHistory);
    state = state.copyWith(
      saveToHistory: saveToHistory,
    );
  }

  Future<void> setQuickSave(bool quickSave) async {
    await _persistence.setQuickSave(quickSave);
    state = state.copyWith(
      quickSave: quickSave,
    );
  }

  Future<void> setAutoFinish(bool autoFinish) async {
    await _persistence.setAutoFinish(autoFinish);
    state = state.copyWith(
      autoFinish: autoFinish,
    );
  }

  Future<void> setMinimizeToTray(bool minimizeToTray) async {
    await _persistence.setMinimizeToTray(minimizeToTray);
    state = state.copyWith(
      minimizeToTray: minimizeToTray,
    );
  }

  Future<void> setLaunchAtStartup(bool launchAtStartup) async {
    await _persistence.setLaunchAtStartup(launchAtStartup);
    state = state.copyWith(
      launchAtStartup: launchAtStartup,
    );
  }

  Future<void> setAutoStartLaunchMinimized(bool launchMinimized) async {
    await _persistence.setAutoStartLaunchMinimized(launchMinimized);
    state = state.copyWith(
      autoStartLaunchMinimized: launchMinimized,
    );
  }

  Future<void> setHttps(bool https) async {
    await _persistence.setHttps(https);
    state = state.copyWith(
      https: https,
    );
  }

  Future<void> setSendMode(SendMode mode) async {
    await _persistence.setSendMode(mode);
    state = state.copyWith(
      sendMode: mode,
    );
  }

  Future<void> setSaveWindowPlacement(bool savePlacement) async {
    await _persistence.setSaveWindowPlacement(savePlacement);
    state = state.copyWith(
      saveWindowPlacement: savePlacement,
    );
  }

  Future<void> setEnableAnimations(bool enableAnimations) async {
    await _persistence.setEnableAnimations(enableAnimations);
    state = state.copyWith(
      enableAnimations: enableAnimations,
    );
  }

  Future<void> setDeviceType(DeviceType deviceType) async {
    await _persistence.setDeviceType(deviceType);
    state = state.copyWith(
      deviceType: deviceType,
    );
  }

  Future<void> setDeviceModel(String deviceModel) async {
    await _persistence.setDeviceModel(deviceModel);
    state = state.copyWith(
      deviceModel: deviceModel,
    );
  }

  Future<void> setShareViaLinkAutoAccept(bool shareViaLinkAutoAccept) async {
    await _persistence.setShareViaLinkAutoAccept(shareViaLinkAutoAccept);

    state = state.copyWith(
      shareViaLinkAutoAccept: shareViaLinkAutoAccept,
    );
  }

  Future<void> setHistoryPanelWidth(double width, {bool fromSync = false}) async {
    final minW = state.syncSidePanelWidths ? 72.0 : 200.0;
    final clamped = width.clamp(minW, 480.0);
    await _persistence.setHistoryPanelWidth(clamped);
    state = state.copyWith(historyPanelWidth: clamped);
    if (state.syncSidePanelWidths && !fromSync) {
      await setNavigationPanelWidth(clamped, fromSync: true);
    }
  }

  Future<void> setHistoryPanelVisible(bool visible) async {
    await _persistence.setHistoryPanelVisible(visible);
    state = state.copyWith(historyPanelVisible: visible);
  }

  Future<void> setKnownDeviceIps(String ips) async {
    await _persistence.setKnownDeviceIps(ips);
    state = state.copyWith(knownDeviceIps: ips);
  }

  Future<void> setStartupWindowWidth(double width) async {
    final clamped = width.clamp(400.0, 4096.0);
    await _persistence.setStartupWindowWidth(clamped);
  }

  Future<void> setStartupWindowHeight(double height) async {
    final clamped = height.clamp(500.0, 4096.0);
    await _persistence.setStartupWindowHeight(clamped);
  }

  Future<void> setSendLowerPanelOpacity(double opacity) async {
    final clamped = opacity.clamp(0.15, 0.95);
    await _persistence.setSendLowerPanelOpacity(clamped);
    state = state.copyWith(sendLowerPanelOpacity: clamped);
  }

  Future<void> setNavigationPanelWidth(double width, {bool fromSync = false}) async {
    final clamped = width.clamp(72.0, 480.0);
    await _persistence.setNavigationPanelWidth(clamped);
    state = state.copyWith(navigationPanelWidth: clamped);
    if (state.syncSidePanelWidths && !fromSync) {
      await setHistoryPanelWidth(clamped, fromSync: true);
    }
  }

  Future<void> setSyncSidePanelWidths(bool value) async {
    await _persistence.setSyncSidePanelWidths(value);
    state = state.copyWith(syncSidePanelWidths: value);
    if (value) {
      final w = state.navigationPanelWidth.clamp(72.0, 480.0);
      await _persistence.setHistoryPanelWidth(w);
      await _persistence.setNavigationPanelWidth(w);
      state = state.copyWith(navigationPanelWidth: w, historyPanelWidth: w);
    }
  }

  Future<void> setPasteButtonOpacity(double value) async {
    final clamped = value.clamp(0.1, 0.95);
    await _persistence.setPasteButtonOpacity(clamped);
    state = state.copyWith(pasteButtonOpacity: clamped);
  }

  Future<void> setPasteButtonGradientSpan(double value) async {
    final clamped = value.clamp(0.0, 1.0);
    await _persistence.setPasteButtonGradientSpan(clamped);
    state = state.copyWith(pasteButtonGradientSpan: clamped);
  }
}
