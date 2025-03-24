import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'home_screen.dart';
import 'package:uuid/uuid.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';

class SignUpScreen extends StatefulWidget {
  final String? relationshipId;
  final ThemeMode currentThemeMode;
  final Function(ThemeMode) onThemeChanged;
  
  const SignUpScreen({
    super.key, 
    this.relationshipId,
    this.currentThemeMode = ThemeMode.light,
    required this.onThemeChanged,
  });

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  bool _isLoading = false;

  // This variable holds the relationshipId extracted from the URL (if any)
  String? relationshipIdFromUrl;

  @override
  void initState() {
    super.initState();
    // Use the relationshipId passed to the widget (if any)
    relationshipIdFromUrl = widget.relationshipId;
    if (kDebugMode) {
      print("Handling URL: ${Uri.base.toString()}");
      print("Extracted relationshipId: $relationshipIdFromUrl");
    }
  }

  /// Updates the user's profile with the relationship id.
  Future<void> _updateUserProfileWithRelationship(String userId, String relationshipId) async {
    final response = await Supabase.instance.client
        .from('profiles')
        .update({'relationship_id': relationshipId})
        .eq('id', userId)
        .select()
        .maybeSingle();

    if (response != null) {
      if (kDebugMode) {
        print("Updated profile with relationship id: $relationshipId for user: $userId");
      }
    } else {
      if (kDebugMode) {
        print("Failed to update profile with relationship id for user: $userId");
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to update profile with relationship information.")),
      );
    }
  }

  /// Handles sign up.
  Future<void> _signUp() async {
    setState(() => _isLoading = true);

    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();
    final String name = _nameController.text.trim();

    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
      );
      final user = response.user;
      if (user == null) return;
      final String userId = user.id;

      final conversationId = const Uuid().v4();

      // Create the user's profile.
      await Supabase.instance.client.from('profiles').insert({
        'id': userId,
        'name': name,
        'email': email,
        'conversation_id': conversationId,
      });

      if (kDebugMode) {
        print("Profile created successfully for user: $userId");
      }

      // Handle relationship linking.
      if (relationshipIdFromUrl != null) {
        // This is Partner B. Find the existing relationship and update partner_b.
        final relationship = await Supabase.instance.client
            .from('relationships')
            .select()
            .eq('id', relationshipIdFromUrl!) // Assert non-null.
            .maybeSingle();

        if (relationship != null) {
          await Supabase.instance.client
              .from('relationships')
              .update({'partner_b': userId})
              .eq('id', relationshipIdFromUrl!);
          if (kDebugMode) {
            print("Updated relationship $relationshipIdFromUrl with partner_b: $userId");
          }
          await _updateUserProfileWithRelationship(userId, relationshipIdFromUrl!);
        } else {
          if (kDebugMode) {
            print("Invalid relationship ID: $relationshipIdFromUrl");
          }
        }
      } else {
        // This is Partner A. Create a new relationship record with partner_a.
        final newRelationship = await Supabase.instance.client
            .from('relationships')
            .insert({'partner_a': userId})
            .select()
            .single();

        if (kDebugMode) {
          print("Created relationship: $newRelationship");
        }

        final String relationshipId = newRelationship['id'] as String;
        await _updateUserProfileWithRelationship(userId, relationshipId);

        // Generate the invitation URL using the relationship id.
        final String inviteUrl = "${kReleaseMode ? 'https://tangoapp.com' : 'http://localhost:49879'}/signup?relationshipId=$relationshipId";
        
        // Show the invite URL dialog with a "Copy URL" button and a "Close" button.
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Invite your partner"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Share this link with your partner to join:"),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SelectableText(
                    inviteUrl,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: inviteUrl));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Invitation URL copied to clipboard.")),
                  );
                },
                child: const Text("Copy URL"),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("Close"),
              )
            ],
          ),
        );
      }

      // Redirect to HomeScreen after processing.
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => HomeScreen(
            currentThemeMode: widget.currentThemeMode,
            onThemeChanged: widget.onThemeChanged,
          )),
        );
      }
    } on AuthException catch (e) {
      if (kDebugMode) {
        print("AuthException: ${e.message}");
      }
      // Show a simple snackbar for email already registered.
      if (e.message.toLowerCase().contains("user already registered")) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Email already registered.")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${e.message}")),
        );
      }
    } catch (error) {
      if (kDebugMode) {
        print("Unhandled error: $error");
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $error")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              _buildHeader(),
              const SizedBox(height: 40),
              _buildRegisterForm(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          height: 80,
          width: 80,
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.person_add,
            size: 40,
            color: Theme.of(context).primaryColor,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Create an Account',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          relationshipIdFromUrl != null 
              ? 'Join your partner\'s relationship'
              : 'Get started with Tango',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildRegisterForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CustomTextField(
          controller: _nameController,
          label: 'Full Name',
          hintText: 'Enter your full name',
          prefixIcon: const Icon(Icons.person_outline),
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _emailController,
          label: 'Email',
          hintText: 'Enter your email',
          keyboardType: TextInputType.emailAddress,
          prefixIcon: const Icon(Icons.email_outlined),
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _passwordController,
          label: 'Password',
          hintText: 'Create a password',
          obscureText: true,
          prefixIcon: const Icon(Icons.lock_outline),
        ),
        const SizedBox(height: 32),
        CustomButton(
          text: 'Sign Up',
          onPressed: _signUp,
          isLoading: _isLoading,
          icon: Icons.arrow_forward,
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Already have an account?",
              style: TextStyle(color: Colors.grey.shade700),
            ),
            TextButton(
              onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
              child: Text(
                "Log in",
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
