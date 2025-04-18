import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../supabase_config.dart';
import '../utils/error_utils.dart';

class EdgeFunctionsService {
  /// Base URL for Supabase edge functions
  static const String _baseUrl = 'https://aabjcortlfrmexxdrqjw.supabase.co/functions/v1';
  
  /// Default model to use if none specified
  static const String defaultModel = 'gpt-3.5-turbo';
  
  /// Calls the chat-api edge function to get AI responses
  static Future<String> callChatApi({
    required String userMessage,
    String model = defaultModel,
  }) async {
    final url = Uri.parse('$_baseUrl/chat-api');
    
    debugPrint('EdgeFunctionsService: callChatApi() called');
    debugPrint('EdgeFunctionsService: Using model: $model');
    debugPrint('EdgeFunctionsService: Message length: ${userMessage.length} characters');
    
    try {
      debugPrint('EdgeFunctionsService: Sending request to $url');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $supabaseAnonKey',
        },
        body: jsonEncode({
          'userMessage': userMessage,
          'model': model,
        }),
      );
      
      debugPrint('EdgeFunctionsService: Received response with status code: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        debugPrint('EdgeFunctionsService: Successfully received response');
        
        final data = jsonDecode(response.body);
        debugPrint('EdgeFunctionsService: Response data: ${response.body}');
        
        // Check if the expected data structure exists
        if (data == null) {
          const errorMsg = 'Response data is null';
          ErrorUtils.logError('EdgeFunctionsService.callChatApi', errorMsg);
          throw Exception(errorMsg);
        }
        
        if (!data.containsKey('choices') || 
            data['choices'] == null || 
            data['choices'].isEmpty) {
          final errorMsg = 'Response missing choices field: ${response.body}';
          ErrorUtils.logError('EdgeFunctionsService.callChatApi', errorMsg);
          throw Exception(errorMsg);
        }
        
        final choice = data['choices'][0];
        if (choice == null || !choice.containsKey('message') || choice['message'] == null) {
          final errorMsg = 'Response missing message field: ${response.body}';
          ErrorUtils.logError('EdgeFunctionsService.callChatApi', errorMsg);
          throw Exception(errorMsg);
        }
        
        final message = choice['message'];
        if (!message.containsKey('content') || message['content'] == null) {
          final errorMsg = 'Response missing content field: ${response.body}';
          ErrorUtils.logError('EdgeFunctionsService.callChatApi', errorMsg);
          throw Exception(errorMsg);
        }
        
        final rawText = message['content'].trim();
        
        debugPrint('EdgeFunctionsService: Response length: ${rawText.length} characters');
        
        // Apply minimal encoding fix for the â character issue
        final processedText = _fixEncodingIssues(rawText);
        
        debugPrint('EdgeFunctionsService: Text processed and returning response');
        return processedText;
      } else {
        final errorMsg = 'Error ${response.statusCode}: ${response.body}';
        ErrorUtils.logError('EdgeFunctionsService.callChatApi', errorMsg);
        throw Exception(errorMsg);
      }
    } catch (e) {
      ErrorUtils.logError('EdgeFunctionsService.callChatApi', e);
      throw Exception('Failed to call chat API: ${ErrorUtils.getUserFriendlyMessage(e)}');
    }
  }
  
  /// Allows calling the edge function with conversation history and system prompt
  static Future<String> callChatApiWithContext({
    required String systemContent,
    required List<Map<String, String>> conversationHistory,
    required String userPrompt,
    String model = defaultModel,
  }) async {
    // Use the baseUrl to ensure we're calling the edge function, not OpenAI directly
    final url = Uri.parse('$_baseUrl/chat-api');
    
    debugPrint('EdgeFunctionsService: callChatApiWithContext() called');
    debugPrint('EdgeFunctionsService: Using model: $model');
    debugPrint('EdgeFunctionsService: System content length: ${systemContent.length} characters');
    debugPrint('EdgeFunctionsService: Conversation history: ${conversationHistory.length} messages');
    debugPrint('EdgeFunctionsService: User prompt length: ${userPrompt.length} characters');
    
    // Build the complete message that includes system content and conversation history
    final messages = [
      {'role': 'system', 'content': systemContent},
      ...conversationHistory,
      {'role': 'user', 'content': userPrompt},
    ];
    
    try {
      debugPrint('EdgeFunctionsService: Sending request to $url');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $supabaseAnonKey',
        },
        body: jsonEncode({
          'messages': messages,
          'model': model,
        }),
      );
      
      debugPrint('EdgeFunctionsService: Received response with status code: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        debugPrint('EdgeFunctionsService: Successfully received response');
        
        final data = jsonDecode(response.body);
        debugPrint('EdgeFunctionsService: Response data: ${response.body}');
        
        // Check if the expected data structure exists
        if (data == null) {
          const errorMsg = 'Response data is null';
          ErrorUtils.logError('EdgeFunctionsService.callChatApiWithContext', errorMsg);
          throw Exception(errorMsg);
        }
        
        if (!data.containsKey('choices') || 
            data['choices'] == null || 
            data['choices'].isEmpty) {
          final errorMsg = 'Response missing choices field: ${response.body}';
          ErrorUtils.logError('EdgeFunctionsService.callChatApiWithContext', errorMsg);
          throw Exception(errorMsg);
        }
        
        final choice = data['choices'][0];
        if (choice == null || !choice.containsKey('message') || choice['message'] == null) {
          final errorMsg = 'Response missing message field: ${response.body}';
          ErrorUtils.logError('EdgeFunctionsService.callChatApiWithContext', errorMsg);
          throw Exception(errorMsg);
        }
        
        final message = choice['message'];
        if (!message.containsKey('content') || message['content'] == null) {
          final errorMsg = 'Response missing content field: ${response.body}';
          ErrorUtils.logError('EdgeFunctionsService.callChatApiWithContext', errorMsg);
          throw Exception(errorMsg);
        }
        
        final rawText = message['content'].trim();
        
        debugPrint('EdgeFunctionsService: Response length: ${rawText.length} characters');
        
        // Apply minimal encoding fix for the â character issue
        final processedText = _fixEncodingIssues(rawText);
        
        debugPrint('EdgeFunctionsService: Text processed and returning response');
        return processedText;
      } else {
        final errorMsg = 'Error ${response.statusCode}: ${response.body}';
        ErrorUtils.logError('EdgeFunctionsService.callChatApiWithContext', errorMsg);
        throw Exception(errorMsg);
      }
    } catch (e) {
      ErrorUtils.logError('EdgeFunctionsService.callChatApiWithContext', e);
      throw Exception('Failed to call chat API: ${ErrorUtils.getUserFriendlyMessage(e)}');
    }
  }
  
  /// Applies minimal fixes for common encoding issues while preserving most of the original text
  static String _fixEncodingIssues(String text) {
    debugPrint('EdgeFunctionsService: _fixEncodingIssues() called for text of length ${text.length}');
    
    // Only fix the problematic 'â' character that's causing issues
    // This affects contractions (it's, there's) and spaces between words
    
    // Handle common contraction patterns
    var result = text
        .replaceAll('âs', "'s")  // Fix it's, that's, etc.
        .replaceAll('âre', "'re")  // Fix you're, they're, etc.
        .replaceAll('âve', "'ve")  // Fix I've, you've, etc.
        .replaceAll('âll', "'ll")  // Fix I'll, we'll, etc.
        .replaceAll('ât', "'t")    // Fix don't, isn't, etc.
        .replaceAll('âd', "'d");   // Fix I'd, you'd, etc.
    
    // Fix cases where 'â' appears between words (should be a space or dash)
    // Use a regex to find patterns like "wordâword" and replace with "word—word"
    result = result.replaceAllMapped(
      RegExp(r'(\w)â(\w)'),
      (match) => '${match.group(1)}—${match.group(2)}'
    );
    
    int replacements = text.length - result.length;
    debugPrint('EdgeFunctionsService: Fixed ${replacements.abs()} encoding issues');
    
    return result;
  }
} 