import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Service for interacting with Google's Gemini AI via direct HTTP
class GeminiService {
  static const String _apiKeyPref = 'gemini_api_key';
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemma-3-27b-it:generateContent';

  /// Save API key securely
  static Future<void> saveApiKey(String apiKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apiKeyPref, apiKey);
  }

  /// Get stored API key
  static Future<String?> getApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_apiKeyPref);
  }

  /// Check if API key is configured
  static Future<bool> isConfigured() async {
    final apiKey = await getApiKey();
    return apiKey != null && apiKey.isNotEmpty;
  }

  /// Send a message to Gemini with context
  static Future<String> chat({
    required String userMessage,
    required String systemContext,
    List<Map<String, String>>? history,
  }) async {
    final apiKey = await getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      return 'Please configure your API key in settings first.';
    }

    try {
      // Build the prompt with context
      final fullPrompt = '''$systemContext

User: $userMessage''';

      final response = await http.post(
        Uri.parse('$_baseUrl?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': fullPrompt},
              ],
            },
          ],
          'generationConfig': {
            'temperature': 0.7,
            'topK': 40,
            'topP': 0.95,
            'maxOutputTokens': 500,
          },
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'];
        return text?.toString().trim() ??
            'Sorry, I could not generate a response.';
      } else {
        final errorBody = response.body;
        print('Gemini API Error: ${response.statusCode} - $errorBody');
        try {
          final errorJson = jsonDecode(errorBody);
          final message = errorJson['error']?['message'];
          final status = errorJson['error']?['status'];
          return 'API Error ($status): $message\n\n(Try creating a new API Key if quota is exceeded)';
        } catch (e) {
          return 'API Error: ${response.statusCode} - $errorBody';
        }
      }
    } catch (e) {
      print('Gemini API Exception: $e');
      return 'Connection Error: $e';
    }
  }

  /// Stream responses (using non-streaming for simplicity, but simulates typing)
  static Stream<String> chatStream({
    required String userMessage,
    required String systemContext,
    List<Map<String, String>>? history,
  }) async* {
    final response = await chat(
      userMessage: userMessage,
      systemContext: systemContext,
      history: history,
    );

    // Yield the full text directly
    yield response;
  }

  /// Clear API key
  static Future<void> clearApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_apiKeyPref);
  }
}
