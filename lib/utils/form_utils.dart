import 'package:flutter/material.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';
import '../extensions/theme_extension.dart';

/// Utilities for standardizing form building across the app
class FormUtils {
  /// Build a standardized form layout with fields and a submit button
  static Widget buildFormLayout({
    required BuildContext context,
    required List<Widget> fields,
    required String buttonText,
    required VoidCallback onSubmit,
    bool isLoading = false,
    IconData? buttonIcon,
    double spacing = 16.0,
    double buttonSpacing = 24.0,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...fields.expand((field) => [field, SizedBox(height: spacing)]).toList()
          ..removeLast(), // Remove the last spacer
        SizedBox(height: buttonSpacing),
        CustomButton(
          text: buttonText,
          onPressed: onSubmit,
          isLoading: isLoading,
          icon: buttonIcon,
          backgroundColor: context.primaryColor,
          textColor: context.theme.colorScheme.onPrimary,
        ),
      ],
    );
  }
  
  /// Build a standardized email field
  static CustomTextField buildEmailField({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
    String? hintText,
    String? Function(String?)? validator,
    Function(String)? onChanged,
  }) {
    return CustomTextField(
      controller: controller,
      label: label,
      hintText: hintText,
      keyboardType: TextInputType.emailAddress,
      prefixIcon: Icon(Icons.email_outlined, color: context.primaryColor),
      validator: validator,
      onChanged: onChanged,
    );
  }
  
  /// Build a standardized password field
  static CustomTextField buildPasswordField({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
    String? hintText,
    String? Function(String?)? validator,
    Function(String)? onChanged,
    bool obscureText = true,
  }) {
    return CustomTextField(
      controller: controller,
      label: label,
      hintText: hintText,
      obscureText: obscureText,
      prefixIcon: Icon(Icons.lock_outline, color: context.primaryColor),
      validator: validator,
      onChanged: onChanged,
    );
  }
  
  /// Build a standardized text field
  static CustomTextField buildTextField({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
    String? hintText,
    IconData? prefixIcon,
    String? Function(String?)? validator,
    Function(String)? onChanged,
    TextInputType keyboardType = TextInputType.text,
    int? maxLines = 1,
  }) {
    return CustomTextField(
      controller: controller,
      label: label,
      hintText: hintText,
      keyboardType: keyboardType,
      prefixIcon: prefixIcon != null 
          ? Icon(prefixIcon, color: context.primaryColor)
          : null,
      validator: validator,
      onChanged: onChanged,
      maxLines: maxLines,
    );
  }
} 