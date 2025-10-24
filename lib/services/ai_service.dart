import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/topic_model.dart';

// Extract a JSON object from an AI text response using layered heuristics.
// Strategy:
// 0) Try to parse the whole text directly (Gemini often returns plain JSON)
// 1) Prefer fenced ```json blocks
// 2) Fallback to any fenced ``` block that looks like JSON
// 3) Scan for the first balanced {...} block that decodes (ignoring braces in strings)
Map<String, dynamic> extractAiJson(String text) {
  Map<String, dynamic>? tryDecode(String input) {
    try {
      final cleaned = input
          .replaceAll('\u200b', '') // zero width space
          .replaceAll('\ufeff', '') // BOM
          .trim();
      final dynamic decoded = jsonDecode(_stripTrailingCommas(cleaned));
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {}
    return null;
  }

  // 0) Direct attempt
  final direct = tryDecode(text);
  if (direct != null) return direct;

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
      if (inner.startsWith('{')) {
        candidate = inner;
      }
    }
  }

  if (candidate != null) {
    final parsed = tryDecode(candidate);
    if (parsed != null) return parsed;
  }

  // 3) Balanced braces scan that ignores braces within JSON strings
  {
    int depth = 0;
    int? startIndex;
    bool inString = false;
    bool isEscaped = false;

    for (int i = 0; i < text.length; i++) {
      final String ch = text[i];
      if (inString) {
        if (isEscaped) {
          isEscaped = false; // current char is escaped, skip special handling
        } else if (ch == '\\') {
          isEscaped = true;
        } else if (ch == '"') {
          inString = false;
        }
        continue; // ignore braces while inside strings
      }

      if (ch == '"') {
        inString = true;
        isEscaped = false;
        continue;
      }

      if (ch == '{') {
        depth++;
        startIndex ??= i;
      } else if (ch == '}') {
        depth--;
        if (depth == 0 && startIndex != null) {
          final sub = text.substring(startIndex, i + 1);
          final parsed = tryDecode(sub);
          if (parsed != null) return parsed;
          startIndex = null; // continue scanning for the next candidate
        }
      }
    }
  }

  throw Exception('failed to parse AI response');
}

// Remove trailing commas before } or ] which occasionally slip into LLM JSON
String _stripTrailingCommas(String input) {
  return input.replaceAll(RegExp(r",\s*(?=[}\]])"), '');
}

class ChatMessage {
  final String role; // 'user' or 'assistant'
  final String content;

  const ChatMessage({required this.role, required this.content});
}

class AIService {
  // Read from compile-time or runtime env; no hardcoded default
  static const String _apiKey = String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');

  bool get isConfigured => _apiKey.isNotEmpty;

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
\nRules:\n- You must respond with ONLY valid JSON.\n- Do not include markdown, code fences, or commentary.\n- Keep each field under ~80 words to avoid truncation.
''';
  }

  Future<Map<String, dynamic>> _callGeminiAPI(String prompt) async {
    // Try with a generous token budget first; retry on truncation.
    final first = await _postToGemini(prompt, maxTokens: 4096);
    final firstFinish = _readFinishReason(first);
    try {
      final String firstText = first['candidates'][0]['content']['parts'][0]['text'] as String;
      return extractAiJson(firstText);
    } catch (e) {
      // If the model hit token limit or we couldn't parse, try again with larger budget and concise prompt
      if (firstFinish == 'MAX_TOKENS') {
        final concisePrompt = _buildPromptConcise(prompt);
        final retry = await _postToGemini(concisePrompt, maxTokens: 8192);
        final String retryText = retry['candidates'][0]['content']['parts'][0]['text'] as String;
        return extractAiJson(retryText);
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _postToGemini(String prompt, {required int maxTokens}) async {
    final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$_apiKey');

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
          'maxOutputTokens': maxTokens,
          'responseMimeType': 'application/json'
        }
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Gemini API error: ${response.statusCode}');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  String? _readFinishReason(Map<String, dynamic> data) {
    try {
      return data['candidates'][0]['finishReason'] as String?;
    } catch (_) {
      return null;
    }
  }

  // Add a more concise version of the prompt for retries when the
  // model hits token limits.
  String _buildPromptConcise(String originalPrompt) {
    return "${originalPrompt}\n\nCONCISE MODE:\n- Use at most 5 steps.\n- Keep each string under 60 words.\n- Return ONLY JSON, no markdown.";
  }

  Future<String> _callGeminiChat(List<ChatMessage> messages) async {
    final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$_apiKey');

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
