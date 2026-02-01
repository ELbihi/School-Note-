import 'package:flutter/material.dart';

class SettingsProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  String _languageCode = 'fr'; 

  ThemeMode get themeMode => _themeMode;
  String get languageCode => _languageCode;

  // Change le thème globalement
  void toggleTheme(bool isDark) {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners(); 
  }

  // Change la langue globalement
  void setLanguage(String code) {
    _languageCode = code;
    notifyListeners();
  }

  String translate(String fr, String en) {
    return _languageCode == 'fr' ? fr : en;
  }
}