import 'package:localsend_app/model/state/settings_state.dart';

/// Parses newline-separated IPv4 addresses from settings.
List<String> parseKnownDeviceIps(String raw) {
  final ips = <String>[];
  for (final line in raw.split('\n')) {
    final ip = line.trim();
    if (ip.isEmpty) {
      continue;
    }
    if (_isValidIpv4(ip)) {
      ips.add(ip);
    }
  }
  return ips;
}

bool _isValidIpv4(String ip) {
  final parts = ip.split('.');
  if (parts.length != 4) {
    return false;
  }
  for (final part in parts) {
    final n = int.tryParse(part);
    if (n == null || n < 0 || n > 255) {
      return false;
    }
  }
  return true;
}

List<String> knownDeviceIpsFromSettings(SettingsState settings) => parseKnownDeviceIps(settings.knownDeviceIps);
