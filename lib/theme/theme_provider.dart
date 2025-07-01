import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeData _currentThemeData = ThemeData.light();
  String _currentThemeName = 'light';

  final Map<String, ThemeData> _availableThemes = {
    'light': ThemeData.light(),
    'dark': ThemeData(
      brightness: Brightness.dark,
      primaryColor: Colors.blue[700],
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blueGrey,
        brightness: Brightness.dark,
        primary: Colors.blue[700],
        onPrimary: Colors.white,
        secondary: Colors.blueGrey[400],
        onSecondary: Colors.white,
        surface: Colors.blueGrey[900],
        onSurface: Colors.white,
        background: Colors.black,
        onBackground: Colors.blueGrey[100],
      ),
      scaffoldBackgroundColor: Colors.black87,
      cardColor: Colors.blueGrey[800]?.withOpacity(0.5),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: Colors.white70),
        titleMedium: TextStyle(color: Colors.white),
        titleLarge: TextStyle(color: Colors.white),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.blueGrey[900],
        foregroundColor: Colors.white,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.blueGrey[900],
        indicatorColor: Colors.blue[700],
        iconTheme: MaterialStateProperty.resolveWith((states) => IconThemeData(color: Colors.white)),
        labelTextStyle: MaterialStateProperty.resolveWith((states) => const TextStyle(color: Colors.white70)),
      ),
    ),
  };

  ThemeProvider() {
    _loadTheme();
  }

  ThemeData get currentThemeData => _currentThemeData;
  String get currentThemeName => _currentThemeName;
  Map<String, ThemeData> get availableThemes => _availableThemes;

  void setTheme(String themeName) {
    if (_availableThemes.containsKey(themeName)) {
      _currentThemeData = _availableThemes[themeName]!;
      _currentThemeName = themeName;
      _saveTheme(themeName);
      notifyListeners();
    }
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final savedThemeName = prefs.getString('selectedTheme') ?? 'light';
    setTheme(savedThemeName);
  }

  Future<void> _saveTheme(String themeName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedTheme', themeName);
  }
} 