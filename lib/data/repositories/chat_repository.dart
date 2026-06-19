import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../models/message.dart';

class ChatRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static String getChatId(String id1, String id2) {
    final ids = [id1, id2]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  Future<void> sendMessage(Message message) async {
    try {
      final chatId = getChatId(message.senderId, message.receiverId);
      await _firestore.collection('chats').doc(chatId).collection('messages').doc(message.id).set(message.toJson());
      await _updateMatchLastMessage(message, chatId);

      // Bildirim altyapısı
      final senderDoc = await _firestore.collection('users').doc(message.senderId).get();
      final senderName = senderDoc.data()?['name'] ?? 'Biri';

      await _firestore.collection('users').doc(message.receiverId).collection('notifications').add({
        'type': 'message',
        'title': 'Yeni Mesaj: $senderName',
        'body': message.content,
        'senderId': message.senderId,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      });
    } catch (e) {
      debugPrint('Error sending message: $e');
      rethrow;
    }
  }

  Future<void> _updateMatchLastMessage(Message message, String chatId) async {
    try {
      await _firestore.collection('matches').doc(chatId).update({
        'lastMessage': message.content,
        'lastMessageAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error updating last message: $e');
    }
  }

  Stream<List<Message>> getMessagesStream(String userId1, String userId2) {
    final chatId = getChatId(userId1, userId2);
    return _firestore.collection('chats').doc(chatId).collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Message.fromJson(doc.data())).toList());
  }

  Future<void> markMessagesAsRead(String userId1, String userId2) async {
    try {
      final chatId = getChatId(userId1, userId2);
      final unreadSnapshot = await _firestore.collection('chats').doc(chatId).collection('messages')
          .where('receiverId', isEqualTo: userId1)
          .where('isRead', isEqualTo: false)
          .get();
      for (final doc in unreadSnapshot.docs) {
        await doc.reference.update({'isRead': true});
      }
    } catch (e) {
      debugPrint('Error marking messages as read: $e');
    }
  }

  Stream<QuerySnapshot> getUnreadNotificationsStream(String userId) {
    return _firestore.collection('users').doc(userId).collection('notifications')
        .where('isRead', isEqualTo: false)
        .snapshots();
  }

  Future<void> markNotificationAsRead(String userId, String notificationId) async {
    try {
      await _firestore.collection('users').doc(userId).collection('notifications').doc(notificationId).update({'isRead': true});
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }
}
