import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/topic_model.dart';

// Extract a JSON object from an AI text response using heuristics.
// 1) Prefer fenced ```json blocks
// 2) Fallback to any fenced ``` block that looks like JSON
// 3) Scan for the first balanced {...} block that decodes
Map<String, dynamic> extractAiJson(String text) {
  String? candidate;

  // 1) ```json ... ```
  final jsonFence = RegExp(r"```json\s*([\s\S]*?)\s*```", multiLine: true);
  final jsonFenceMatch = jsonFence.firstMatch(text);
  if (jsonFenceMatch != null) {
    candidate = jsonFenceMatch.group(1)!.trim();
  }

  // 2) Any fenced block that looks like JSON
  if (candidate == null) {
    final anyFence = RegExp(r"```\s*([\s\S]*?)\s*```", multiLine: true);
    final anyFenceMatch = anyFence.firstMatch(text);
    if (anyFenceMatch != null) {
      final inner = anyFenceMatch.group(1)!.trim();
      if (inner.startsWith('{') && inner.endsWith('}')) {
        candidate = inner;
      }
    }
  }

  // 3) Balanced braces scan as a last resort
  if (candidate == null) {
    int depth = 0;
    int? startIndex;
    for (int i = 0; i < text.length; i++) {
      final ch = text[i];
      if (ch == '{') {
        depth++;
        startIndex ??= i;
      } else if (ch == '}') {
        depth--;
        if (depth == 0 && startIndex != null) {
          final sub = text.substring(startIndex, i + 1).trim();
          try {
            final decoded = jsonDecode(sub);
            if (decoded is Map<String, dynamic>) {
              return decoded;
            }
          } catch (_) {
            // keep scanning
          }
          startIndex = null;
        }
      }
    }
  }

  if (candidate != null) {
    final cleaned = candidate.replaceAll('\u200b', '');
    final decoded = jsonDecode(cleaned);
    if (decoded is Map<String, dynamic>) return decoded;
  }

  throw Exception('failed to parse AI response');
}

class ChatMessage {
  final String role; // 'user' or 'assistant'
  final String content;

  const ChatMessage({required this.role, required this.content});
}

class AIService {
  // Fixed configuration: hardcoded Gemini key and provider
  static const String _apiKey = "AIzaSyDz8fWmnhu8OJvXmlL7L4ZNQGU6mGiRcHnofda";

  // Always configured since key is bundled
  bool get isConfigured => true;

  Future<AITutorial> generateTutorial(Topic topic) async {
    if (!isConfigured) {
      throw Exception('API key not configured. Please set your API key first.');
    }

    try {
      final String prompt = _buildPrompt(topic);
      final Map<String, dynamic> response = await _callGeminiAPI(prompt);
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
      return await _callGeminiChat(messages);
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
\nRules:\n- You must respond with ONLY valid JSON.\n- Do not include markdown, code fences, or commentary.
''';
  }

  Future<Map<String, dynamic>> _callGeminiAPI(String prompt) async {
    final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$_apiKey');

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
          'responseMimeType': 'application/json'
        }
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final String text = data['candidates'][0]['content']['parts'][0]['text'] as String;
      return extractAiJson(text);
    } else {
      throw Exception('Gemini API error: ${response.statusCode}');
    }
  }

  Future<String> _callGeminiChat(List<ChatMessage> messages) async {
    final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$_apiKey');

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

  // Removed OpenAI-specific methods since provider is fixed to Gemini

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
