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
      final data = match.toJson();
      data['id'] = match.id; // Firestore'dan okurken id alanı güvenilir olsun
      await _firestore.collection('matches').doc(match.id).set(data);
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

  /// Beğeni / geçme işlemini yönetir.
  /// [isSuperLike] true ise süper beğeni olarak kaydeder.
  /// Karşılıklı beğeni varsa eşleşme oluşturur ve her iki tarafa bildirim gönderir.
  /// Returns true if a new match was created.
  Future<bool> handleLike(
    String currentUserId,
    String targetUserId,
    bool isLike, {
    bool isSuperLike = false,
  }) async {
    try {
      // Beğeniyi Firestore'a yaz
      await _firestore
          .collection('likes')
          .doc(currentUserId)
          .collection('liked')
          .doc(targetUserId)
          .set({
        'isLike': isLike,
        'isSuperLike': isSuperLike,
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (isLike) {
        // Karşı tarafın bu kişiyi beğenip beğenmediğini kontrol et
        final targetDoc = await _firestore
            .collection('likes')
            .doc(targetUserId)
            .collection('liked')
            .doc(currentUserId)
            .get();

        if (targetDoc.exists && targetDoc.data()?['isLike'] == true) {
          final matchId = ChatRepository.getChatId(currentUserId, targetUserId);

          // ÇİFT MATCH ÖNLEMESİ: Match zaten var mı kontrol et
          final existingMatch = await _firestore.collection('matches').doc(matchId).get();
          if (existingMatch.exists) {
            debugPrint('Match already exists: $matchId — skipping duplicate');
            return false;
          }

          // Süper beğeni kontrolü: herhangi biri süper beğendiyse MatchType.superLike
          final currentIsSuperLike = isSuperLike;
          final targetIsSuperLike = targetDoc.data()?['isSuperLike'] == true;
          final matchType = (currentIsSuperLike || targetIsSuperLike)
              ? MatchType.superLike
              : MatchType.regular;

          final match = Match(
            id: matchId,
            userId1: currentUserId,
            userId2: targetUserId,
            matchedAt: DateTime.now(),
            type: matchType,
          );

          await createMatch(match);

          // Her iki kullanıcıya eşleşme bildirimi gönder
          await _sendMatchNotification(currentUserId, targetUserId);
          await _sendMatchNotification(targetUserId, currentUserId);

          return true;
        }
      }
    } catch (e) {
      debugPrint('Error handling like: $e');
      rethrow; // UI katmanında kullanıcıya hata gösterilsin
    }
    return false;
  }

  /// Eşleşme bildirimi gönderir.
  Future<void> _sendMatchNotification(String toUserId, String fromUserId) async {
    try {
      // Gönderen kullanıcının adını al
      final fromUserDoc = await _firestore.collection('users').doc(fromUserId).get();
      final fromUserName = fromUserDoc.data()?['name'] ?? 'Biri';

      await _firestore
          .collection('users')
          .doc(toUserId)
          .collection('notifications')
          .add({
        'type': 'match',
        'title': '🎉 Yeni Eşleşme!',
        'body': '$fromUserName ile eşleştiniz! Hemen mesaj gönderin.',
        'fromUserId': fromUserId,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      });
    } catch (e) {
      debugPrint('Match notification failed: $e');
      // Bildirim hatası kritik değil, eşleşmeyi engellemeli
    }
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
        data['id'] = doc.id; // id güvencesi
        final user = User.fromJson(data);

        // Cinsiyet filtresi — 'all' her zaman geçer
        if (preferredGender != 'all' && user.gender != preferredGender) {
          genderFiltered++;
          continue;
        }

        // Yaş filtresi
        int age = now.year - user.birthDate.year;
        if (now.month < user.birthDate.month ||
            (now.month == user.birthDate.month && now.day < user.birthDate.day)) {
          age--;
        }
        if (age < minAge || age > maxAge) {
          ageFiltered++;
          continue;
        }

        // Mesafe filtresi — konum 0,0 ise (henüz GPS alınamamış) atla
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
