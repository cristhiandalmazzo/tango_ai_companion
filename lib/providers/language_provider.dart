import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    
    notifyListeners();
  }

  Future<void> toggleLanguage() async {
    if (_locale.languageCode == 'en') {
      await setLocale(const Locale('pt', 'BR'));
    } else {
      await setLocale(const Locale('en'));
    }
  }
} 