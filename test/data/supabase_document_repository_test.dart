import 'package:flutter_test/flutter_test.dart';
import 'package:study_document_manager/core/config/supabase_config.dart';
import 'package:study_document_manager/data/models/document_model.dart';
import 'package:study_document_manager/data/repositories/supabase_document_repository.dart';
import 'package:study_document_manager/domain/entities/document.dart';
import 'package:study_document_manager/domain/entities/document_type.dart';

void main() {
  group('Supabase Configuration & Security Tests', () {
    test('SupabaseConfig: Cấu hình URL và Anon Key hợp lệ', () {
      expect(SupabaseConfig.supabaseUrl, isNotEmpty);
      expect(SupabaseConfig.supabaseAnonKey, isNotEmpty);
      expect(SupabaseConfig.isConfigured, isTrue);
      expect(SupabaseConfig.supabaseUrl.startsWith('https://'), isTrue);
    });

    test('DocumentModel.toSupabaseJson: Khóa ngoại owner_id mapping chính xác từ userId', () {
      final doc = Document(
        id: 'doc-uuid-123',
        title: 'Lập trình Flutter nâng cao',
        subject: 'Mobile Development',
        type: DocumentType.lecture,
        description: 'Tài liệu học tập tích hợp Firebase và Supabase',
        fileUrlOrPath: 'https://firebasestorage.googleapis.com/...',
        tags: const ['flutter', 'supabase'],
        isFavorite: true,
        createdAt: DateTime.parse('2026-10-13T10:00:00Z'),
        updatedAt: DateTime.parse('2026-10-13T10:00:00Z'),
        userId: 'firebase_user_abc123',
        authorEmail: 'student@example.com',
      );

      final model = DocumentModel.fromEntity(doc);
      final supabaseJson = model.toSupabaseJson();

      // Kiểm tra các trường cột PostgreSQL chuẩn
      expect(supabaseJson['id'], equals('doc-uuid-123'));
      expect(supabaseJson['owner_id'], equals('firebase_user_abc123'));
      expect(supabaseJson['author_email'], equals('student@example.com'));
      expect(supabaseJson['title'], equals('Lập trình Flutter nâng cao'));
      expect(supabaseJson['subject'], equals('Mobile Development'));
      expect(supabaseJson['type'], equals('lecture'));
      expect(supabaseJson['file_url'], equals('https://firebasestorage.googleapis.com/...'));
      expect(supabaseJson['is_favorite'], isTrue);
    });
  });

  group('SupabaseDocumentRepository Security & Validation Tests', () {
    test('addDocument: Ném ngoại lệ rõ ràng khi người dùng chưa đăng nhập', () async {
      // Khi không có session đăng nhập Firebase
      final repository = SupabaseDocumentRepository();

      final doc = Document(
        id: 'new-doc-1',
        title: 'Tài liệu thử nghiệm',
        subject: 'Toán cao cấp',
        type: DocumentType.exercise,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(
        () async => await repository.addDocument(doc),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Chỉ người dùng đã xác thực mới được tạo tài liệu mới'),
          ),
        ),
      );
    });

    test('syncUserProfile: Ném ngoại lệ ArgumentError khi UID hoặc Email rỗng', () async {
      final repository = SupabaseDocumentRepository();

      expect(
        () async => await repository.syncUserProfile(uid: '', email: 'test@example.com'),
        throwsA(isA<ArgumentError>()),
      );

      expect(
        () async => await repository.syncUserProfile(uid: 'uid123', email: ''),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
