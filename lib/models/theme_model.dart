import 'package:flutter/material.dart';

enum AppTheme {
  light,
  dark,
  system,
}

extension AppThemeExtension on AppTheme {
  String get displayName {
    switch (this) {
      case AppTheme.light:
        return 'Light';
      case AppTheme.dark:
        return 'Dark';
      case AppTheme.system:
        return 'System Default';
    }
  }

  IconData get icon {
    switch (this) {
      case AppTheme.light:
        return Icons.light_mode;
      case AppTheme.dark:
        return Icons.dark_mode;
      case AppTheme.system:
        return Icons.settings;
    }
  }
}