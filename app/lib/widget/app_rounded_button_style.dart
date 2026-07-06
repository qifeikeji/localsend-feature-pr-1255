import 'package:flutter/material.dart';
import 'package:localsend_app/theme.dart';

/// Shared corner radius for left-rail tiles and matching toolbar buttons.
const double kAppRoundedButtonRadius = 10;

RoundedRectangleBorder appRoundedButtonShape() {
  return RoundedRectangleBorder(borderRadius: BorderRadius.circular(kAppRoundedButtonRadius));
}

ButtonStyle appToolbarElevatedButtonStyle(BuildContext context) {
  final scheme = Theme.of(context).colorScheme;
  return ElevatedButton.styleFrom(
    shape: appRoundedButtonShape(),
    backgroundColor: scheme.secondaryContainerIfDark,
    foregroundColor: scheme.onSecondaryContainerIfDark,
  );
}
