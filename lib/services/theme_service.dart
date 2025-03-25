import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class ThemeService {
  static const String _themeKey = 'theme_mode';
  
  // Get the current theme mode
  static Future<ThemeMode> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    // Default to light mode (index 1) instead of system (index 0)
    // This ensures we're always in a definite state - light or dark
    final themeIndex = prefs.getInt(_themeKey) ?? 1; 
    final mode = ThemeMode.values[themeIndex];
    debugPrint('ThemeService: Getting current theme mode: $mode');
    return mode;
  }
  
  // Save the current theme mode
  static Future<void> saveThemeMode(ThemeMode mode) async {
    debugPrint('ThemeService: Saving theme mode: $mode');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, mode.index);
    debugPrint('ThemeService: Theme mode saved: $mode');
  }
  
  // Toggle between light and dark theme
  static Future<ThemeMode> toggleTheme() async {
    debugPrint('ThemeService: toggleTheme called');
    final currentMode = await getThemeMode();
    final newMode = currentMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    debugPrint('ThemeService: Toggling from $currentMode to $newMode');
    await saveThemeMode(newMode);
    return newMode;
  }
  
  // Direct toggle - for more responsive UI when we already know the current theme
  static Future<void> directToggle(ThemeMode currentMode) async {
    debugPrint('ThemeService: directToggle called with $currentMode');
    final newMode = currentMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    await saveThemeMode(newMode);
    debugPrint('ThemeService: directToggle completed, new mode: $newMode');
  }
  
  // Light theme data
  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: const Color(0xFF5E6BF8),
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFF333333),
        elevation: 0,
      ),
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF5E6BF8),
        brightness: Brightness.light,
      ),
      cardTheme: const CardTheme(
        elevation: 2,
        shadowColor: Colors.black12,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF5E6BF8), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF5E6BF8),
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF5E6BF8),
          side: const BorderSide(color: Color(0xFF5E6BF8)),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF5E6BF8),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        ),
      ),
      textTheme: TextTheme(
        displayLarge: const TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Color(0xFF333333),
        ),
        displayMedium: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: Color(0xFF333333),
        ),
        displaySmall: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Color(0xFF333333),
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: Colors.grey.shade800,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: Colors.grey.shade800,
        ),
      ),
    );
  }
  
  // Dark theme data
  static ThemeData get darkTheme {
    return ThemeData(
      primaryColor: const Color(0xFF5E6BF8),
      scaffoldBackgroundColor: const Color(0xFF121212),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF5E6BF8),
        brightness: Brightness.dark,
        onSurface: Colors.white,
        onPrimary: Colors.white,
      ),
      cardTheme: const CardTheme(
        color: Color(0xFF1E1E1E),
        elevation: 2,
        shadowColor: Colors.black45,
      ),
      iconTheme: const IconThemeData(
        color: Colors.white,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2A2A2A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade800),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade800),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF5E6BF8), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF5E6BF8),
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF5E6BF8),
          side: const BorderSide(color: Color(0xFF5E6BF8)),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF5E6BF8),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        displaySmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: Colors.white70,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: Colors.white70,
        ),
      ),
    );
  }
} 