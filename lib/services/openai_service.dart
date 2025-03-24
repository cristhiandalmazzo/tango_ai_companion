import 'dart:convert';
import 'package:http/http.dart' as http;
import '../openai_config.dart';

/// A reusable function to call the OpenAI Chat Completion endpoint.
/// 
/// [systemContent] typically holds your system instruction, which can include 
/// the user's profile data (name, bio, etc.).
/// [conversationHistory] is a list of messages that represent the ongoing chat:
///   e.g., [{'role': 'user', 'content': 'Hi'}, {'role': 'assistant', 'content': 'Hello!'}]
/// [userPrompt] is the latest user query or message.
/// 
/// The function returns the AI's response as a [String].
/// If there's an error, it throws an exception or returns an error message.
Future<String> getAICompletion({
  required String systemContent,
  required List<Map<String, String>> conversationHistory,
  required String userPrompt,
  String model = "gpt-4o-mini",
  int maxTokens = 150,
  double temperature = 0.7,
}) async {
  // Construct the entire messages array: 
  // 1) system message with profile context
  // 2) conversationHistory 
  // 3) final user message
  final messages = [
    {'role': 'system', 'content': systemContent},
    ...conversationHistory, // previous user & assistant messages
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
      "model": model,
      "messages": messages,
      "max_tokens": maxTokens,
      "temperature": temperature,
    }),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    final String aiContent =
        data["choices"][0]["message"]["content"].trim();
    return aiContent;
  } else {
    // Optionally throw an error, or return a fallback message.
    final errMsg = "OpenAI Error ${response.statusCode}: ${response.body}";
    throw Exception(errMsg);
  }
}
