import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/screen_container.dart';
import '../services/relationship_service.dart';
import '../widgets/app_container.dart';

class SettingsScreen extends StatefulWidget {
  final ThemeMode currentThemeMode;
  final Function(ThemeMode) onThemeChanged;
  
  const SettingsScreen({
    super.key,
    this.currentThemeMode = ThemeMode.light,
    required this.onThemeChanged,
  });
  
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isLoading = false;

  Future<void> _exitRelationship() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to exit a relationship')),
      );
      return;
    }

    try {
      setState(() => _isLoading = true);

      // Get current relationship data
      final relationshipData = await RelationshipService.fetchRelationshipData();
      if (relationshipData == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No active relationship found')),
        );
        return;
      }

      final relationship = relationshipData['relationship'];
      if (relationship == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No active relationship found')),
        );
        return;
      }

      // Get partner IDs
      final partnerAId = relationship['partner_a'];
      final partnerBId = relationship['partner_b'];

      // Update current relationship to inactive
      await Supabase.instance.client
          .from('relationships')
          .update({'active': false})
          .eq('id', relationship['id']);

      // Create new relationships for both partners
      final newRelationshipId = await RelationshipService.createNewRelationship(user.id);
      
      // Update profiles with new relationship IDs
      if (partnerAId != null) {
        await Supabase.instance.client
            .from('profiles')
            .update({'relationship_id': newRelationshipId})
            .eq('id', partnerAId);
      }

      if (partnerBId != null) {
        final newPartnerRelationshipId = await RelationshipService.createNewRelationship(partnerBId);
        await Supabase.instance.client
            .from('profiles')
            .update({'relationship_id': newPartnerRelationshipId})
            .eq('id', partnerBId);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Relationship ended successfully')),
        );
        // Navigate back to home screen
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error ending relationship: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showExitRelationshipDialog() async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Exit Relationship'),
          content: const Text(
            'Are you sure you want to exit this relationship? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _exitRelationship();
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Exit Relationship'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScreenContainer(
      title: 'Settings',
      currentThemeMode: widget.currentThemeMode,
      onThemeChanged: widget.onThemeChanged,
      body: SingleChildScrollView(
        child: AppContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSection('Appearance', [
                _buildThemeToggle(context),
                _buildDivider(),
              ]),
              _buildSection('Account', [
                _buildListTile(
                  context,
                  icon: Icons.person_outline,
                  title: 'Profile Settings',
                  onTap: () => Navigator.pushNamed(context, '/profile'),
                ),
                _buildDivider(),
                _buildListTile(
                  context,
                  icon: Icons.notifications_outlined,
                  title: 'Notifications',
                  onTap: () {},
                ),
                _buildDivider(),
                _buildListTile(
                  context,
                  icon: Icons.privacy_tip_outlined,
                  title: 'Privacy',
                  onTap: () {},
                ),
                _buildDivider(),
                _buildListTile(
                  context,
                  icon: Icons.security_outlined,
                  title: 'Security',
                  onTap: () {},
                ),
                _buildDivider(),
                _buildListTile(
                  context,
                  icon: Icons.heart_broken,
                  title: 'Exit Relationship',
                  onTap: _showExitRelationshipDialog,
                ),
              ]),
              _buildSection('Support', [
                _buildListTile(
                  context,
                  icon: Icons.help_outline,
                  title: 'Help Center',
                  onTap: () {},
                ),
                _buildDivider(),
                _buildListTile(
                  context,
                  icon: Icons.info_outline,
                  title: 'About',
                  onTap: () {},
                ),
                _buildDivider(),
                _buildListTile(
                  context,
                  icon: Icons.logout,
                  title: 'Logout',
                  onTap: () {
                    // Handle logout
                  },
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThemeToggle(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.dark_mode),
      title: const Text('Dark Mode'),
      trailing: Switch(
        value: widget.currentThemeMode == ThemeMode.dark,
        onChanged: (value) {
          widget.onThemeChanged(value ? ThemeMode.dark : ThemeMode.light);
        },
      ),
    );
  }

  Widget _buildListTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1);
  }

  Widget _buildSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
        ),
        ...items,
      ],
    );
  }
} 