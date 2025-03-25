import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../widgets/screen_container.dart';
import '../services/relationship_service.dart';
import '../widgets/app_container.dart';
import '../providers/language_provider.dart';
import '../widgets/language_selector.dart';

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
    final l10n = AppLocalizations.of(context)!;
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.mustBeLoggedIn)),
      );
      return;
    }

    try {
      setState(() => _isLoading = true);

      // Get current relationship data
      final relationshipData = await RelationshipService.fetchRelationshipData();
      if (relationshipData == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.noActiveRelationship)),
        );
        return;
      }

      final relationship = relationshipData['relationship'];
      if (relationship == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.noActiveRelationship)),
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
          SnackBar(content: Text(l10n.relationshipEnded)),
        );
        // Navigate back to home screen
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.errorEndingRelationship + e.toString()),
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
    final l10n = AppLocalizations.of(context)!;
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(l10n.exitRelationship),
          content: Text(
            l10n.confirmExitRelationship,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _exitRelationship();
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: Text(l10n.exitRelationship),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return ScreenContainer(
      title: l10n.settings,
      currentThemeMode: widget.currentThemeMode,
      onThemeChanged: widget.onThemeChanged,
      body: SingleChildScrollView(
        child: AppContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSection(l10n.theme, [
                _buildThemeToggle(context),
                _buildDivider(),
                _buildLanguageSelector(context),
              ]),
              _buildSection(l10n.profile, [
                _buildListTile(
                  context,
                  icon: Icons.person_outline,
                  title: l10n.profile,
                  onTap: () => Navigator.pushNamed(context, '/profile'),
                ),
                _buildDivider(),
                _buildListTile(
                  context,
                  icon: Icons.notifications_outlined,
                  title: l10n.notifications,
                  onTap: () {},
                ),
                _buildDivider(),
                _buildListTile(
                  context,
                  icon: Icons.privacy_tip_outlined,
                  title: l10n.privacy,
                  onTap: () {},
                ),
                _buildDivider(),
                _buildListTile(
                  context,
                  icon: Icons.security_outlined,
                  title: l10n.security,
                  onTap: () {},
                ),
                _buildDivider(),
                _buildListTile(
                  context,
                  icon: Icons.heart_broken,
                  title: l10n.exitRelationship,
                  onTap: _showExitRelationshipDialog,
                ),
              ]),
              _buildSection(l10n.support, [
                _buildListTile(
                  context,
                  icon: Icons.help_outline,
                  title: l10n.helpCenter,
                  onTap: () {},
                ),
                _buildDivider(),
                _buildListTile(
                  context,
                  icon: Icons.info_outline,
                  title: l10n.about,
                  onTap: () {},
                ),
                _buildDivider(),
                _buildListTile(
                  context,
                  icon: Icons.logout,
                  title: l10n.logout,
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
    final l10n = AppLocalizations.of(context)!;
    return ListTile(
      leading: const Icon(Icons.dark_mode),
      title: Text(l10n.darkMode),
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

  Widget _buildLanguageSelector(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ListTile(
      leading: Icon(Icons.language, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : null),
      title: Text(l10n.language, style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.white : null)),
      trailing: LanguageSelector(isCompact: false),
    );
  }
} 