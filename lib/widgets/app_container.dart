import 'package:flutter/material.dart';

/// A container widget that applies consistent horizontal padding
/// to make the app content more centered on the screen.
class AppContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? additionalPadding;
  final Color? backgroundColor;
  final double maxWidth;
  
  /// Creates an AppContainer with consistent horizontal padding
  ///
  /// [child] - The widget to be padded
  /// [additionalPadding] - Optional additional padding to apply
  /// [backgroundColor] - Optional background color for the container
  /// [maxWidth] - Maximum width of the container (defaults to 800)
  const AppContainer({
    super.key,
    required this.child,
    this.additionalPadding,
    this.backgroundColor,
    this.maxWidth = 800,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate responsive padding based on screen width
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth > 600 
        ? 24.0 // Larger padding for web/tablet
        : 16.0; // Smaller padding for mobile
    
    return Center(
      child: Container(
        color: backgroundColor,
        width: double.infinity,
        constraints: BoxConstraints(
          maxWidth: maxWidth,
        ),
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding).add(
          additionalPadding ?? EdgeInsets.zero
        ),
        child: child,
      ),
    );
  }
} 