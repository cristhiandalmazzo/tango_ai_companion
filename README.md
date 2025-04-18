# Tango AI Companion

Tango is a relationship companion app that uses AI to help couples improve their communication, understanding, and connection.

## Features

- **AI-Powered Chat**: Get relationship advice and communication suggestions from an AI companion
- **Relationship Dashboard**: Track relationship metrics, add notes, and monitor progress
- **Partner Profiles**: Manage profiles for both partners with interests, personality traits, and more
- **Dark Mode Support**: Full light and dark theme implementations for comfortable viewing
- **Multi-language Support**: Localization ready for multiple languages

## Architecture

The app is built with Flutter and uses Supabase for backend services. Key architectural components include:

### Services

- **RelationshipService**: Manages relationship data and metrics
- **ProfileService**: Handles user profiles and partner data
- **StorageService**: Manages file storage, particularly profile pictures
- **EdgeFunctionsService**: Interfaces with Supabase Edge Functions for AI capabilities
- **TextProcessingService**: Standardizes text handling across the app

### Utilities

The app uses a standardized set of utilities to maintain consistency:

- **ThemeExtension**: Context extensions for theme properties
- **StyleConstants**: Consistent spacing, sizing, and style values
- **NavigationUtils**: Standardized navigation patterns
- **ErrorUtils**: Consistent error handling and logging
- **FormUtils**: Reusable form building components

### Screens

Major screens in the application include:

- **Home**: Main dashboard with quick access to features
- **Chat**: AI conversation interface
- **Relationship**: Relationship metrics and status management
- **Profile**: User profile management
- **Settings**: App configuration and preferences

## Getting Started

### Prerequisites

- Flutter SDK (2.10.0 or higher)
- Dart SDK (2.16.0 or higher)
- A Supabase project with appropriate setup

### Installation

1. Clone the repository
```bash
git clone https://github.com/yourusername/tango_ai_companion.git
cd tango_ai_companion
```

2. Install dependencies
```bash
flutter pub get
```

3. Create a `supabase_config.dart` file in the lib folder with your Supabase credentials
```dart
const String supabaseUrl = 'YOUR_SUPABASE_URL';
const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
```

4. Run the app
```bash
flutter run
```

## Development Principles

- **Consistent Code Patterns**: Using utilities for standardized implementations
- **Dark Mode First**: Ensuring all UI components work well in both light and dark themes
- **Error Handling**: Comprehensive error handling with user-friendly messages
- **Responsive Design**: Adapting layouts for different screen sizes
- **Localization Ready**: All user-facing strings support localization

## Contributing

Guidelines for contributing to the project:

1. Use the established utility classes for new features
2. Ensure proper error handling in all user interactions
3. Test both light and dark themes for new UI components
4. Keep screen components modular and under 300 lines when possible