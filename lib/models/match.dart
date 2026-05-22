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
      matchedAt: json['matchedAt'] is DateTime
          ? json['matchedAt']
          : DateTime.parse(json['matchedAt']),
      type: MatchType.values.firstWhere(
        (e) => e.toString() == 'MatchType.${json['type']}',
        orElse: () => MatchType.regular,
      ),
      isActive: json['isActive'] ?? true,
      lastMessageAt: json['lastMessageAt'] != null
          ? (json['lastMessageAt'] is DateTime
              ? json['lastMessageAt']
              : DateTime.parse(json['lastMessageAt']))
          : null,
      lastMessage: json['lastMessage'],
    );
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
    // Sort user IDs to create consistent chat ID
    final sortedIds = [userId1, userId2]..sort();
    return '${sortedIds[0]}_${sortedIds[1]}';
  }
}

enum MatchType {
  regular,
  superLike,
  boost,
}
