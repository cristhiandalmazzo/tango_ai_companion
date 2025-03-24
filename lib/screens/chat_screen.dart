import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../openai_config.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  
  // Conversation history that we'll send to the Chat endpoint.
  // Each entry is a map with 'role' and 'content'.
  // We begin with an empty list. We'll add a system message once we fetch the user's profile.
  List<Map<String, String>> _messages = [];
  
  bool _isLoading = false;
  String? _userName;        // We'll store the user's name from their profile.
  String? _userBio;         // Example additional field.

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  /// Fetch user profile from Supabase. Adjust fields as needed.
  Future<void> _fetchUserProfile() async {
    setState(() => _isLoading = true);

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      // If not logged in, handle accordingly (e.g., navigate to login).
      setState(() => _isLoading = false);
      return;
    }

    try {
      final response = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (response != null) {
        setState(() {
          _userName = response['name'] as String?;
          _userBio  = response['bio'] as String?;
        });
        
        // Construct the system message with user profile data.
        _messages.insert(0, {
          'role': 'system',
          'content': _buildSystemPrompt(
            userName: _userName ?? 'User',
            userBio:  _userBio ?? '',
          ),
        });
      }
    } catch (error) {
      // Handle error (e.g., show a SnackBar).
      debugPrint("Error fetching user profile: $error");
    }

    setState(() => _isLoading = false);
  }

  /// Build a system message that sets the overall context. 
  /// You can include user name, bio, location, interests, or anything relevant.
  String _buildSystemPrompt({required String userName, required String userBio}) {
    return """
You are a helpful AI assistant. 
The user’s name is $userName. 
They have this bio: "$userBio". 
Greet them warmly, keep track of previous conversation context, and provide helpful answers.
""";
  }

  /// Send the user's message to OpenAI, get the AI's response, and update the conversation.
  Future<void> _sendMessage(String userMessage) async {
    if (userMessage.trim().isEmpty) return;

    setState(() {
      // Add the user's message to the conversation history.
      _messages.add({'role': 'user', 'content': userMessage});
      _isLoading = true;
    });
    
    try {
      // Build request to the Chat Completion endpoint.
      final url = Uri.parse("https://api.openai.com/v1/chat/completions");
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $openAIApiKey",
        },
        body: jsonEncode({
          "model": "gpt-3.5-turbo",
          "messages": _messages, // Our conversation so far.
          "max_tokens": 150,
          "temperature": 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final String aiContent = data["choices"][0]["message"]["content"].trim();
        
        setState(() {
          // Add assistant's response to the conversation
          _messages.add({'role': 'assistant', 'content': aiContent});
        });
      } else {
        // Show error
        debugPrint("OpenAI Error: ${response.statusCode} - ${response.body}");
        setState(() {
          _messages.add({
            'role': 'assistant',
            'content': "Sorry, something went wrong. (${response.statusCode})"
          });
        });
      }
    } catch (e) {
      debugPrint("Error sending message: $e");
      setState(() {
        _messages.add({
          'role': 'assistant',
          'content': "An error occurred: $e",
        });
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_userName == null ? "AI Chat" : "Chat with $_userName"),
      ),
      body: _isLoading && _messages.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Chat history list
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      final role = msg['role'];
                      final content = msg['content'];

                      // Display differently if it's user or assistant
                      final isUser = (role == 'user');
                      final alignment = isUser ? Alignment.centerRight : Alignment.centerLeft;
                      final color = isUser ? Colors.blue[100] : Colors.grey[300];
                      
                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 6.0),
                        padding: const EdgeInsets.all(10.0),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        alignment: alignment,
                        child: Text(content ?? ""),
                      );
                    },
                  ),
                ),
                // Input field + send button
                if (!_isLoading) ...[
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
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
                            final text = _controller.text;
                            _controller.clear();
                            _sendMessage(text);
                          },
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  // Show a simple indicator or disable input if you want.
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text("Thinking..."),
                  ),
                ],
              ],
            ),
    );
  }
}
