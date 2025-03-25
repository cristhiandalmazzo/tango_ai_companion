import 'package:flutter/material.dart';

/// Style constants to maintain consistent styling across the app
class StyleConstants {
  // Spacing
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXL = 32.0;
  
  // Radii
  static const double radiusS = 8.0;
  static const double radiusM = 12.0;
  static const double radiusL = 16.0;
  static const double radiusXL = 24.0;
  
  // Avatar sizes
  static const double avatarSizeSmall = 32.0;
  static const double avatarSizeMedium = 48.0;
  static const double avatarSizeLarge = 60.0;
  
  // Font sizes
  static const double fontSizeXS = 12.0;
  static const double fontSizeS = 14.0;
  static const double fontSizeM = 16.0;
  static const double fontSizeL = 20.0;
  static const double fontSizeXL = 24.0;
  static const double fontSizeXXL = 32.0;
  
  // Theme tint values
  static const double darkBackgroundTint = 0.03;
  static const double darkCardTint = 0.05;
  
  // Animation durations
  static const Duration animationShort = Duration(milliseconds: 150);
  static const Duration animationMedium = Duration(milliseconds: 300);
  static const Duration animationLong = Duration(milliseconds: 500);
  
  // Colors - should ideally come from the theme, but useful for consistent references
  static const Color primaryColor = Color(0xFF5E6BF8);
  static const Color errorColor = Color(0xFFE53935);
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF2C2C2C);
} 