import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../domain/entities/user_profile.dart';

class CloudAuthService {
  CloudAuthService();

  AppUserProfile? _currentUser;
  bool _isFirebaseReady = false;

  AppUserProfile? get currentUser => _currentUser;
  bool get isFirebaseReady => _isFirebaseReady;

  Future<void> initialize() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
      _isFirebaseReady = true;
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        _currentUser = AppUserProfile(
          id: firebaseUser.uid,
          email: firebaseUser.email ?? 'unknown@student.local',
          fullName: firebaseUser.displayName ?? 'Student User',
          avatarUrl: firebaseUser.photoURL,
          isAuthenticated: true,
        );
      } else {
        _currentUser ??= AppUserProfile.demo();
      }
    } catch (_) {
      _isFirebaseReady = false;
      _currentUser ??= AppUserProfile.demo();
    }
  }

  Future<AppUserProfile?> signInWithGoogle() async {
    if (!_isFirebaseReady) {
      _currentUser = AppUserProfile.demo();
      return _currentUser;
    }

    try {
      final googleProvider = GoogleAuthProvider();
      final userCredential =
          await FirebaseAuth.instance.signInWithProvider(googleProvider);
      final firebaseUser = userCredential.user;

      if (firebaseUser == null) {
        return _currentUser;
      }

      _currentUser = AppUserProfile(
        id: firebaseUser.uid,
        email: firebaseUser.email ?? 'user@student.local',
        fullName: firebaseUser.displayName ?? 'Google User',
        avatarUrl: firebaseUser.photoURL,
        isAuthenticated: true,
      );
      return _currentUser;
    } catch (_) {
      _currentUser = AppUserProfile.demo();
      return _currentUser;
    }
  }

  Future<void> signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {
      // Demo mode fallback
    }
    _currentUser = null;
  }
}
