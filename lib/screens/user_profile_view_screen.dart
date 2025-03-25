import 'package:flutter/material.dart';
import '../widgets/screen_container.dart';
import '../widgets/app_container.dart';
import '../services/profile_service.dart';

class UserProfileViewScreen extends StatefulWidget {
  final ThemeMode currentThemeMode;
  final Function(ThemeMode) onThemeChanged;
  
  const UserProfileViewScreen({
    super.key,
    this.currentThemeMode = ThemeMode.light,
    required this.onThemeChanged,
  });
  
  @override
  _UserProfileViewScreenState createState() => _UserProfileViewScreenState();
}

class _UserProfileViewScreenState extends State<UserProfileViewScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _userProfile;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    try {
      // Fetch user profile data
      final userData = await ProfileService.fetchProfile();
      
      setState(() {
        _userProfile = userData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load profile: ${e.toString()}';
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
              onPressed: _loadUserProfile,
            ),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ScreenContainer(
      title: 'My Profile',
      isLoading: false, // Handle loading states within the body
      currentThemeMode: widget.currentThemeMode,
      onThemeChanged: widget.onThemeChanged,
      body: SingleChildScrollView(
        child: AppContainer(
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_errorMessage.isNotEmpty || _userProfile == null) {
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
              'Error Loading Profile',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadUserProfile,
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Profile picture
        _buildProfilePicture(),
        const SizedBox(height: 24),
        
        // Edit Profile Button
        ElevatedButton.icon(
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/edit_profile');
          },
          icon: const Icon(Icons.edit),
          label: const Text('Edit Profile'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Name
        _buildProfileDetail(
          title: 'Name', 
          value: _userProfile!['name'] ?? _userProfile!['full_name'] ?? 'Not provided',
          icon: Icons.person,
        ),
        
        // Bio
        if (_userProfile!['bio'] != null)
          _buildProfileDetail(
            title: 'Bio', 
            value: _userProfile!['bio'], 
            icon: Icons.description,
            maxLines: 5,
          ),
          
        // Location
        if (_userProfile!['location'] != null)
          _buildProfileDetail(
            title: 'Location', 
            value: _userProfile!['location'], 
            icon: Icons.location_on,
          ),
          
        // Occupation
        if (_userProfile!['occupation'] != null)
          _buildProfileDetail(
            title: 'Occupation', 
            value: _userProfile!['occupation'], 
            icon: Icons.work,
          ),
        
        // Education
        if (_userProfile!['education'] != null)
          _buildProfileDetail(
            title: 'Education', 
            value: _userProfile!['education'], 
            icon: Icons.school,
          ),
        
        // Gender
        if (_userProfile!['gender'] != null)
          _buildProfileDetail(
            title: 'Gender', 
            value: _userProfile!['gender'], 
            icon: Icons.person_outline,
          ),
        
        // Age
        if (_userProfile!['birthdate'] != null)
          _buildProfileDetail(
            title: 'Age', 
            value: _calculateAge(_userProfile!['birthdate']), 
            icon: Icons.cake,
          ),
        
        const SizedBox(height: 16),
        
        // Interests
        if (_userProfile!['interests'] != null && (_userProfile!['interests'] as List).isNotEmpty)
          _buildChipsSection(
            title: 'Interests', 
            items: List<String>.from(_userProfile!['interests']),
            icon: Icons.favorite_border,
            chipColor: Theme.of(context).colorScheme.primaryContainer,
          ),
        
        // Personality Traits
        if (_userProfile!['personality_traits'] != null && (_userProfile!['personality_traits'] as List).isNotEmpty)
          _buildChipsSection(
            title: 'Personality Traits', 
            items: List<String>.from(_userProfile!['personality_traits']),
            icon: Icons.psychology,
            chipColor: Theme.of(context).colorScheme.secondaryContainer,
          ),
        
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildProfilePicture() {
    final String pictureUrl = _userProfile!['profile_picture_url'] ?? '';
    final String name = _userProfile!['name'] ?? _userProfile!['full_name'] ?? 'Me';
    
    // Calculate age from birthdate if available
    String? ageText;
    if (_userProfile!['birthdate'] != null) {
      final birthdate = DateTime.tryParse(_userProfile!['birthdate']);
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
                      color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade400 : Theme.of(context).textTheme.bodySmall?.color,
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