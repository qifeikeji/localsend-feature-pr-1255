import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:localsend_app/gen/strings.g.dart';
import 'package:localsend_app/model/persistence/color_mode.dart';
import 'package:localsend_app/provider/device_info_provider.dart';
import 'package:localsend_app/util/native/platform_check.dart';
import 'package:localsend_app/util/ui/dynamic_colors.dart';
import 'package:refena_flutter/refena_flutter.dart';
import 'package:yaru/yaru.dart' as yaru;

final _borderRadius = BorderRadius.circular(5);

/// On desktop, we need to add additional padding to achieve the same visual appearance as on mobile
double get desktopPaddingFix => checkPlatformIsDesktop() ? 8 : 0;

ThemeData getTheme(ColorMode colorMode, Brightness brightness, DynamicColors? dynamicColors) {
  if (colorMode == ColorMode.yaru) {
    return _getYaruTheme(brightness);
  }
  if (colorMode == ColorMode.macos) {
    return _getMacosTheme();
  }

  final colorScheme = _determineColorScheme(colorMode, brightness, dynamicColors);

  final lightInputBorder = OutlineInputBorder(
    borderSide: BorderSide(color: colorScheme.secondaryContainer),
    borderRadius: _borderRadius,
  );

  final darkInputBorder = OutlineInputBorder(
    borderSide: BorderSide(color: colorScheme.secondaryContainer),
    borderRadius: _borderRadius,
  );

  // https://github.com/localsend/localsend/issues/52
  final String? fontFamily;
  if (checkPlatform([TargetPlatform.windows])) {
    fontFamily = switch (LocaleSettings.currentLocale) {
      AppLocale.ja => 'Yu Gothic UI',
      AppLocale.ko => 'Malgun Gothic',
      AppLocale.zhCn => 'Microsoft YaHei UI',
      AppLocale.zhHk || AppLocale.zhTw => 'Microsoft JhengHei UI',
      _ => 'Segoe UI Variable Display',
    };
  } else {
    fontFamily = null;
  }

  return ThemeData(
    colorScheme: colorScheme,
    useMaterial3: true,
    iconTheme: IconThemeData(color: colorScheme.onSurface),
    navigationBarTheme: colorScheme.brightness == Brightness.dark
        ? NavigationBarThemeData(
            iconTheme: MaterialStateProperty.all(const IconThemeData(color: Colors.white)),
          )
        : null,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colorScheme.secondaryContainer,
      border: colorScheme.brightness == Brightness.light ? lightInputBorder : darkInputBorder,
      focusedBorder: colorScheme.brightness == Brightness.light ? lightInputBorder : darkInputBorder,
      enabledBorder: colorScheme.brightness == Brightness.light ? lightInputBorder : darkInputBorder,
      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 10),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: colorScheme.brightness == Brightness.dark ? Colors.white : null,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8 + desktopPaddingFix),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8 + desktopPaddingFix),
      ),
    ),
    fontFamily: fontFamily,
  );
}

Future<void> updateSystemOverlayStyle(BuildContext context) async {
  final brightness = Theme.of(context).brightness;
  await updateSystemOverlayStyleWithBrightness(brightness);
}

Future<void> updateSystemOverlayStyleWithBrightness(Brightness brightness) async {
  if (checkPlatform([TargetPlatform.android])) {
    // See https://github.com/flutter/flutter/issues/90098
    final darkMode = brightness == Brightness.dark;
    final androidSdkInt = RefenaScope.defaultRef.read(deviceInfoProvider).androidSdkInt ?? 0;
    final bool edgeToEdge = androidSdkInt >= 29;

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge); // ignore: unawaited_futures

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: brightness == Brightness.light ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: edgeToEdge ? Colors.transparent : (darkMode ? Colors.black : Colors.white),
      systemNavigationBarContrastEnforced: false,
      systemNavigationBarIconBrightness: darkMode ? Brightness.light : Brightness.dark,
    ));
  } else {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarBrightness: brightness, // iOS
      statusBarColor: Colors.transparent, // Not relevant to this issue
    ));
  }
}

extension ThemeDataExt on ThemeData {
  /// This is the actual [cardColor] being used.
  Color get cardColorWithElevation {
    return ElevationOverlay.applySurfaceTint(cardColor, colorScheme.surfaceTint, 1);
  }
}

extension ColorSchemeExt on ColorScheme {
  Color get warning {
    return Colors.orange;
  }

  Color? get secondaryContainerIfDark {
    return brightness == Brightness.dark ? secondaryContainer : null;
  }

  Color? get onSecondaryContainerIfDark {
    return brightness == Brightness.dark ? onSecondaryContainer : null;
  }
}

extension InputDecorationThemeExt on InputDecorationTheme {
  BorderRadius get borderRadius => _borderRadius;
}

ColorScheme _determineColorScheme(ColorMode mode, Brightness brightness, DynamicColors? dynamicColors) {
  final defaultColorScheme = ColorScheme.fromSeed(
    seedColor: Colors.teal,
    brightness: brightness,
  );

  final colorScheme = switch (mode) {
    ColorMode.system => brightness == Brightness.light ? dynamicColors?.light : dynamicColors?.dark,
    ColorMode.localsend => null,
    ColorMode.oled => (dynamicColors?.dark ?? defaultColorScheme).copyWith(
        background: Colors.black,
        surface: Colors.black,
      ),
    ColorMode.yaru => throw 'Should reach here',
    ColorMode.macos => throw 'Should reach here',
  };

  return colorScheme ?? defaultColorScheme;
}

ThemeData _getYaruTheme(Brightness brightness) {
  final baseTheme = brightness == Brightness.light ? yaru.yaruLight : yaru.yaruDark;
  final colorScheme = baseTheme.colorScheme;

  final lightInputBorder = OutlineInputBorder(
    borderSide: BorderSide(color: colorScheme.secondaryContainer),
    borderRadius: _borderRadius,
  );

  final darkInputBorder = OutlineInputBorder(
    borderSide: BorderSide(color: colorScheme.secondaryContainer),
    borderRadius: _borderRadius,
  );

  return baseTheme.copyWith(
    navigationBarTheme: colorScheme.brightness == Brightness.dark
        ? NavigationBarThemeData(
            iconTheme: MaterialStateProperty.all(const IconThemeData(color: Colors.white)),
          )
        : null,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colorScheme.secondaryContainer,
      border: colorScheme.brightness == Brightness.light ? lightInputBorder : darkInputBorder,
      focusedBorder: colorScheme.brightness == Brightness.light ? lightInputBorder : darkInputBorder,
      enabledBorder: colorScheme.brightness == Brightness.light ? lightInputBorder : darkInputBorder,
      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 10),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: colorScheme.brightness == Brightness.dark ? Colors.white : null,
        padding: checkPlatformIsDesktop() ? const EdgeInsets.all(16) : const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        padding: checkPlatformIsDesktop() ? const EdgeInsets.all(16) : const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    ),
  );
}

/// macOS Ventura-style dark appearance (desktop accent, switches, surfaces).
ThemeData _getMacosTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF0A84FF),
    brightness: Brightness.dark,
  ).copyWith(
    primary: const Color(0xFF0A84FF),
    primaryContainer: const Color(0xFF409CFF),
    secondaryContainer: const Color(0xFF3A3A3C),
    surface: const Color(0xFF2C2C2E),
    surfaceContainerHighest: const Color(0xFF3A3A3C),
    outline: const Color(0xFF48484A),
    outlineVariant: const Color(0xFF3A3A3C),
    onSurface: Colors.white,
    onSecondaryContainer: Colors.white,
  );

  const macSwitchTrackOn = Color(0xFF32D74B);
  const macSwitchTrackOff = Color(0x7878807A);
  const macSwitchThumb = Color(0xFFFFFFFF);

  final inputBorder = OutlineInputBorder(
    borderSide: const BorderSide(color: Color(0xFF48484A)),
    borderRadius: _borderRadius,
  );

  final String? fontFamily = checkPlatform([TargetPlatform.windows])
      ? switch (LocaleSettings.currentLocale) {
          AppLocale.ja => 'Yu Gothic UI',
          AppLocale.ko => 'Malgun Gothic',
          AppLocale.zhCn => 'Microsoft YaHei UI',
          AppLocale.zhHk || AppLocale.zhTw => 'Microsoft Jhenghei UI',
          _ => 'Segoe UI Variable Display',
        }
      : null;

  return ThemeData(
    colorScheme: colorScheme,
    useMaterial3: true,
    scaffoldBackgroundColor: const Color(0xFF1D1D1F),
    cardColor: const Color(0xFF2C2C2E),
    iconTheme: const IconThemeData(color: Colors.white),
    navigationBarTheme: NavigationBarThemeData(
      iconTheme: WidgetStateProperty.all(const IconThemeData(color: Colors.white)),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) => macSwitchThumb),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return macSwitchTrackOn;
        }
        return macSwitchTrackOff;
      }),
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.all(Colors.white),
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return const Color(0xFF3A3A3C).withOpacity(0.5);
          }
          if (states.contains(WidgetState.hovered) || states.contains(WidgetState.pressed)) {
            return const Color(0xFF48484A);
          }
          return const Color(0xFF3A3A3C);
        }),
        padding: WidgetStateProperty.all(EdgeInsets.symmetric(horizontal: 16, vertical: 8 + desktopPaddingFix)),
        shape: WidgetStateProperty.all(RoundedRectangleBorder(borderRadius: _borderRadius)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.hovered)) {
            return const Color(0xFF64B5FF);
          }
          return const Color(0xFF0A84FF);
        }),
        padding: WidgetStateProperty.all(EdgeInsets.symmetric(horizontal: 16, vertical: 8 + desktopPaddingFix)),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.hovered) || states.contains(WidgetState.pressed)) {
            return const Color(0xFF409CFF);
          }
          return const Color(0xFF0A84FF);
        }),
        foregroundColor: WidgetStateProperty.all(Colors.white),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF3A3A3C),
      border: inputBorder,
      focusedBorder: inputBorder.copyWith(borderSide: const BorderSide(color: Color(0xFF0A84FF))),
      enabledBorder: inputBorder,
      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 10),
    ),
    dividerColor: const Color(0xFF48484A),
    fontFamily: fontFamily,
  );
}
