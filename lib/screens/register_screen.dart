import 'dart:math';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart'; // Make sure this package is added in pubspec.yaml
import 'package:flutter/services.dart'; // For Clipboard

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});
  
  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  // Create a UUID generator instance.
  final uuid = Uuid();

  /// Generates a 6-digit numeric relationship code.
  String generateRelationshipCode() {
    final random = Random();
    return List.generate(6, (index) => random.nextInt(10)).join();
  }

  /// Generates a UUID for the invitation token.
  String generateInvitationToken() {
    return uuid.v4();
  }

  /// Inserts a new relationship record into the Supabase "relationships" table.
  /// Returns the inserted record as a Map.
  Future<Map<String, dynamic>> createRelationship() async {
    final String relationshipCode = generateRelationshipCode();
    final String invitationToken = generateInvitationToken();
    final DateTime tokenExpiry = DateTime.now().add(const Duration(hours: 24));

    // Insert the new relationship record.
    final data = await Supabase.instance.client
        .from('relationships')
        .insert({
          'code': relationshipCode,
          'invitation_token': invitationToken,
          'token_expiry': tokenExpiry.toIso8601String(),
        })
        .select()
        .single();
    
    return data;
  }

  /// Constructs the invitation URL that Partner A can share.
  String getInvitationUrl(String code, String token) {
    // Update the URL below to match your app's invitation URL pattern.
    return "https://your-app-url/invite?code=$code&token=$token";
  }

Future<void> _signUp() async {
  setState(() => _isLoading = true);
  try {
    // Sign up the user using Supabase Auth.
    final response = await Supabase.instance.client.auth.signUp(
      email: _emailController.text,
      password: _passwordController.text,
    );

    // Debug: Check the response by printing the user
    print("SignUp user: ${response.user}");

    if (response.user != null) {
      // Once sign up is successful, create a relationship record.
      final relationshipRecord = await createRelationship();
      print("Created relationship: $relationshipRecord");

      if (relationshipRecord != null) {
        final String code = relationshipRecord['code'];
        final String token = relationshipRecord['invitation_token'];
        final String invitationUrl = getInvitationUrl(code, token);

        // Display the invitation URL in a dialog.
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Invitation URL'),
              content: SelectableText(invitationUrl),
              actions: [
                TextButton(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: invitationUrl));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Copied to clipboard!')),
                    );
                  },
                  child: const Text('Copy URL'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/login');
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign up initiated. Please check your email for confirmation.')),
      );
    }
  } catch (error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $error')),
    );
  } finally {
    setState(() => _isLoading = false);
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
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _signUp,
                    child: const Text('Sign Up'),
                  ),
          ],
        ),
      ),
    );
  }
}
