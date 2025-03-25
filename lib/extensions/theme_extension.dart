import 'package:flutter/material.dart';

/// Extension on BuildContext to provide easy access to theme properties
extension ThemeExtension on BuildContext {
  /// Get the current theme
  ThemeData get theme => Theme.of(this);
  
  /// Check if dark mode is active
  bool get isDarkMode => theme.brightness == Brightness.dark;
  
  /// Get the primary color from the theme
  Color get primaryColor => theme.colorScheme.primary;
  
  /// Get a background color with a subtle primary tint for dark mode
  Color get darkBackgroundWithTint => isDarkMode
      ? Color.lerp(const Color(0xFF121212), theme.colorScheme.primary, 0.03)!
      : theme.scaffoldBackgroundColor;
  
  /// Get the appropriate text color based on theme
  Color get textPrimaryColor => isDarkMode ? Colors.white : Colors.black87;
  
  /// Get the secondary text color based on theme
  Color get textSecondaryColor => isDarkMode 
      ? Colors.white70 
      : Colors.grey.shade700;
      
  /// Get a card background color with primary tint for dark mode
  Color get cardBackgroundColor => isDarkMode
      ? Color.lerp(const Color(0xFF2C2C2C), theme.colorScheme.primary, 0.05)!
      : theme.cardTheme.color ?? Colors.white;
} 