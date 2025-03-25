import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool centerTitle;
  final Color? backgroundColor;
  final bool automaticallyImplyLeading;
  final double elevation;
  final Widget? flexibleSpace;

  const CustomAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.centerTitle = true,
    this.backgroundColor,
    this.automaticallyImplyLeading = true,
    this.elevation = 0.5,
    this.flexibleSpace,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return AppBar(
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      centerTitle: centerTitle,
      actions: actions,
      leading: leading,
      backgroundColor: backgroundColor ?? Theme.of(context).scaffoldBackgroundColor,
      automaticallyImplyLeading: automaticallyImplyLeading,
      elevation: elevation,
      shadowColor: Colors.black.withOpacity(0.1),
      flexibleSpace: flexibleSpace,
      iconTheme: IconThemeData(
        color: isDarkMode ? Colors.white : Theme.of(context).primaryColor
      ),
      titleTextStyle: TextStyle(
        color: Theme.of(context).textTheme.bodyLarge?.color,
        fontWeight: FontWeight.bold,
        fontSize: 20,
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
} 