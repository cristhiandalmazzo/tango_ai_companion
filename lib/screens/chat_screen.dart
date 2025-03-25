import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../widgets/screen_container.dart';
import '../widgets/chat_message_bubble.dart';
import '../widgets/chat_input.dart';
import '../services/edge_functions_service.dart';

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fetchUserProfile();
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
        final text = message['text'] as String;
        
        // Only add if a proper role and content
        if (senderType.isNotEmpty && text.isNotEmpty) {
          previousMessages.add({
            'role': senderType,
            'content': text,
          });
          debugPrint('ChatScreen: Added message to UI: ${senderType.substring(0, 1)}: ${text.substring(0, min(20, text.length))}...');
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
        
        // If relationshipId is missing, use a default value
        if (_relationshipId == null) {
          _relationshipId = 'self'; // Default value for personal chats
          debugPrint('ChatScreen: Using default relationship_id: $_relationshipId');
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
      // Only include the last 5 messages to avoid overloading the prompt
      final recentUserMessages = _usersConversation.length > 5 
          ? _usersConversation.sublist(_usersConversation.length - 5) 
          : _usersConversation;
          
      for (final message in recentUserMessages) {
        final sender = message['sender_type'] == 'user' 
            ? _userName 
            : 'AI Assistant';
        previousConversationsText += "$sender: ${message['text']}\n";
      }
    }
    
    if (_partnersConversation.isNotEmpty) {
      previousConversationsText += "\n\nPartner's previous conversation (most recent):\n";
      // Only include the last 5 messages to avoid overloading the prompt
      final recentPartnerMessages = _partnersConversation.length > 5 
          ? _partnersConversation.sublist(_partnersConversation.length - 5) 
          : _partnersConversation;
          
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

    final prompt = """
You are a helpful AI assistant. 
The user's name is $_userName.
They have this bio: $_userBio
They live in $_userLocation. 
They were born on $_userBirthdate, identified as $_userGender.
They work as $_userOccupation and studied $_userEducation.
They have these interests: $interestsText
They have these personality traits: $personalityText.
$previousConversationsText

Greet them warmly, keep track of previous conversation context, and provide helpful answers.
Use the previous conversations for context when appropriate.
""";

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
    debugPrint('ChatScreen: Generating AI greeting');
    try {
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
      debugPrint("ChatScreen: Error greeting user: $e");
      setState(() {
        _messages.add({
          'role': 'assistant',
          'content': "An error occurred while greeting you: $e",
        });
        
        // Scroll to bottom even if there's an error
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });
      });
    } finally {
      setState(() => _isLoading = false);
      debugPrint('ChatScreen: _greetUser() completed');
    }
  }

  /// Called when the user presses send.
  /// We pass the entire conversation plus the system prompt to the AI.
  Future<void> _sendMessage(String userMessage) async {
    debugPrint('ChatScreen: _sendMessage() called with message length: ${userMessage.length}');
    if (userMessage.trim().isEmpty) {
      debugPrint('ChatScreen: Message is empty, ignoring');
      return;
    }
    if (_conversationId == null) {
      debugPrint('ChatScreen: No conversation ID, ignoring message');
      return;
    }

    setState(() {
      _messages.add({'role': 'user', 'content': userMessage});
      _isLoading = true;
    });
    
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
        debugPrint('ChatScreen: Refreshing relationship conversations before AI response');
        await _fetchConversationsForRelationship();
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
        debugPrint('ChatScreen: Refreshing relationship conversations after AI response');
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
    
    try {
      debugPrint('ChatScreen: Inserting user message into messages table');
      await Supabase.instance.client
          .from('messages')
          .insert({
            'conversation_id': _conversationId,
            'sender_id': _userId,
            'sender_type': 'user',
            'text': content,
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
    
    try {
      debugPrint('ChatScreen: Inserting AI message into messages table');
      await Supabase.instance.client
          .from('messages')
          .insert({
            'conversation_id': _conversationId,
            'sender_id': null, // AI has no user ID
            'sender_type': 'assistant',
            'text': content,
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
          final text = message['text'] as String;
          
          previousMessages.add({
            'role': senderType,
            'content': text,
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

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16.0),
      itemCount: _messages.length,
      physics: const AlwaysScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final role = _messages[index]['role']!;
        final text = _messages[index]['content'] ?? "";
        final isUser = (role == 'user');

        return ChatMessageBubble(
          message: text,
          isUser: isUser,
        );
      },
    );
  }
}
