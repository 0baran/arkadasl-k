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
    // Mock implementation
  }

  Future<List<Match>> getUserMatches(String userId) async {
    return [];
  }

  Stream<List<Match>> getUserMatchesStream(String userId) {
    return Stream.value([]);
  }

  Future<void> sendMessage(Message message) async {
    // Mock implementation
  }

  Future<void> _updateMatchLastMessage(Message message, String chatId) async {
    // Mock implementation
  }

  Stream<List<Message>> getMessagesStream(String userId1, String userId2) {
    return Stream.value([]);
  }

  Future<void> markMessagesAsRead(String userId1, String userId2) async {
    // Mock implementation
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
    // Mock nearby users
    return [
      User(
        id: 'user1',
        email: 'user1@test.com',
        name: 'Ayşe',
        birthDate: DateTime.now().subtract(const Duration(days: 9000)),
        gender: 'female',
        bio: 'Merhaba! Tanışmak istiyorum.',
        photoUrls: [],
        interests: ['Müzik', 'Spor'],
        location: GeoLocation(latitude: latitude + 0.01, longitude: longitude + 0.01),
        createdAt: DateTime.now(),
      ),
      User(
        id: 'user2',
        email: 'user2@test.com',
        name: 'Mehmet',
        birthDate: DateTime.now().subtract(const Duration(days: 8500)),
        gender: 'male',
        bio: 'Yeni insanlarla tanışmak istiyorum.',
        photoUrls: [],
        interests: ['Sinema', 'Yemek'],
        location: GeoLocation(latitude: latitude - 0.01, longitude: longitude - 0.01),
        createdAt: DateTime.now(),
      ),
    ];
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
