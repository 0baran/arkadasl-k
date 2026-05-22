import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import '../core/constants.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadProfileImage(String userId, File imageFile) async {
    final ref = _storage.ref().child('${AppConstants.profileImagesPath}/$userId/${DateTime.now().millisecondsSinceEpoch}.jpg');
    final uploadTask = await ref.putFile(imageFile);
    return await uploadTask.ref.getDownloadURL();
  }

  Future<String> uploadChatImage(String chatId, File imageFile) async {
    final ref = _storage.ref().child('${AppConstants.chatImagesPath}/$chatId/${DateTime.now().millisecondsSinceEpoch}.jpg');
    final uploadTask = await ref.putFile(imageFile);
    return await uploadTask.ref.getDownloadURL();
  }

  Future<void> deleteProfileImage(String userId, String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      print('Error deleting profile image: $e');
    }
  }

  Future<void> deleteUserProfileImages(String userId) async {
    try {
      final ref = _storage.ref().child('${AppConstants.profileImagesPath}/$userId');
      final result = await ref.listAll();
      for (var item in result.items) {
        await item.delete();
      }
    } catch (e) {
      print('Error deleting user profile images: $e');
    }
  }
}
