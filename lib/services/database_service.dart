import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';
import '../models/match.dart';
import '../models/message.dart';
import '../core/constants.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createUser(User user) async {
    try {
      await _firestore.collection('users').doc(user.id).set(user.toJson());
    } catch (e) {
      print('Error creating user: $e');
    }
  }

  Future<User?> getUser(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists && doc.data() != null) {
        return User.fromJson(doc.data()!);
      }
    } catch (e) {
      print('Error getting user: $e');
    }
    return null;
  }

  Future<void> deleteUser(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).delete();
    } catch (e) {
      print('Error deleting user: $e');
    }
  }

  Future<void> updateUser(User user) async {
    try {
      await _firestore.collection('users').doc(user.id).update(user.toJson());
    } catch (e) {
      print('Error updating user: $e');
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

  Future<void> createMatch(Match match) async {
    try {
      await _firestore.collection('matches').doc(match.id).set(match.toJson());
    } catch (e) {
      print('Error creating match: $e');
    }
  }

  Future<List<Match>> getUserMatches(String userId) async {
    try {
      final snapshot = await _firestore.collection('matches')
          .where(Filter.or(Filter('userId1', isEqualTo: userId), Filter('userId2', isEqualTo: userId)))
          .get();
      return snapshot.docs.map((doc) => Match.fromJson(doc.data())).toList();
    } catch (e) {
      print('Error getting matches: $e');
      return [];
    }
  }

  Stream<List<Match>> getUserMatchesStream(String userId) {
    return _firestore.collection('matches')
        .where(Filter.or(Filter('userId1', isEqualTo: userId), Filter('userId2', isEqualTo: userId)))
        .snapshots()
        .map((snapshot) {
      final matches = snapshot.docs.map((doc) => Match.fromJson(doc.data())).toList();
      matches.sort((a, b) => (b.lastMessageAt ?? b.matchedAt).compareTo(a.lastMessageAt ?? a.matchedAt));
      return matches;
    });
  }

  Future<void> sendMessage(Message message) async {
    try {
      final chatId = _getChatId(message.senderId, message.receiverId);
      await _firestore.collection('chats').doc(chatId).collection('messages').doc(message.id).set(message.toJson());
      await _updateMatchLastMessage(message, chatId);
    } catch (e) {
      print('Error sending message: $e');
    }
  }

  Future<void> _updateMatchLastMessage(Message message, String chatId) async {
    try {
      await _firestore.collection('matches').doc(chatId).update({
        'lastMessage': message.content,
        'lastMessageAt': message.timestamp.toIso8601String(),
      });
    } catch (e) {
      print('Error updating last message: $e');
    }
  }

  Stream<List<Message>> getMessagesStream(String userId1, String userId2) {
    final chatId = _getChatId(userId1, userId2);
    return _firestore.collection('chats').doc(chatId).collection('messages')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Message.fromJson(doc.data())).toList());
  }

  Future<void> markMessagesAsRead(String userId1, String userId2) async {
    // Future enhancement
  }

  String _getChatId(String id1, String id2) {
    final ids = [id1, id2]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  Future<bool> handleLike(String currentUserId, String targetUserId, bool isLike) async {
    try {
      await _firestore.collection('likes').doc(currentUserId).collection('liked').doc(targetUserId).set({
        'isLike': isLike,
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (isLike) {
        final targetDoc = await _firestore.collection('likes').doc(targetUserId).collection('liked').doc(currentUserId).get();
        if (targetDoc.exists && targetDoc.data()?['isLike'] == true) {
          final matchId = _getChatId(currentUserId, targetUserId);
          final match = Match(
            id: matchId,
            userId1: currentUserId,
            userId2: targetUserId,
            matchedAt: DateTime.now(),
          );
          await createMatch(match);
          return true; // Indicates a match occurred
        }
      }
    } catch (e) {
      print('Error handling like: $e');
    }
    return false;
  }

  Future<List<User>> getNearbyUsers(
    String currentUserId,
    double latitude,
    double longitude,
    double maxDistance,
    int minAge,
    int maxAge,
    String preferredGender,
  ) async {
    try {
      final swipedSnapshot = await _firestore.collection('likes').doc(currentUserId).collection('liked').get();
      final swipedIds = swipedSnapshot.docs.map((d) => d.id).toSet();
      swipedIds.add(currentUserId);

      Query query = _firestore.collection('users');
      if (preferredGender != 'all' && preferredGender != 'everyone') {
        query = query.where('gender', isEqualTo: preferredGender);
      }

      final usersSnapshot = await query.get();
      List<User> nearbyUsers = [];

      for (var doc in usersSnapshot.docs) {
        if (!swipedIds.contains(doc.id)) {
          final user = User.fromJson(doc.data() as Map<String, dynamic>);
          final distance = _calculateDistance(latitude, longitude, user.location.latitude, user.location.longitude);
          if (distance <= maxDistance) {
            nearbyUsers.add(user);
          }
        }
      }
      return nearbyUsers;
    } catch (e) {
      print('Error getting nearby users: $e');
      return [];
    }
  }

  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371; // km
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    // Simple distance calculation
    final c = 2 * (dLat.abs() + dLon.abs());

    return earthRadius * c;
  }

  double _toRadians(double degree) {
    return degree * (3.14159265359 / 180);
  }
}
