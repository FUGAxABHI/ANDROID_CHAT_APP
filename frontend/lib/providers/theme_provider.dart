import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/theme.dart'; // Import AppTheme

class ThemeProvider with ChangeNotifier {
  static const String _backgroundImageKey = 'background_image';
  static const String _themeKey = 'app_theme';
  String? _backgroundImagePath;
  ThemeData _currentTheme = AppTheme.darkTheme; // Default theme

  ThemeProvider() {
    _loadPreferences();
  }

  String? get backgroundImagePath => _backgroundImagePath;
  ThemeData get currentTheme => _currentTheme;

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _backgroundImagePath = prefs.getString(_backgroundImageKey);
    final savedTheme = prefs.getString(_themeKey);
    if (savedTheme == 'glass') {
      _currentTheme = AppTheme.glassTheme;
    } else {
      _currentTheme = AppTheme.darkTheme;
    }
    notifyListeners();
  }

  Future<void> setBackgroundImage(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_backgroundImageKey, path);
    _backgroundImagePath = path;
    notifyListeners();
  }

  Future<void> clearBackgroundImage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_backgroundImageKey);
    _backgroundImagePath = null;
    notifyListeners();
  }

  Future<void> setTheme(ThemeData theme) async {
    final prefs = await SharedPreferences.getInstance();
    if (theme == AppTheme.glassTheme) {
      await prefs.setString(_themeKey, 'glass');
    } else {
      await prefs.setString(_themeKey, 'dark');
    }
    _currentTheme = theme;
    notifyListeners();
  }
}
