import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:relationship_mediator/screens/chat_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/user_profile_view_screen.dart';
import 'screens/relationship_screen.dart';
import 'screens/partner_profile_screen.dart';
import 'screens/settings_screen.dart';
import 'supabase_config.dart';
import 'services/theme_service.dart';
import 'services/text_processing_service.dart';
import 'providers/language_provider.dart';
import 'widgets/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // For web: clean URL strategy (no hash)
  if (kIsWeb) {
    setUrlStrategy(PathUrlStrategy());
  }

  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  if (kDebugMode) {
    print("Supabase initialized successfully.");
  }

  runApp(
    ChangeNotifierProvider(
      create: (_) => LanguageProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // Start with a definite state (light) rather than relying on system default
  ThemeMode _themeMode = ThemeMode.light;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final themeMode = await ThemeService.getThemeMode();
    debugPrint('MyApp: Loaded theme from storage: $themeMode');
    setState(() {
      _themeMode = themeMode;
      debugPrint('MyApp: Set initial theme to $_themeMode');
    });
  }

  void _changeTheme(ThemeMode mode) {
    debugPrint('MyApp: _changeTheme called with mode: $mode');
    debugPrint('MyApp: Current mode before change: $_themeMode');
    
    setState(() {
      _themeMode = mode;
      debugPrint('MyApp: Theme changed to $_themeMode');
    });
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    
    // Sync app language with user profile when user is logged in
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      // Use Future.microtask to avoid calling setState during build
      Future.microtask(() => languageProvider.syncWithUserProfile());
    }
    
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Tango AI Companion',
      
      // Localization support
      locale: languageProvider.locale,
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'), // English
        Locale('pt', 'BR'), // Brazilian Portuguese
      ],
      
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      darkTheme: ThemeData.dark(useMaterial3: true).copyWith(
        scaffoldBackgroundColor: const Color(0xFF212121), // Softer gray background
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
          surface: const Color(0xFF2C2C2C), // Softer gray for surfaces
          background: const Color(0xFF212121), // Softer gray for background
          onBackground: Colors.white,
          onSurface: Colors.white,
        ),
        cardColor: const Color(0xFF2C2C2C), // Softer gray for cards
        // Ensure text has good contrast against dark backgrounds
        textTheme: const TextTheme(
          displayLarge: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
          displayMedium: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
          displaySmall: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          headlineMedium: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
          bodyLarge: TextStyle(color: Colors.white, fontSize: 16),
          bodyMedium: TextStyle(color: Colors.white70, fontSize: 14),
          bodySmall: TextStyle(color: Colors.white60, fontSize: 12),
        ),
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
      ),
      themeMode: _themeMode,
      home: SplashScreen(
        duration: const Duration(seconds: 2),
        nextScreen: FutureBuilder(
          future: _initializeApp(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }
            return const LoginScreen();
          },
        ),
      ),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => HomeScreen(
          currentThemeMode: _themeMode,
          onThemeChanged: _changeTheme,
        ),
        '/profile': (context) => UserProfileViewScreen(
          currentThemeMode: _themeMode,
          onThemeChanged: _changeTheme,
        ),
        '/edit_profile': (context) => ProfileScreen(
          currentThemeMode: _themeMode,
          onThemeChanged: _changeTheme,
        ),
        '/ai_chat': (context) => ChatScreen(
          currentThemeMode: _themeMode,
          onThemeChanged: _changeTheme,
        ),
        '/relationship': (context) => RelationshipScreen(
          currentThemeMode: _themeMode,
          onThemeChanged: _changeTheme,
        ),
        '/partner_profile': (context) => PartnerProfileScreen(
          currentThemeMode: _themeMode,
          onThemeChanged: _changeTheme,
        ),
        '/settings': (context) => SettingsScreen(
          currentThemeMode: _themeMode,
          onThemeChanged: _changeTheme,
        ),
      },
      // Use onGenerateRoute to handle dynamic routes.
      onGenerateRoute: (settings) {
        if (kDebugMode) {
          print("Processing route: ${settings.name}");
        }

        // Handle the signup route with relationshipId
        // Check for multiple possible URL patterns
        if (settings.name!.contains('signup')) {
          if (kDebugMode) {
            print("Found signup in route: ${settings.name}");
          }
          
          // Try to extract the relationshipId parameter from different formats
          String? relationshipId;
          
          try {
            final uri = Uri.parse(settings.name!);
            relationshipId = uri.queryParameters['relationshipId'];
            
            if (kDebugMode) {
              print("Query parameters: ${uri.queryParameters}");
              print("Extracted relationshipId from query: $relationshipId");
            }
            
            // If relationship ID is null, try to check if it's in the path segments
            if (relationshipId == null && uri.pathSegments.length > 1) {
              final lastSegment = uri.pathSegments.last;
              if (lastSegment != 'signup' && lastSegment.length > 8) {
                relationshipId = lastSegment;
                if (kDebugMode) {
                  print("Extracted relationshipId from path: $relationshipId");
                }
              }
            }
          } catch (e) {
            if (kDebugMode) {
              print("Error parsing URL: $e");
            }
          }
          
          return MaterialPageRoute(
            builder: (context) => SignUpScreen(
              relationshipId: relationshipId,
              currentThemeMode: _themeMode,
              onThemeChanged: _changeTheme,
            ),
          );
        }

        // Default route: if no route specified, go to LoginScreen.
        if (settings.name == '/') {
          return MaterialPageRoute(builder: (context) => const LoginScreen());
        }
        
        // Fallback to LoginScreen for unknown routes.
        return MaterialPageRoute(builder: (context) => const LoginScreen());
      },
    );
  }

  Future<void> _initializeApp() async {
    // Remove duplicate Supabase initialization
    // Supabase is already initialized in the main() function
    // This was causing the "This instance is already initialized" error
    debugPrint('_initializeApp: Initialization complete');
  }
}
