import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';
import '../widgets/app_container.dart';
import '../widgets/language_selector.dart';
import '../widgets/loading_indicator.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _signIn() async {
    setState(() => _isLoading = true);
    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
      
      if (response.user != null) {
        await Provider.of<LanguageProvider>(context, listen: false).syncWithUserProfile();
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sign in failed.')),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDarkMode 
          ? Color.lerp(const Color(0xFF121212), theme.colorScheme.primary, 0.03)
          : theme.scaffoldBackgroundColor,
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
                    child: LanguageSelector(isCompact: false),
                  ),
                ),
                const SizedBox(height: 20),
                _buildHeader(),
                const SizedBox(height: 40),
                _buildLoginForm(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    return Column(
      children: [
        Container(
          height: 80,
          width: 80,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.lock_outline,
            size: 40,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          l10n.welcome,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          l10n.signInToContinue,
          style: TextStyle(
            fontSize: 16,
            color: isDarkMode ? Colors.white70 : Colors.grey.shade600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildLoginForm() {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CustomTextField(
          controller: _emailController,
          label: l10n.email,
          hintText: l10n.enterEmail,
          keyboardType: TextInputType.emailAddress,
          prefixIcon: Icon(Icons.email_outlined, color: theme.colorScheme.primary),
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _passwordController,
          label: l10n.password,
          hintText: l10n.createPassword,
          obscureText: true,
          prefixIcon: Icon(Icons.lock_outline, color: theme.colorScheme.primary),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () {
              // Navigate to password reset
              Navigator.pushNamed(context, '/forgot-password');
            },
            child: Text(
              l10n.forgotPassword,
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        CustomButton(
          text: l10n.login,
          onPressed: _signIn,
          isLoading: _isLoading,
          icon: Icons.arrow_forward,
          backgroundColor: theme.colorScheme.primary,
          textColor: theme.colorScheme.onPrimary,
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              l10n.dontHaveAccount,
              style: TextStyle(
                color: theme.brightness == Brightness.dark 
                    ? Colors.white70
                    : Colors.grey.shade700
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pushReplacementNamed(context, '/signup'),
              child: Text(
                l10n.register,
                style: TextStyle(
                  color: theme.colorScheme.primary,
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
