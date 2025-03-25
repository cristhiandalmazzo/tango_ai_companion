import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LanguageProvider extends ChangeNotifier {
  Locale _locale = const Locale('en');
  final String _prefsKey = 'language_code';

  Locale get locale => _locale;

  LanguageProvider() {
    _loadSavedLanguage();
  }

  Future<void> _loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLanguageCode = prefs.getString(_prefsKey);
    if (savedLanguageCode != null) {
      if (savedLanguageCode == 'pt_BR') {
        _locale = const Locale('pt', 'BR');
      } else {
        _locale = Locale(savedLanguageCode);
      }
      notifyListeners();
    }
  }

  Future<void> setLocale(Locale locale) async {
    if (_locale == locale) return;
    
    _locale = locale;
    
    final prefs = await SharedPreferences.getInstance();
    if (locale.countryCode != null) {
      await prefs.setString(_prefsKey, '${locale.languageCode}_${locale.countryCode}');
    } else {
      await prefs.setString(_prefsKey, locale.languageCode);
    }
    
    // Update user profile in the database when language is changed
    await _updateUserProfileLanguage();
    
    notifyListeners();
  }

  Future<void> _updateUserProfileLanguage() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return; // User not logged in
      
      // Convert locale to database format
      String languageCode = _locale.languageCode;
      if (_locale.languageCode == 'pt' && _locale.countryCode == 'BR') {
        languageCode = 'pt';
      }
      
      // Update the profile
      await Supabase.instance.client
          .from('profiles')
          .update({
            'language_preference': languageCode,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', user.id);
          
      debugPrint('Updated user profile language to $languageCode');
    } catch (e) {
      debugPrint('Failed to update user profile language: $e');
    }
  }

  Future<void> toggleLanguage() async {
    if (_locale.languageCode == 'en') {
      await setLocale(const Locale('pt', 'BR'));
    } else {
      await setLocale(const Locale('en'));
    }
  }
  
  // New method to sync app language with user profile
  Future<void> syncWithUserProfile() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return; // User not logged in
      
      // Fetch current profile
      final response = await Supabase.instance.client
          .from('profiles')
          .select('language_preference')
          .eq('id', user.id)
          .maybeSingle();
          
      if (response == null) return;
      
      final String? langPref = response['language_preference'];
      if (langPref == null) return;
      
      // Set locale based on profile preference
      if (langPref == 'pt') {
        await setLocale(const Locale('pt', 'BR'));
      } else if (langPref == 'en') {
        await setLocale(const Locale('en'));
      }
    } catch (e) {
      debugPrint('Failed to sync app language with user profile: $e');
    }
  }
} 