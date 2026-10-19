import 'package:flutter/foundation.dart';

import '../../domain/entities/user_profile.dart';
import '../../services/cloud_auth_service.dart';
import '../../services/supabase_document_service.dart';

class CloudSessionController extends ChangeNotifier {
  CloudSessionController({
    required this.authService,
    required this.supabaseService,
  });

  final CloudAuthService authService;
  final SupabaseDocumentService supabaseService;

  AppUserProfile? _currentUser;
  bool _isSupabaseReady = false;
  bool _isLoading = false;

  AppUserProfile? get currentUser => _currentUser;
  bool get isSupabaseReady => _isSupabaseReady;
  bool get isLoading => _isLoading;

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    await authService.initialize();
    await supabaseService.initialize();
    _isSupabaseReady = supabaseService.isConfigured;
    _currentUser = authService.currentUser ?? AppUserProfile.demo();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> signInWithGoogle() async {
    _isLoading = true;
    notifyListeners();

    _currentUser = await authService.signInWithGoogle() ?? AppUserProfile.demo();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> signOut() async {
    await authService.signOut();
    _currentUser = null;
    notifyListeners();
  }
}
