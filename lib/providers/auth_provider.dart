import 'package:flutter/material.dart';

/// Provider for authentication state and operations
class AuthProvider extends ChangeNotifier {
  /// The current user's ID, or null if not logged in
  String? _userId;
  
  /// The current user's email, or null if not logged in
  String? _userEmail;
  
  /// Whether the user is currently logged in
  bool _isLoggedIn = false;
  
  /// Get the current user ID
  String? get userId => _userId;
  
  /// Get the current user email
  String? get userEmail => _userEmail;
  
  /// Check if the user is logged in
  bool get isLoggedIn => _isLoggedIn;

  /// Set the current user from login or signup
  void setUser(String userId, String email) {
    _userId = userId;
    _userEmail = email;
    _isLoggedIn = true;
    notifyListeners();
  }

  /// Clear the current user data on logout
  void clearUser() {
    _userId = null;
    _userEmail = null;
    _isLoggedIn = false;
    notifyListeners();
  }
} 