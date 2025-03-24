import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/screen_container.dart';
import '../widgets/chat_message_bubble.dart';
import '../widgets/chat_input.dart';

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

class _ChatScreenState extends State<ChatScreen> {
  // All user and AI messages (no system message here).
  // Each item: {'role': 'user'/'assistant', 'content': '...'}
  final List<Map<String, String>> _messages = [];

  // For the user's input field.
  final TextEditingController _controller = TextEditingController();

  bool _isLoading = false;

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
    _fetchUserProfile();
  }

  /// Fetch user profile from Supabase. Then greet the user automatically.
  Future<void> _fetchUserProfile() async {
    setState(() => _isLoading = true);

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final response =
          await Supabase.instance.client
              .from('profiles')
              .select()
              .eq('id', user.id)
              .maybeSingle();

      if (response != null) {
        setState(() {
          _userName = (response['name'] ?? "") as String;
          _userBio = (response['bio'] ?? "") as String;
          _userLocation = (response['location'] ?? "") as String;
          _userBirthdate = (response['birthdate'] ?? "") as String;
          _userGender = (response['gender'] ?? "") as String;
          _userOccupation = (response['occupation'] ?? "") as String;
          _userEducation = (response['education'] ?? "") as String;

          final rawInterests = response['interests'];
          if (rawInterests != null && rawInterests is List) {
            _userInterests = rawInterests.map((e) => e.toString()).toList();
          }

          final rawPersonality = response['personality_traits'];
          if (rawPersonality != null && rawPersonality is List) {
            _userPersonality = rawPersonality.map((e) => e.toString()).toList();
          }
        });

        // Once we have the profile, greet the user automatically.
        await _greetUser();
      }
    } catch (error) {
      debugPrint("Error fetching user profile: $error");
    }

    setState(() => _isLoading = false);
  }

  /// Build the system prompt from the user's profile data.
  /// We'll call this every time we do an AI request.
  String _buildSystemPrompt() {
    final interestsText = _userInterests.join(", ");
    final personalityText = _userPersonality.join(", ");

    return """
You are a helpful AI assistant. 
The user's name is $_userName.
They have this bio: $_userBio
They live in $_userLocation. 
They were born on $_userBirthdate, identified as $_userGender.
They work as $_userOccupation and studied $_userEducation.
They have these interests: $interestsText
They have these personality traits: $personalityText

Greet them warmly, keep track of previous conversation context, and provide helpful answers.
""";
  }

  /// Send an initial greeting. We'll treat it as if the user said "Hello! I'd like a greeting."
  Future<void> _greetUser() async {
    if (_userName.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final greeting = await _callOpenAI(
        systemContent: _buildSystemPrompt(),
        conversationHistory: _messages,
        userPrompt: "Hello! I'd like a personalized greeting.",
      );

      // Add the AI's greeting to the conversation
      setState(() {
        _messages.add({'role': 'assistant', 'content': greeting});
      });
    } catch (e) {
      debugPrint("Error greeting user: $e");
      setState(() {
        _messages.add({
          'role': 'assistant',
          'content': "An error occurred while greeting you: $e",
        });
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Called when the user presses send.
  /// We pass the entire conversation plus the system prompt to the AI.
  Future<void> _sendMessage(String userMessage) async {
    if (userMessage.trim().isEmpty) return;

    setState(() {
      _messages.add({'role': 'user', 'content': userMessage});
      _isLoading = true;
    });

    try {
      final response = await _callOpenAI(
        systemContent: _buildSystemPrompt(),
        conversationHistory: _messages,
        userPrompt: userMessage,
      );

      setState(() {
        _messages.add({'role': 'assistant', 'content': response});
      });
    } catch (e) {
      debugPrint("Error sending message: $e");
      setState(() {
        _messages.add({
          'role': 'assistant',
          'content': "Oops, something went wrong: $e",
        });
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Makes the actual call to OpenAI's Chat Completion endpoint.
  Future<String> _callOpenAI({
    required String systemContent,
    required List<Map<String, String>> conversationHistory,
    required String userPrompt,
  }) async {
    const openAIApiKey = String.fromEnvironment('OPENAI_API_KEY', defaultValue: '');
    if (openAIApiKey.isEmpty) {
      debugPrint("OPENAI_API_KEY is empty!");
    }
    // Convert conversationHistory to the correct format.
    // (We already have role: user/assistant, content: ...).
    // We'll inject the system message first, then the existing conversation, then the new user message.
    final messages = <Map<String, String>>[
      {'role': 'system', 'content': systemContent},
      ...conversationHistory, // user & assistant
      {'role': 'user', 'content': userPrompt},
    ];

    final url = Uri.parse("https://api.openai.com/v1/chat/completions");
    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $openAIApiKey",
      },
      body: jsonEncode({
        "model": "gpt-4o-mini",
        "messages": messages,
        "max_tokens": 150,
        "temperature": 0.7,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final String aiContent = data["choices"][0]["message"]["content"].trim();
      String cleanedText = aiContent
          .replaceAll(''', "'")
          .replaceAll(''', "'")
          .replaceAll('"', '"')
          .replaceAll('"', '"');
      String normalizeText(String text) {
        // For example, remove or replace all non-ASCII characters:
        return text.replaceAll(RegExp(r'[^\x00-\x7F]+'), '');
      }

      return normalizeText(cleanedText);
    } else {
      throw Exception("OpenAI Error ${response.statusCode}: ${response.body}");
    }
  }

  @override
  Widget build(BuildContext context) {
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
      padding: const EdgeInsets.all(16.0),
      itemCount: _messages.length,
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
