// Firebase olmadan geçici mock implementasyon
// Firebase kurulumundan sonra gerçek servisi geri yükleyin

class StorageService {
  Future<String> uploadProfileImage(String userId, dynamic imageFile) async {
    // Mock implementation - fake URL döndür
    return 'https://via.placeholder.com/150';
  }

  Future<String> uploadChatImage(String chatId, dynamic imageFile) async {
    return 'https://via.placeholder.com/150';
  }

  Future<void> deleteProfileImage(String userId, String imageUrl) async {
    // Mock implementation
  }

  Future<void> deleteUserProfileImages(String userId) async {
    // Mock implementation
  }
}
