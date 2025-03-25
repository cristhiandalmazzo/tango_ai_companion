import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../extensions/theme_extension.dart';
import '../utils/style_constants.dart';
import '../utils/navigation_utils.dart';
import '../utils/error_utils.dart';
import '../widgets/screen_container.dart';
import '../services/relationship_service.dart';
import '../services/profile_service.dart';
import '../widgets/app_container.dart';
import '../providers/language_provider.dart';
import '../widgets/language_selector.dart';
import '../services/ai_auto_messenger_service.dart';

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
  
  // Auto messenger variables
  AIAutoMessengerService? _autoMessenger;
  bool _isAutoMessengerActive = false;
  String? _conversationId;
  String? _relationshipId;
  int _intervalMinutes = 5;
  bool _isInitialized = false;
  
  // Track if user has seen the intro dialog
  bool _hasConfirmedAutoMessaging = false;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }
  
  /// Initialize auto messenger service with user data
  Future<void> _fetchUserData() async {
    setState(() => _isLoading = true);
    
    try {
      final profile = await ProfileService.fetchProfile();
      _conversationId = profile['conversation_id'] as String?;
      _relationshipId = profile['relationship_id'] as String?;
      
      if (_conversationId != null && _relationshipId != null) {
        _initAutoMessenger();
      }
    } catch (e) {
      debugPrint("Error fetching user data: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  /// Initialize the auto messenger service
  Future<void> _initAutoMessenger() async {
    if (_conversationId != null && _relationshipId != null) {
      _autoMessenger = await AIAutoMessengerService.getInstance(
        conversationId: _conversationId!,
        relationshipId: _relationshipId!,
        intervalMinutes: _intervalMinutes,
      );
      
      setState(() {
        _isAutoMessengerActive = _autoMessenger?.isActive ?? false;
        _intervalMinutes = _autoMessenger?.intervalMinutes ?? 25;
        _isInitialized = true;
      });
    }
  }
  
  /// Show confirmation dialog for first-time auto messaging
  Future<bool> _showAutoMessagingConfirmation() async {
    if (_hasConfirmedAutoMessaging) {
      return true;
    }
    
    bool confirmed = false;
    
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        final l10n = AppLocalizations.of(context)!;
        
        return AlertDialog(
          title: const Text("Auto Messaging"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "This feature will automatically send AI-generated messages as you in the chat.",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text("Important information:"),
              const SizedBox(height: 8),
              Text("• Messages will be sent every $_intervalMinutes minutes"),
              const Text("• Messages will be generated based on your profile bio"),
              const Text("• You can stop this feature at any time"),
              const Text("• All messages will appear as if you sent them"),
              const SizedBox(height: 16),
              const Text("Are you sure you want to enable auto messaging?"),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                confirmed = false;
                NavigationUtils.goBack(context);
              },
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () {
                confirmed = true;
                _hasConfirmedAutoMessaging = true;
                NavigationUtils.goBack(context);
              },
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary,
              ),
              child: const Text("Enable Auto Messaging"),
            ),
          ],
        );
      },
    );
    
    return confirmed;
  }
  
  /// Start or stop the auto messenger
  void _toggleAutoMessenger() async {
    if (_autoMessenger == null) {
      await _initAutoMessenger();
    }
    
    if (_autoMessenger == null) {
      // If still null, show error
      ErrorUtils.showErrorSnackBar(
        context,
        "No active conversation found",
      );
      return;
    }
    
    setState(() => _isLoading = true);
    
    if (_isAutoMessengerActive) {
      // Stopping auto messaging doesn't need confirmation
      _autoMessenger?.stop();
      setState(() {
        _isAutoMessengerActive = false;
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Auto messaging stopped"),
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      // When starting, show confirmation dialog first
      final confirmed = await _showAutoMessagingConfirmation();
      
      if (confirmed) {
        _autoMessenger?.start();
        setState(() {
          _isAutoMessengerActive = true;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Auto messaging started (every $_intervalMinutes minutes)"),
            duration: const Duration(seconds: 2),
          ),
        );
      }
      
      setState(() => _isLoading = false);
    }
  }
  
  /// Show dialog to change interval
  Future<void> _showIntervalDialog() async {
    if (_autoMessenger == null) {
      await _initAutoMessenger();
    }
    
    if (_autoMessenger == null) {
      ErrorUtils.showErrorSnackBar(
        context,
        "No active conversation found",
      );
      return;
    }
    
    int selectedInterval = _intervalMinutes;
    
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        final l10n = AppLocalizations.of(context)!;
        
        return AlertDialog(
          title: const Text("Set Message Interval"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Select how often messages are sent"),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: selectedInterval,
                decoration: const InputDecoration(
                  labelText: "Minutes between messages",
                  border: OutlineInputBorder(),
                ),
                items: [1, 5, 10, 15, 25, 30, 45, 60, 120, 240]
                    .map((interval) => DropdownMenuItem<int>(
                          value: interval,
                          child: Text('$interval minutes'),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    selectedInterval = value;
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => NavigationUtils.goBack(context),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () {
                if (_autoMessenger != null && selectedInterval != _intervalMinutes) {
                  _autoMessenger!.setIntervalMinutes(selectedInterval);
                  setState(() {
                    _intervalMinutes = selectedInterval;
                  });
                  
                  // Show confirmation
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Interval set to $selectedInterval minutes'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
                NavigationUtils.goBack(context);
              },
              child: Text(l10n.save),
            ),
          ],
        );
      },
    );
  }

  Future<void> _exitRelationship() async {
    final l10n = AppLocalizations.of(context)!;
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      ErrorUtils.showErrorSnackBar(context, l10n.mustBeLoggedIn);
      return;
    }

    try {
      setState(() => _isLoading = true);

      // Get current relationship data
      final relationshipData = await RelationshipService.fetchRelationshipData();
      if (relationshipData == null) {
        if (mounted) {
          ErrorUtils.showErrorSnackBar(context, l10n.noActiveRelationship);
        }
        return;
      }

      final relationship = relationshipData['relationship'];
      if (relationship == null) {
        if (mounted) {
          ErrorUtils.showErrorSnackBar(context, l10n.noActiveRelationship);
        }
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
        ErrorUtils.showErrorSnackBar(context, l10n.relationshipEnded);
        // Navigate back to home screen
        NavigationUtils.replace(context, '/home');
      }
    } catch (e) {
      ErrorUtils.logError('SettingsScreen._exitRelationship', e);
      if (mounted) {
        ErrorUtils.showErrorSnackBar(
          context, 
          l10n.errorEndingRelationship + ErrorUtils.getUserFriendlyMessage(e),
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
              onPressed: () => NavigationUtils.goBack(context),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () {
                NavigationUtils.goBack(context);
                _exitRelationship();
              },
              style: TextButton.styleFrom(
                foregroundColor: context.theme.colorScheme.error,
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
              _buildSection("Automation", [
                _buildListTile(
                  context,
                  icon: _isAutoMessengerActive ? Icons.timer : Icons.timer_outlined,
                  iconColor: _isAutoMessengerActive ? Theme.of(context).colorScheme.primary : null,
                  title: _isAutoMessengerActive ? "Stop Auto Messaging" : "Start Auto Messaging",
                  subtitle: _isAutoMessengerActive 
                      ? 'Active every $_intervalMinutes minutes'
                      : 'Send automatic messages as you',
                  onTap: _isLoading ? null : _toggleAutoMessenger,
                ),
                _buildDivider(),
                _buildListTile(
                  context,
                  icon: Icons.schedule,
                  title: "Message Interval",
                  subtitle: '$_intervalMinutes minutes',
                  onTap: _isLoading ? null : _showIntervalDialog,
                ),
              ]),
              _buildSection(l10n.profile, [
                _buildListTile(
                  context,
                  icon: Icons.person_outline,
                  title: l10n.profile,
                  onTap: () => NavigationUtils.goTo(context, '/profile'),
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
                  onTap: () async {
                    try {
                      await Supabase.instance.client.auth.signOut();
                      if (mounted) {
                        NavigationUtils.goToAndClearStack(context, '/login');
                      }
                    } catch (e) {
                      ErrorUtils.logError('SettingsScreen.logout', e);
                      if (mounted) {
                        ErrorUtils.showErrorSnackBar(
                          context, 
                          ErrorUtils.getUserFriendlyMessage(e),
                        );
                      }
                    }
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

  Widget _buildLanguageSelector(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          leading: const Icon(Icons.language),
          title: Text(l10n.language),
          trailing: const LanguageSelector(),
        ),
      ],
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, top: 24, bottom: 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        ...children,
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildListTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    Color? iconColor,
    String? subtitle,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: iconColor,
      ),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      onTap: onTap,
      enabled: onTap != null,
    );
  }

  Widget _buildDivider() {
    return const Divider(
      height: 1,
      indent: 72,
      endIndent: 0,
    );
  }
} 