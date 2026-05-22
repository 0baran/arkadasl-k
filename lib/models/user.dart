import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String id;
  final String email;
  final String name;
  final DateTime birthDate;
  final String gender;
  final String bio;
  final List<String> photoUrls;
  final List<String> interests;
  final GeoLocation location;
  final DateTime createdAt;
  final DateTime? lastSeen;
  final bool isVerified;
  final bool isPremium;
  final UserSettings settings;

  User({
    required this.id,
    required this.email,
    required this.name,
    required this.birthDate,
    required this.gender,
    this.bio = '',
    this.photoUrls = const [],
    this.interests = const [],
    required this.location,
    required this.createdAt,
    this.lastSeen,
    this.isVerified = false,
    this.isPremium = false,
    UserSettings? settings,
  }) : settings = settings ?? UserSettings();

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? json['uid'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      birthDate: _parseDate(json['birthDate']),
      gender: json['gender'] ?? 'other',
      bio: json['bio'] ?? '',
      photoUrls: List<String>.from(json['photoUrls'] ?? []),
      interests: List<String>.from(json['interests'] ?? []),
      location: GeoLocation.fromJson(json['location'] ?? {}),
      createdAt: _parseDate(json['createdAt']),
      lastSeen: json['lastSeen'] != null ? _parseDate(json['lastSeen']) : null,
      isVerified: json['isVerified'] ?? false,
      isPremium: json['isPremium'] ?? false,
      settings: json['settings'] != null
          ? UserSettings.fromJson(json['settings'])
          : UserSettings(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'birthDate': birthDate.toIso8601String(),
      'gender': gender,
      'bio': bio,
      'photoUrls': photoUrls,
      'interests': interests,
      'location': location.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'lastSeen': lastSeen?.toIso8601String(),
      'isVerified': isVerified,
      'isPremium': isPremium,
      'settings': settings.toJson(),
    };
  }

  User copyWith({
    String? id,
    String? email,
    String? name,
    DateTime? birthDate,
    String? gender,
    String? bio,
    List<String>? photoUrls,
    List<String>? interests,
    GeoLocation? location,
    DateTime? createdAt,
    DateTime? lastSeen,
    bool? isVerified,
    bool? isPremium,
    UserSettings? settings,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      birthDate: birthDate ?? this.birthDate,
      gender: gender ?? this.gender,
      bio: bio ?? this.bio,
      photoUrls: photoUrls ?? this.photoUrls,
      interests: interests ?? this.interests,
      location: location ?? this.location,
      createdAt: createdAt ?? this.createdAt,
      lastSeen: lastSeen ?? this.lastSeen,
      isVerified: isVerified ?? this.isVerified,
      isPremium: isPremium ?? this.isPremium,
      settings: settings ?? this.settings,
    );
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
}

class GeoLocation {
  final double latitude;
  final double longitude;

  GeoLocation({
    required this.latitude,
    required this.longitude,
  });

  factory GeoLocation.fromJson(Map<String, dynamic> json) {
    return GeoLocation(
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  GeoLocation copyWith({
    double? latitude,
    double? longitude,
  }) {
    return GeoLocation(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }
}

class UserSettings {
  final double maxDistance; // km
  final int minAge;
  final int maxAge;
  final String preferredGender;
  final bool showDistance;
  final bool notificationsEnabled;
  final bool darkMode;

  UserSettings({
    this.maxDistance = 50.0,
    this.minAge = 18,
    this.maxAge = 50,
    this.preferredGender = 'all',
    this.showDistance = true,
    this.notificationsEnabled = true,
    this.darkMode = false,
  });

  factory UserSettings.fromJson(Map<String, dynamic> json) {
    return UserSettings(
      maxDistance: (json['maxDistance'] ?? 50.0).toDouble(),
      minAge: json['minAge'] ?? 18,
      maxAge: json['maxAge'] ?? 50,
      preferredGender: json['preferredGender'] ?? 'all',
      showDistance: json['showDistance'] ?? true,
      notificationsEnabled: json['notificationsEnabled'] ?? true,
      darkMode: json['darkMode'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'maxDistance': maxDistance,
      'minAge': minAge,
      'maxAge': maxAge,
      'preferredGender': preferredGender,
      'showDistance': showDistance,
      'notificationsEnabled': notificationsEnabled,
      'darkMode': darkMode,
    };
  }

  UserSettings copyWith({
    double? maxDistance,
    int? minAge,
    int? maxAge,
    String? preferredGender,
    bool? showDistance,
    bool? notificationsEnabled,
    bool? darkMode,
  }) {
    return UserSettings(
      maxDistance: maxDistance ?? this.maxDistance,
      minAge: minAge ?? this.minAge,
      maxAge: maxAge ?? this.maxAge,
      preferredGender: preferredGender ?? this.preferredGender,
      showDistance: showDistance ?? this.showDistance,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      darkMode: darkMode ?? this.darkMode,
    );
  }
}
