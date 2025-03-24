import 'package:flutter/material.dart';
import '../services/theme_service.dart';

class ThemeToggle extends StatelessWidget {
  final Function(ThemeMode) onThemeChanged;
  final ThemeMode currentThemeMode;

  const ThemeToggle({
    super.key,
    required this.onThemeChanged,
    required this.currentThemeMode,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = currentThemeMode == ThemeMode.dark;
    
    return GestureDetector(
      onTap: _toggleTheme,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDarkMode 
              ? Colors.grey.shade800
              : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(
          isDarkMode ? Icons.light_mode : Icons.dark_mode,
          color: isDarkMode ? Colors.yellow : Colors.blueGrey,
          size: 20,
        ),
      ),
    );
  }

  Future<void> _toggleTheme() async {
    final newMode = await ThemeService.toggleTheme();
    onThemeChanged(newMode);
  }
} 