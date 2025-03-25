import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/screen_container.dart';
import '../widgets/app_container.dart';
import '../widgets/custom_button.dart';
import '../widgets/connected_avatars.dart';
import '../services/profile_service.dart';
import '../services/relationship_service.dart';

class HomeScreen extends StatefulWidget {
  final ThemeMode currentThemeMode;
  final Function(ThemeMode) onThemeChanged;

  const HomeScreen({
    super.key, 
    this.currentThemeMode = ThemeMode.light,
    required this.onThemeChanged,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _userProfile = {};
  Map<String, dynamic> _partnerProfile = {};
  Map<String, dynamic> _relationshipData = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load user profile
      final userData = await ProfileService.fetchProfile();
      _userProfile = userData;

      // Load relationship data and partner profile
      final relationshipData = await RelationshipService.fetchRelationshipData();
      _relationshipData = relationshipData;

      // Determine which profile is the current user and which is the partner
      final currentUserId = relationshipData['current_user_id'];
      if (relationshipData['partner_a']?['id'] == currentUserId) {
        _partnerProfile = relationshipData['partner_b'] ?? {};
      } else {
        _partnerProfile = relationshipData['partner_a'] ?? {};
      }
    } catch (e) {
      // Handle errors
      debugPrint('Error loading data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return ScreenContainer(
      title: l10n.appTitle,
      currentThemeMode: widget.currentThemeMode,
      onThemeChanged: widget.onThemeChanged,
      body: SingleChildScrollView(
        child: AppContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeCard(context),
              const SizedBox(height: 24),
              if (!_isLoading && _partnerProfile.isNotEmpty)
                _buildRelationshipSection(context),
              const SizedBox(height: 24),
              _buildFeatureSection(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRelationshipSection(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.relationship,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 2,
          color: isDarkMode ? const Color(0xFF2A2A2A) : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                ConnectedAvatars(
                  userProfile: _userProfile,
                  partnerProfile: _partnerProfile,
                  avatarSize: 60.0,
                  centerWidget: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 5,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(6),
                    child: Icon(
                      Icons.favorite,
                      color: Colors.red.shade400,
                      size: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _relationshipData['relationship']?['name'] ?? l10n.viewAndStrengthen,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                CustomButton(
                  text: l10n.relationship,
                  onPressed: () {
                    Navigator.pushNamed(context, '/relationship');
                  },
                  icon: Icons.favorite_border,
                  isOutlined: true,
                  width: double.infinity,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWelcomeCard(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.welcome,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.aiCompanion,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 20),
          CustomButton(
            text: l10n.chat,
            onPressed: () {
              Navigator.pushNamed(context, '/ai_chat');
            },
            icon: Icons.chat_bubble_outline,
            backgroundColor: Colors.white,
            textColor: Theme.of(context).primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureSection(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    final features = [
      {
        'icon': Icons.chat_bubble_outline,
        'title': l10n.chat,
        'description': l10n.chatDescription,
        'route': '/ai_chat',
      },
      {
        'icon': Icons.person_outline,
        'title': l10n.profile,
        'description': l10n.profileDescription,
        'route': '/profile',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.features,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: features.length,
          itemBuilder: (context, index) {
            final feature = features[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 2,
              color: isDarkMode ? const Color(0xFF2A2A2A) : null,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                leading: CircleAvatar(
                  backgroundColor: isDarkMode 
                      ? Theme.of(context).primaryColor.withOpacity(0.3)
                      : Theme.of(context).primaryColor.withOpacity(0.1),
                  child: Icon(
                    feature['icon'] as IconData,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                title: Text(
                  feature['title'] as String,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                subtitle: Text(
                  feature['description'] as String,
                  style: TextStyle(
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                ),
                trailing: Icon(
                  Icons.arrow_forward_ios, 
                  size: 16,
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                ),
                onTap: () {
                  Navigator.pushNamed(context, feature['route'] as String);
                },
              ),
            );
          },
        ),
      ],
    );
  }
}
