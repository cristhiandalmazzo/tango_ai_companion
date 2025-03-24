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
    // This function should fetch profile data from Supabase.
    // For example, you can move your fetch logic here, or call a service method.
    // For demonstration, let's assume it returns a Map<String, dynamic>.
    final data = await ProfileService.fetchProfile(); // You would implement this.
    setState(() {
      _profileData = data;
      _isLoading = false;
    });
  }

  Future<void> _saveProfile(Map<String, dynamic> updates) async {
    // This function should call your service to update the profile.
    final result = await ProfileService.updateProfile(updates);
    if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile updated successfully.")),
      );
      _loadProfile();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to update profile.")),
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
      title: 'My Profile',
      isLoading: _isLoading,
      currentThemeMode: widget.currentThemeMode,
      onThemeChanged: widget.onThemeChanged,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: ProfileForm(
          initialData: _profileData,
          onSave: _saveProfile,
        ),
      ),
    );
  }
}
