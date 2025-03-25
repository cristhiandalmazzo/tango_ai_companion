import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'home_screen.dart';
import 'package:uuid/uuid.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';
import '../widgets/app_container.dart';
import '../widgets/language_selector.dart';

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
            .insert({
              'partner_a': userId,
              'active': true,
              'status': 'undefined'
            })
            .select()
            .single();

        if (kDebugMode) {
          print("Created relationship: $newRelationship");
        }

        final String relationshipId = newRelationship['id'] as String;
        await _updateUserProfileWithRelationship(userId, relationshipId);

        // Generate the invitation URL using the relationship id.
        final String inviteUrl = "${kReleaseMode ? 'https://cristhiandalmazzo.github.io/tango_ai_companion' : 'http://localhost:49879'}/signup?relationshipId=$relationshipId";
        
        // Show the invite URL dialog with a "Copy URL" button and a "Close" button.
        final l10n = AppLocalizations.of(context)!;
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(l10n.invitePartner),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.shareLink),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark 
                        ? const Color(0xFF2A2A2A) 
                        : Colors.grey.shade100,
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
                    SnackBar(content: Text(l10n.linkCopied)),
                  );
                },
                child: Text(l10n.copyURL),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.close),
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
      final l10n = AppLocalizations.of(context)!;
      if (e.message.toLowerCase().contains("user already registered")) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.emailRegistered)),
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
          child: AppContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: LanguageSelector(isCompact: true),
                  ),
                ),
                const SizedBox(height: 20),
                _buildHeader(),
                const SizedBox(height: 40),
                _buildRegisterForm(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final l10n = AppLocalizations.of(context)!;
    
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
        Text(
          l10n.register,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          relationshipIdFromUrl != null 
              ? l10n.joinPartnerRelationship
              : l10n.welcome,
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
    final l10n = AppLocalizations.of(context)!;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CustomTextField(
          controller: _nameController,
          label: l10n.name,
          hintText: l10n.enterFullName,
          prefixIcon: const Icon(Icons.person_outline),
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _emailController,
          label: l10n.email,
          hintText: l10n.enterEmail,
          keyboardType: TextInputType.emailAddress,
          prefixIcon: const Icon(Icons.email_outlined),
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _passwordController,
          label: l10n.password,
          hintText: l10n.createPassword,
          obscureText: true,
          prefixIcon: const Icon(Icons.lock_outline),
        ),
        const SizedBox(height: 32),
        CustomButton(
          text: l10n.register,
          onPressed: _signUp,
          isLoading: _isLoading,
          icon: Icons.arrow_forward,
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              l10n.haveAccount,
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark 
                    ? Colors.grey.shade300 
                    : Colors.grey.shade700
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
              child: Text(
                l10n.login,
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Theme.of(context).primaryColor,
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
