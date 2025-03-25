import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import 'interests_chips.dart'; // Your reusable interests widget.
import 'traits_chips.dart';    // Your reusable traits widget.
import 'profile_picture_picker.dart'; // The new profile picture picker widget.

class ProfileForm extends StatefulWidget {
  final Map<String, dynamic> initialData;
  final Future<void> Function(Map<String, dynamic> updates) onSave;
  final bool isLoading;

  const ProfileForm({
    Key? key,
    required this.initialData,
    required this.onSave,
    this.isLoading = false,
  }) : super(key: key);

  @override
  _ProfileFormState createState() => _ProfileFormState();
}

class _ProfileFormState extends State<ProfileForm> {
  final _formKey = GlobalKey<FormState>();
  Map<String, dynamic> _profileData = {};

  // Controllers for text fields.
  late final TextEditingController _nameController;
  late final TextEditingController _bioController;
  late final TextEditingController _locationController;
  late final TextEditingController _occupationController;
  late final TextEditingController _educationController;

  // Selected values.
  String? _selectedGender;
  String? _selectedLanguage;
  List<String> _selectedInterests = [];
  List<String> _selectedTraits = [];
  DateTime? _birthDate; // Now we store the birthdate

  // Predefined lists.
  final List<String> _allInterests = [
    'Music', 'Sports', 'Reading', 'Travel', 'Cooking', 'Art', 
    'Technology', 'Gaming', 'Fitness', 'Nature', 'Fashion', 'Movies', 'Photography', 'Dancing', 'Writing'
  ];
  final List<String> _allTraits = [
    'Outgoing', 'Introverted', 'Creative', 'Analytical', 'Empathetic', 
    'Adventurous', 'Organized', 'Spontaneous', 'Reliable', 'Optimistic', 'Humorous', 'Thoughtful'
  ];
  final List<String> _genderOptions = ['Male', 'Female', 'Other', 'Prefer not to say'];
  final List<String> _languageOptions = ['English', 'Portuguese (Brazil)'];

  @override
  void initState() {
    super.initState();
    _profileData = Map<String, dynamic>.from(widget.initialData);
    _nameController = TextEditingController(text: _profileData['name'] ?? '');
    _bioController = TextEditingController(text: _profileData['bio'] ?? '');
    _locationController = TextEditingController(text: _profileData['location'] ?? '');
    _occupationController = TextEditingController(text: _profileData['occupation'] ?? '');
    _educationController = TextEditingController(text: _profileData['education'] ?? '');
    _selectedGender = _profileData['gender'];
    
    // Handle language preference - map database values to dropdown options
    String? langPref = _profileData['language_preference'];
    if (langPref == 'pt') {
      _selectedLanguage = 'Portuguese (Brazil)';
    } else if (langPref == 'en' || langPref == 'English') {
      _selectedLanguage = 'English';
    } else {
      _selectedLanguage = 'English'; // Default to English if unknown
    }
    
    if (_profileData['interests'] != null && _profileData['interests'] is List) {
      _selectedInterests = List<String>.from(_profileData['interests']);
    }
    if (_profileData['personality_traits'] != null && _profileData['personality_traits'] is List) {
      _selectedTraits = List<String>.from(_profileData['personality_traits']);
    }
    // Initialize _birthDate from backend if available.
    if (_profileData['birthdate'] != null) {
      _birthDate = DateTime.tryParse(_profileData['birthdate']);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    _occupationController.dispose();
    _educationController.dispose();
    super.dispose();
  }

  Future<void> _pickBirthDate() async {
    final initialDate = _birthDate ?? DateTime(2000, 1, 1);
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _birthDate = picked;
      });
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    
    // Convert selected language display name to language code
    String? languageCode;
    if (_selectedLanguage == 'Portuguese (Brazil)') {
      languageCode = 'pt';
    } else {
      languageCode = 'en';
    }
    
    final updates = {
      'name': _nameController.text,
      'bio': _bioController.text,
      'location': _locationController.text,
      'occupation': _occupationController.text,
      'education': _educationController.text,
      'gender': _selectedGender,
      'language_preference': languageCode,
      'interests': _selectedInterests,
      'personality_traits': _selectedTraits,
      // Store birthdate instead of age.
      'birthdate': _birthDate?.toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };
    
    // Update app-wide language when profile is updated
    _updateAppLanguage(languageCode);
    
    widget.onSave(updates);
  }

  void _updateAppLanguage(String languageCode) {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    if (languageCode == 'pt') {
      languageProvider.setLocale(const Locale('pt', 'BR'));
    } else {
      languageProvider.setLocale(const Locale('en'));
    }
  }

  void _handleProfileUpdated(Map<String, dynamic> updatedProfile) {
    setState(() {
      _profileData = updatedProfile;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Profile picture picker
          Center(
            child: ProfilePicturePicker(
              currentImageUrl: _profileData['profile_picture_url'],
              onProfileUpdated: _handleProfileUpdated,
              isLoading: widget.isLoading,
              size: 120,
            ),
          ),
          const SizedBox(height: 24),
          
          // Name.
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Name'),
            validator: (value) =>
                (value == null || value.isEmpty) ? 'Name cannot be empty' : null,
          ),
          const SizedBox(height: 16),
          // Bio.
          TextFormField(
            controller: _bioController,
            decoration: const InputDecoration(labelText: 'Bio'),
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          // Location.
          TextFormField(
            controller: _locationController,
            decoration: const InputDecoration(labelText: 'Location'),
          ),
          const SizedBox(height: 16),
          // Occupation.
          TextFormField(
            controller: _occupationController,
            decoration: const InputDecoration(labelText: 'Occupation'),
          ),
          const SizedBox(height: 16),
          // Education.
          TextFormField(
            controller: _educationController,
            decoration: const InputDecoration(labelText: 'Education'),
          ),
          const SizedBox(height: 16),
          // Interests Chips.
          const Text(
            'Select Interests',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          InterestsChips(
            allInterests: _allInterests,
            selectedInterests: _selectedInterests,
            onSelectionChanged: (newSelected) {
              setState(() {
                _selectedInterests = newSelected;
              });
            },
          ),
          const SizedBox(height: 16),
          // Traits Chips.
          const Text(
            'Select Personality Traits',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          // Assuming you have created a TraitsChips widget similar to InterestsChips.
          TraitsChips(
            allTraits: _allTraits,
            selectedTraits: _selectedTraits,
            onSelectionChanged: (newSelected) {
              setState(() {
                _selectedTraits = newSelected;
              });
            },
          ),
          const SizedBox(height: 16),
          // Gender Dropdown.
          DropdownButtonFormField<String>(
            value: _selectedGender,
            decoration: const InputDecoration(labelText: 'Gender'),
            items: _genderOptions
                .map((gender) => DropdownMenuItem(
                      value: gender,
                      child: Text(gender),
                    ))
                .toList(),
            onChanged: (value) => setState(() => _selectedGender = value),
          ),
          const SizedBox(height: 16),
          // Language Preference Dropdown.
          DropdownButtonFormField<String>(
            value: _selectedLanguage,
            decoration: const InputDecoration(labelText: 'Language Preference'),
            items: _languageOptions
                .map((lang) => DropdownMenuItem(
                      value: lang,
                      child: Text(lang),
                    ))
                .toList(),
            onChanged: (value) => setState(() => _selectedLanguage = value),
          ),
          const SizedBox(height: 16),
          // Birthdate Picker.
          Row(
            children: [
              Expanded(
                child: Text(
                  _birthDate == null
                      ? 'No birthdate selected'
                      : 'Birthdate: ${_birthDate!.toLocal().toString().split(' ')[0]}',
                ),
              ),
              TextButton(
                onPressed: _pickBirthDate,
                child: const Text('Select Birthdate'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _save,
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
