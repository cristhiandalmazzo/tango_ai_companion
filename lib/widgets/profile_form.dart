import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import 'interests_chips.dart'; // Your reusable interests widget.
import 'traits_chips.dart';    // Your reusable traits widget.
import 'profile_picture_picker.dart'; // The new profile picture picker widget.
import 'language_selector.dart'; // The language selector widget

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
    
    // Get the current language code directly from the provider
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    final String languageCode = languageProvider.locale.languageCode;
    
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
    
    // Language is already updated via the LanguageSelector widget
    // No need to call _updateAppLanguage here
    
    widget.onSave(updates);
  }

  void _handleProfileUpdated(Map<String, dynamic> updatedProfile) {
    setState(() {
      _profileData = updatedProfile;
    });
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Name',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: 'Enter your name',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: Theme.of(context).dividerColor,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: Theme.of(context).dividerColor,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: Theme.of(context).primaryColor,
                      width: 2,
                    ),
                  ),
                ),
                validator: (value) =>
                    (value == null || value.isEmpty) ? 'Name cannot be empty' : null,
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Bio.
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Bio',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _bioController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Tell us about yourself',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: Theme.of(context).dividerColor,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: Theme.of(context).dividerColor,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: Theme.of(context).primaryColor,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Location.
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Location',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _locationController,
                decoration: InputDecoration(
                  hintText: 'Enter your location',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: Theme.of(context).dividerColor,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: Theme.of(context).dividerColor,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: Theme.of(context).primaryColor,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Occupation.
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Occupation',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _occupationController,
                decoration: InputDecoration(
                  hintText: 'Enter your occupation',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: Theme.of(context).dividerColor,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: Theme.of(context).dividerColor,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: Theme.of(context).primaryColor,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Education.
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Education',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _educationController,
                decoration: InputDecoration(
                  hintText: 'Enter your education',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: Theme.of(context).dividerColor,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: Theme.of(context).dividerColor,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: Theme.of(context).primaryColor,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ],
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Gender',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).dividerColor,
                    width: 1,
                  ),
                ),
                child: Theme(
                  data: Theme.of(context).copyWith(
                    // Ensure dropdown menu has proper background
                    canvasColor: Theme.of(context).scaffoldBackgroundColor,
                  ),
                  child: DropdownButtonHideUnderline(
                    child: ButtonTheme(
                      alignedDropdown: true,
                      child: DropdownButton<String>(
                        value: _selectedGender,
                        isExpanded: true,
                        hint: Text(
                          'Select Gender',
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                          ),
                        ),
                        icon: Icon(
                          Icons.arrow_drop_down,
                          color: Theme.of(context).iconTheme.color,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        borderRadius: BorderRadius.circular(8),
                        items: _genderOptions.map((gender) => DropdownMenuItem(
                          value: gender,
                          child: Text(
                            gender,
                            style: TextStyle(
                              color: Theme.of(context).textTheme.bodyLarge?.color,
                            ),
                          ),
                        )).toList(),
                        onChanged: (value) => setState(() => _selectedGender = value),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Language Preference using LanguageSelector.
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Language Preference',
                style: TextStyle(fontSize: 16),
              ),
              StatefulBuilder(
                builder: (context, setState) {
                  // When language changes, update the _selectedLanguage
                  _selectedLanguage = languageProvider.locale.languageCode == 'pt' 
                      ? 'Portuguese (Brazil)' 
                      : 'English';
                  
                  return LanguageSelector(isCompact: false);
                }
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          // Birthdate Picker.
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Birthdate',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).dividerColor,
                    width: 1,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _birthDate == null
                          ? 'No birthdate selected'
                          : 'Birthdate: ${_birthDate!.toLocal().toString().split(' ')[0]}',
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _pickBirthDate,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Select Date'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: widget.isLoading ? null : _save,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Theme.of(context).disabledColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: widget.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Save Profile',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
