import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../models/user.dart';
import 'chat_repository.dart'; // To delete match on block

class UserRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createUser(User user) async {
    try {
      await _firestore.collection('users').doc(user.id).set(user.toJson());
    } catch (e) {
      debugPrint('Error creating user: $e');
      rethrow;
    }
  }

  Future<User?> getUser(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists && doc.data() != null) {
        return User.fromJson(doc.data()!);
      }
    } catch (e) {
      debugPrint('Error getting user: $e');
    }
    return null;
  }

  Future<void> deleteUser(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).delete();
    } catch (e) {
      debugPrint('Error deleting user: $e');
      rethrow;
    }
  }

  Future<void> updateUser(User user) async {
    try {
      await _firestore.collection('users').doc(user.id).update(user.toJson());
    } catch (e) {
      debugPrint('Error updating user: $e');
      rethrow;
    }
  }

  Stream<User?> getUserStream(String userId) {
    return _firestore.collection('users').doc(userId).snapshots().map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        return User.fromJson(snapshot.data()!);
      }
      return null;
    });
  }

  Future<void> blockUser(String currentUserId, String targetUserId) async {
    try {
      await _firestore.collection('users').doc(currentUserId).update({
        'blockedUsers': FieldValue.arrayUnion([targetUserId])
      });
      final matchId = ChatRepository.getChatId(currentUserId, targetUserId);
      await _firestore.collection('matches').doc(matchId).delete();
    } catch (e) {
      debugPrint('Error blocking user: $e');
    }
  }

  Future<void> reportUser(String currentUserId, String targetUserId, String reason) async {
    try {
      await _firestore.collection('reports').add({
        'reporterId': currentUserId,
        'reportedId': targetUserId,
        'reason': reason,
        'timestamp': FieldValue.serverTimestamp(),
      });
      await blockUser(currentUserId, targetUserId);
    } catch (e) {
      debugPrint('Error reporting user: $e');
    }
  }
}
