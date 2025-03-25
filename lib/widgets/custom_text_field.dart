import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hintText;
  final bool obscureText;
  final TextInputType keyboardType;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final int? maxLines;
  final int? maxLength;
  final bool autofocus;
  final Function(String)? onChanged;
  final Function(String)? onSubmitted;
  final FocusNode? focusNode;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hintText,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.prefixIcon,
    this.suffixIcon,
    this.validator,
    this.maxLines = 1,
    this.maxLength,
    this.autofocus = false,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        validator: validator,
        maxLines: maxLines,
        maxLength: maxLength,
        autofocus: autofocus,
        focusNode: focusNode,
        onChanged: onChanged,
        onFieldSubmitted: onSubmitted,
        style: TextStyle(
          color: isDarkMode ? Colors.white : Colors.black87,
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          labelStyle: TextStyle(
            color: controller.text.isNotEmpty ? theme.colorScheme.primary : (isDarkMode ? Colors.grey[300] : Colors.grey[700]),
          ),
          hintStyle: TextStyle(
            color: isDarkMode ? Colors.grey[400] : Colors.grey[500],
          ),
          prefixIcon: prefixIcon != null 
            ? prefixIcon 
            : null,
          suffixIcon: suffixIcon,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: theme.colorScheme.primary,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: isDarkMode ? Colors.grey[500]! : Colors.grey[300]!,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: theme.colorScheme.primary, 
              width: 2,
            ),
          ),
          filled: true,
          fillColor: isDarkMode ? Color.lerp(const Color(0xFF2A2A2A), theme.colorScheme.primary, 0.03) : Colors.grey.shade50,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }
} 