import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../domain/entities/user_profile.dart';

class CloudAuthService {
  CloudAuthService();

  final GoogleSignIn _googleSignIn = GoogleSignIn.standard(scopes: ['email']);

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
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return _currentUser;
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final firebaseUserCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      final firebaseUser = firebaseUserCredential.user;

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
      await _googleSignIn.signOut();
    } catch (_) {
      // Demo mode fallback: the app remains functional without live Firebase config.
    }
    _currentUser = null;
  }
}
