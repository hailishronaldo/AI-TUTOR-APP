import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/topic_model.dart';

class ChatMessage {
  final String role; // 'user' or 'assistant'
  final String content;

  const ChatMessage({required this.role, required this.content});
}

class AIService {
  String? _apiKey;
  String? _apiProvider;

  void setApiKey(String apiKey, String provider) {
    _apiKey = apiKey;
    _apiProvider = provider;
  }

  bool get isConfigured => _apiKey != null && _apiProvider != null;

  Future<AITutorial> generateTutorial(Topic topic) async {
    if (!isConfigured) {
      throw Exception('API key not configured. Please set your API key first.');
    }

    try {
      final String prompt = _buildPrompt(topic);
      final Map<String, dynamic> response;

      if (_apiProvider == 'gemini') {
        response = await _callGeminiAPI(prompt);
      } else if (_apiProvider == 'chatgpt') {
        response = await _callChatGPTAPI(prompt);
      } else {
        throw Exception('Unsupported AI provider: $_apiProvider');
      }

      return _parseResponse(response, topic);
    } catch (e) {
      throw Exception('Failed to generate tutorial: $e');
    }
  }

  // Simple chat API for AI tab
  Future<String> sendChatResponse(List<ChatMessage> messages) async {
    if (!isConfigured) {
      throw Exception('API key not configured. Please set your API key first.');
    }
    try {
      if (_apiProvider == 'gemini') {
        return await _callGeminiChat(messages);
      } else if (_apiProvider == 'chatgpt') {
        return await _callChatGPTChat(messages);
      } else {
        throw Exception('Unsupported AI provider: $_apiProvider');
      }
    } catch (e) {
      throw Exception('Failed to get chat response: $e');
    }
  }

  String _buildPrompt(Topic topic) {
    return '''
Create a comprehensive step-by-step tutorial for the topic: "${topic.title}"

Description: ${topic.description}
Difficulty: ${topic.difficulty}
Estimated time: ${topic.estimatedMinutes} minutes

Please provide:
1. A brief summary of what the learner will achieve
2. 5-7 detailed steps, each with:
   - A clear title
   - Detailed explanation
   - Code examples (if applicable)
   - Key concepts to understand

Format the response as JSON with this structure:
{
  "summary": "Brief overview of the tutorial",
  "steps": [
    {
      "stepNumber": 1,
      "title": "Step title",
      "content": "Detailed explanation",
      "codeExample": "code here (optional)",
      "explanation": "Why this matters"
    }
  ]
}
''';
  }

  Future<Map<String, dynamic>> _callGeminiAPI(String prompt) async {
    final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key=$_apiKey');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': prompt}
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.7,
          'maxOutputTokens': 2048,
        }
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final text = data['candidates'][0]['content']['parts'][0]['text'];

      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(text);
      if (jsonMatch != null) {
        return jsonDecode(jsonMatch.group(0)!);
      }
      throw Exception('Failed to parse AI response');
    } else {
      throw Exception('Gemini API error: ${response.statusCode}');
    }
  }

  Future<String> _callGeminiChat(List<ChatMessage> messages) async {
    final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key=$_apiKey');

    // Map messages to Gemini's content format
    final contents = messages.map((m) => {
          'role': m.role == 'assistant' ? 'model' : 'user',
          'parts': [
            {'text': m.content}
          ]
        }).toList();

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': contents,
        'generationConfig': {
          'temperature': 0.7,
          'maxOutputTokens': 1024,
        }
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final text = data['candidates'][0]['content']['parts'][0]['text'];
      return text as String;
    } else {
      throw Exception('Gemini API error: ${response.statusCode} ${response.body}');
    }
  }

  Future<Map<String, dynamic>> _callChatGPTAPI(String prompt) async {
    final url = Uri.parse('https://api.openai.com/v1/chat/completions');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      },
      body: jsonEncode({
        'model': 'gpt-3.5-turbo',
        'messages': [
          {
            'role': 'system',
            'content':
                'You are an expert tutor. Create structured, educational content in JSON format.'
          },
          {'role': 'user', 'content': prompt}
        ],
        'temperature': 0.7,
        'max_tokens': 2048,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final text = data['choices'][0]['message']['content'];

      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(text);
      if (jsonMatch != null) {
        return jsonDecode(jsonMatch.group(0)!);
      }
      throw Exception('Failed to parse AI response');
    } else {
      throw Exception('ChatGPT API error: ${response.statusCode}');
    }
  }

  Future<String> _callChatGPTChat(List<ChatMessage> messages) async {
    final url = Uri.parse('https://api.openai.com/v1/chat/completions');

    final openAIMessages = <Map<String, String>>[
      {
        'role': 'system',
        'content': 'You are a helpful AI tutor. Answer clearly and concisely.'
      },
      ...messages.map((m) => {
            'role': m.role, // 'user' | 'assistant'
            'content': m.content,
          }),
    ];

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      },
      body: jsonEncode({
        'model': 'gpt-3.5-turbo',
        'messages': openAIMessages,
        'temperature': 0.7,
        'max_tokens': 512,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final text = data['choices'][0]['message']['content'];
      return text as String;
    } else {
      throw Exception('ChatGPT API error: ${response.statusCode} ${response.body}');
    }
  }

  AITutorial _parseResponse(Map<String, dynamic> response, Topic topic) {
    return AITutorial(
      topicId: topic.id,
      topicTitle: topic.title,
      steps: (response['steps'] as List)
          .map((step) => TutorialStep.fromJson(step as Map<String, dynamic>))
          .toList(),
      summary: response['summary'] as String,
      generatedAt: DateTime.now(),
    );
  }
}

final aiService = AIService();
