import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../widgets/screen_container.dart';
import '../widgets/chat_message_bubble.dart';
import '../widgets/chat_input.dart';
import '../widgets/app_container.dart';
import '../services/edge_functions_service.dart';
import '../services/profile_service.dart';
import '../services/relationship_service.dart';
import '../services/text_processing_service.dart';

class ChatScreen extends StatefulWidget {
  final ThemeMode currentThemeMode;
  final Function(ThemeMode) onThemeChanged;
  
  const ChatScreen({
    super.key,
    this.currentThemeMode = ThemeMode.light,
    required this.onThemeChanged,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  // All user and AI messages (no system message here).
  // Each item: {'role': 'user'/'assistant', 'content': '...'}
  final List<Map<String, String>> _messages = [];

  // For the user's input field.
  final TextEditingController _controller = TextEditingController();
  
  // ScrollController for auto-scrolling to new messages
  final ScrollController _scrollController = ScrollController();
  
  // Flag to track if initial messages have been loaded
  bool _initialMessagesLoaded = false;

  bool _isLoading = false;
  
  // User ID and conversation ID for database storage
  String? _userId;
  String? _conversationId;
  String? _relationshipId;
  
  // Store messages from both user and partner conversations
  List<Map<String, dynamic>> _usersConversation = [];
  List<Map<String, dynamic>> _partnersConversation = [];

  // Profile fields from Supabase
  String _userName = "";
  String _userBio = "";
  List<String> _userInterests = [];
  String _userLocation = "";
  String _userBirthdate = "";
  String _userGender = "";
  String _userOccupation = "";
  String _userEducation = "";
  List<String> _userPersonality = [];

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Initializing...
    _fetchUserProfile().then((_) {
      if (_relationshipId != null) {
        _fetchPartnerProfile();
        _fetchRelationshipData();
        _fetchConversationsForRelationship();
      }
    });
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    super.dispose();
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Try to scroll after dependencies change (like after navigation)
    if (_messages.isNotEmpty) {
      _scheduleScrollToBottom();
    }
  }
  
  @override
  void didUpdateWidget(ChatScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Try to scroll after widget updates
    if (_messages.isNotEmpty) {
      _scheduleScrollToBottom();
    }
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // When app resumes, make sure to scroll to bottom if needed
    if (state == AppLifecycleState.resumed && _messages.isNotEmpty) {
      _scheduleScrollToBottom();
    }
  }
  
  // Schedule scroll with a slight delay to ensure rendering is complete
  void _scheduleScrollToBottom() {
    // First attempt - immediate post frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
    
    // Second attempt - with a slight delay to ensure layout is complete
    Future.delayed(const Duration(milliseconds: 300), () {
      _scrollToBottom();
    });
  }

  /// Fetch all messages for this relationship_id and categorize them
  Future<void> _fetchConversationsForRelationship() async {
    debugPrint('ChatScreen: _fetchConversationsForRelationship() called');
    if (_relationshipId == null) {
      debugPrint('ChatScreen: No relationship ID, skipping fetch');
      return;
    }
    
    try {
      debugPrint('ChatScreen: Querying messages table for relationship: $_relationshipId');
      final response = await Supabase.instance.client
          .from('messages')
          .select('*, profiles:sender_id(name)')
          .eq('relationship_id', _relationshipId!)
          .order('created_at');
      
      if (response != null) {
        _usersConversation.clear();
        _partnersConversation.clear();
        
        debugPrint('ChatScreen: Processing ${response.length} messages from relationship');
        
        // Debug print the first few messages to check their content
        if (response.isNotEmpty) {
          debugPrint('ChatScreen: Sample message data: ${response[0]}');
        }
        
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
        
        debugPrint("ChatScreen: Loaded ${_usersConversation.length} messages from user's conversation");
        debugPrint("ChatScreen: Loaded ${_partnersConversation.length} messages from partner's conversation");
        
        // Update UI with messages from the current conversation
        _loadMessagesIntoUI();
      }
    } catch (e) {
      debugPrint("ChatScreen: Error fetching relationship conversations: $e");
    }
  }
  
  /// Load messages from the database into the UI
  void _loadMessagesIntoUI() {
    debugPrint('ChatScreen: Loading messages into UI');
    
    if (_usersConversation.isEmpty) {
      debugPrint('ChatScreen: No messages to load into UI');
      return;
    }
    
    // Only load messages if we don't already have them in the UI
    // This prevents duplicating messages when refreshing
    if (_messages.isEmpty) {
      // Clear existing messages to prevent duplication
      final List<Map<String, String>> previousMessages = [];
      
      // Sort messages by creation time to ensure proper order
      final sortedMessages = List<Map<String, dynamic>>.from(_usersConversation);
      sortedMessages.sort((a, b) {
        final aTime = a['created_at'] as String? ?? '';
        final bTime = b['created_at'] as String? ?? '';
        return aTime.compareTo(bTime);
      });
      
      debugPrint('ChatScreen: Sorted ${sortedMessages.length} messages by creation time');
      
      for (final message in sortedMessages) {
        final senderType = message['sender_type'] as String;
        final rawText = message['text'] as String;
        final normalizedText = TextProcessingService.normalizeTextPreserveMarkup(rawText);
        
        // Only add if a proper role and content
        if (senderType.isNotEmpty && normalizedText.isNotEmpty) {
          previousMessages.add({
            'role': senderType,
            'content': normalizedText,
          });
          debugPrint('ChatScreen: Added message to UI: ${senderType.substring(0, 1)}: ${normalizedText.substring(0, min(20, normalizedText.length))}...');
        }
      }
      
      debugPrint('ChatScreen: Adding ${previousMessages.length} messages to UI');
      
      if (previousMessages.isNotEmpty) {
        setState(() {
          _messages.addAll(previousMessages);
          _initialMessagesLoaded = true;
        });
        
        // Use multiple approaches to ensure scrolling happens
        _scheduleScrollToBottom();
      }
    }
  }

  /// Scroll to the bottom of the chat
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      try {
        debugPrint('ChatScreen: Scrolling to bottom of chat');
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      } catch (e) {
        debugPrint('ChatScreen: Error scrolling to bottom: $e');
      }
    } else {
      debugPrint('ChatScreen: ScrollController has no clients yet');
    }
  }

  /// Fetch user profile from Supabase. Then greet the user automatically.
  Future<void> _fetchUserProfile() async {
    debugPrint('ChatScreen: _fetchUserProfile() called');
    setState(() => _isLoading = true);

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      debugPrint('ChatScreen: No current user found, returning');
      setState(() => _isLoading = false);
      return;
    }
    
    _userId = user.id;
    debugPrint('ChatScreen: Current user ID: $_userId');

    try {
      debugPrint('ChatScreen: Fetching profile from Supabase');
      final response =
          await Supabase.instance.client
              .from('profiles')
              .select()
              .eq('id', user.id)
              .maybeSingle();

      if (response != null) {
        debugPrint('ChatScreen: Profile fetched successfully');
        setState(() {
          _userName = (response['name'] ?? "") as String;
          _userBio = (response['bio'] ?? "") as String;
          _userLocation = (response['location'] ?? "") as String;
          _userBirthdate = (response['birthdate'] ?? "") as String;
          _userGender = (response['gender'] ?? "") as String;
          _userOccupation = (response['occupation'] ?? "") as String;
          _userEducation = (response['education'] ?? "") as String;
          _conversationId = response['conversation_id'] as String?;
          _relationshipId = response['relationship_id'] as String?;

          final rawInterests = response['interests'];
          if (rawInterests != null && rawInterests is List) {
            _userInterests = rawInterests.map((e) => e.toString()).toList();
          }

          final rawPersonality = response['personality_traits'];
          if (rawPersonality != null && rawPersonality is List) {
            _userPersonality = rawPersonality.map((e) => e.toString()).toList();
          }
        });
        
        // If relationshipId is missing, create a new relationship
        if (_relationshipId == null) {
          debugPrint('ChatScreen: No relationship found, creating new one');
          final newRelationshipId = const Uuid().v4();
          
          // Create a new relationship record
          await Supabase.instance.client
              .from('relationships')
              .insert({
                'id': newRelationshipId,
                'partner_a': user.id,
                'partner_b': null,
                'start_date': DateTime.now().toIso8601String(),
                'status': 'active',
                'additional_data': {
                  'notes': [],
                  'strength': 0,
                  'insights': [],
                }
              });
          
          // Update the profile with the new relationship_id
          await Supabase.instance.client
              .from('profiles')
              .update({'relationship_id': newRelationshipId})
              .eq('id', user.id);
          
          _relationshipId = newRelationshipId;
          debugPrint('ChatScreen: Created new relationship with ID: $_relationshipId');
        }
        
        // Check if conversation_id is null and generate a new one if needed
        if (_conversationId == null) {
          final newConvoId = const Uuid().v4();
          _conversationId = newConvoId;
          
          debugPrint('ChatScreen: Generated new conversation_id: $_conversationId');
          
          // Update the profile with the new conversation_id
          debugPrint('ChatScreen: Updating profile with new conversation_id');
          await Supabase.instance.client
              .from('profiles')
              .update({'conversation_id': newConvoId})
              .eq('id', user.id);
          
          debugPrint('ChatScreen: Created new conversation_id: $newConvoId');
        } else {
          debugPrint('ChatScreen: Using existing conversation_id: $_conversationId');
        }
        
        // Fetch partner profile if we have a relationship
        if (_relationshipId != null) {
          debugPrint('ChatScreen: Fetching partner profile');
          await _fetchPartnerProfile();
        }

        // Once we have the profile, fetch conversations for this relationship_id
        if (_relationshipId != null) {
          debugPrint('ChatScreen: Fetching conversations for relationship_id: $_relationshipId');
          await _fetchConversationsForRelationship();
        }

        // Only greet if we don't have messages
        if (_messages.isEmpty) {
          // Once we have the profile, greet the user automatically.
          debugPrint('ChatScreen: Greeting user (no previous messages found)');
          await _greetUser();
        } else {
          debugPrint('ChatScreen: Skipping greeting as ${_messages.length} messages were loaded');
        }
      }
    } catch (error) {
      debugPrint("ChatScreen: Error fetching user profile: $error");
    }

    setState(() => _isLoading = false);
    debugPrint('ChatScreen: _fetchUserProfile() completed');
  }
  
  /// Fetch partner profile using ProfileService
  Future<void> _fetchPartnerProfile() async {
    debugPrint('ChatScreen: _fetchPartnerProfile() called');
    
    try {
      final partnerProfile = await ProfileService.fetchPartnerProfile();
      
      if (partnerProfile != null) {
        debugPrint('ChatScreen: Partner profile fetched successfully');
        setState(() {
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
        });
        
        debugPrint('ChatScreen: Partner profile data loaded');
      } else {
        debugPrint('ChatScreen: No partner profile found');
      }
    } catch (e) {
      debugPrint('ChatScreen: Error fetching partner profile: $e');
    }
  }

  /// Build the system prompt from the user's profile data.
  /// We'll call this every time we do an AI request.
  String _buildSystemPrompt() {
    debugPrint('ChatScreen: Building system prompt');
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
          debugPrint('ChatScreen: Error parsing anniversary date: $e');
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
          debugPrint('ChatScreen: Error parsing relationship notes: $e');
        }
      }
      
      relationshipContext = "\n\nRelationship context:\n$anniversaryText$notesText";
    }

    final prompt = """
You are Tango, an ai companion specialized in relationships.
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
Tango: """;

    debugPrint('ChatScreen: System prompt built, length: ${prompt.length} characters');
    return prompt;
  }

  /// Send an initial greeting. We'll treat it as if the user said "Hello! I'd like a greeting."
  Future<void> _greetUser() async {
    debugPrint('ChatScreen: _greetUser() called');
    if (_userName.isEmpty) {
      debugPrint('ChatScreen: Username is empty, skipping greeting');
      return;
    }
    if (_conversationId == null) {
      debugPrint('ChatScreen: No conversation ID, skipping greeting');
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      // Refresh relationship data before generating the greeting
      if (_relationshipId != null) {
        debugPrint('ChatScreen: Refreshing relationship data for greeting');
        await _fetchRelationshipData();
      }
      
      debugPrint('ChatScreen: Generating AI greeting');
      final greeting = await _callOpenAI(
        systemContent: _buildSystemPrompt(),
        conversationHistory: _messages,
        userPrompt: "Hello! I'd like a personalized greeting.",
      );

      debugPrint('ChatScreen: Greeting received: ${greeting.length} characters');
      // Add the AI's greeting to the conversation
      setState(() {
        _messages.add({'role': 'assistant', 'content': greeting});
      });
      
      // Scroll to bottom after adding the greeting
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
      
      // Store the AI greeting message in the database
      debugPrint('ChatScreen: Storing AI greeting in database');
      await _storeAiMessage(greeting);
    } catch (e) {
      debugPrint('ChatScreen: Error generating greeting: $e');
      setState(() {
        _messages.add({
          'role': 'assistant',
          'content': "Hello there! I'm Tango, your relationship companion.",
        });
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Called when the user presses send.
  /// We pass the entire conversation plus the system prompt to the AI.
  Future<void> _sendMessage(String userMessage) async {
    debugPrint('ChatScreen: _sendMessage() called with message length: ${userMessage.length}');
    if (userMessage.trim().isEmpty) {
      debugPrint('ChatScreen: Empty message, not sending');
      return;
    }
    
    // Don't allow sending messages while already processing
    if (_isLoading) {
      debugPrint('ChatScreen: Already sending a message, ignoring');
      return;
    }
    
    setState(() {
      _messages.add({'role': 'user', 'content': userMessage});
      _isLoading = true;
    });
    
    // Clear the input field
    _controller.clear();
    
    // Scroll to the bottom after adding user message
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
    
    // Store the user message in the database
    debugPrint('ChatScreen: Storing user message in database');
    await _storeUserMessage(userMessage);
    
    try {
      // Refresh messages for this relationship to get any context from partner conversations
      if (_relationshipId != null) {
        debugPrint('ChatScreen: Refreshing relationship context before AI response');
        await _fetchConversationsForRelationship();
        await _fetchRelationshipData();
      }
      
      debugPrint('ChatScreen: Generating AI response');
      final response = await _callOpenAI(
        systemContent: _buildSystemPrompt(),
        conversationHistory: _messages,
        userPrompt: userMessage,
      );

      debugPrint('ChatScreen: AI response received: ${response.length} characters');
      setState(() {
        _messages.add({'role': 'assistant', 'content': response});
      });
      
      // Scroll to the bottom after adding AI response
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
      
      // Store the AI response in the database
      debugPrint('ChatScreen: Storing AI response in database');
      await _storeAiMessage(response);
      
      // Refresh messages again to include the latest AI response
      if (_relationshipId != null) {
        debugPrint('ChatScreen: Refreshing relationship messages after AI response');
        await _fetchConversationsForRelationship();
      }
    } catch (e) {
      debugPrint("ChatScreen: Error sending message: $e");
      setState(() {
        _messages.add({
          'role': 'assistant',
          'content': "Oops, something went wrong: $e",
        });
        
        // Scroll to bottom even if there's an error
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });
      });
    } finally {
      setState(() => _isLoading = false);
      debugPrint('ChatScreen: _sendMessage() completed');
    }
  }
  
  /// Store user message in the messages table
  Future<void> _storeUserMessage(String content) async {
    debugPrint('ChatScreen: _storeUserMessage() called with content length: ${content.length}');
    if (_conversationId == null || _userId == null || _relationshipId == null) {
      debugPrint("ChatScreen: Missing required fields for storing message: conversationId=$_conversationId, userId=$_userId, relationshipId=$_relationshipId");
      return;
    }

    // Skip storing if relationship_id is 'self' or not a valid UUID
    if (_relationshipId == 'self' || !_isValidUUID(_relationshipId!)) {
      debugPrint('ChatScreen: Invalid relationship ID ($_relationshipId), skipping message storage');
      return;
    }
    
    try {
      final normalizedContent = TextProcessingService.normalizeTextPreserveMarkup(content);
      debugPrint('ChatScreen: Inserting user message into messages table');
      await Supabase.instance.client
          .from('messages')
          .insert({
            'conversation_id': _conversationId,
            'sender_id': _userId,
            'sender_type': 'user',
            'text': normalizedContent,
            'relationship_id': _relationshipId,
          });
      debugPrint("ChatScreen: Stored user message in database");
    } catch (e) {
      debugPrint("ChatScreen: Error storing user message: $e");
    }
  }
  
  /// Store AI message in the messages table
  Future<void> _storeAiMessage(String content) async {
    debugPrint('ChatScreen: _storeAiMessage() called with content length: ${content.length}');
    if (_conversationId == null || _relationshipId == null) {
      debugPrint("ChatScreen: Missing required fields for storing AI message: conversationId=$_conversationId, relationshipId=$_relationshipId");
      return;
    }

    // Skip storing if relationship_id is 'self' or not a valid UUID
    if (_relationshipId == 'self' || !_isValidUUID(_relationshipId!)) {
      debugPrint('ChatScreen: Invalid relationship ID ($_relationshipId), skipping message storage');
      return;
    }
    
    try {
      final normalizedContent = TextProcessingService.normalizeTextPreserveMarkup(content);
      debugPrint('ChatScreen: Inserting AI message into messages table');
      await Supabase.instance.client
          .from('messages')
          .insert({
            'conversation_id': _conversationId,
            'sender_id': null, // AI has no user ID
            'sender_type': 'assistant',
            'text': normalizedContent,
            'relationship_id': _relationshipId,
          });
      debugPrint("ChatScreen: Stored AI message in database");
    } catch (e) {
      debugPrint("ChatScreen: Error storing AI message: $e");
    }
  }
  
  /// Optional: Fetch previous messages for this conversation
  Future<void> _fetchPreviousMessages() async {
    debugPrint('ChatScreen: _fetchPreviousMessages() called');
    if (_conversationId == null) {
      debugPrint('ChatScreen: No conversation ID, skipping message fetch');
      return;
    }
    
    try {
      debugPrint('ChatScreen: Querying messages table for conversation: $_conversationId');
      final response = await Supabase.instance.client
          .from('messages')
          .select()
          .eq('conversation_id', _conversationId!)
          .order('created_at');
      
      if (response != null) {
        final List<Map<String, String>> previousMessages = [];
        
        debugPrint('ChatScreen: Processing ${response.length} previous messages');
        for (final message in response) {
          final senderType = message['sender_type'] as String;
          final rawText = message['text'] as String;
          final normalizedText = TextProcessingService.normalizeTextPreserveMarkup(rawText);
          
          previousMessages.add({
            'role': senderType,
            'content': normalizedText,
          });
        }
        
        setState(() {
          _messages.addAll(previousMessages);
        });
        
        debugPrint("ChatScreen: Loaded ${previousMessages.length} previous messages");
      }
    } catch (e) {
      debugPrint("ChatScreen: Error fetching previous messages: $e");
    }
  }

  /// Makes the actual call to OpenAI's Chat Completion endpoint.
  Future<String> _callOpenAI({
    required String systemContent,
    required List<Map<String, String>> conversationHistory,
    required String userPrompt,
  }) async {
    debugPrint('ChatScreen: _callOpenAI() called');
    debugPrint('ChatScreen: System content length: ${systemContent.length}');
    debugPrint('ChatScreen: Conversation history: ${conversationHistory.length} messages');
    debugPrint('ChatScreen: User prompt length: ${userPrompt.length}');
    
    try {
      debugPrint('ChatScreen: Calling edge function service');
      // Use the EdgeFunctionsService to call the Supabase edge function
      // No text processing is applied - raw responses are returned
      final response = await EdgeFunctionsService.callChatApiWithContext(
        systemContent: systemContent,
        conversationHistory: conversationHistory,
        userPrompt: userPrompt,
        model: 'gpt-4o-mini', // Specify the model parameter
      );
      
      debugPrint('ChatScreen: Received response from edge function, length: ${response.length}');
      return response;
    } catch (e) {
      debugPrint("ChatScreen: Error calling chat API: $e");
      throw Exception("Error calling chat API: $e");
    }
  }

  Future<void> _fetchRelationshipData() async {
    debugPrint('ChatScreen: _fetchRelationshipData() called');
    
    if (_relationshipId == null) {
      debugPrint('ChatScreen: No relationship ID, skipping relationship data fetch');
      return;
    }
    
    try {
      final data = await RelationshipService.fetchRelationshipData();
      
      setState(() {
        _relationshipData = data;
      });
      
      debugPrint('ChatScreen: Relationship data loaded');
    } catch (e) {
      debugPrint('ChatScreen: Error fetching relationship data: $e');
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

  @override
  Widget build(BuildContext context) {
    // Use a more robust approach to ensure scrolling after build
    if (_initialMessagesLoaded) {
      _scheduleScrollToBottom();
    }
    
    return ScreenContainer(
      title: _userName.isEmpty ? "AI Chat" : "Chat with $_userName",
      centerTitle: false,
      currentThemeMode: widget.currentThemeMode,
      onThemeChanged: widget.onThemeChanged,
      body: Column(
        children: [
          Expanded(
            child: _isLoading && _messages.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _buildChatMessages(),
          ),
          if (_isLoading && _messages.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: ChatMessageBubble(
                  message: '',
                  isUser: false,
                  isTyping: true,
                ),
              ),
            ),
          ChatInput(
            controller: _controller,
            onSend: _sendMessage,
            isLoading: _isLoading,
          ),
        ],
      ),
    );
  }

  Widget _buildChatMessages() {
    if (_messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'Start your conversation',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return AppContainer(
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        itemCount: _messages.length,
        physics: const AlwaysScrollableScrollPhysics(),
        itemBuilder: (context, index) {
          final role = _messages[index]['role']!;
          final rawText = _messages[index]['content'] ?? "";
          final text = TextProcessingService.normalizeTextPreserveMarkup(rawText);
          final isUser = (role == 'user');

          return ChatMessageBubble(
            message: text,
            isUser: isUser,
          );
        },
      ),
    );
  }
}
