import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
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
      notifyListeners();
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
      final user = app_user.User(
        id: userCredential.user!.uid,
        email: email,
        name: name,
        birthDate: birthDate,
        gender: gender,
        bio: 'Yeni kullanıcı',
        photoUrls: [],
        interests: [],
        location: app_user.GeoLocation(latitude: 41.0, longitude: 29.0),
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

  Future<void> signInWithGoogle() async {
    final userCredential = await _authService.signInWithGoogle();
    if (userCredential?.user != null) {
      final existingUser = await _databaseService.getUser(userCredential!.user!.uid);
      if (existingUser == null) {
        final user = app_user.User(
          id: userCredential.user!.uid,
          email: userCredential.user!.email ?? '',
          name: userCredential.user!.displayName ?? 'Google Kullanıcısı',
          birthDate: DateTime.now().subtract(const Duration(days: 6570)),
          gender: 'other',
          bio: 'Google ile katıldı',
          photoUrls: userCredential.user!.photoURL != null ? [userCredential.user!.photoURL!] : [],
          interests: [],
          location: app_user.GeoLocation(latitude: 41.0, longitude: 29.0),
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

  Future<void> signInWithPhoneCredential(firebase_auth.AuthCredential credential) async {
    final userCredential = await _authService.signInWithCredential(credential);
    if (userCredential.user != null) {
      final existingUser = await _databaseService.getUser(userCredential.user!.uid);
      if (existingUser == null) {
        final user = app_user.User(
          id: userCredential.user!.uid,
          email: '', // Telefonla girenlerin e-postası olmayabilir
          name: 'Yeni Kullanıcı (Tel)',
          birthDate: DateTime.now().subtract(const Duration(days: 6570)),
          gender: 'other',
          bio: 'Telefonla katıldı',
          photoUrls: [],
          interests: [],
          location: app_user.GeoLocation(latitude: 41.0, longitude: 29.0),
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
    if (_currentUser != null) {
      await _databaseService.deleteUser(_currentUser!.id);
    }
    await _authService.deleteAccount();
    _currentUser = null;
    notifyListeners();
  }
}
