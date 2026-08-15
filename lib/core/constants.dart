class AppConstants {
  // App Info
  static const String appName = 'Arkadaşlık Uygulaması';
  static const String appVersion = '1.0.50';

  // Firebase Collections
  static const String usersCollection = 'users';
  static const String matchesCollection = 'matches';
  static const String messagesCollection = 'messages';
  static const String chatsCollection = 'chats';

  // Storage Paths
  static const String profileImagesPath = 'profile_images';
  static const String chatImagesPath = 'chat_images';

  // Distance Settings
  static const double defaultDistance = 50.0; // km
  static const double maxDistance = 500.0; // km (genişletildi — kullanıcı isteğe bağlı artırabilir)
  static const double minDistance = 1.0; // km

  // Age Settings
  static const int minAge = 18;
  static const int maxAge = 100;
  static const int defaultMinAge = 18;
  static const int defaultMaxAge = 50;

  // Profile Settings
  static const int maxPhotos = 6;
  static const int maxBioLength = 500;
  static const int maxNameLength = 50;

  // Match Settings
  static const int dailySwipeLimit = 100;

  // Notification Channels
  static const String matchChannel = 'match_notifications';
  static const String messageChannel = 'message_notifications';
  static const String likeChannel = 'like_notifications';

  static const String gender = 'other';
  static const String male = 'male';
  static const String female = 'female';
  static const String other = 'other';
}

class AppStrings {
  // Auth
  static const String welcome = 'Hoş Geldiniz';
  static const String login = 'Giriş Yap';
  static const String register = 'Kayıt Ol';
  static const String email = 'E-posta';
  static const String password = 'Şifre';
  static const String confirmPassword = 'Şifre Tekrar';
  static const String forgotPassword = 'Şifremi Unuttum';
  static const String orContinueWith = 'veya şununla devam et:';
  static const String alreadyHaveAccount = 'Zaten hesabınız var mı?';
  static const String dontHaveAccount = 'Hesabınız yok mu?';

  // Profile
  static const String editProfile = 'Profili Düzenle';
  static const String save = 'Kaydet';
  static const String cancel = 'İptal';
  static const String name = 'İsim';
  static const String age = 'Yaş';
  static const String gender = 'Cinsiyet';
  static const String bio = 'Hakkımda';
  static const String interests = 'İlgi Alanları';
  static const String addPhotos = 'Fotoğraf Ekle';
  static const String male = 'Erkek';
  static const String female = 'Kadın';
  static const String other = 'Diğer';

  // Match
  static const String itsAMatch = 'Eşleşme!';
  static const String like = 'Beğen';
  static const String dislike = 'Beğenme';
  static const String superLike = 'Süper Beğen';
  static const String noMoreProfiles = 'Başka profil yok';

  // Chat
  static const String message = 'Mesaj';
  static const String typeMessage = 'Mesaj yazın...';
  static const String send = 'Gönder';
  static const String online = 'Çevrimiçi';
  static const String offline = 'Çevrimdışı';

  // Settings
  static const String settings = 'Ayarlar';
  static const String notifications = 'Bildirimler';
  static const String privacy = 'Gizlilik';
  static const String language = 'Dil';
  static const String darkMode = 'Karanlık Mod';
  static const String logout = 'Çıkış Yap';
  static const String deleteAccount = 'Hesabı Sil';

  // Errors
  static const String errorOccurred = 'Bir hata oluştu';
  static const String invalidEmail = 'Geçersiz e-posta';
  static const String weakPassword = 'En az 8 karakter, büyük harf, küçük harf ve rakam içermeli';
  static const String emailAlreadyInUse = 'Bu e-posta zaten kullanımda';
  static const String userNotFound = 'Kullanıcı bulunamadı';
  static const String wrongPassword = 'Yanlış şifre';
  static const String networkError = 'İnternet bağlantısı yok';
  static const String permissionDenied = 'İzin reddedildi';
  static const String locationDisabled = 'Konum servisi kapalı';
}
