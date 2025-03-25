import 'package:flutter/material.dart';

/// A container widget that applies consistent horizontal padding
/// to make the app content more centered on the screen.
class AppContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? additionalPadding;
  final Color? backgroundColor;
  
  /// Creates an AppContainer with consistent horizontal padding (10% on each side)
  ///
  /// [child] - The widget to be padded
  /// [additionalPadding] - Optional additional padding to apply
  /// [backgroundColor] - Optional background color for the container
  const AppContainer({
    super.key,
    required this.child,
    this.additionalPadding,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate 10% of screen width for horizontal padding
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth * 0.2;
    
    return Container(
      color: backgroundColor,
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding).add(
        additionalPadding ?? EdgeInsets.zero
      ),
      child: child,
    );
  }
} 