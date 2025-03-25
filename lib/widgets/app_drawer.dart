import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'theme_toggle.dart';

class AppDrawer extends StatelessWidget {
  final ThemeMode currentThemeMode;
  final Function(ThemeMode) onThemeChanged;

  const AppDrawer({
    super.key, 
    this.currentThemeMode = ThemeMode.light,
    required this.onThemeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final currentUser = Supabase.instance.client.auth.currentUser;
    final theme = Theme.of(context);
    
    return Drawer(
      elevation: 2,
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
                  icon: Icons.settings_outlined,
                  title: 'Settings',
                  trailing: ThemeToggle(
                    currentThemeMode: currentThemeMode,
                    onThemeChanged: onThemeChanged,
                  ),
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
    return DrawerHeader(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white24,
            child: Icon(
              Icons.person,
              size: 30,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            user?.email?.split('@').first ?? 'Welcome',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            user?.email ?? '',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
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
        color: Theme.of(context).primaryColor,
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 16,
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
          backgroundColor: Colors.redAccent,
          foregroundColor: Colors.white,
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
