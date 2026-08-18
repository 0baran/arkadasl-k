import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'auth_service.dart';
import 'database_service.dart';
import '../models/user.dart' as app_user;

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final DatabaseService _databaseService = DatabaseService();

  firebase_auth.User? _firebaseUser;
  app_user.User? _currentUser;

  firebase_auth.User? get firebaseUser => _firebaseUser;
  app_user.User? get currentUser => _currentUser;
  bool get isLoggedIn => _firebaseUser != null;
  bool get isUserProfileComplete => _currentUser != null;

  AuthProvider() {
    // Uygulama açılır açılmaz önbellekteki kullanıcıyı al
    _firebaseUser = _authService.currentUser;
    if (_firebaseUser != null) {
      _loadUserProfile(_firebaseUser!.uid);
    }

    _authService.authStateChanges.listen((user) async {
      _firebaseUser = user;
      if (user != null) {
        await _loadUserProfile(user.uid);
      } else {
        _currentUser = null;
      }
      notifyListeners();
    });
  }

  Future<void> _loadUserProfile(String userId) async {
    try {
      _currentUser = await _databaseService.getUser(userId);
      notifyListeners(); // Profil bilgisi gelir gelmez UI'yi güncelle (Splash ekranından hemen geçmesi için)
      
      if (_currentUser != null) {
        // FCM token alma işlemi internet yavaşsa takılabilir, bu yüzden async çalıştırıp UI'yi bekletmiyoruz.
        Future.microtask(() async {
          try {
            String? token = await FirebaseMessaging.instance.getToken();
            if (token != null && _currentUser!.fcmToken != token) {
              final updatedUser = _currentUser!.copyWith(fcmToken: token);
              await _databaseService.updateUser(updatedUser);
              _currentUser = updatedUser;
              notifyListeners();
            }
          } catch (e) {
            debugPrint('FCM Token güncellenemedi: $e');
          }
        });
      }
    } catch (e) {
      debugPrint('Kullanıcı profili yüklenemedi: $e');
    }
  }

  Future<void> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    required DateTime birthDate,
    required String gender,
  }) async {
    final userCredential = await _authService.registerWithEmailAndPassword(
      email: email,
      password: password,
    );

    if (userCredential.user != null) {
      await userCredential.user!.updateDisplayName(name);
      final user = app_user.User(
        id: userCredential.user!.uid,
        email: email,
        name: name,
        birthDate: birthDate,
        gender: gender,
        bio: '',
        photoUrls: [],
        interests: [],
        location: app_user.GeoLocation(latitude: 0.0, longitude: 0.0), // Kesfet ekrani acilinca gercek GPS'e guncellenir
        createdAt: DateTime.now(),
      );

      await _databaseService.createUser(user);
      _currentUser = user;
      notifyListeners();
    }
  }

  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    await _authService.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(firebase_auth.PhoneAuthCredential) verificationCompleted,
    required Function(firebase_auth.FirebaseAuthException) verificationFailed,
    required Function(String, int?) codeSent,
    required Function(String) codeAutoRetrievalTimeout,
  }) async {
    await _authService.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: verificationCompleted,
      verificationFailed: verificationFailed,
      codeSent: codeSent,
      codeAutoRetrievalTimeout: codeAutoRetrievalTimeout,
    );
  }

  Future<void> signInWithCredential(firebase_auth.AuthCredential credential) async {
    await _authService.signInWithCredential(credential);
  }

  /// Google ile giriş yapar. Yeni kullanici ise [true] döndürür.
  Future<bool> signInWithGoogle() async {
    final userCredential = await _authService.signInWithGoogle();
    bool isNewUser = false;
    if (userCredential?.user != null) {
      final existingUser = await _databaseService.getUser(userCredential!.user!.uid);
      if (existingUser == null) {
        isNewUser = true;
        
        String gName = userCredential.user!.displayName ?? '';
        if (gName.isEmpty || gName.contains('@')) {
          gName = (userCredential.user!.email != null && userCredential.user!.email!.contains('@')) 
                  ? userCredential.user!.email!.split('@')[0] 
                  : 'Kullanıcı';
        }

        final user = app_user.User(
          id: userCredential.user!.uid,
          email: userCredential.user!.email ?? '',
          name: gName,
          birthDate: DateTime(2000), // Profil duzenlemede guncellenmeli
          gender: 'other',
          bio: '',
          photoUrls: userCredential.user!.photoURL != null ? [userCredential.user!.photoURL!] : [],
          interests: [],
          location: app_user.GeoLocation(latitude: 0.0, longitude: 0.0), // Kesfet acilinca guncellenir
          createdAt: DateTime.now(),
        );
        await _databaseService.createUser(user);
        _currentUser = user;
      } else {
        _currentUser = existingUser;
      }
      notifyListeners();
    }
    return isNewUser;
  }

  Future<void> signInWithPhoneCredential(firebase_auth.AuthCredential credential) async {
    final userCredential = await _authService.signInWithCredential(credential);
    if (userCredential.user != null) {
      final existingUser = await _databaseService.getUser(userCredential.user!.uid);
      if (existingUser == null) {
        final user = app_user.User(
          id: userCredential.user!.uid,
          email: '',
          name: 'Yeni Kullanici',
          birthDate: DateTime(2000), // Profil duzenlemede guncellenmeli
          gender: 'other',
          bio: '',
          photoUrls: [],
          interests: [],
          location: app_user.GeoLocation(latitude: 0.0, longitude: 0.0), // Kesfet acilinca guncellenir
          createdAt: DateTime.now(),
        );
        await _databaseService.createUser(user);
        _currentUser = user;
      } else {
        _currentUser = existingUser;
      }
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
  }

  Future<void> updateProfile(app_user.User updatedUser) async {
    await _databaseService.updateUser(updatedUser);
    _currentUser = updatedUser;
    notifyListeners();
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _authService.sendPasswordResetEmail(email);
  }

  Future<void> deleteAccount() async {
    try {
      if (_currentUser != null) {
        await _databaseService.deleteUser(_currentUser!.id);
      }
      await _authService.deleteAccount();
      _currentUser = null;
      notifyListeners();
    } on firebase_auth.FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw Exception('Güvenlik nedeniyle hesabınızı silmek için lütfen çıkış yapıp tekrar giriş yapın.');
      }
      throw Exception(e.message ?? 'Hesap silinirken bir hata oluştu');
    } catch (e) {
      throw Exception('Hesap silinemedi: $e');
    }
  }
}
