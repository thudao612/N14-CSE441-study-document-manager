import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../domain/repositories/i_document_permission_repository.dart';

/// Hàm xử lý thông báo nền (Background Message Handler)
/// Bắt buộc phải là Top-level function với annotation @pragma('vm:entry-point')
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
    debugPrint(
      'FCM Background message received: ${message.messageId} - ${message.notification?.title}',
    );
  } catch (e) {
    debugPrint('Error handling background FCM: $e');
  }
}

/// Dịch vụ quản lý Firebase Cloud Messaging (FCM) - Tầng Services
/// Phục vụ thông báo đẩy (Push Notifications) khi có sự kiện:
/// - Chia sẻ tài liệu mới (Viewer / Editor)
/// - Yêu cầu mượn tài liệu hoặc phê duyệt mượn tài liệu
/// - Cập nhật trạng thái tài liệu
class FirebaseMessagingService {
  static final FirebaseMessagingService _instance =
      FirebaseMessagingService._internal();
  factory FirebaseMessagingService() => _instance;
  FirebaseMessagingService._internal();

  FirebaseMessaging? _customFcm;
  FirebaseMessaging? get _fcm {
    if (_customFcm != null) return _customFcm;
    try {
      return FirebaseMessaging.instance;
    } catch (_) {
      return null;
    }
  }

  @visibleForTesting
  void setCustomFcmForTesting(FirebaseMessaging? fcm) {
    _customFcm = fcm;
  }

  final StreamController<RemoteMessage> _messageStreamController =
      StreamController<RemoteMessage>.broadcast();

  Stream<RemoteMessage> get onMessageStream => _messageStreamController.stream;

  String? _cachedToken;
  String? get currentFcmToken => _cachedToken;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  /// Khởi tạo dịch vụ Firebase Messaging an toàn trên đa nền tảng
  Future<void> initialize({
    IDocumentPermissionRepository? permissionRepository,
    String? currentUserId,
    String? currentUserEmail,
    void Function(String title, String body)? onForegroundMessage,
  }) async {
    if (_isInitialized) return;

    // Firebase Messaging hỗ trợ chính thức trên Android, iOS và Web.
    // Trên Windows Desktop, tránh gọi native channel để không gây exception.
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) {
      debugPrint('FCM Notice: Firebase Messaging không hỗ trợ trực tiếp trên Windows Desktop.');
      _isInitialized = true;
      return;
    }

    final fcm = _fcm;
    if (fcm == null) {
      debugPrint('FCM Notice: Firebase chưa khởi tạo hoặc môi trường kiểm thử.');
      _isInitialized = true;
      return;
    }

    try {
      // 1. Yêu cầu cấp quyền nhận thông báo từ người dùng
      final settings = await fcm.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      debugPrint(
        'FCM Notification authorizationStatus: ${settings.authorizationStatus}',
      );

      // 2. Lấy FCM Device Token
      _cachedToken = await fcm.getToken();
      if (_cachedToken != null) {
        debugPrint('FCM Device Token: $_cachedToken');
        // Đồng bộ token vào Supabase nếu có thông tin người dùng
        if (permissionRepository != null &&
            currentUserId != null &&
            currentUserEmail != null) {
          await syncTokenToSupabase(
            repository: permissionRepository,
            uid: currentUserId,
            email: currentUserEmail,
          );
        }
      }

      // 3. Lắng nghe khi FCM Token được làm mới
      fcm.onTokenRefresh.listen((newToken) {
        _cachedToken = newToken;
        debugPrint('FCM Token refreshed: $newToken');
        if (permissionRepository != null &&
            currentUserId != null &&
            currentUserEmail != null) {
          syncTokenToSupabase(
            repository: permissionRepository,
            uid: currentUserId,
            email: currentUserEmail,
            tokenOverride: newToken,
          );
        }
      });

      // 4. Lắng nghe thông báo khi ứng dụng đang mở ở tiền cảnh (Foreground)
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('FCM Foreground message: ${message.notification?.title}');
        _messageStreamController.add(message);

        final title = message.notification?.title ?? 'Thông báo tài liệu';
        final body = message.notification?.body ?? '';
        if (onForegroundMessage != null && body.isNotEmpty) {
          onForegroundMessage(title, body);
        }
      });

      // 5. Lắng nghe khi người dùng bấm vào thông báo để mở ứng dụng
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('FCM Message opened app: ${message.data}');
        _messageStreamController.add(message);
      });

      // 6. Đăng ký background message handler
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      _isInitialized = true;
      debugPrint('FirebaseMessagingService initialized successfully.');
    } catch (e) {
      debugPrint('FirebaseMessagingService initialization error: $e');
      _isInitialized = true; // Đánh dấu hoàn tất để không retry lặp vô hạn
    }
  }

  /// Đồng bộ FCM Device Token vào bảng `users` trên Supabase
  Future<void> syncTokenToSupabase({
    required IDocumentPermissionRepository repository,
    required String uid,
    required String email,
    String? tokenOverride,
  }) async {
    final token = tokenOverride ?? _cachedToken;
    if (token == null || token.isEmpty) return;

    try {
      await repository.syncUserProfile(
        uid: uid,
        email: email,
        fcmToken: token,
      );
      debugPrint('FCM Token successfully synced to Supabase for $email');
    } catch (e) {
      debugPrint('Failed to sync FCM Token to Supabase: $e');
    }
  }

  /// Đăng ký lắng nghe một Topic cụ thể (ví dụ: 'all_documents', 'announcements')
  Future<void> subscribeToTopic(String topic) async {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) return;
    final fcm = _fcm;
    if (fcm == null) return;
    try {
      await fcm.subscribeToTopic(topic);
      debugPrint('FCM Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('FCM Subscribe error: $e');
    }
  }

  /// Hủy đăng ký lắng nghe một Topic
  Future<void> unsubscribeFromTopic(String topic) async {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) return;
    final fcm = _fcm;
    if (fcm == null) return;
    try {
      await fcm.unsubscribeFromTopic(topic);
      debugPrint('FCM Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('FCM Unsubscribe error: $e');
    }
  }

  void dispose() {
    _messageStreamController.close();
  }
}
