import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../services/profile_service.dart';
import '../extensions/theme_extension.dart';
import '../utils/style_constants.dart';
import '../utils/navigation_utils.dart';
import '../utils/error_utils.dart';
import '../widgets/loading_indicator.dart';
import 'theme_toggle.dart';
import 'user_avatar.dart';

class AppDrawer extends StatefulWidget {
  final ThemeMode currentThemeMode;
  final Function(ThemeMode) onThemeChanged;

  const AppDrawer({
    super.key, 
    this.currentThemeMode = ThemeMode.light,
    required this.onThemeChanged,
  });

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  Map<String, dynamic>? _userProfile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final profile = await ProfileService.fetchProfile();
      if (mounted) {
        setState(() {
          _userProfile = profile;
          _isLoading = false;
        });
      }
    } catch (e) {
      ErrorUtils.logError('AppDrawer', e);
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = Supabase.instance.client.auth.currentUser;
    
    return Drawer(
      elevation: 2,
      backgroundColor: context.isDarkMode 
          ? Color.lerp(StyleConstants.darkSurface, context.primaryColor, StyleConstants.darkCardTint)
          : context.theme.colorScheme.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(StyleConstants.radiusL),
          bottomRight: Radius.circular(StyleConstants.radiusL),
        ),
      ),
      child: Column(
        children: [
          _buildDrawerHeader(context, currentUser),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildNavItem(
                  context: context,
                  icon: Icons.home_outlined,
                  title: 'Home',
                  onTap: () => NavigationUtils.replace(context, '/home'),
                ),
                _buildNavItem(
                  context: context,
                  icon: Icons.person_outline,
                  title: 'Profile',
                  onTap: () => NavigationUtils.replace(context, '/profile'),
                ),
                _buildNavItem(
                  context: context,
                  icon: Icons.favorite_border_outlined,
                  title: 'Relationship',
                  onTap: () => NavigationUtils.replace(context, '/relationship'),
                ),
                _buildNavItem(
                  context: context,
                  icon: Icons.chat_outlined,
                  title: 'AI Chat',
                  onTap: () => NavigationUtils.replace(context, '/ai_chat'),
                ),
                const Divider(),
                _buildNavItem(
                  context: context,
                  icon: Icons.dark_mode,
                  title: 'Dark Mode',
                  trailing: Builder(
                    builder: (context) {
                      debugPrint('AppDrawer: Building ThemeToggle with currentThemeMode: ${widget.currentThemeMode}');
                      return ThemeToggle(
                        key: const ValueKey('theme_toggle'),
                        currentThemeMode: widget.currentThemeMode,
                        onThemeChanged: (mode) {
                          debugPrint('AppDrawer: ThemeToggle callback called with mode: $mode');
                          // Ensure we're setting to a definite state
                          final newMode = (mode == ThemeMode.dark) ? ThemeMode.dark : ThemeMode.light;
                          debugPrint('AppDrawer: Enforcing definite theme state: $newMode');
                          widget.onThemeChanged(newMode);
                          debugPrint('AppDrawer: Called parent onThemeChanged');
                        },
                      );
                    }
                  ),
                ),
                _buildNavItem(
                  context: context,
                  icon: Icons.settings_outlined,
                  title: 'Settings',
                  onTap: () => NavigationUtils.replace(context, '/settings'),
                ),
              ],
            ),
          ),
          _buildLogoutButton(context),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader(BuildContext context, User? user) {
    final String? profilePictureUrl = _userProfile?['profile_picture_url'];
    final String displayName = _userProfile?['name'] ?? user?.email?.split('@').first ?? 'Welcome';
    final String userId = user?.id ?? '';
    
    return DrawerHeader(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            context.primaryColor,
            context.primaryColor.withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => NavigationUtils.replace(context, '/profile'),
            child: _isLoading 
                ? LoadingIndicator(
                    size: StyleConstants.avatarSizeLarge,
                    color: context.theme.colorScheme.onPrimary,
                    centered: false,
                  )
                : userId.isNotEmpty
                    ? UserAvatar(
                        userId: userId,
                        size: StyleConstants.avatarSizeLarge,
                        imageUrl: profilePictureUrl,
                        name: displayName,
                        onTap: () => NavigationUtils.replace(context, '/profile'),
                      )
                    : CircleAvatar(
                        radius: 30,
                        backgroundColor: context.theme.colorScheme.onPrimary.withOpacity(0.25),
                        child: Icon(
                          Icons.person,
                          size: 30,
                          color: context.theme.colorScheme.onPrimary,
                        ),
                      ),
          ),
          SizedBox(height: StyleConstants.spacingM),
          GestureDetector(
            onTap: () => NavigationUtils.replace(context, '/profile'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: TextStyle(
                    color: context.theme.colorScheme.onPrimary,
                    fontSize: StyleConstants.fontSizeL,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: StyleConstants.spacingXS),
                Text(
                  user?.email ?? '',
                  style: TextStyle(
                    color: context.theme.colorScheme.onPrimary.withOpacity(0.7),
                    fontSize: StyleConstants.fontSizeS,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: context.primaryColor,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: StyleConstants.fontSizeM,
          color: context.primaryColor.withOpacity(0.9),
        ),
      ),
      trailing: trailing,
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(
        horizontal: StyleConstants.spacingL,
        vertical: StyleConstants.spacingXS,
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(StyleConstants.spacingL),
      child: ElevatedButton.icon(
        onPressed: () async {
          NavigationUtils.goBack(context); // Close the drawer first.
          try {
            await Supabase.instance.client.auth.signOut();
            if (mounted) {
              NavigationUtils.goToAndClearStack(context, '/login');
            }
          } catch (e) {
            ErrorUtils.logError('AppDrawer', e);
            if (mounted) {
              ErrorUtils.showErrorSnackBar(context, 'Error signing out. Please try again.');
            }
          }
        },
        icon: const Icon(Icons.logout),
        label: const Text('Logout'),
        style: ElevatedButton.styleFrom(
          backgroundColor: context.theme.colorScheme.error,
          foregroundColor: context.theme.colorScheme.onError,
          padding: EdgeInsets.symmetric(
            vertical: StyleConstants.spacingM,
            horizontal: StyleConstants.spacingM,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(StyleConstants.radiusM),
          ),
        ),
      ),
    );
  }
}
