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
    
    return PopupMenuButton<Locale>(
      tooltip: l10n.changeLanguage,
      icon: isCompact 
          ? const Icon(Icons.language, size: 20)
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.language, size: 20),
                const SizedBox(width: 4),
                Text(
                  _getLanguageName(languageProvider.locale, l10n),
                  style: const TextStyle(fontSize: 14),
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
              Text(l10n.english),
              if (languageProvider.locale.languageCode == 'en')
                const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Icon(Icons.check, size: 18),
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
              Text(l10n.portuguese),
              if (languageProvider.locale.languageCode == 'pt')
                const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Icon(Icons.check, size: 18),
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