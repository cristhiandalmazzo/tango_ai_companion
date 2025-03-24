import 'package:flutter/material.dart';
import 'app_drawer.dart';
import 'custom_app_bar.dart';

class ScreenContainer extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final bool showDrawer;
  final bool isLoading;
  final bool centerTitle;
  final Widget? loadingWidget;
  final Widget? bottomNavigationBar;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final ThemeMode currentThemeMode;
  final Function(ThemeMode) onThemeChanged;

  const ScreenContainer({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.floatingActionButton,
    this.showDrawer = true,
    this.isLoading = false,
    this.centerTitle = true,
    this.loadingWidget,
    this.bottomNavigationBar,
    this.floatingActionButtonLocation,
    this.currentThemeMode = ThemeMode.light,
    required this.onThemeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: title,
        actions: actions,
        centerTitle: centerTitle,
      ),
      drawer: showDrawer 
          ? AppDrawer(
              currentThemeMode: currentThemeMode,
              onThemeChanged: onThemeChanged,
            ) 
          : null,
      body: isLoading
          ? Center(
              child: loadingWidget ??
                  const CircularProgressIndicator(),
            )
          : body,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      bottomNavigationBar: bottomNavigationBar,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    );
  }
} 