import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'edge_functions_service.dart';
import 'text_processing_service.dart';
import 'profile_service.dart';
import 'relationship_service.dart';

/// A service that automatically sends AI-generated messages at regular intervals
class AIAutoMessengerService {
  // Singleton instance
  static AIAutoMessengerService? _instance;
  
  // Supabase client 
  final SupabaseClient _supabaseClient;
  
  // Chat details
  final String _conversationId;
  final String _relationshipId;
  
  // Timer for scheduling messages
  Timer? _messageTimer;
  
  // Interval between messages (in minutes)
  int _intervalMinutes;
  
  // AI prompt for message generation
  String _aiPrompt;
  
  // Active status
  bool _isActive = false;
  
  // Store messages from both user and partner conversations (for context)
  List<Map<String, dynamic>> _usersConversation = [];
  List<Map<String, dynamic>> _partnersConversation = [];
  
  // Profile fields for context
  String _userName = "";
  String _userBio = "";
  List<String> _userInterests = [];
  String _userLocation = "";
  String _userBirthdate = "";
  String _userGender = "";
  String _userOccupation = "";
  String _userEducation = "";
  List<String> _userPersonality = [];
  String _languagePreference = "";
  
  // Partner profile fields
  String _partnerName = "";
  String _partnerBio = "";
  List<String> _partnerInterests = [];
  String _partnerLocation = "";
  String _partnerBirthdate = "";
  String _partnerGender = "";
  String _partnerOccupation = "";
  String _partnerEducation = "";
  List<String> _partnerPersonality = [];
  
  // Relationship data
  Map<String, dynamic>? _relationshipData;
  
  // Private constructor for singleton
  AIAutoMessengerService._({
    required String conversationId,
    required String relationshipId,
    required int intervalMinutes,
    required String aiPrompt,
  }) : _conversationId = conversationId,
       _relationshipId = relationshipId,
       _intervalMinutes = intervalMinutes,
       _aiPrompt = aiPrompt,
       _supabaseClient = Supabase.instance.client;

  /// Factory method to get or create instance
  static Future<AIAutoMessengerService> getInstance({
    required String conversationId,
    required String relationshipId,
    int intervalMinutes = 25,
    String? aiPrompt,
  }) async {
    // If no instance or if there's a new conversation/relationship, create a new instance
    if (_instance == null || 
        _instance!._conversationId != conversationId || 
        _instance!._relationshipId != relationshipId) {
      
      // Get user's bio to use as part of the prompt if no custom prompt is provided
      String finalPrompt = aiPrompt ?? "";
      
      if (finalPrompt.isEmpty) {
        try {
          final profile = await ProfileService.fetchProfile();
          final userBio = profile['bio'] as String? ?? "";
          final userName = profile['name'] as String? ?? "user";
          
          if (userBio.isNotEmpty) {
            finalPrompt = """
You're roleplaying as a person with this bio: "$userBio"
Your name is $userName.
Generate a natural message that sounds like a real person sharing a thought, 
asking a question, or continuing a conversation based on this bio.
Keep it casual, friendly, and around 1-3 sentences.
Don't introduce yourself or use AI disclaimers.
Write in first person as if you are this person.
""";
          } else {
            // Fallback if no bio
            finalPrompt = """
You are a helpful assistant simulating a person in a chat. 
Generate a natural message that sounds like a real person sharing an interesting 
thought, asking a question, or continuing a conversation. 
Keep it casual, friendly, and around 1-3 sentences.
Don't introduce yourself or use AI disclaimers.
""";
          }
        } catch (e) {
          debugPrint("[AIAutoMessenger] Error getting user bio: $e");
          // Fallback prompt
          finalPrompt = """
You are a helpful assistant simulating a person in a chat. 
Generate a natural message that sounds like a real person sharing an interesting 
thought, asking a question, or continuing a conversation. 
Keep it casual, friendly, and around 1-3 sentences.
Don't introduce yourself or use AI disclaimers.
""";
        }
      }
      
      // Create new instance
      _instance = AIAutoMessengerService._(
        conversationId: conversationId,
        relationshipId: relationshipId,
        intervalMinutes: intervalMinutes,
        aiPrompt: finalPrompt,
      );
      
      // Load profile data for context
      await _instance!._loadProfileData();
      
      // Load existing conversation messages for context
      await _instance!._fetchConversationsForRelationship();
      
      debugPrint("[AIAutoMessenger] New instance created");
    } else if (intervalMinutes != _instance!._intervalMinutes) {
      // If only the interval has changed, update it
      _instance!._intervalMinutes = intervalMinutes;
      
      // If service is active, restart with new interval
      if (_instance!._isActive) {
        _instance!.stop();
        _instance!.start();
      }
      
      debugPrint("[AIAutoMessenger] Updated interval to $intervalMinutes minutes");
    }
    
    return _instance!;
  }
  
  /// Start sending messages at the specified interval
  void start() {
    final user = _supabaseClient.auth.currentUser;
    if (user == null) {
      debugPrint("[AIAutoMessenger] Cannot start: No authenticated user");
      return;
    }
    
    if (_messageTimer != null) {
      debugPrint("[AIAutoMessenger] Auto-messenger already running");
      return;
    }
    
    _isActive = true;
    debugPrint("[AIAutoMessenger] Starting auto-messenger (interval: $_intervalMinutes minutes)");
    
    // Send first message immediately
    _generateAndSendMessage();
    
    // Schedule subsequent messages
    _messageTimer = Timer.periodic(
      Duration(minutes: _intervalMinutes),
      (_) => _generateAndSendMessage(),
    );
  }
  
  /// Stop sending messages
  void stop() {
    if (_messageTimer != null) {
      _messageTimer!.cancel();
      _messageTimer = null;
      _isActive = false;
      debugPrint("[AIAutoMessenger] Auto-messenger stopped");
    }
  }
  
  /// Check if the service is currently active
  bool get isActive => _isActive;
  
  /// Get the current interval in minutes
  int get intervalMinutes => _intervalMinutes;
  
  /// Set a new interval in minutes
  void setIntervalMinutes(int minutes) {
    if (minutes < 1) {
      debugPrint("[AIAutoMessenger] Invalid interval: $minutes minutes. Minimum is 1 minute.");
      return;
    }
    
    if (_intervalMinutes != minutes) {
      debugPrint("[AIAutoMessenger] Changing interval from $_intervalMinutes to $minutes minutes");
      _intervalMinutes = minutes;
      
      // If active, restart with new interval
      if (_isActive) {
        stop();
        start();
      }
    }
  }
  
  /// Set a new AI prompt
  void setAiPrompt(String prompt) {
    if (prompt.isNotEmpty && _aiPrompt != prompt) {
      debugPrint("[AIAutoMessenger] Changing AI prompt");
      _aiPrompt = prompt;
    }
  }
  
  /// Load user and partner profile data for context
  Future<void> _loadProfileData() async {
    debugPrint("[AIAutoMessenger] Loading profile data for context");
    
    try {
      // Get current user
      final user = _supabaseClient.auth.currentUser;
      if (user == null) {
        debugPrint("[AIAutoMessenger] No authenticated user found");
        return;
      }
      
      // Load user profile
      final profile = await ProfileService.fetchProfile();
      if (profile != null) {
        _userName = (profile['name'] ?? "") as String;
        _userBio = (profile['bio'] ?? "") as String;
        _userLocation = (profile['location'] ?? "") as String;
        _userBirthdate = (profile['birthdate'] ?? "") as String;
        _userGender = (profile['gender'] ?? "") as String;
        _userOccupation = (profile['occupation'] ?? "") as String;
        _userEducation = (profile['education'] ?? "") as String;
        _languagePreference = profile['language_preference'] as String? ?? "";
        
        final rawInterests = profile['interests'];
        if (rawInterests != null && rawInterests is List) {
          _userInterests = rawInterests.map((e) => e.toString()).toList();
        }
        
        final rawPersonality = profile['personality_traits'];
        if (rawPersonality != null && rawPersonality is List) {
          _userPersonality = rawPersonality.map((e) => e.toString()).toList();
        }
      }
      
      // Load partner profile
      final partnerProfile = await ProfileService.fetchPartnerProfile();
      if (partnerProfile != null) {
        _partnerName = (partnerProfile['name'] ?? "") as String;
        _partnerBio = (partnerProfile['bio'] ?? "") as String;
        _partnerLocation = (partnerProfile['location'] ?? "") as String;
        _partnerBirthdate = (partnerProfile['birthdate'] ?? "") as String;
        _partnerGender = (partnerProfile['gender'] ?? "") as String;
        _partnerOccupation = (partnerProfile['occupation'] ?? "") as String;
        _partnerEducation = (partnerProfile['education'] ?? "") as String;
        
        final rawInterests = partnerProfile['interests'];
        if (rawInterests != null && rawInterests is List) {
          _partnerInterests = rawInterests.map((e) => e.toString()).toList();
        }
        
        final rawPersonality = partnerProfile['personality_traits'];
        if (rawPersonality != null && rawPersonality is List) {
          _partnerPersonality = rawPersonality.map((e) => e.toString()).toList();
        }
      }
      
      // Load relationship data
      if (_relationshipId != null) {
        _relationshipData = await RelationshipService.fetchRelationshipData();
      }
      
      debugPrint("[AIAutoMessenger] Profile data loaded successfully");
    } catch (e) {
      debugPrint("[AIAutoMessenger] Error loading profile data: $e");
    }
  }
  
  /// Fetch all messages for this relationship_id and categorize them
  Future<void> _fetchConversationsForRelationship() async {
    debugPrint('[AIAutoMessenger] Fetching conversations for relationship: $_relationshipId');
    if (_relationshipId == null) {
      debugPrint('[AIAutoMessenger] No relationship ID, skipping fetch');
      return;
    }

    try {
      final response = await _supabaseClient
          .from('messages')
          .select('*, profiles:sender_id(name)')
          .eq('relationship_id', _relationshipId)
          .order('created_at');

      if (response != null) {
        _usersConversation.clear();
        _partnersConversation.clear();

        for (final message in response) {
          // Convert to Map<String, dynamic> to store with profile details
          final messageWithDetails = Map<String, dynamic>.from(message);

          // If this message belongs to current conversation_id, add to user's conversation
          if (message['conversation_id'] == _conversationId) {
            _usersConversation.add(messageWithDetails);
          } else {
            // Otherwise it's from the partner's conversation
            _partnersConversation.add(messageWithDetails);
          }
        }

        debugPrint("[AIAutoMessenger] Loaded ${_usersConversation.length} messages from user's conversation");
        debugPrint("[AIAutoMessenger] Loaded ${_partnersConversation.length} messages from partner's conversation");
      }
    } catch (e) {
      debugPrint("[AIAutoMessenger] Error fetching relationship conversations: $e");
    }
  }
  
  /// Build the system prompt from the user's profile data.
  String _buildSystemPrompt() {
    debugPrint('[AIAutoMessenger] Building system prompt');
    final interestsText = _userInterests.join(", ");
    final personalityText = _userPersonality.join(", ");

    // Format previous conversations to include in the system prompt
    String previousConversationsText = "";

    if (_usersConversation.isNotEmpty) {
      previousConversationsText += "\n\nUser's previous conversation (most recent):\n";
      // Include all messages instead of just the last 5
      final recentUserMessages = _usersConversation;

      for (final message in recentUserMessages) {
        final sender = message['sender_type'] == 'user' 
            ? _userName 
            : 'AI Assistant';
        previousConversationsText += "$sender: ${message['text']}\n";
      }
    }

    if (_partnersConversation.isNotEmpty) {
      previousConversationsText += "\n\nPartner's previous conversation (most recent):\n";
      // Include all messages instead of just the last 5
      final recentPartnerMessages = _partnersConversation;

      for (final message in recentPartnerMessages) {
        final senderName = message['profiles'] != null
            ? message['profiles']['name'] ?? 'Partner'
            : 'Partner';
        final sender = message['sender_type'] == 'user' 
            ? senderName 
            : 'AI Assistant';
        previousConversationsText += "$sender: ${message['text']}\n";
      }
    }

    // Build the partner profile section if available
    String partnerProfileText = "";
    if (_partnerName.isNotEmpty) {
      final partnerInterestsText = _partnerInterests.join(", ");
      final partnerPersonalityText = _partnerPersonality.join(", ");

      partnerProfileText = """
\nThe user has a partner named $_partnerName.
Partner bio: $_partnerBio
Partner location: $_partnerLocation
Partner birthdate: $_partnerBirthdate, identifies as $_partnerGender
Partner occupation: $_partnerOccupation
Partner education: $_partnerEducation
Partner interests: $partnerInterestsText
Partner personality traits: $partnerPersonalityText
""";
    }

    // Fetch relationship data for additional context
    String relationshipContext = "";
    if (_relationshipData != null && _relationshipData!.isNotEmpty) {
      // Anniversary date
      String anniversaryText = "";
      if (_relationshipData!['relationship']?['start_date'] != null) {
        try {
          final anniversaryDate = DateTime.parse(_relationshipData!['relationship']['start_date']);
          final now = DateTime.now();
          final difference = now.difference(anniversaryDate);
          final years = difference.inDays ~/ 365;
          final months = (difference.inDays % 365) ~/ 30;

          if (years > 0) {
            anniversaryText = "The couple has been together for $years years";
            if (months > 0) {
              anniversaryText += " and $months months";
            }
            anniversaryText += ". ";
          } else if (months > 0) {
            anniversaryText = "The couple has been together for $months months. ";
          } else {
            anniversaryText = "The couple has been together for ${difference.inDays} days. ";
          }

          anniversaryText += "Their anniversary date is ${anniversaryDate.day}/${anniversaryDate.month}/${anniversaryDate.year}. ";

          // Calculate days until next anniversary
          final nextAnniversary = DateTime(now.year, anniversaryDate.month, anniversaryDate.day);
          if (nextAnniversary.isBefore(now)) {
            final nextYearAnniversary = DateTime(now.year + 1, anniversaryDate.month, anniversaryDate.day);
            final daysUntil = nextYearAnniversary.difference(now).inDays;
            anniversaryText += "Their next anniversary is in $daysUntil days.";
          } else {
            final daysUntil = nextAnniversary.difference(now).inDays;
            anniversaryText += "Their anniversary this year is in $daysUntil days.";
          }
        } catch (e) {
          // Handle date parsing error
          debugPrint('[AIAutoMessenger] Error parsing anniversary date: $e');
        }
      }

      // Relationship notes
      String notesText = "";
      if (_relationshipData!['relationship']?['additional_data'] != null) {
        try {
          final additionalData = _relationshipData!['relationship']['additional_data'];
          if (additionalData['notes'] != null && additionalData['notes'] is List && additionalData['notes'].isNotEmpty) {
            notesText = "\n\nRelationship notes:";
            final notes = List<Map<String, dynamic>>.from(additionalData['notes']);

            // Sort notes by date (newest first)
            notes.sort((a, b) {
              if (a['date'] == null || b['date'] == null) return 0;
              return DateTime.parse(b['date']).compareTo(DateTime.parse(a['date']));
            });

            for (final note in notes) {
              final title = note['title'] ?? 'Note';
              final content = note['content'] ?? '';
              final dateStr = note['date'] ?? '';

              String formattedDate = '';
              if (dateStr.isNotEmpty) {
                try {
                  final date = DateTime.parse(dateStr);
                  formattedDate = ' (${date.day}/${date.month}/${date.year})';
                } catch (e) {
                  // Skip date formatting on error
                }
              }

              notesText += "\n- $title$formattedDate: $content";
            }
          }
        } catch (e) {
          // Handle parsing error
          debugPrint('[AIAutoMessenger] Error parsing relationship notes: $e');
        }
      }

      relationshipContext = "\n\nRelationship context:\n$anniversaryText$notesText";
    }

    final prompt = """
You are Tango, an AI companion specialized in relationships.
You are talking to a user and their partner, but in separate conversations. 
You are currently talking to $_userName.
They have this bio: $_userBio
They live in $_userLocation. 
They were born on $_userBirthdate, identified as $_userGender.
They work as $_userOccupation and studied $_userEducation.
They have these interests: $interestsText
They have these personality traits: $personalityText.
$partnerProfileText
$relationshipContext
For context, here are the previous conversations: $previousConversationsText
IMPORTANT: 
- Your responses must use only standard ASCII apostrophes (') and not fancy or encoded apostrophes (â, ä).
- Always use standard UTF-8 encoding for all text, especially for contractions like "it's", "that's", etc.
- You can use markdown formatting in your responses (bold, italic, lists, etc.) as the app supports markdown rendering.
- The user's language preference is $_languagePreference, so you should use that language for your responses unless the user explicitly asks you to use another language.
Tango: """;

    debugPrint('[AIAutoMessenger] System prompt built, length: ${prompt.length} characters');
    return prompt;
  }
  
  /// Generate a message using the AI service and send it, then get a response from Tango
  Future<void> _generateAndSendMessage() async {
    try {
      debugPrint("[AIAutoMessenger] Generating AI message using user's bio");
      
      // First refresh conversations to ensure we have latest context
      await _fetchConversationsForRelationship();
      
      // Build user context-aware prompt instead of using simple bio prompt
      final userSystemPrompt = """
You are simulating a person in a chat conversation. You are roleplaying as $_userName.
You have this bio: $_userBio
You live in $_userLocation. 
You were born on $_userBirthdate, identified as $_userGender.
You work as $_userOccupation and studied $_userEducation.
Your interests include: ${_userInterests.join(", ")}
Your personality traits include: ${_userPersonality.join(", ")}

${_partnerName.isNotEmpty ? "You are talking with $_partnerName who has this bio: $_partnerBio" : "You are talking with an AI companion."}

IMPORTANT:
- Generate a natural message that sounds like a real person sharing a thought, asking a question, or continuing a conversation.
- Keep it casual, friendly, and around 1-3 sentences.
- Don't introduce yourself or use AI disclaimers.
- Write in first person as if you are this person.
- Take into account the conversation history below to maintain a fluid and natural conversation.
- If there's ongoing conversation, follow up appropriately - don't change topics abruptly.
- Your message should sound like it's from a real person, not an AI.
""";
      
      // Convert conversation history to format for API
      List<Map<String, String>> userConversationHistory = [];
      
      // Add recent messages from the conversation history to provide context
      if (_usersConversation.isNotEmpty) {
        // Get the most recent messages (up to 10) to avoid token limits
        final recentMessages = _usersConversation.length > 10 
            ? _usersConversation.sublist(_usersConversation.length - 10) 
            : _usersConversation;
            
        for (final message in recentMessages) {
          final role = message['sender_type'] == 'user' ? 'user' : 'assistant';
          final content = message['text'] as String;
          userConversationHistory.add({
            'role': role,
            'content': content,
          });
        }
      }
      
      // Generate the user's auto-message with context awareness
      final userMessage = await EdgeFunctionsService.callChatApiWithContext(
        systemContent: userSystemPrompt,
        conversationHistory: userConversationHistory,
        userPrompt: "Continue the conversation naturally. If this is a new conversation, start with something interesting.",
        model: 'gpt-4o-mini',
      );
      
      debugPrint("[AIAutoMessenger] Generated context-aware auto-message: ${_truncateText(userMessage, 50)}");
      
      // Send the auto-message as the user
      await _sendUserMessage(userMessage);
      
      // Convert current conversation to the format expected by OpenAI
      List<Map<String, String>> conversationHistory = [];
      for (final message in _usersConversation) {
        final role = message['sender_type'] == 'user' ? 'user' : 'assistant';
        final content = message['text'] as String;
        conversationHistory.add({
          'role': role,
          'content': content,
        });
      }
      
      // Now get an AI response to the user's auto-message
      debugPrint("[AIAutoMessenger] Getting Tango's response to auto-message");
      final aiResponse = await _callOpenAI(
        systemContent: _buildSystemPrompt(),
        conversationHistory: conversationHistory,
        userPrompt: userMessage,
      );
      
      debugPrint("[AIAutoMessenger] Tango's response received: ${_truncateText(aiResponse, 50)}");
      
      // Store the AI's response in the database
      await _storeAiMessage(aiResponse);
      
      // Refresh conversations again to include this complete exchange in future context
      await _fetchConversationsForRelationship();
      
    } catch (e) {
      debugPrint("[AIAutoMessenger] Error in message generation cycle: $e");
    }
  }
  
  /// Call OpenAI's Chat Completion endpoint via edge function
  Future<String> _callOpenAI({
    required String systemContent,
    required List<Map<String, String>> conversationHistory,
    required String userPrompt,
  }) async {
    try {
      debugPrint('[AIAutoMessenger] Calling edge function for AI response');
      
      // Use the EdgeFunctionsService to call the Supabase edge function
      final response = await EdgeFunctionsService.callChatApiWithContext(
        systemContent: systemContent,
        conversationHistory: conversationHistory,
        userPrompt: userPrompt,
        model: 'gpt-4o-mini', // Use the same model as the chat screen
      );
      
      return response;
    } catch (e) {
      debugPrint("[AIAutoMessenger] Error calling chat API: $e");
      throw Exception("Error calling chat API: $e");
    }
  }
  
  /// Send a user message to the database
  Future<void> _sendUserMessage(String content) async {
    if (!_isValidUUID(_relationshipId)) {
      debugPrint("[AIAutoMessenger] Invalid relationship ID ($_relationshipId), skipping message storage");
      return;
    }
    
    try {
      final user = _supabaseClient.auth.currentUser;
      if (user == null) {
        debugPrint("[AIAutoMessenger] No authenticated user found, cannot send message");
        stop(); // Stop the service since we're not authenticated
        return;
      }
      
      final userId = user.id;
      debugPrint("[AIAutoMessenger] Sending message as user: $userId");
      
      // Normalize content 
      final normalizedContent = TextProcessingService.normalizeTextPreserveMarkup(content);
      
      // Insert the message into the database
      await _supabaseClient
          .from('messages')
          .insert({
            'conversation_id': _conversationId,
            'sender_id': userId,
            'sender_type': 'user',
            'text': normalizedContent,
            'relationship_id': _relationshipId,
          });
          
      debugPrint("[AIAutoMessenger] User message sent successfully");
    } catch (e) {
      debugPrint("[AIAutoMessenger] Error sending user message: $e");
    }
  }
  
  /// Store AI message in the messages table
  Future<void> _storeAiMessage(String content) async {
    if (!_isValidUUID(_relationshipId)) {
      debugPrint("[AIAutoMessenger] Invalid relationship ID ($_relationshipId), skipping message storage");
      return;
    }
    
    try {
      // Normalize content 
      final normalizedContent = TextProcessingService.normalizeTextPreserveMarkup(content);
      
      // Insert the message into the database
      await _supabaseClient
          .from('messages')
          .insert({
            'conversation_id': _conversationId,
            'sender_id': null, // AI has no user ID
            'sender_type': 'assistant',
            'text': normalizedContent,
            'relationship_id': _relationshipId,
          });
          
      debugPrint("[AIAutoMessenger] AI message sent successfully");
    } catch (e) {
      debugPrint("[AIAutoMessenger] Error sending AI message: $e");
    }
  }
  
  /// Helper method to check if a string is a valid UUID
  bool _isValidUUID(String uuid) {
    try {
      // Check if the string matches the UUID format
      final uuidPattern = RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
        caseSensitive: false,
      );
      return uuidPattern.hasMatch(uuid);
    } catch (e) {
      return false;
    }
  }
  
  /// Helper function to truncate text for display
  String _truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }
} 