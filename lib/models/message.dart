import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String id;
  final String senderId;
  final String receiverId;
  final String content;
  final MessageType type;
  final DateTime timestamp;
  final bool isRead;
  final String? imageUrl;

  Message({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    this.type = MessageType.text,
    required this.timestamp,
    this.isRead = false,
    this.imageUrl,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] ?? json['messageId'] ?? '',
      senderId: json['senderId'] ?? '',
      receiverId: json['receiverId'] ?? '',
      content: json['content'] ?? '',
      type: _parseMessageType(json['type']),
      timestamp: _parseDate(json['timestamp']),
      isRead: json['isRead'] ?? false,
      imageUrl: json['imageUrl'],
    );
  }

  static MessageType _parseMessageType(dynamic type) {
    if (type is String) {
      return MessageType.values.firstWhere(
        (e) => e.name == type,
        orElse: () => MessageType.text,
      );
    }
    return MessageType.text;
  }

  static DateTime _parseDate(dynamic dateVal) {
    if (dateVal == null) return DateTime.now();
    if (dateVal is DateTime) return dateVal;
    if (dateVal is Timestamp) return dateVal.toDate();
    if (dateVal is String) {
      return DateTime.tryParse(dateVal) ?? DateTime.now();
    }
    return DateTime.now();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'content': content,
      'type': type.toString().split('.').last,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'imageUrl': imageUrl,
    };
  }

  Message copyWith({
    String? id,
    String? senderId,
    String? receiverId,
    String? content,
    MessageType? type,
    DateTime? timestamp,
    bool? isRead,
    String? imageUrl,
  }) {
    return Message(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      content: content ?? this.content,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  bool isFromUser(String userId) => senderId == userId;
}

enum MessageType {
  text,
  image,
  system,
}
