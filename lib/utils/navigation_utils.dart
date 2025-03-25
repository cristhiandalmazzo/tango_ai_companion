import 'package:flutter/material.dart';

/// Utilities for standardizing navigation across the app
class NavigationUtils {
  /// Navigate to a new screen
  static void goTo(BuildContext context, String route, {Object? arguments}) {
    Navigator.pushNamed(context, route, arguments: arguments);
  }
  
  /// Replace the current screen with a new one
  static void replace(BuildContext context, String route, {Object? arguments}) {
    Navigator.pushReplacementNamed(context, route, arguments: arguments);
  }
  
  /// Go to a screen and clear the navigation stack
  static void goToAndClearStack(BuildContext context, String route, {Object? arguments}) {
    Navigator.pushNamedAndRemoveUntil(
      context, 
      route, 
      (route) => false,
      arguments: arguments,
    );
  }
  
  /// Navigate back to the previous screen
  static void goBack(BuildContext context, {dynamic result}) {
    Navigator.pop(context, result);
  }
  
  /// Navigate back to a specific route
  static void goBackToRoute(BuildContext context, String route) {
    Navigator.popUntil(context, ModalRoute.withName(route));
  }
  
  /// Navigate back a certain number of screens
  static void goBackSteps(BuildContext context, int steps) {
    int count = 0;
    Navigator.popUntil(context, (route) {
      return count++ >= steps;
    });
  }
} 