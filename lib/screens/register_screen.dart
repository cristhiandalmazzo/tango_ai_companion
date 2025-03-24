import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'home_screen.dart';

class SignUpScreen extends StatefulWidget {
  final String? relationshipId;
  const SignUpScreen({super.key, this.relationshipId});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

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

      // Create the user's profile.
      await Supabase.instance.client.from('profiles').insert({
        'id': userId,
        'name': name,
        'email': email,
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
        final String inviteUrl = "${kReleaseMode ? 'https://tangoapp.com' : 'http://localhost:49651'}/signup?relationshipId=$relationshipId";
        
        // Show the invite URL dialog with a "Copy URL" button and a "Close" button.
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Invite your partner"),
            content: SelectableText(inviteUrl),
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
          MaterialPageRoute(builder: (_) => const HomeScreen()),
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign Up')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _signUp,
              child: const Text('Sign Up'),
            ),
            TextButton(
              onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
              child: const Text("Already have an account? Log in"),
            ),
          ],
        ),
      ),
    );
  }
}
