import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  FirebaseFirestore get firestore => _firestore;

  Future<void> createOrUpdateUserProfile(String userId, {String? email, String? displayName, bool? isAnonymous}) async {
    await _firestore.collection('user_profiles').doc(userId).set({
      'email': email,
      'display_name': displayName,
      'is_anonymous': isAnonymous ?? false,
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<Map<String, dynamic>?> getTopicDetails(String userId, String topicId) async {
    final doc = await _firestore
        .collection('topic_details')
        .doc('${userId}_$topicId')
        .get();

    return doc.exists ? doc.data() : null;
  }

  Future<void> saveTopicDetails({
    required String userId,
    required String topicId,
    required String topicTitle,
    required String summary,
    required List<Map<String, dynamic>> steps,
  }) async {
    await _firestore.collection('topic_details').doc('${userId}_$topicId').set({
      'user_id': userId,
      'topic_id': topicId,
      'topic_title': topicTitle,
      'summary': summary,
      'steps': steps,
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> recordTopicVisit(String userId, String topicId) async {
    final docRef = _firestore.collection('visited_topics').doc('${userId}_$topicId');
    final doc = await docRef.get();

    if (doc.exists) {
      await docRef.update({
        'visit_count': FieldValue.increment(1),
        'last_visited_at': FieldValue.serverTimestamp(),
      });
    } else {
      await docRef.set({
        'user_id': userId,
        'topic_id': topicId,
        'visit_count': 1,
        'last_visited_at': FieldValue.serverTimestamp(),
        'progress': 0.0,
      });
    }
  }

  Future<void> updateTopicProgress(String userId, String topicId, double progress) async {
    await _firestore.collection('visited_topics').doc('${userId}_$topicId').update({
      'progress': progress,
    });
  }

  Future<List<Map<String, dynamic>>> getVisitedTopics(String userId) async {
    final snapshot = await _firestore
        .collection('visited_topics')
        .where('user_id', isEqualTo: userId)
        .orderBy('last_visited_at', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  Future<void> saveChatMessage({
    required String userId,
    required String role,
    required String content,
  }) async {
    await _firestore.collection('chat_messages').add({
      'user_id': userId,
      'role': role,
      'content': content,
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  Future<List<Map<String, dynamic>>> getChatMessages(String userId, {int limit = 50}) async {
    final snapshot = await _firestore
        .collection('chat_messages')
        .where('user_id', isEqualTo: userId)
        .orderBy('created_at', descending: false)
        .limit(limit)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  Future<void> clearChatMessages(String userId) async {
    final snapshot = await _firestore
        .collection('chat_messages')
        .where('user_id', isEqualTo: userId)
        .get();

    for (var doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }
}

final firebaseService = FirebaseService();
