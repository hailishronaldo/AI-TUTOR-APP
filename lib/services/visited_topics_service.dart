import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class VisitedTopicsService {
  static const String _prefsKey = 'visited_topics_v1';
  static const int _maxItems = 20;

  static Future<void> recordVisit(String topicId) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_prefsKey);
    List<dynamic> entries = raw != null ? (jsonDecode(raw) as List<dynamic>) : <dynamic>[];

    // Normalize entries to list of maps with id and ts
    entries = entries.where((e) => e is Map && e['id'] != null && e['ts'] != null).toList();

    // Remove existing entry for this id
    entries.removeWhere((e) => e['id'] == topicId);

    // Add new entry at the top
    entries.insert(0, <String, dynamic>{
      'id': topicId,
      'ts': DateTime.now().millisecondsSinceEpoch,
    });

    // Enforce max size
    if (entries.length > _maxItems) {
      entries = entries.sublist(0, _maxItems);
    }

    await prefs.setString(_prefsKey, jsonEncode(entries));
  }

  static Future<List<String>> getVisitedIdsOrdered() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_prefsKey);
    if (raw == null) return <String>[];
    try {
      final List<dynamic> entries = jsonDecode(raw) as List<dynamic>;
      final List<Map<String, dynamic>> normalized = entries
          .where((e) => e is Map && e['id'] != null && e['ts'] != null)
          .map<Map<String, dynamic>>((e) => <String, dynamic>{'id': e['id'] as String, 'ts': e['ts'] as int})
          .toList();
      normalized.sort((a, b) => (b['ts'] as int).compareTo(a['ts'] as int));
      return normalized.map((e) => e['id'] as String).toList();
    } catch (_) {
      return <String>[];
    }
  }

  static Future<void> clearAll() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
  }
}
