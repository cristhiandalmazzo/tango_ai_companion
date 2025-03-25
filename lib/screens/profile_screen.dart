import 'package:flutter/material.dart';
import '../widgets/screen_container.dart';
import '../widgets/profile_form.dart';
import '../services/profile_service.dart'; // For API calls if you decide to separate them.

class ProfileScreen extends StatefulWidget {
  final ThemeMode currentThemeMode;
  final Function(ThemeMode) onThemeChanged;
  
  const ProfileScreen({
    super.key,
    this.currentThemeMode = ThemeMode.light,
    required this.onThemeChanged,
  });
  
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _profileData = {};

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final data = await ProfileService.fetchProfile();
      setState(() {
        _profileData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load profile: ${e.toString()}")),
      );
    }
  }

  Future<void> _saveProfile(Map<String, dynamic> updates) async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final result = await ProfileService.updateProfile(updates);
      if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile updated successfully.")),
        );
        setState(() {
          _profileData = result;
          _isLoading = false;
        });
      } else {
        throw Exception("Failed to update profile");
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to update profile: ${e.toString()}")),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  Widget build(BuildContext context) {
    return ScreenContainer(
      title: 'Edit Profile',
      isLoading: false, // We'll handle loading states within the form
      currentThemeMode: widget.currentThemeMode,
      onThemeChanged: widget.onThemeChanged,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // View Profile button
            Container(
              margin: const EdgeInsets.only(bottom: 20),
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/profile');
                },
                icon: const Icon(Icons.visibility),
                label: const Text('View Profile'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            
            // Profile form
            _profileData.isEmpty && _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ProfileForm(
                  initialData: _profileData,
                  onSave: _saveProfile,
                  isLoading: _isLoading,
                ),
          ],
        ),
      ),
    );
  }
}
