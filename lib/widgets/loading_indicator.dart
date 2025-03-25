import 'package:flutter/material.dart';

/// A loading indicator widget that displays a centered circular progress indicator
/// with customizable size and color
class LoadingIndicator extends StatelessWidget {
  /// Size of the loading indicator
  final double size;
  
  /// Color of the loading indicator (uses theme's primary color if not specified)
  final Color? color;
  
  /// Thickness of the loading indicator's stroke
  final double strokeWidth;
  
  /// Whether to center the indicator in its parent
  final bool centered;
  
  /// Whether to add padding around the indicator
  final bool withPadding;
  
  /// Create a loading indicator with customizable properties
  const LoadingIndicator({
    Key? key,
    this.size = 48.0,
    this.color,
    this.strokeWidth = 2.0,
    this.centered = true,
    this.withPadding = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final loadingIndicator = SizedBox(
      height: size,
      width: size,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
        valueColor: color != null 
            ? AlwaysStoppedAnimation<Color>(color!)
            : AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
      ),
    );
    
    Widget result = loadingIndicator;
    
    if (withPadding) {
      result = Padding(
        padding: const EdgeInsets.all(16.0),
        child: result,
      );
    }
    
    if (centered) {
      result = Center(child: result);
    }
    
    return result;
  }
} 