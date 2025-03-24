import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

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

  /// Build the system prompt from the user’s profile data.
  /// We'll call this every time we do an AI request.
  String _buildSystemPrompt() {
    final interestsText = _userInterests.join(", ");
    final personalityText = _userPersonality.join(", ");

    return """
You are a helpful AI assistant. 
The user’s name is $_userName.
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
    final openAIApiKey = dotenv.env['OPENAI_API_KEY'] ?? '';
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
          .replaceAll('’', "'")
          .replaceAll('‘', "'")
          .replaceAll('“', '"')
          .replaceAll('”', '"');
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
    return Scaffold(
      appBar: AppBar(
        title: Text(_userName.isEmpty ? "AI Chat" : "Chat with $_userName"),
      ),
      body:
          _isLoading && _messages.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  // The conversation
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final role = _messages[index]['role']!;
                        final text = _messages[index]['content'] ?? "";

                        final isUser = (role == 'user');
                        final alignment =
                            isUser
                                ? Alignment.centerRight
                                : Alignment.centerLeft;
                        final color =
                            isUser ? Colors.blue[100] : Colors.grey[300];

                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 6.0),
                          padding: const EdgeInsets.all(12.0),
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          alignment: alignment,
                          child: Text(text),
                        );
                      },
                    ),
                  ),
                  // Input field
                  if (!_isLoading)
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8.0,
                        vertical: 8.0,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              decoration: const InputDecoration(
                                hintText: "Type your message...",
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.send),
                            onPressed: () {
                              final userText = _controller.text;
                              _controller.clear();
                              _sendMessage(userText);
                            },
                          ),
                        ],
                      ),
                    )
                  else
                    // Indicate the AI is responding
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text("Thinking..."),
                    ),
                ],
              ),
    );
  }
}
