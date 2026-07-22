import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../models/match.dart';
import '../../models/user.dart';
import 'chat_repository.dart';

class MatchRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createMatch(Match match) async {
    try {
      await _firestore.collection('matches').doc(match.id).set(match.toJson());
    } catch (e) {
      debugPrint('Error creating match: $e');
      rethrow;
    }
  }

  Future<List<Match>> getUserMatches(String userId) async {
    try {
      final snapshot = await _firestore.collection('matches')
          .where(Filter.or(Filter('userId1', isEqualTo: userId), Filter('userId2', isEqualTo: userId)))
          .get();
      return snapshot.docs.map((doc) => Match.fromJson(doc.data())).toList();
    } catch (e) {
      debugPrint('Error getting matches: $e');
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

  Future<bool> handleLike(String currentUserId, String targetUserId, bool isLike) async {
    try {
      await _firestore.collection('likes').doc(currentUserId).collection('liked').doc(targetUserId).set({
        'isLike': isLike,
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (isLike) {
        final targetDoc = await _firestore.collection('likes').doc(targetUserId).collection('liked').doc(currentUserId).get();
        if (targetDoc.exists && targetDoc.data()?['isLike'] == true) {
          final matchId = ChatRepository.getChatId(currentUserId, targetUserId);
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
      debugPrint('Error handling like: $e');
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
    List<String> blockedUsers,
  ) async {
    try {
      final swipedSnapshot = await _firestore.collection('likes').doc(currentUserId).collection('liked').get();
      final swipedIds = swipedSnapshot.docs.map((d) => d.id).toSet();
      swipedIds.add(currentUserId);
      swipedIds.addAll(blockedUsers);

      final usersSnapshot = await _firestore.collection('users').limit(500).get();
      debugPrint('getNearbyUsers: fetched ${usersSnapshot.docs.length} docs from Firestore');
      debugPrint('getNearbyUsers: swipedIds count = ${swipedIds.length}');

      List<User> nearbyUsers = [];
      final now = DateTime.now();
      int ageFiltered = 0;
      int distanceFiltered = 0;
      int genderFiltered = 0;
      int swipedFiltered = 0;

      for (var doc in usersSnapshot.docs) {
        if (swipedIds.contains(doc.id)) {
          swipedFiltered++;
          continue;
        }

        final data = doc.data();
        data['id'] = doc.id;
        final user = User.fromJson(data);

        if (preferredGender != 'all' && preferredGender != 'everyone' && user.gender != preferredGender) {
          genderFiltered++;
          continue;
        }
        
        int age = now.year - user.birthDate.year;
        if (now.month < user.birthDate.month ||
            (now.month == user.birthDate.month && now.day < user.birthDate.day)) {
          age--;
        }

        if (age < minAge || age > maxAge) {
          ageFiltered++;
          continue;
        }

        // Konum 0,0 ise (kayıt sırasında henüz GPS alınamamış) mesafe filtresini atla
        final userLat = user.location.latitude;
        final userLon = user.location.longitude;
        if (userLat != 0.0 || userLon != 0.0) {
          final distance = _calculateDistance(latitude, longitude, userLat, userLon);
          if (distance > maxDistance) {
            distanceFiltered++;
            continue;
          }
        }
        nearbyUsers.add(user);
      }
      
      debugPrint('getNearbyUsers: swiped:$swipedFiltered gender:$genderFiltered age:$ageFiltered dist:$distanceFiltered found:${nearbyUsers.length}');
      return nearbyUsers;
    } catch (e) {
      debugPrint('getNearbyUsers ERROR: $e');
      rethrow;
    }
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // km
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.asin(math.sqrt(a));

    return earthRadius * c;
  }

  double _toRadians(double degree) {
    return degree * (3.14159265359 / 180);
  }

  Future<void> resetSwipes(String currentUserId) async {
    try {
      final snapshot = await _firestore.collection('likes').doc(currentUserId).collection('liked').get();
      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }
      debugPrint('Swipes reset successfully');
    } catch (e) {
      debugPrint('Error resetting swipes: $e');
    }
  }
}
