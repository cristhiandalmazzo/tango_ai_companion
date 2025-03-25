import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../widgets/screen_container.dart';
import '../widgets/profile_form.dart';
import '../widgets/app_container.dart';
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
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.failedToLoad + e.toString())),
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
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.profileUpdated)),
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
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.failedToUpdate + e.toString())),
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
    final l10n = AppLocalizations.of(context)!;
    
    return ScreenContainer(
      title: l10n.profile,
      isLoading: false, // We'll handle loading states within the form
      currentThemeMode: widget.currentThemeMode,
      onThemeChanged: widget.onThemeChanged,
      body: SingleChildScrollView(
        child: AppContainer(
          additionalPadding: const EdgeInsets.symmetric(vertical: 16),
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
                  label: Text(l10n.profile),
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
      ),
    );
  }
}
