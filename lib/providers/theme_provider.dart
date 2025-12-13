import 'package:flutter/material.dart';
import '../services/theme_service.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  bool _isInitialized = false;
  
  ThemeMode get themeMode => _themeMode;
  bool get isInitialized => _isInitialized;
  
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  bool get isLightMode => _themeMode == ThemeMode.light;
  bool get isSystemMode => _themeMode == ThemeMode.system;
  
  ThemeProvider() {
    _loadSettings();
  }
  
  Future<void> _loadSettings() async {
    try {
      await ThemeService.loadTheme();
      _themeMode = ThemeService.themeMode;
    } catch (e) {
      // Hata durumunda varsayılan tema kullan
      _themeMode = ThemeMode.system;
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }
  
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await ThemeService.setThemeMode(mode);
    notifyListeners();
  }
  
  // Tema durumunu kontrol et
  String get currentThemeName {
    switch (_themeMode) {
      case ThemeMode.light:
        return 'Açık Tema';
      case ThemeMode.dark:
        return 'Koyu Tema';
      case ThemeMode.system:
        return 'Sistem Tema';
    }
  }
  
  
  Future<void> toggleTheme() async {
    if (_themeMode == ThemeMode.light) {
      await setThemeMode(ThemeMode.dark);
    } else if (_themeMode == ThemeMode.dark) {
      await setThemeMode(ThemeMode.system);
    } else {
      await setThemeMode(ThemeMode.light);
    }
  }
  
  // Debug için tema durumunu yazdır
  void debugThemeStatus() {
    // Debug print statements removed for production
    // print('Current Theme Mode: $_themeMode');
    // print('Is Dark Mode: $isDarkMode');
    // print('Is Light Mode: $isLightMode');
    // print('Is System Mode: $isSystemMode');
    // print('Current Theme Name: $currentThemeName');
  }
}
