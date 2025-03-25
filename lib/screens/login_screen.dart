import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../extensions/theme_extension.dart';
import '../utils/style_constants.dart';
import '../utils/navigation_utils.dart';
import '../utils/error_utils.dart';
import '../utils/form_utils.dart';
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
        if (mounted) {
          NavigationUtils.replace(context, '/home');
        }
      } else {
        if (mounted) {
          ErrorUtils.showErrorSnackBar(context, 'Sign in failed.');
        }
      }
    } catch (error) {
      ErrorUtils.logError('LoginScreen._signIn', error);
      if (mounted) {
        ErrorUtils.showErrorSnackBar(
          context, 
          ErrorUtils.getUserFriendlyMessage(error),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.darkBackgroundWithTint,
      body: SafeArea(
        child: SingleChildScrollView(
          child: AppContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: EdgeInsets.only(top: StyleConstants.spacingM),
                    child: LanguageSelector(isCompact: false),
                  ),
                ),
                SizedBox(height: StyleConstants.spacingL),
                _buildHeader(),
                SizedBox(height: StyleConstants.spacingXL),
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
    
    return Column(
      children: [
        Container(
          height: StyleConstants.avatarSizeLarge,
          width: StyleConstants.avatarSizeLarge,
          decoration: BoxDecoration(
            color: context.primaryColor.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.lock_outline,
            size: 40,
            color: context.primaryColor,
          ),
        ),
        SizedBox(height: StyleConstants.spacingM),
        Text(
          l10n.welcome,
          style: TextStyle(
            fontSize: StyleConstants.fontSizeXL,
            fontWeight: FontWeight.bold,
            color: context.primaryColor,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: StyleConstants.spacingS),
        Text(
          l10n.signInToContinue,
          style: TextStyle(
            fontSize: StyleConstants.fontSizeM,
            color: context.textSecondaryColor,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildLoginForm() {
    final l10n = AppLocalizations.of(context)!;
    
    return FormUtils.buildFormLayout(
      context: context,
      fields: [
        FormUtils.buildEmailField(
          context: context,
          controller: _emailController,
          label: l10n.email,
          hintText: l10n.enterEmail,
        ),
        FormUtils.buildPasswordField(
          context: context,
          controller: _passwordController,
          label: l10n.password,
          hintText: l10n.createPassword,
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => NavigationUtils.goTo(context, '/forgot-password'),
            child: Text(
              l10n.forgotPassword,
              style: TextStyle(
                color: context.primaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        SizedBox(height: StyleConstants.spacingM),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              l10n.dontHaveAccount,
              style: TextStyle(
                color: context.textSecondaryColor,
              ),
            ),
            TextButton(
              onPressed: () => NavigationUtils.replace(context, '/signup'),
              child: Text(
                l10n.register,
                style: TextStyle(
                  color: context.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ],
      buttonText: l10n.login,
      onSubmit: _signIn,
      isLoading: _isLoading,
      buttonIcon: Icons.arrow_forward,
    );
  }
}
