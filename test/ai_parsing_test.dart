import 'package:flutter_test/flutter_test.dart';
import 'package:ai_tutor/services/ai_service.dart';

void main() {
  group('extractAiJson', () {
    test('parses fenced json block', () {
      const text = """
Here is your tutorial:
```json
{"summary":"s","steps":[{"stepNumber":1,"title":"t","content":"c"}]}
```
""";
      final json = extractAiJson(text);
      expect(json['summary'], 's');
      expect(json['steps'][0]['stepNumber'], 1);
    });

    test('parses balanced braces when no fences', () {
      const text = "prefix {\n  \"summary\": \"ok\", \n  \"steps\": [{\n    \"stepNumber\": \"2\",\n    \"title\": \"t\",\n    \"content\": \"c\"\n  }]\n}\n suffix";
      final json = extractAiJson(text);
      expect(json['summary'], 'ok');
      expect(json['steps'][0]['stepNumber'].toString(), '2');
    });
  });
}
