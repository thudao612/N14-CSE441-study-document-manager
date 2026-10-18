import 'package:flutter_test/flutter_test.dart';
import 'package:study_document_manager/data/models/app_user_model.dart';
import 'package:study_document_manager/data/models/document_model.dart';
import 'package:study_document_manager/data/models/document_permission_model.dart';
import 'package:study_document_manager/domain/entities/document_type.dart';

void main() {
  group('Supabase Models Serialization & Deserialization Tests', () {
    test('DocumentPermissionModel: Chuyển đổi chính xác từ Supabase JSON và Entity', () {
      final json = {
        'id': 'perm-101',
        'document_id': 'doc-xyz',
        'user_id': 'uid-b',
        'role': 'editor',
        'created_at': '2026-10-13T10:00:00.000Z',
        'users': {
          'email': 'student_b@school.edu.vn',
          'display_name': 'Sinh viên B',
        },
      };

      final model = DocumentPermissionModel.fromJson(json);

      expect(model.id, 'perm-101');
      expect(model.documentId, 'doc-xyz');
      expect(model.userId, 'uid-b');
      expect(model.userEmail, 'student_b@school.edu.vn');
      expect(model.role, 'editor');

      final entity = model.toEntity();
      expect(entity.isEditor, true);
      expect(entity.isViewer, false);
      expect(entity.userEmail, 'student_b@school.edu.vn');

      final backJson = model.toJson();
      expect(backJson['document_id'], 'doc-xyz');
      expect(backJson['user_id'], 'uid-b');
      expect(backJson['role'], 'editor');
    });

    test('AppUserModel: Chuyển đổi chính xác từ Supabase users table JSON', () {
      final json = {
        'id': 'firebase-uid-123',
        'email': 'lecturer@university.edu.vn',
        'display_name': 'TS. Nguyễn Văn A',
        'photo_url': 'https://avatar.google.com/123.jpg',
      };

      final model = AppUserModel.fromJson(json);
      expect(model.id, 'firebase-uid-123');
      expect(model.email, 'lecturer@university.edu.vn');
      expect(model.displayName, 'TS. Nguyễn Văn A');

      final entity = model.toEntity();
      expect(entity.displayTitle, 'TS. Nguyễn Văn A');
      expect(entity.id, 'firebase-uid-123');
    });

    test('DocumentModel: toSupabaseJson xuất đúng tên cột PostgreSQL (snake_case)', () {
      final json = {
        'id': 'doc-pg-01',
        'title': 'Giáo trình Giải tích 1',
        'subject': 'Toán cao cấp',
        'type': 'lecture',
        'description': 'Tài liệu học kỳ 1',
        'file_url': 'https://firebasestorage.googleapis.com/.../giai_tich.pdf',
        'file_name': 'giai_tich.pdf',
        'file_size': 1024500,
        'tags': ['math', 'calculus'],
        'is_favorite': true,
        'owner_id': 'uid-teacher',
        'author_email': 'teacher@math.edu.vn',
        'created_at': '2026-10-13T08:00:00.000Z',
        'updated_at': '2026-10-13T08:00:00.000Z',
        'user_role': 'owner',
      };

      final model = DocumentModel.fromJson(json);
      expect(model.id, 'doc-pg-01');
      expect(model.userId, 'uid-teacher');
      expect(model.fileUrlOrPath, contains('firebasestorage'));
      expect(model.userRole, 'owner');
      expect(model.fileSize, 1024500);

      final entity = model.toEntity();
      expect(entity.isOwner, true);
      expect(entity.canEdit, true);
      expect(entity.isShared, false);
      expect(entity.type, DocumentType.lecture);

      final supabaseJson = model.toSupabaseJson();
      expect(supabaseJson['owner_id'], 'uid-teacher');
      expect(supabaseJson['file_url'], contains('firebasestorage'));
      expect(supabaseJson['file_name'], 'giai_tich.pdf');
      expect(supabaseJson['file_size'], 1024500);
      expect(supabaseJson['tags'], ['math', 'calculus']);
    });
  });
}
