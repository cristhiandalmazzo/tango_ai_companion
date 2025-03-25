import 'package:flutter/material.dart';
import '../widgets/screen_container.dart';
import '../services/profile_service.dart';
import '../services/relationship_service.dart';

class PartnerProfileScreen extends StatefulWidget {
  final ThemeMode currentThemeMode;
  final Function(ThemeMode) onThemeChanged;
  final String? partnerId; // Optional partner ID if known
  
  const PartnerProfileScreen({
    super.key,
    this.currentThemeMode = ThemeMode.light,
    required this.onThemeChanged,
    this.partnerId,
  });
  
  @override
  _PartnerProfileScreenState createState() => _PartnerProfileScreenState();
}

class _PartnerProfileScreenState extends State<PartnerProfileScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _partnerProfile;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadPartnerProfile();
  }

  Future<void> _loadPartnerProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    try {
      Map<String, dynamic>? partnerData;
      
      // If we have a specific partnerId, use it
      if (widget.partnerId != null) {
        // Implementation for direct partner lookup by ID would go here
        // For now, we'll use the relationship-based lookup
        partnerData = await ProfileService.fetchPartnerProfile();
      } else {
        // Get partner through relationship
        partnerData = await ProfileService.fetchPartnerProfile();
      }
      
      if (partnerData == null) {
        throw Exception("Could not find partner profile");
      }
      
      setState(() {
        _partnerProfile = partnerData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load partner profile: ${e.toString()}';
      });
      _showErrorSnackBar();
    }
  }

  void _showErrorSnackBar() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_errorMessage.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMessage),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: _loadPartnerProfile,
            ),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ScreenContainer(
      title: 'Partner Profile',
      isLoading: false, // Handle loading states within the body
      currentThemeMode: widget.currentThemeMode,
      onThemeChanged: widget.onThemeChanged,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_errorMessage.isNotEmpty || _partnerProfile == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 60,
            ),
            const SizedBox(height: 16),
            Text(
              _partnerProfile == null ? 'Partner Profile Not Found' : 'Error Loading Partner Profile',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Text(
                _partnerProfile == null ? 'Could not find partner profile information.' : _errorMessage,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadPartnerProfile,
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Profile picture
          _buildProfilePicture(),
          const SizedBox(height: 24),
          
          // Name
          _buildProfileDetail(
            title: 'Name', 
            value: _partnerProfile!['name'] ?? _partnerProfile!['full_name'] ?? 'Not provided',
            icon: Icons.person,
          ),
          
          // Bio
          if (_partnerProfile!['bio'] != null)
            _buildProfileDetail(
              title: 'Bio', 
              value: _partnerProfile!['bio'], 
              icon: Icons.description,
              maxLines: 5,
            ),
            
          // Location
          if (_partnerProfile!['location'] != null)
            _buildProfileDetail(
              title: 'Location', 
              value: _partnerProfile!['location'], 
              icon: Icons.location_on,
            ),
            
          // Occupation
          if (_partnerProfile!['occupation'] != null)
            _buildProfileDetail(
              title: 'Occupation', 
              value: _partnerProfile!['occupation'], 
              icon: Icons.work,
            ),
            
          // Education
          if (_partnerProfile!['education'] != null)
            _buildProfileDetail(
              title: 'Education', 
              value: _partnerProfile!['education'], 
              icon: Icons.school,
            ),
            
          // Gender
          if (_partnerProfile!['gender'] != null)
            _buildProfileDetail(
              title: 'Gender', 
              value: _partnerProfile!['gender'], 
              icon: Icons.person_outline,
            ),
            
          // Age
          if (_partnerProfile!['birthdate'] != null)
            _buildProfileDetail(
              title: 'Age', 
              value: _calculateAge(_partnerProfile!['birthdate']), 
              icon: Icons.cake,
            ),
            
          const SizedBox(height: 16),
          
          // Interests
          if (_partnerProfile!['interests'] != null && (_partnerProfile!['interests'] as List).isNotEmpty)
            _buildChipsSection(
              title: 'Interests', 
              items: List<String>.from(_partnerProfile!['interests']),
              icon: Icons.favorite_border,
              chipColor: Theme.of(context).colorScheme.primaryContainer,
            ),
            
          // Personality Traits
          if (_partnerProfile!['personality_traits'] != null && (_partnerProfile!['personality_traits'] as List).isNotEmpty)
            _buildChipsSection(
              title: 'Personality Traits', 
              items: List<String>.from(_partnerProfile!['personality_traits']),
              icon: Icons.psychology,
              chipColor: Theme.of(context).colorScheme.secondaryContainer,
            ),
          
          // Remove the "Back to Relationship" button
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildProfilePicture() {
    final String pictureUrl = _partnerProfile!['profile_picture_url'] ?? '';
    final String name = _partnerProfile!['name'] ?? _partnerProfile!['full_name'] ?? 'Partner';
    
    // Calculate age from birthdate if available
    String? ageText;
    if (_partnerProfile!['birthdate'] != null) {
      final birthdate = DateTime.tryParse(_partnerProfile!['birthdate']);
      if (birthdate != null) {
        final now = DateTime.now();
        int age = now.year - birthdate.year;
        // Adjust age if birthday hasn't occurred yet this year
        if (now.month < birthdate.month || 
            (now.month == birthdate.month && now.day < birthdate.day)) {
          age--;
        }
        ageText = '$age years old';
      }
    }
    
    return Column(
      children: [
        CircleAvatar(
          radius: 60,
          backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
          backgroundImage: pictureUrl.isNotEmpty 
              ? NetworkImage(pictureUrl) 
              : null,
          child: pictureUrl.isEmpty 
              ? Icon(
                  Icons.person,
                  size: 60,
                  color: Theme.of(context).colorScheme.primary,
                )
              : null,
        ),
        const SizedBox(height: 16),
        Text(
          name,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        if (ageText != null)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              ageText,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
          ),
      ],
    );
  }
  
  Widget _buildProfileDetail({
    required String title,
    required String value,
    required IconData icon,
    int maxLines = 2,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    icon,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyLarge,
                maxLines: maxLines,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildChipsSection({
    required String title,
    required List<String> items,
    required IconData icon,
    Color? chipColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    icon,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: items.map((item) => Chip(
                  label: Text(item),
                  backgroundColor: chipColor,
                )).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _calculateAge(String birthdateStr) {
    final birthdate = DateTime.tryParse(birthdateStr);
    if (birthdate == null) {
      return 'Birthdate not available';
    }
    
    final now = DateTime.now();
    int age = now.year - birthdate.year;
    
    // Adjust age if birthday hasn't occurred yet this year
    if (now.month < birthdate.month || 
        (now.month == birthdate.month && now.day < birthdate.day)) {
      age--;
    }
    
    return '$age years';
  }
} 