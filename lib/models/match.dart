import 'package:cloud_firestore/cloud_firestore.dart';

class Match {
  final String id;
  final String userId1;
  final String userId2;
  final DateTime matchedAt;
  final MatchType type;
  final bool isActive;
  final DateTime? lastMessageAt;
  final String? lastMessage;

  Match({
    required this.id,
    required this.userId1,
    required this.userId2,
    required this.matchedAt,
    this.type = MatchType.regular,
    this.isActive = true,
    this.lastMessageAt,
    this.lastMessage,
  });

  factory Match.fromJson(Map<String, dynamic> json) {
    return Match(
      id: json['id'] ?? json['matchId'] ?? '',
      userId1: json['userId1'] ?? '',
      userId2: json['userId2'] ?? '',
      matchedAt: _parseDate(json['matchedAt']),
      type: _parseMatchType(json['type']),
      isActive: json['isActive'] ?? true,
      lastMessageAt: json['lastMessageAt'] != null
          ? _parseDate(json['lastMessageAt'])
          : null,
      lastMessage: json['lastMessage'],
    );
  }

  static MatchType _parseMatchType(dynamic type) {
    if (type is String) {
      return MatchType.values.firstWhere(
        (e) => e.name == type,
        orElse: () => MatchType.regular,
      );
    }
    return MatchType.regular;
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
      'userId1': userId1,
      'userId2': userId2,
      'matchedAt': matchedAt.toIso8601String(),
      'type': type.toString().split('.').last,
      'isActive': isActive,
      'lastMessageAt': lastMessageAt?.toIso8601String(),
      'lastMessage': lastMessage,
    };
  }

  Match copyWith({
    String? id,
    String? userId1,
    String? userId2,
    DateTime? matchedAt,
    MatchType? type,
    bool? isActive,
    DateTime? lastMessageAt,
    String? lastMessage,
  }) {
    return Match(
      id: id ?? this.id,
      userId1: userId1 ?? this.userId1,
      userId2: userId2 ?? this.userId2,
      matchedAt: matchedAt ?? this.matchedAt,
      type: type ?? this.type,
      isActive: isActive ?? this.isActive,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      lastMessage: lastMessage ?? this.lastMessage,
    );
  }

  String getChatId() {
    final sortedIds = [userId1, userId2]..sort();
    return '${sortedIds[0]}_${sortedIds[1]}';
  }
}

enum MatchType {
  regular,
  superLike,
  boost,
}
