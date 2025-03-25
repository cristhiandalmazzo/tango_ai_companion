import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../widgets/error_view.dart';

/// Utilities for standardizing error handling across the app
class ErrorUtils {
  /// Log an error with context
  static void logError(String context, dynamic error, [StackTrace? stackTrace]) {
    debugPrint('Error in $context: $error');
    if (stackTrace != null) {
      debugPrint('Stack trace: $stackTrace');
    }
  }
  
  /// Get a user-friendly error message based on the error type
  static String getUserFriendlyMessage(dynamic error) {
    final message = error.toString().toLowerCase();
    
    if (message.contains('connection') || message.contains('network') || 
        message.contains('socket') || message.contains('timeout')) {
      return 'Connection error. Please check your internet connection and try again.';
    }
    
    if (message.contains('authentication') || message.contains('auth') || 
        message.contains('login') || message.contains('unauthorized')) {
      return 'Authentication error. Please log in again.';
    }
    
    if (message.contains('permission') || message.contains('access denied')) {
      return 'Permission denied. You don\'t have access to this feature.';
    }
    
    if (message.contains('not found')) {
      return 'The requested resource was not found. Please try again.';
    }
    
    if (message.contains('timeout')) {
      return 'The operation timed out. Please try again.';
    }
    
    // Default message
    return 'An unexpected error occurred. Please try again.';
  }
  
  /// Show a snackbar with an error message
  static void showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }
  
  /// Build an error widget for use in UI
  static Widget buildErrorWidget({
    required BuildContext context,
    required String errorMessage,
    required VoidCallback onRetry,
    String? retryText,
    IconData icon = Icons.error_outline,
  }) {
    return ErrorView(
      errorMessage: errorMessage,
      onRetry: onRetry,
      retryText: retryText,
      icon: icon,
    );
  }
  
  /// Handle an error and return appropriate UI
  static Widget handleError({
    required BuildContext context,
    required dynamic error,
    required VoidCallback onRetry,
    String? customMessage,
    String? retryText,
  }) {
    final message = customMessage ?? getUserFriendlyMessage(error);
    return buildErrorWidget(
      context: context,
      errorMessage: message,
      onRetry: onRetry,
      retryText: retryText,
    );
  }
} 