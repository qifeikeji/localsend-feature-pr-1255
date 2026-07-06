import 'package:flutter/material.dart';
import 'package:localsend_app/gen/strings.g.dart';
import 'package:localsend_app/model/persistence/color_mode.dart';
import 'package:localsend_app/provider/settings_provider.dart';
import 'package:localsend_app/theme.dart';
import 'package:localsend_app/util/sleep.dart';
import 'package:localsend_app/util/ui/dynamic_colors.dart';
import 'package:localsend_app/widget/custom_dropdown_button.dart';
import 'package:refena_flutter/refena_flutter.dart';

class TransferAppearanceControls extends StatelessWidget {
  const TransferAppearanceControls();

  @override
  Widget build(BuildContext context) {
    final ref = context.ref;
    final settings = ref.watch(settingsProvider);
    final supportsDynamic = ref.watch(dynamicColorsProvider) != null;
    final colorModes = supportsDynamic ? ColorMode.values : ColorMode.values.where((e) => e != ColorMode.system).toList();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(t.settingsTab.general.brightness, style: Theme.of(context).textTheme.labelSmall),
                const SizedBox(height: 4),
                CustomDropdownButton<ThemeMode>(
                  value: settings.theme,
                  items: ThemeMode.values
                      .map(
                        (mode) => DropdownMenuItem(
                          value: mode,
                          alignment: Alignment.center,
                          child: Text(_themeLabel(mode)),
                        ),
                      )
                      .toList(),
                  onChanged: (theme) async {
                    await ref.notifier(settingsProvider).setTheme(theme);
                    await sleepAsync(500);
                    if (context.mounted) {
                      await updateSystemOverlayStyle(context);
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(t.settingsTab.general.color, style: Theme.of(context).textTheme.labelSmall),
                const SizedBox(height: 4),
                CustomDropdownButton<ColorMode>(
                  value: settings.colorMode,
                  items: colorModes
                      .map(
                        (mode) => DropdownMenuItem(
                          value: mode,
                          alignment: Alignment.center,
                          child: Text(_colorLabel(mode)),
                        ),
                      )
                      .toList(),
                  onChanged: (mode) async {
                    await ref.notifier(settingsProvider).setColorMode(mode);
                    if (mode == ColorMode.oled) {
                      await ref.notifier(settingsProvider).setTheme(ThemeMode.dark);
                      await updateSystemOverlayStyleWithBrightness(Brightness.dark);
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _themeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return t.settingsTab.general.brightnessOptions.system;
      case ThemeMode.light:
        return t.settingsTab.general.brightnessOptions.light;
      case ThemeMode.dark:
        return t.settingsTab.general.brightnessOptions.dark;
    }
  }

  String _colorLabel(ColorMode mode) {
    return switch (mode) {
      ColorMode.system => t.settingsTab.general.colorOptions.system,
      ColorMode.localsend => t.appName,
      ColorMode.oled => t.settingsTab.general.colorOptions.oled,
      ColorMode.yaru => 'Yaru',
    };
  }
}
