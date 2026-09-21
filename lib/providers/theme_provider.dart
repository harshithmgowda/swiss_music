import 'package:flutter/material.dart';

import '../services/storage_service.dart';
import '../theme/app_theme.dart';

class ThemeProvider with ChangeNotifier {
  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;

  Future<void> init() async {
    try {
      final saved = await StorageService.instance.getSetting('dark_mode');
      if (saved != null) {
        _isDarkMode = saved == 'true';
        AppTheme.isDark = _isDarkMode;
        notifyListeners();
      }
    } catch (_) {}
  }

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    AppTheme.isDark = _isDarkMode;
    notifyListeners();
    StorageService.instance.setSetting('dark_mode', _isDarkMode.toString());
  }

  void setDarkMode(bool value) {
    if (_isDarkMode != value) {
      _isDarkMode = value;
      AppTheme.isDark = _isDarkMode;
      notifyListeners();
      StorageService.instance.setSetting('dark_mode', _isDarkMode.toString());
    }
  }
}
