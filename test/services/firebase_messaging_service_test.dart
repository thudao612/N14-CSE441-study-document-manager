import 'package:flutter_test/flutter_test.dart';
import 'package:study_document_manager/data/models/app_user_model.dart';
import 'package:study_document_manager/domain/entities/app_user.dart';
import 'package:study_document_manager/services/firebase_messaging_service.dart';

void main() {
  group('FirebaseMessagingService & FCM Token Tests', () {
    test('AppUserModel: Đọc và ghi fcm_token chuẩn xác', () {
      final json = {
        'id': 'user-123',
        'email': 'student@school.edu.vn',
        'display_name': 'Học sinh A',
        'photo_url': 'https://example.com/avatar.png',
        'fcm_token': 'fcm_token_device_xyz_789',
      };

      final model = AppUserModel.fromJson(json);
      expect(model.id, equals('user-123'));
      expect(model.email, equals('student@school.edu.vn'));
      expect(model.displayName, equals('Học sinh A'));
      expect(model.fcmToken, equals('fcm_token_device_xyz_789'));

      final entity = model.toEntity();
      expect(entity, isA<AppUser>());
      expect(entity.fcmToken, equals('fcm_token_device_xyz_789'));

      final serialized = model.toJson();
      expect(serialized['fcm_token'], equals('fcm_token_device_xyz_789'));
    });

    test('FirebaseMessagingService: Singleton khởi tạo an toàn', () {
      final service1 = FirebaseMessagingService();
      final service2 = FirebaseMessagingService();

      expect(identical(service1, service2), isTrue);
      expect(service1.onMessageStream, isNotNull);
    });

    test('FirebaseMessagingService: Xử lý nền tảng Desktop không ném exception', () async {
      final service = FirebaseMessagingService();
      // Chạy initialize trong môi trường test (non-mobile) đảm bảo an toàn tuyệt đối
      await service.initialize();
      expect(service.isInitialized, isTrue);
    });
  });
}
