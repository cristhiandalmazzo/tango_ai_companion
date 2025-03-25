import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../services/profile_service.dart';
import 'theme_toggle.dart';

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
      if (kDebugMode) {
        print('Error loading profile: $e');
      }
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
    final theme = Theme.of(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Drawer(
      elevation: 2,
      backgroundColor: isDarkMode 
          ? Color.lerp(const Color(0xFF2C2C2C), theme.colorScheme.primary, 0.05)
          : theme.colorScheme.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(16),
          bottomRight: Radius.circular(16),
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
                  onTap: () => Navigator.pushReplacementNamed(context, '/home'),
                ),
                _buildNavItem(
                  context: context,
                  icon: Icons.person_outline,
                  title: 'Profile',
                  onTap: () => Navigator.pushReplacementNamed(context, '/profile'),
                ),
                _buildNavItem(
                  context: context,
                  icon: Icons.favorite_border_outlined,
                  title: 'Relationship',
                  onTap: () => Navigator.pushReplacementNamed(context, '/relationship'),
                ),
                _buildNavItem(
                  context: context,
                  icon: Icons.chat_outlined,
                  title: 'AI Chat',
                  onTap: () => Navigator.pushReplacementNamed(context, '/ai_chat'),
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
                  onTap: () => Navigator.pushReplacementNamed(context, '/settings'),
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
    final theme = Theme.of(context);
    final String? profilePictureUrl = _userProfile?['profile_picture_url'];
    final String displayName = _userProfile?['name'] ?? user?.email?.split('@').first ?? 'Welcome';
    
    return DrawerHeader(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => Navigator.pushReplacementNamed(context, '/profile'),
            child: _isLoading 
                ? CircleAvatar(
                    radius: 30,
                    backgroundColor: theme.colorScheme.onPrimary.withOpacity(0.25),
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.colorScheme.onPrimary,
                      ),
                    ),
                  )
                : profilePictureUrl != null && profilePictureUrl.isNotEmpty
                    ? CircleAvatar(
                        radius: 30,
                        backgroundColor: theme.colorScheme.onPrimary.withOpacity(0.25),
                        backgroundImage: NetworkImage(profilePictureUrl),
                        onBackgroundImageError: (_, __) {
                          // Handle image loading error
                        },
                      )
                    : CircleAvatar(
                        radius: 30,
                        backgroundColor: theme.colorScheme.onPrimary.withOpacity(0.25),
                        child: Icon(
                          Icons.person,
                          size: 30,
                          color: theme.colorScheme.onPrimary,
                        ),
                      ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => Navigator.pushReplacementNamed(context, '/profile'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: TextStyle(
                    color: theme.colorScheme.onPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.email ?? '',
                  style: TextStyle(
                    color: theme.colorScheme.onPrimary.withOpacity(0.7),
                    fontSize: 14,
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
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    return ListTile(
      leading: Icon(
        icon,
        color: theme.colorScheme.primary,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 16,
          color: isDarkMode 
              ? theme.colorScheme.primary.withOpacity(0.9)
              : theme.colorScheme.primary.withOpacity(0.9),
        ),
      ),
      trailing: trailing,
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 4,
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(20),
      child: ElevatedButton.icon(
        onPressed: () async {
          Navigator.pop(context); // Close the drawer first.
          await Supabase.instance.client.auth.signOut();
          Navigator.pushNamedAndRemoveUntil(
            context, '/login', (route) => false,
          );
        },
        icon: const Icon(Icons.logout),
        label: const Text('Logout'),
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.error,
          foregroundColor: theme.colorScheme.onError,
          padding: const EdgeInsets.symmetric(
            vertical: 12,
            horizontal: 16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}
