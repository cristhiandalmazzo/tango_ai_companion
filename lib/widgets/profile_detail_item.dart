import 'package:flutter/material.dart';

class ProfileDetailItem extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final int maxLines;
  final bool useCard;
  
  const ProfileDetailItem({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.maxLines = 2,
    this.useCard = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    final content = Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: theme.colorScheme.primary,
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDarkMode 
                        ? theme.colorScheme.primary 
                        : theme.colorScheme.primary.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                  maxLines: maxLines,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
    
    if (useCard) {
      return Card(
        elevation: 1,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        color: isDarkMode 
            ? theme.cardColor 
            : theme.cardColor.withOpacity(0.95),
        child: content,
      );
    }
    
    return content;
  }
} 