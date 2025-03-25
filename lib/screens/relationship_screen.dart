import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../widgets/screen_container.dart';
import '../widgets/app_container.dart';
import '../services/relationship_service.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/relationship_provider.dart';
import '../models/relationship.dart';
import '../models/note.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/user_avatar.dart';
import './chat_screen.dart'; // Update to direct import
import '../widgets/error_view.dart';
import '../widgets/connected_avatars.dart';
import '../extensions/theme_extension.dart';
import '../utils/style_constants.dart';
import '../utils/navigation_utils.dart';
import '../utils/error_utils.dart';

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
    _loadRelationshipData()
        .then((_) {
          // Data loaded successfully
        })
        .catchError((error) {
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
      ErrorUtils.logError('RelationshipScreen._loadRelationshipData', e);
      setState(() {
        _isLoading = false;
        _errorMessage = ErrorUtils.getUserFriendlyMessage(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return ScreenContainer(
      title: l10n.relationship,
      isLoading: _isLoading,
      currentThemeMode: widget.currentThemeMode,
      onThemeChanged: widget.onThemeChanged,
      body:
          _errorMessage.isNotEmpty
              ? _buildErrorView()
              : _buildRelationshipView(),
    );
  }

  Widget _buildErrorView() {
    return ErrorUtils.buildErrorWidget(
      context: context,
      errorMessage: _errorMessage,
      onRetry: _loadRelationshipData,
    );
  }

  Widget _buildRelationshipView() {
    final l10n = AppLocalizations.of(context)!;
    final size = MediaQuery.of(context).size;

    return SingleChildScrollView(
      child: AppContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: StyleConstants.spacingL),
            Text(
              l10n.relationship,
              style: context.theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: StyleConstants.spacingXS),
            Text(
              _relationshipData['relationship']?['name'] ??
                  l10n.viewAndStrengthen,
              style: context.theme.textTheme.bodyLarge?.copyWith(
                color: context.textSecondaryColor,
              ),
            ),
            SizedBox(
              height: StyleConstants.spacingXL + StyleConstants.spacingS,
            ),

            // Partner cards with connection
            ConnectedAvatars(
              userProfile: _currentUserProfile,
              partnerProfile: _partnerProfile,
              avatarSize: 80.0,
              lineWidth: 0.4,
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
                padding: EdgeInsets.all(StyleConstants.spacingXS + 2),
                child: Icon(
                  Icons.favorite,
                  color: Colors.red.shade400,
                  size: 20,
                ),
              ),
            ),

            // Re-invite partner button if partner hasn't signed up
            if (!_isPartnerSignedUp()) ...[
              SizedBox(height: StyleConstants.spacingM),
              ElevatedButton.icon(
                onPressed: _showReInviteDialog,
                icon: const Icon(Icons.person_add),
                label: Text(l10n.reInvitePartner),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor:
                      context.isDarkMode
                          ? Colors.grey.shade700
                          : context.theme.colorScheme.secondary,
                  padding: EdgeInsets.symmetric(
                    horizontal: StyleConstants.spacingL,
                    vertical: StyleConstants.spacingM - 4,
                  ),
                ),
              ),
            ],

            SizedBox(
              height: StyleConstants.spacingXL + StyleConstants.spacingS,
            ),

            // Relationship strength meter
            _buildStrengthMeter(),

            SizedBox(height: StyleConstants.spacingL + StyleConstants.spacingS),

            // Anniversary date
            _buildAnniversarySection(),

            SizedBox(height: StyleConstants.spacingL + StyleConstants.spacingS),

            // Relationship status
            _buildRelationshipStatusSection(),

            SizedBox(height: StyleConstants.spacingL + StyleConstants.spacingS),

            // Relationship insights card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(StyleConstants.radiusL),
              ),
              child: Padding(
                padding: EdgeInsets.all(StyleConstants.spacingM),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          color:
                              context.isDarkMode
                                  ? Colors.amber.shade300
                                  : Colors.amber,
                        ),
                        SizedBox(width: StyleConstants.spacingS),
                        Text(
                          l10n.relationshipInsights,
                          style: context.theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: context.textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: StyleConstants.spacingM),
                    Text(
                      _metrics['insight'] ?? l10n.communicationImproving,
                      style: context.theme.textTheme.bodyMedium?.copyWith(
                        color: context.textSecondaryColor,
                      ),
                    ),
                    SizedBox(height: StyleConstants.spacingM),
                    Row(
                      children: [
                        Expanded(
                          child: _buildInsightMetric(
                            l10n.communication,
                            _metrics['communication'] ?? 70,
                          ),
                        ),
                        SizedBox(width: StyleConstants.spacingM),
                        Expanded(
                          child: _buildInsightMetric(
                            l10n.understanding,
                            _metrics['understanding'] ?? 65,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: StyleConstants.spacingM),
                    ElevatedButton(
                      onPressed: () {
                        NavigationUtils.replace(context, '/ai_chat');
                      },
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            StyleConstants.radiusS,
                          ),
                        ),
                        foregroundColor:
                            context.isDarkMode ? Colors.white : null,
                      ),
                      child: Text(l10n.strengthenWithAiChat),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: StyleConstants.spacingL),

            // Notes section
            _buildNotesSection(),

            SizedBox(height: StyleConstants.spacingL),

            // Common interests section
            if (_getCommonInterests().isNotEmpty)
              _buildCommonInterestsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildPartnerCard(Map<String, dynamic> profile, bool isCurrentUser) {
    final l10n = AppLocalizations.of(context)!;
    final String name =
        profile['full_name'] ??
        profile['username'] ??
        profile['name'] ??
        'Partner';

    // Calculate age from birthdate if available
    int? age;
    if (profile['birthdate'] != null) {
      try {
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
      } catch (e) {
        // Handle date parsing error
        ErrorUtils.logError('RelationshipScreen._buildPartnerCard', e);
      }
    }

    final String description =
        profile['bio'] ??
        'No description for ${isCurrentUser ? 'you' : 'your partner'} has been added yet.';

    // Get profile picture URL if available
    final String pictureUrl = profile['profile_picture_url'] ?? '';

    return Expanded(
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(StyleConstants.radiusL),
        ),
        child: Padding(
          padding: EdgeInsets.all(StyleConstants.spacingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              UserAvatar(
                userId: profile['id'] ?? '',
                imageUrl: pictureUrl,
                name: name,
                size: 80,
              ),
              SizedBox(height: StyleConstants.spacingM - 4),
              Text(
                isCurrentUser ? l10n.you : name,
                style: context.theme.textTheme.titleLarge?.copyWith(
                  color: context.textPrimaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (age != null)
                Text(
                  '$age years',
                  style: context.theme.textTheme.bodyMedium?.copyWith(
                    color: context.textSecondaryColor,
                  ),
                ),
              SizedBox(height: StyleConstants.spacingM - 4),
              Text(
                description,
                textAlign: TextAlign.center,
                style: context.theme.textTheme.bodyMedium,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: StyleConstants.spacingM - 4),
              OutlinedButton(
                onPressed: () {
                  NavigationUtils.replace(
                    context,
                    isCurrentUser ? '/profile' : '/partner_profile',
                  );
                },
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(StyleConstants.radiusS),
                  ),
                  foregroundColor: context.isDarkMode ? Colors.white : null,
                ),
                child: Text(l10n.viewProfile),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStrengthMeter() {
    final l10n = AppLocalizations.of(context)!;
    Color strengthColor;
    String strengthLabel;

    if (_strengthPercentage >= 80) {
      strengthColor = Colors.green;
      strengthLabel = l10n.excellent;
    } else if (_strengthPercentage >= 60) {
      strengthColor = Colors.green.shade300;
      strengthLabel = l10n.good;
    } else if (_strengthPercentage >= 40) {
      strengthColor = Colors.amber;
      strengthLabel = l10n.moderate;
    } else {
      strengthColor = Colors.red.shade300;
      strengthLabel = l10n.needsWork;
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.relationshipStrength,
              style: context.theme.textTheme.titleMedium?.copyWith(
                color: context.textSecondaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '$_strengthPercentage%',
              style: context.theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: strengthColor,
              ),
            ),
          ],
        ),
        SizedBox(height: StyleConstants.spacingS),
        ClipRRect(
          borderRadius: BorderRadius.circular(StyleConstants.radiusS),
          child: LinearProgressIndicator(
            value: _strengthPercentage / 100,
            minHeight: 10,
            backgroundColor:
                context.isDarkMode
                    ? Colors.grey.shade800
                    : Colors.grey.shade300,
            valueColor: AlwaysStoppedAnimation<Color>(strengthColor),
          ),
        ),
        SizedBox(height: StyleConstants.spacingS),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.needsWork,
              style: context.theme.textTheme.bodySmall?.copyWith(
                color: context.isDarkMode ? Colors.grey.shade400 : null,
              ),
            ),
            Text(
              l10n.excellent,
              style: context.theme.textTheme.bodySmall?.copyWith(
                color: context.isDarkMode ? Colors.grey.shade400 : null,
              ),
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
          style: context.theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: StyleConstants.spacingXS),
        ClipRRect(
          borderRadius: BorderRadius.circular(StyleConstants.radiusS / 2),
          child: LinearProgressIndicator(
            value: value / 100,
            minHeight: 6,
            backgroundColor:
                context.isDarkMode
                    ? Colors.grey.shade800
                    : Colors.grey.shade300,
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
        anniversaryDate = DateTime.parse(
          _relationshipData['relationship']['start_date'],
        );
      } catch (e) {
        // Handle date parsing error
        ErrorUtils.logError('RelationshipScreen._buildAnniversarySection', e);
      }
    }

    String formattedDate = 'Not set';
    if (anniversaryDate != null) {
      formattedDate =
          '${anniversaryDate.day}/${anniversaryDate.month}/${anniversaryDate.year}';
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(StyleConstants.radiusL),
      ),
      child: Padding(
        padding: EdgeInsets.all(StyleConstants.spacingM),
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
                      color:
                          context.isDarkMode
                              ? Colors.lightBlueAccent
                              : context.primaryColor,
                    ),
                    SizedBox(width: StyleConstants.spacingS),
                    Text(
                      'Anniversary Date',
                      style: context.theme.textTheme.titleMedium?.copyWith(
                        color: context.textSecondaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(
                    Icons.edit,
                    color: context.isDarkMode ? Colors.white70 : null,
                  ),
                  onPressed: () => _showDatePickerDialog(anniversaryDate),
                ),
              ],
            ),
            SizedBox(height: StyleConstants.spacingM - 4),
            Text(formattedDate, style: context.theme.textTheme.bodyLarge),
            if (anniversaryDate != null) ...[
              SizedBox(height: StyleConstants.spacingS),
              Text(
                _getAnniversaryMessage(anniversaryDate),
                style: context.theme.textTheme.bodyMedium?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: context.isDarkMode ? Colors.white70 : null,
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
    final thisYearAnniversary = DateTime(
      now.year,
      anniversaryDate.month,
      anniversaryDate.day,
    );
    final daysUntilAnniversary = thisYearAnniversary.difference(now).inDays;

    if (daysUntilAnniversary == 0) {
      return "Today is your anniversary! 🎉";
    } else if (daysUntilAnniversary > 0) {
      return "$daysUntilAnniversary days until your anniversary!";
    } else {
      // Anniversary has passed this year
      final nextYearAnniversary = DateTime(
        now.year + 1,
        anniversaryDate.month,
        anniversaryDate.day,
      );
      final daysUntilNextAnniversary =
          nextYearAnniversary.difference(now).inDays;
      return "$daysUntilNextAnniversary days until your next anniversary!";
    }
  }

  Future<void> _showDatePickerDialog(DateTime? initialDate) async {
    final now = DateTime.now();

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate ?? now,
      firstDate: DateTime(1900),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: context.theme.copyWith(
            colorScheme:
                context.isDarkMode
                    ? ColorScheme.dark(
                      primary: context.primaryColor,
                      onPrimary: context.theme.colorScheme.onPrimary,
                      onSurface: context.theme.colorScheme.onSurface,
                      surface: context.theme.colorScheme.surface,
                    )
                    : ColorScheme.light(
                      primary: context.primaryColor,
                      onPrimary: context.theme.colorScheme.onPrimary,
                      onSurface: context.theme.colorScheme.onSurface,
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
    final l10n = AppLocalizations.of(context)!;

    try {
      setState(() {
        _isLoading = true;
      });

      final result = await RelationshipService.updateRelationship({
        'start_date': date.toIso8601String(),
      });

      if (result) {
        if (mounted) {
          ErrorUtils.showErrorSnackBar(context, 'Anniversary date updated!');
        }

        // Refresh relationship data
        await _loadRelationshipData();
      } else {
        throw Exception('Failed to update anniversary date');
      }
    } catch (e) {
      ErrorUtils.logError('RelationshipScreen._saveAnniversaryDate', e);
      if (mounted) {
        ErrorUtils.showErrorSnackBar(
          context,
          ErrorUtils.getUserFriendlyMessage(e),
        );
      }
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
        final additionalData =
            _relationshipData['relationship']['additional_data'];
        if (additionalData['notes'] != null) {
          notes = List<Map<String, dynamic>>.from(additionalData['notes']);
        }
      } catch (e) {
        // Handle parsing error
        ErrorUtils.logError('RelationshipScreen._buildNotesSection', e);
      }
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(StyleConstants.radiusL),
      ),
      child: Padding(
        padding: EdgeInsets.all(StyleConstants.spacingM),
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
                      color:
                          context.isDarkMode
                              ? Colors.lightBlueAccent
                              : context.primaryColor,
                    ),
                    SizedBox(width: StyleConstants.spacingS),
                    Text(
                      'Relationship Notes',
                      style: context.theme.textTheme.titleMedium?.copyWith(
                        color: context.textSecondaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(
                    Icons.add,
                    color: context.isDarkMode ? Colors.white70 : null,
                  ),
                  onPressed: _showAddNoteDialog,
                ),
              ],
            ),
            SizedBox(height: StyleConstants.spacingM - 4),
            if (notes.isEmpty)
              Text(
                'No notes yet. Tap the + button to add your first note.',
                style: context.theme.textTheme.bodyMedium?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: context.isDarkMode ? Colors.white70 : null,
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
                  final formattedDate =
                      dateAdded != null
                          ? '${dateAdded.day}/${dateAdded.month}/${dateAdded.year}'
                          : '';

                  return Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: StyleConstants.spacingS,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              note['title'] ?? 'Note',
                              style: context.theme.textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.delete,
                                size: 18,
                                color:
                                    context.isDarkMode ? Colors.white70 : null,
                              ),
                              onPressed: () => _deleteNote(index),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                        SizedBox(height: StyleConstants.spacingXS),
                        Text(note['content'] ?? ''),
                        SizedBox(height: StyleConstants.spacingXS),
                        if (formattedDate.isNotEmpty)
                          Text(
                            'Added on $formattedDate',
                            style: context.theme.textTheme.bodySmall?.copyWith(
                              fontStyle: FontStyle.italic,
                              color:
                                  context.isDarkMode
                                      ? Colors.grey.shade400
                                      : null,
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
      builder:
          (context) => AlertDialog(
            title: Text(
              'Add New Note',
              style: TextStyle(
                color: context.textPrimaryColor,
                fontWeight: FontWeight.bold,
                fontSize: StyleConstants.fontSizeL,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: 'Title',
                    hintText: 'Enter a title for your note',
                    labelStyle: TextStyle(
                      color: context.isDarkMode ? Colors.grey.shade300 : null,
                    ),
                    hintStyle: TextStyle(
                      color: context.isDarkMode ? Colors.grey.shade400 : null,
                    ),
                  ),
                ),
                SizedBox(height: StyleConstants.spacingM),
                TextField(
                  controller: contentController,
                  decoration: InputDecoration(
                    labelText: 'Content',
                    hintText: 'Write your note here',
                    labelStyle: TextStyle(
                      color: context.isDarkMode ? Colors.grey.shade300 : null,
                    ),
                    hintStyle: TextStyle(
                      color: context.isDarkMode ? Colors.grey.shade400 : null,
                    ),
                  ),
                  maxLines: 5,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => NavigationUtils.goBack(context),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: context.isDarkMode ? Colors.white : null,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  if (contentController.text.trim().isNotEmpty) {
                    NavigationUtils.goBack(context);
                    _saveNote(
                      titleController.text.trim().isEmpty
                          ? 'Note'
                          : titleController.text.trim(),
                      contentController.text.trim(),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  foregroundColor: context.isDarkMode ? Colors.white : null,
                ),
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
        additionalData = Map<String, dynamic>.from(
          _relationshipData['relationship']['additional_data'],
        );
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
        if (mounted) {
          ErrorUtils.showErrorSnackBar(context, 'Note added successfully!');
        }

        // Refresh relationship data
        await _loadRelationshipData();
      } else {
        throw Exception('Failed to add note');
      }
    } catch (e) {
      ErrorUtils.logError('RelationshipScreen._saveNote', e);
      if (mounted) {
        ErrorUtils.showErrorSnackBar(
          context,
          ErrorUtils.getUserFriendlyMessage(e),
        );
      }
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
        _relationshipData['relationship']['additional_data'] ?? {},
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
            if (mounted) {
              ErrorUtils.showErrorSnackBar(
                context,
                'Note deleted successfully!',
              );
            }

            // Refresh relationship data
            await _loadRelationshipData();
          } else {
            throw Exception('Failed to delete note');
          }
        }
      }
    } catch (e) {
      ErrorUtils.logError('RelationshipScreen._deleteNote', e);
      if (mounted) {
        ErrorUtils.showErrorSnackBar(
          context,
          ErrorUtils.getUserFriendlyMessage(e),
        );
      }
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
        borderRadius: BorderRadius.circular(StyleConstants.radiusL),
      ),
      child: Padding(
        padding: EdgeInsets.all(StyleConstants.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.favorite_border,
                  color:
                      context.isDarkMode
                          ? Colors.pink.shade300
                          : Colors.red.shade400,
                ),
                SizedBox(width: StyleConstants.spacingS),
                Text(
                  'Common Interests',
                  style: context.theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: StyleConstants.spacingM - 4),
            Wrap(
              spacing: StyleConstants.spacingS,
              runSpacing: StyleConstants.spacingS,
              children:
                  commonInterests
                      .map(
                        (interest) => Chip(
                          label: Text(
                            interest,
                            style: TextStyle(
                              color:
                                  context.isDarkMode
                                      ? Colors.white
                                      : context
                                          .theme
                                          .colorScheme
                                          .onPrimaryContainer,
                            ),
                          ),
                          backgroundColor:
                              context.theme.colorScheme.primaryContainer,
                        ),
                      )
                      .toList(),
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods

  IconData _getRelationshipIcon() {
    final relationshipType =
        _relationshipData['relationship']?['type'] ?? 'romantic';

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
    final relationshipType =
        _relationshipData['relationship']?['type'] ?? 'romantic';

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

    final userInterestStrings =
        userInterests.map((i) => i.toString().toLowerCase()).toList();
    final partnerInterestStrings =
        partnerInterests.map((i) => i.toString().toLowerCase()).toList();

    return userInterestStrings
        .where((interest) => partnerInterestStrings.contains(interest))
        .toList();
  }

  // Show a snackbar message with retry option
  void _showErrorSnackBar() {
    if (_errorMessage.isNotEmpty && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ErrorUtils.showErrorSnackBar(context, _errorMessage);
      });
    }
  }

  // Check if both partners have signed up
  bool _isPartnerSignedUp() {
    // Use the flag provided by the RelationshipService
    if (_relationshipData.containsKey('is_partner_b_signed_up')) {
      return _relationshipData['is_partner_b_signed_up'] ?? false;
    }

    // Fallback to checking partner_b directly if the flag is not present
    final partnerBId = _relationshipData['relationship']?['partner_b'];
    return partnerBId != null && partnerBId.toString().isNotEmpty;
  }

  // Show re-invite dialog
  Future<void> _showReInviteDialog() async {
    final relationshipId = _relationshipData['relationship']?['id'];

    if (relationshipId == null) {
      ErrorUtils.showErrorSnackBar(context, 'Relationship ID not found.');
      return;
    }

    // Generate the invitation URL using the relationship id
    final String inviteUrl =
        "${kReleaseMode ? 'https://cristhiandalmazzo.github.io/tango_ai_companion' : 'http://localhost:49879'}/signup?relationshipId=$relationshipId";

    // Show the invite URL dialog
    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Invite Your Partner"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Your partner hasn't signed up yet. Share this link with them to join:",
                ),
                SizedBox(height: StyleConstants.spacingM - 4),
                Container(
                  padding: EdgeInsets.all(StyleConstants.spacingM - 4),
                  decoration: BoxDecoration(
                    color:
                        context.isDarkMode
                            ? const Color(0xFF3A3A3A)
                            : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(StyleConstants.radiusS),
                  ),
                  child: SelectableText(
                    inviteUrl,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: context.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: inviteUrl));
                  if (mounted) {
                    ErrorUtils.showErrorSnackBar(
                      context,
                      "Invitation URL copied to clipboard.",
                    );
                  }
                },
                child: const Text("Copy URL"),
              ),
              TextButton(
                onPressed: () => NavigationUtils.goBack(context),
                child: const Text("Close"),
              ),
            ],
          ),
    );
  }

  Widget _buildRelationshipStatusSection() {
    final relationship = _relationshipData['relationship'] ?? {};
    final currentStatus = relationship['status'] ?? 'undefined';
    final l10n = AppLocalizations.of(context)!;

    final statusOptions = {
      'undefined': 'Not Set',
      'dating': 'Dating',
      'engaged': 'Engaged',
      'married': 'Married',
      'partners': 'Partners',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Relationship Status',
          style: context.theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: context.textSecondaryColor,
          ),
        ),
        SizedBox(height: StyleConstants.spacingM),

        Container(
          decoration: BoxDecoration(
            color:
                context.isDarkMode
                    ? const Color(0xFF3A3A3A)
                    : context.theme.cardColor,
            borderRadius: BorderRadius.circular(StyleConstants.radiusM),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: EdgeInsets.symmetric(
            horizontal: StyleConstants.spacingL,
            vertical: StyleConstants.spacingM - 1,
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: currentStatus,
              isExpanded: true,
              icon: Icon(
                Icons.arrow_drop_down,
                color: context.isDarkMode ? Colors.white : null,
              ),
              elevation: 16,
              dropdownColor:
                  context.isDarkMode ? const Color(0xFF2A2A2A) : null,
              style: TextStyle(
                color: context.textPrimaryColor,
                fontSize: StyleConstants.fontSizeM,
              ),
              onChanged: (String? newStatus) {
                if (newStatus != null && newStatus != currentStatus) {
                  _updateRelationshipStatus(newStatus);
                }
              },
              items:
                  statusOptions.entries.map<DropdownMenuItem<String>>((entry) {
                    return DropdownMenuItem<String>(
                      value: entry.key,
                      child: Text(entry.value),
                    );
                  }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _updateRelationshipStatus(String newStatus) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await RelationshipService.updateRelationship({
        'status': newStatus,
      });

      if (result) {
        // Reload the data
        await _loadRelationshipData();

        if (mounted) {
          ErrorUtils.showErrorSnackBar(context, 'Relationship status updated');
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ErrorUtils.logError('RelationshipScreen._updateRelationshipStatus', e);
        ErrorUtils.showErrorSnackBar(
          context,
          ErrorUtils.getUserFriendlyMessage(e),
        );
      }
    }
  }
}
