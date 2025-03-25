# Utility Libraries

This directory contains utility classes that help standardize patterns across the app.

## Theme Extension

The `ThemeExtension` provides easy access to theme properties:

```dart
import '../extensions/theme_extension.dart';

// Instead of:
final theme = Theme.of(context);
final isDarkMode = theme.brightness == Brightness.dark;
final primaryColor = theme.colorScheme.primary;

// Use:
final isDarkMode = context.isDarkMode;
final primaryColor = context.primaryColor;
final backgroundColor = context.darkBackgroundWithTint;
```

## Style Constants

Use `StyleConstants` for consistent spacing, sizing, and other style values:

```dart
import '../utils/style_constants.dart';

// Instead of:
const padding = EdgeInsets.all(16.0);
const borderRadius = 12.0;

// Use:
const padding = EdgeInsets.all(StyleConstants.spacingM);
const borderRadius = StyleConstants.radiusM;
```

## Navigation Utilities

Use `NavigationUtils` for standardized navigation:

```dart
import '../utils/navigation_utils.dart';

// Instead of:
Navigator.pushReplacementNamed(context, '/profile');

// Use:
NavigationUtils.replace(context, '/profile');
```

## Form Utilities

Use `FormUtils` for standardized form building:

```dart
import '../utils/form_utils.dart';

// Instead of custom email fields:
CustomTextField(
  controller: _emailController,
  label: 'Email',
  keyboardType: TextInputType.emailAddress,
  prefixIcon: Icon(Icons.email),
)

// Use:
FormUtils.buildEmailField(
  context: context,
  controller: _emailController,
  label: 'Email',
)

// For entire forms:
FormUtils.buildFormLayout(
  context: context,
  fields: [
    FormUtils.buildEmailField(...),
    FormUtils.buildPasswordField(...),
  ],
  buttonText: 'Login',
  onSubmit: _handleLogin,
  isLoading: _isLoading,
)
```

## Error Utilities

Use `ErrorUtils` for standardized error handling:

```dart
import '../utils/error_utils.dart';

// For logging:
ErrorUtils.logError('ProfileScreen', error);

// For snackbars:
ErrorUtils.showErrorSnackBar(context, 'Failed to load profile');

// For error widgets:
return ErrorUtils.handleError(
  context: context,
  error: error,
  onRetry: _loadData,
);
```

## Example Implementation

Here's an example of how to use these utilities together:

```dart
import 'package:flutter/material.dart';
import '../extensions/theme_extension.dart';
import '../utils/navigation_utils.dart';
import '../utils/form_utils.dart';
import '../utils/error_utils.dart';
import '../utils/style_constants.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/app_container.dart';

class ExampleScreen extends StatefulWidget {
  @override
  _ExampleScreenState createState() => _ExampleScreenState();
}

class _ExampleScreenState extends State<ExampleScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  dynamic _error;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.darkBackgroundWithTint,
      appBar: AppBar(title: Text('Example')),
      body: _buildBody(),
    );
  }
  
  Widget _buildBody() {
    if (_isLoading) {
      return LoadingIndicator(
        size: StyleConstants.avatarSizeLarge,
      );
    }
    
    if (_error != null) {
      return ErrorUtils.handleError(
        context: context,
        error: _error,
        onRetry: _loadData,
      );
    }
    
    return AppContainer(
      child: FormUtils.buildFormLayout(
        context: context,
        fields: [
          FormUtils.buildEmailField(
            context: context,
            controller: _emailController,
            label: 'Email',
          ),
          FormUtils.buildPasswordField(
            context: context,
            controller: _passwordController,
            label: 'Password',
          ),
        ],
        buttonText: 'Submit',
        onSubmit: _handleSubmit,
        isLoading: _isLoading,
      ),
    );
  }
  
  void _loadData() {
    // Example implementation
  }
  
  void _handleSubmit() {
    try {
      // Form submission logic
    } catch (e) {
      ErrorUtils.logError('ExampleScreen', e);
      ErrorUtils.showErrorSnackBar(
        context, 
        ErrorUtils.getUserFriendlyMessage(e),
      );
    }
  }
} 