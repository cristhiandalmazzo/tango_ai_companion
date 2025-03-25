import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../providers/language_provider.dart';

class LanguageSelector extends StatelessWidget {
  final bool isCompact;
  
  const LanguageSelector({
    super.key,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final l10n = AppLocalizations.of(context)!;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return PopupMenuButton<Locale>(
      tooltip: l10n.changeLanguage,
      color: Theme.of(context).scaffoldBackgroundColor,
      icon: isCompact 
          ? Icon(
              Icons.language, 
              size: 20,
              color: isDarkMode ? Colors.white : null,
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.language, 
                  size: 20,
                  color: isDarkMode ? Colors.white : null,
                ),
                const SizedBox(width: 4),
                Text(
                  _getLanguageName(languageProvider.locale, l10n),
                  style: TextStyle(
                    fontSize: 14,
                    color: isDarkMode ? Colors.white : null,
                  ),
                ),
              ],
            ),
      onSelected: (Locale locale) {
        languageProvider.setLocale(locale);
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<Locale>>[
        PopupMenuItem<Locale>(
          value: const Locale('en'),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                margin: const EdgeInsets.only(right: 8),
                child: const Text("🇺🇸", style: TextStyle(fontSize: 18)),
              ),
              Text(
                l10n.english,
                style: TextStyle(
                  color: isDarkMode ? Colors.white : null,
                ),
              ),
              if (languageProvider.locale.languageCode == 'en')
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Icon(
                    Icons.check, 
                    size: 18,
                    color: isDarkMode ? Colors.white : null,
                  ),
                ),
            ],
          ),
        ),
        PopupMenuItem<Locale>(
          value: const Locale('pt', 'BR'),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                margin: const EdgeInsets.only(right: 8),
                child: const Text("🇧🇷", style: TextStyle(fontSize: 18)),
              ),
              Text(
                l10n.portuguese,
                style: TextStyle(
                  color: isDarkMode ? Colors.white : null,
                ),
              ),
              if (languageProvider.locale.languageCode == 'pt')
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Icon(
                    Icons.check, 
                    size: 18,
                    color: isDarkMode ? Colors.white : null,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
  
  String _getLanguageName(Locale locale, AppLocalizations l10n) {
    if (locale.languageCode == 'pt') {
      return l10n.portuguese.split(' ').first; // Just "Português"
    }
    return l10n.english;
  }
} 