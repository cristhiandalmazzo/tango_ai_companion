import 'package:flutter/material.dart';
import '../widgets/screen_container.dart';
import '../services/relationship_service.dart';
import 'dart:convert';

class RelationshipScreen extends StatefulWidget {
  final ThemeMode currentThemeMode;
  final Function(ThemeMode) onThemeChanged;
  
  const RelationshipScreen({
    super.key,
    this.currentThemeMode = ThemeMode.light,
    required this.onThemeChanged,
  });
  
  @override
  _RelationshipScreenState createState() => _RelationshipScreenState();
}

class _RelationshipScreenState extends State<RelationshipScreen> {
  bool _isLoading = true;
  String _errorMessage = '';
  Map<String, dynamic> _relationshipData = {};
  Map<String, dynamic> _currentUserProfile = {};
  Map<String, dynamic> _partnerProfile = {};
  Map<String, dynamic> _metrics = {};
  int _strengthPercentage = 0;

  @override
  void initState() {
    super.initState();
    _loadRelationshipData().then((_) {
      // Data loaded successfully
    }).catchError((error) {
      // Show error snackbar
      _showErrorSnackBar();
    });
  }

  Future<void> _loadRelationshipData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    try {
      // Fetch relationship data from the service
      final data = await RelationshipService.fetchRelationshipData();
      
      setState(() {
        _relationshipData = data;
        
        // Determine which profile is the current user and which is the partner
        final currentUserId = data['current_user_id'];
        if (data['partner_a']['id'] == currentUserId) {
          _currentUserProfile = data['partner_a'];
          _partnerProfile = data['partner_b'];
        } else {
          _currentUserProfile = data['partner_b'];
          _partnerProfile = data['partner_a'];
        }
        
        // Get metrics
        _metrics = data['metrics'] ?? {};
        _strengthPercentage = (_metrics['strength'] ?? 65).toInt();
        
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Could not load relationship data: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScreenContainer(
      title: 'Your Relationship',
      isLoading: _isLoading,
      currentThemeMode: widget.currentThemeMode,
      onThemeChanged: widget.onThemeChanged,
      body: _errorMessage.isNotEmpty
          ? _buildErrorView()
          : _buildRelationshipView(),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 80,
            ),
            const SizedBox(height: 20),
            Text(
              'Error',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loadRelationshipData,
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRelationshipView() {
    final size = MediaQuery.of(context).size;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          Text(
            'Your Connection',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _relationshipData['relationship']?['name'] ?? 'View and strengthen your relationship',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
          const SizedBox(height: 40),
          
          // Partner cards with connection
          Stack(
            alignment: Alignment.center,
            children: [
              // Connection line
              Positioned(
                child: Container(
                  height: 4,
                  width: size.width * 0.4,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _getColorFromInterests(_currentUserProfile['interests']),
                        _getColorFromInterests(_partnerProfile['interests']),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              
              // Connection heart icon
              Positioned(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey.shade800 : Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    _getRelationshipIcon(),
                    color: _getRelationshipIconColor(),
                    size: 28,
                  ),
                ),
              ),
              
              // Partner cards
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildPartnerCard(_currentUserProfile, true),
                  const SizedBox(width: 60), // Space for connection line and heart
                  _buildPartnerCard(_partnerProfile, false),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 40),
          
          // Relationship strength meter
          _buildStrengthMeter(),
          
          const SizedBox(height: 30),
          
          // Anniversary date
          _buildAnniversarySection(),
          
          const SizedBox(height: 30),
          
          // Relationship insights card
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        color: Colors.amber,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Relationship Insights',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _metrics['insight'] ?? 
                    'Your communication has been improving. Continue sharing your thoughts and feelings to strengthen your connection.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildInsightMetric('Communication', 
                          _metrics['communication'] ?? 70),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildInsightMetric('Understanding', 
                          _metrics['understanding'] ?? 65),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/ai_chat');
                    },
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Strengthen With AI Chat'),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Notes section
          _buildNotesSection(),
          
          const SizedBox(height: 20),
          
          // Common interests section
          if (_getCommonInterests().isNotEmpty) _buildCommonInterestsSection(),
        ],
      ),
    );
  }

  Widget _buildPartnerCard(Map<String, dynamic> profile, bool isCurrentUser) {
    final String name = profile['full_name'] ?? profile['username'] ?? profile['name'] ?? 'Partner';
    
    // Calculate age from birthdate if available
    int? age;
    if (profile['birthdate'] != null) {
      final birthdate = DateTime.tryParse(profile['birthdate']);
      if (birthdate != null) {
        final now = DateTime.now();
        age = now.year - birthdate.year;
        // Adjust age if birthday hasn't occurred yet this year
        if (now.month < birthdate.month || 
            (now.month == birthdate.month && now.day < birthdate.day)) {
          age--;
        }
      }
    }
    
    final String description = profile['bio'] ?? 
        (isCurrentUser ? 'You' : 'Your partner') + ' has not added a description yet.';
    
    // Use profile_picture_url if available, or generate a placeholder
    final String pictureUrl = profile['profile_picture_url'] ?? 
        'https://ui-avatars.com/api/?name=${Uri.encodeComponent(name)}&background=random';
        
    return Expanded(
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 40,
                backgroundImage: NetworkImage(pictureUrl),
                onBackgroundImageError: (_, __) {
                  // Fallback for image loading errors
                },
              ),
              const SizedBox(height: 12),
              Text(
                isCurrentUser ? 'You' : name,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (age != null) Text(
                '$age years',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                description,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(
                    context, 
                    isCurrentUser ? '/profile' : '/partner_profile',
                  );
                },
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(isCurrentUser ? 'View Profile' : 'View Profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStrengthMeter() {
    Color strengthColor;
    String strengthLabel;
    
    if (_strengthPercentage >= 80) {
      strengthColor = Colors.green;
      strengthLabel = 'Excellent';
    } else if (_strengthPercentage >= 60) {
      strengthColor = Colors.green.shade300;
      strengthLabel = 'Good';
    } else if (_strengthPercentage >= 40) {
      strengthColor = Colors.amber;
      strengthLabel = 'Moderate';
    } else {
      strengthColor = Colors.red.shade300;
      strengthLabel = 'Needs Work';
    }
    
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Relationship Strength',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '$_strengthPercentage%',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: strengthColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: _strengthPercentage / 100,
            minHeight: 10,
            backgroundColor: Colors.grey.shade300,
            valueColor: AlwaysStoppedAnimation<Color>(strengthColor),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Needs Work',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              'Excellent',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildInsightMetric(String title, int value) {
    Color metricColor;
    
    if (value >= 80) {
      metricColor = Colors.green;
    } else if (value >= 60) {
      metricColor = Colors.green.shade300;
    } else if (value >= 40) {
      metricColor = Colors.amber;
    } else {
      metricColor = Colors.red.shade300;
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value / 100,
            minHeight: 6,
            backgroundColor: Colors.grey.shade300,
            valueColor: AlwaysStoppedAnimation<Color>(metricColor),
          ),
        ),
      ],
    );
  }
  
  Widget _buildAnniversarySection() {
    // Get anniversary date from relationship data
    DateTime? anniversaryDate;
    
    if (_relationshipData['relationship']?['start_date'] != null) {
      try {
        anniversaryDate = DateTime.parse(_relationshipData['relationship']['start_date']);
      } catch (e) {
        // Handle date parsing error
      }
    }
    
    String formattedDate = 'Not set';
    if (anniversaryDate != null) {
      formattedDate = '${anniversaryDate.day}/${anniversaryDate.month}/${anniversaryDate.year}';
    }
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Anniversary Date',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _showDatePickerDialog(anniversaryDate),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              formattedDate,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            if (anniversaryDate != null) ...[
              const SizedBox(height: 8),
              Text(
                _getAnniversaryMessage(anniversaryDate),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  String _getAnniversaryMessage(DateTime anniversaryDate) {
    final now = DateTime.now();
    final thisYearAnniversary = DateTime(now.year, anniversaryDate.month, anniversaryDate.day);
    final daysUntilAnniversary = thisYearAnniversary.difference(now).inDays;
    
    if (daysUntilAnniversary == 0) {
      return "Today is your anniversary! 🎉";
    } else if (daysUntilAnniversary > 0) {
      return "$daysUntilAnniversary days until your anniversary!";
    } else {
      // Anniversary has passed this year
      final nextYearAnniversary = DateTime(now.year + 1, anniversaryDate.month, anniversaryDate.day);
      final daysUntilNextAnniversary = nextYearAnniversary.difference(now).inDays;
      return "$daysUntilNextAnniversary days until your next anniversary!";
    }
  }
  
  Future<void> _showDatePickerDialog(DateTime? initialDate) async {
    final now = DateTime.now();
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate ?? now,
      firstDate: DateTime(1900),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDarkMode
                ? ColorScheme.dark(
                    primary: Theme.of(context).colorScheme.primary,
                    onPrimary: Theme.of(context).colorScheme.onPrimary,
                    onSurface: Theme.of(context).colorScheme.onSurface,
                    surface: Theme.of(context).colorScheme.surface,
                  )
                : ColorScheme.light(
                    primary: Theme.of(context).colorScheme.primary,
                    onPrimary: Theme.of(context).colorScheme.onPrimary,
                    onSurface: Theme.of(context).colorScheme.onSurface,
                  ),
          ),
          child: child!,
        );
      },
    );
    
    if (pickedDate != null) {
      _saveAnniversaryDate(pickedDate);
    }
  }
  
  Future<void> _saveAnniversaryDate(DateTime date) async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      final result = await RelationshipService.updateRelationship({
        'start_date': date.toIso8601String(),
      });
      
      if (result) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Anniversary date updated!')),
        );
        
        // Refresh relationship data
        await _loadRelationshipData();
      } else {
        throw Exception('Failed to update anniversary date');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildNotesSection() {
    // Get notes from the additional_data column
    List<Map<String, dynamic>> notes = [];
    
    if (_relationshipData['relationship']?['additional_data'] != null) {
      try {
        final additionalData = _relationshipData['relationship']['additional_data'];
        if (additionalData['notes'] != null) {
          notes = List<Map<String, dynamic>>.from(additionalData['notes']);
        }
      } catch (e) {
        // Handle parsing error
      }
    }
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.note_alt,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Relationship Notes',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _showAddNoteDialog,
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (notes.isEmpty)
              Text(
                'No notes yet. Tap the + button to add your first note.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontStyle: FontStyle.italic,
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: notes.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final note = notes[index];
                  final dateAdded = DateTime.tryParse(note['date'] ?? '');
                  final formattedDate = dateAdded != null
                      ? '${dateAdded.day}/${dateAdded.month}/${dateAdded.year}'
                      : '';
                      
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              note['title'] ?? 'Note',
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, size: 18),
                              onPressed: () => _deleteNote(index),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(note['content'] ?? ''),
                        const SizedBox(height: 4),
                        if (formattedDate.isNotEmpty)
                          Text(
                            'Added on $formattedDate',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _showAddNoteDialog() async {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Note'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'Enter a title for your note',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: contentController,
              decoration: const InputDecoration(
                labelText: 'Content',
                hintText: 'Write your note here',
              ),
              maxLines: 5,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (contentController.text.trim().isNotEmpty) {
                Navigator.pop(context);
                _saveNote(
                  titleController.text.trim().isEmpty 
                      ? 'Note' 
                      : titleController.text.trim(),
                  contentController.text.trim(),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _saveNote(String title, String content) async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      // Get current additional_data or create new
      Map<String, dynamic> additionalData = {};
      if (_relationshipData['relationship']?['additional_data'] != null) {
        additionalData = Map<String, dynamic>.from(_relationshipData['relationship']['additional_data']);
      }
      
      // Get existing notes or create new list
      List<Map<String, dynamic>> notes = [];
      if (additionalData['notes'] != null) {
        notes = List<Map<String, dynamic>>.from(additionalData['notes']);
      }
      
      // Add new note
      notes.add({
        'title': title,
        'content': content,
        'date': DateTime.now().toIso8601String(),
      });
      
      // Update additional_data
      additionalData['notes'] = notes;
      
      // Save to database
      final result = await RelationshipService.updateRelationship({
        'additional_data': additionalData,
      });
      
      if (result) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Note added successfully!')),
        );
        
        // Refresh relationship data
        await _loadRelationshipData();
      } else {
        throw Exception('Failed to add note');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _deleteNote(int index) async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      // Get current additional_data
      Map<String, dynamic> additionalData = Map<String, dynamic>.from(
        _relationshipData['relationship']['additional_data'] ?? {}
      );
      
      // Get existing notes
      List<Map<String, dynamic>> notes = [];
      if (additionalData['notes'] != null) {
        notes = List<Map<String, dynamic>>.from(additionalData['notes']);
        
        // Remove note
        if (index >= 0 && index < notes.length) {
          notes.removeAt(index);
          
          // Update additional_data
          additionalData['notes'] = notes;
          
          // Save to database
          final result = await RelationshipService.updateRelationship({
            'additional_data': additionalData,
          });
          
          if (result) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Note deleted successfully!')),
            );
            
            // Refresh relationship data
            await _loadRelationshipData();
          } else {
            throw Exception('Failed to delete note');
          }
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildCommonInterestsSection() {
    final commonInterests = _getCommonInterests();
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.favorite_border,
                  color: Colors.red.shade400,
                ),
                const SizedBox(width: 8),
                Text(
                  'Common Interests',
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
              children: commonInterests.map((interest) => Chip(
                label: Text(interest),
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                labelStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }
  
  // Helper methods
  
  IconData _getRelationshipIcon() {
    final relationshipType = _relationshipData['relationship']?['type'] ?? 'romantic';
    
    switch (relationshipType.toLowerCase()) {
      case 'romantic':
        return Icons.favorite;
      case 'friendship':
        return Icons.people;
      case 'family':
        return Icons.family_restroom;
      default:
        return Icons.favorite;
    }
  }
  
  Color _getRelationshipIconColor() {
    final relationshipType = _relationshipData['relationship']?['type'] ?? 'romantic';
    
    switch (relationshipType.toLowerCase()) {
      case 'romantic':
        return Colors.red.shade400;
      case 'friendship':
        return Colors.blue.shade400;
      case 'family':
        return Colors.green.shade400;
      default:
        return Colors.red.shade400;
    }
  }
  
  Color _getColorFromInterests(List<dynamic>? interests) {
    if (interests == null || interests.isEmpty) {
      return Colors.blue.shade300;
    }
    
    // Generate a color based on the first interest
    final String interest = interests.first.toString().toLowerCase();
    
    if (interest.contains('sport') || interest.contains('fitness')) {
      return Colors.green.shade500;
    } else if (interest.contains('art') || interest.contains('music')) {
      return Colors.purple.shade400;
    } else if (interest.contains('tech') || interest.contains('science')) {
      return Colors.blue.shade500;
    } else if (interest.contains('food') || interest.contains('cooking')) {
      return Colors.orange.shade400;
    } else if (interest.contains('travel') || interest.contains('adventure')) {
      return Colors.teal.shade400;
    } else {
      return Colors.blue.shade300;
    }
  }
  
  List<String> _getCommonInterests() {
    final List<dynamic> userInterests = _currentUserProfile['interests'] ?? [];
    final List<dynamic> partnerInterests = _partnerProfile['interests'] ?? [];
    
    final userInterestStrings = userInterests.map((i) => i.toString().toLowerCase()).toList();
    final partnerInterestStrings = partnerInterests.map((i) => i.toString().toLowerCase()).toList();
    
    return userInterestStrings.where((interest) => 
      partnerInterestStrings.contains(interest)).toList();
  }
  
  // Show a snackbar message with retry option
  void _showErrorSnackBar() {
    if (_errorMessage.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMessage),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: _loadRelationshipData,
            ),
          ),
        );
      });
    }
  }
} 