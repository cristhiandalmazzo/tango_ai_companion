import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ErrorView extends StatelessWidget {
  final String errorMessage;
  final VoidCallback onRetry;
  final String? retryText;
  final IconData icon;
  final double iconSize;

  const ErrorView({
    super.key,
    required this.errorMessage,
    required this.onRetry,
    this.retryText,
    this.icon = Icons.error_outline,
    this.iconSize = 80,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isDarkMode ? Colors.red.shade300 : Colors.red,
              size: iconSize,
            ),
            const SizedBox(height: 20),
            Text(
              l10n.error,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: onRetry,
              child: Text(retryText ?? l10n.retry),
            ),
          ],
        ),
      ),
    );
  }
} 