import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:relationship_mediator/screens/chat_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart'; // SignUpScreen is in register_screen.dart
import 'screens/home_screen.dart';
import 'screens/profile_screen.dart';
import 'supabase_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // For web: clean URL strategy (no hash)
  if (kIsWeb) {
    setUrlStrategy(PathUrlStrategy());
  }

  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Tango',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/ai_chat': (context) => const ChatScreen(),
      },
      // Use onGenerateRoute to handle dynamic routes.
      onGenerateRoute: (settings) {
        // Default route: if no route specified, go to LoginScreen.
        if (settings.name == '/') {
          return MaterialPageRoute(builder: (context) => const LoginScreen());
        }
        // Handle the signup route with relationshipId
        if (settings.name!.startsWith('/signup')) {
          // Parse the URL to extract the relationshipId query parameter.
          final uri = Uri.parse(settings.name!);
          final relationshipId = uri.queryParameters['relationshipId'];
          if (kDebugMode) {
            print("Handling URL: ${settings.name}");
            print("Extracted relationshipId: $relationshipId");
          }
          return MaterialPageRoute(
              builder: (context) => SignUpScreen(relationshipId: relationshipId));
        }
        // Fallback to LoginScreen for unknown routes.
        return MaterialPageRoute(builder: (context) => const LoginScreen());
      },
    );
  }
}
