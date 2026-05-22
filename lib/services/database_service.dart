import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/repositories/user_repository.dart';
import '../data/repositories/match_repository.dart';
import '../data/repositories/chat_repository.dart';
import '../models/user.dart';
import '../models/match.dart';
import '../models/message.dart';

class DatabaseService {
  final UserRepository _userRepo = UserRepository();
  final MatchRepository _matchRepo = MatchRepository();
  final ChatRepository _chatRepo = ChatRepository();

  // --- USER REPOSITORY DELEGATES ---
  Future<void> createUser(User user) => _userRepo.createUser(user);
  Future<User?> getUser(String userId) => _userRepo.getUser(userId);
  Future<void> deleteUser(String userId) => _userRepo.deleteUser(userId);
  Future<void> updateUser(User user) => _userRepo.updateUser(user);
  Stream<User?> getUserStream(String userId) => _userRepo.getUserStream(userId);
  Future<void> blockUser(String currentUserId, String targetUserId) => _userRepo.blockUser(currentUserId, targetUserId);
  Future<void> reportUser(String currentUserId, String targetUserId, String reason) => _userRepo.reportUser(currentUserId, targetUserId, reason);

  // --- MATCH REPOSITORY DELEGATES ---
  Future<void> createMatch(Match match) => _matchRepo.createMatch(match);
  Future<List<Match>> getUserMatches(String userId) => _matchRepo.getUserMatches(userId);
  Stream<List<Match>> getUserMatchesStream(String userId) => _matchRepo.getUserMatchesStream(userId);
  Future<bool> handleLike(String currentUserId, String targetUserId, bool isLike) => _matchRepo.handleLike(currentUserId, targetUserId, isLike);
  Future<List<User>> getNearbyUsers(String currentUserId, double latitude, double longitude, double maxDistance, int minAge, int maxAge, String preferredGender, List<String> blockedUsers) => _matchRepo.getNearbyUsers(currentUserId, latitude, longitude, maxDistance, minAge, maxAge, preferredGender, blockedUsers);
  Future<void> resetSwipes(String currentUserId) => _matchRepo.resetSwipes(currentUserId);

  // --- CHAT REPOSITORY DELEGATES ---
  Future<void> sendMessage(Message message) => _chatRepo.sendMessage(message);
  Stream<List<Message>> getMessagesStream(String userId1, String userId2) => _chatRepo.getMessagesStream(userId1, userId2);
  Future<void> markMessagesAsRead(String userId1, String userId2) => _chatRepo.markMessagesAsRead(userId1, userId2);
  Stream<QuerySnapshot> getUnreadNotificationsStream(String userId) => _chatRepo.getUnreadNotificationsStream(userId);
  Future<void> markNotificationAsRead(String userId, String notificationId) => _chatRepo.markNotificationAsRead(userId, notificationId);
}
