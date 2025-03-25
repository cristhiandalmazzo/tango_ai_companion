import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:developer' as developer;
import '../services/theme_service.dart';

class ThemeToggle extends StatefulWidget {
  final Function(ThemeMode) onThemeChanged;
  final ThemeMode currentThemeMode;

  const ThemeToggle({
    super.key,
    required this.onThemeChanged,
    required this.currentThemeMode,
  });

  @override
  State<ThemeToggle> createState() => _ThemeToggleState();
}

class _ThemeToggleState extends State<ThemeToggle> with SingleTickerProviderStateMixin {
  bool _isProcessing = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    debugPrint('ThemeToggle: initialized with theme ${widget.currentThemeMode}');
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Consider ThemeMode.system and ThemeMode.light as "light" for the toggle appearance
    final isDarkMode = widget.currentThemeMode == ThemeMode.dark;
    final isSystemOrLight = widget.currentThemeMode == ThemeMode.system || widget.currentThemeMode == ThemeMode.light;
    
    // Debug the current theme state
    debugPrint('ThemeToggle: Building with theme ${widget.currentThemeMode}, isDarkMode=$isDarkMode');
    
    return GestureDetector(
      onTapDown: (_) {
        debugPrint('ThemeToggle: TAP DOWN DETECTED');
        _animationController.forward();
        HapticFeedback.lightImpact();
      },
      onTapUp: (_) {
        _animationController.reverse();
        if (!_isProcessing) {
          debugPrint('ThemeToggle: TAP UP DETECTED - TOGGLING THEME');
          _toggleTheme();
        }
      },
      onTapCancel: () {
        debugPrint('ThemeToggle: TAP CANCELLED');
        _animationController.reverse();
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: 40, // Increased touch target size
          height: 40, 
          padding: const EdgeInsets.all(4.0),
          decoration: BoxDecoration(
            color: isDarkMode
                ? Colors.grey.shade800
                : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).shadowColor.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: _isProcessing
              ? Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: isDarkMode ? Colors.yellow.shade300 : Colors.blueGrey.shade700,
                    ),
                  ),
                )
              : Icon(
                  isDarkMode ? Icons.light_mode : Icons.dark_mode,
                  color: isDarkMode ? Colors.yellow.shade300 : Colors.blueGrey.shade700,
                  size: 24, // Larger icon
                ),
        ),
      ),
    );
  }

  Future<void> _toggleTheme() async {
    debugPrint('ThemeToggle: _toggleTheme called - current theme: ${widget.currentThemeMode}');
    
    if (_isProcessing) {
      debugPrint('ThemeToggle: Already processing, ignoring toggle');
      return;
    }
    
    setState(() {
      _isProcessing = true;
      debugPrint('ThemeToggle: Setting _isProcessing to true');
    });
    
    try {
      // Improved toggle logic to handle ThemeMode.system
      // If current mode is system or light, go to dark. Otherwise go to light.
      final ThemeMode newMode;
      if (widget.currentThemeMode == ThemeMode.dark) {
        newMode = ThemeMode.light;
      } else {
        // This handles both ThemeMode.light and ThemeMode.system
        newMode = ThemeMode.dark;
      }
          
      debugPrint('ThemeToggle: Changing theme from ${widget.currentThemeMode} to $newMode');
      
      // Notify parent about the change
      widget.onThemeChanged(newMode);
      
      debugPrint('ThemeToggle: Called onThemeChanged callback');
      
      // Then save the change to persist it
      await ThemeService.saveThemeMode(newMode);
      
      debugPrint('ThemeToggle: Saved theme to preferences');
    } catch (e) {
      debugPrint('ThemeToggle: Error toggling theme: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          debugPrint('ThemeToggle: Setting _isProcessing to false');
        });
      }
    }
  }
} 