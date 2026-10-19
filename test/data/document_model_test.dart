import 'package:flutter_test/flutter_test.dart';
import 'package:study_document_manager/data/models/document_model.dart';
import 'package:study_document_manager/domain/entities/document.dart';
import 'package:study_document_manager/domain/entities/document_type.dart';

void main() {
  group('DocumentModel serialization & deserialization Tests', () {
    test('đọc và ghi tên địa điểm cùng tọa độ cho Firestore/Supabase', () {
      final model = DocumentModel.fromJson({
        'id': 'doc-location',
        'title': 'Tài liệu tại lớp',
        'subject': 'CNTT',
        'type': 'lecture',
        'description': '',
        'file_url': '',
        'tags': const <String>[],
        'is_favorite': false,
        'created_at': '2026-10-10T00:00:00.000',
        'updated_at': '2026-10-10T00:00:00.000',
        'location_name': 'Phòng học A203',
        'lat': 21.0285,
        'long': '105.8542',
      });

      expect(model.locationName, 'Phòng học A203');
      expect(model.latitude, 21.0285);
      expect(model.longitude, 105.8542);
      expect(model.toFirestoreJson()['lat'], 21.0285);
      expect(model.toFirestoreJson()['long'], 105.8542);
      expect(model.toSupabaseJson()['location_name'], 'Phòng học A203');
      expect(model.toSupabaseJson()['lat'], 21.0285);
      expect(model.toSupabaseJson()['long'], 105.8542);
      expect(model.toEntity().hasCoordinates, isTrue);
    });

    test('tọa độ không có trên dữ liệu cũ tiếp tục được hỗ trợ', () {
      final model = DocumentModel.fromJson({
        'id': 'legacy-doc',
        'title': 'Tài liệu cũ',
      });

      expect(model.locationName, isEmpty);
      expect(model.latitude, isNull);
      expect(model.longitude, isNull);
      expect(model.toEntity().hasCoordinates, isFalse);
    });

    test('fromJson map chính xác userId và authorEmail', () {
      final json = {
        'id': 'doc-123',
        'title': 'Cấu trúc Dữ liệu',
        'subject': 'CNTT',
        'type': 'lecture',
        'description': 'Mô tả bài học',
        'fileUrlOrPath': 'https://drive.google.com/file/d/abc/view',
        'tags': ['tree', 'graph'],
        'isFavorite': true,
        'createdAt': '2026-10-10T00:00:00.000',
        'updatedAt': '2026-10-10T00:00:00.000',
        'userId': 'user-uid-789',
        'authorEmail': 'sinhvien@test.edu.vn',
      };

      final model = DocumentModel.fromJson(json);

      expect(model.id, 'doc-123');
      expect(model.userId, 'user-uid-789');
      expect(model.authorEmail, 'sinhvien@test.edu.vn');
      expect(model.title, 'Cấu trúc Dữ liệu');
      expect(model.fileUrlOrPath, 'https://drive.google.com/file/d/abc/view');
    });

    test('toJson và toFirestoreJson xuất đầy đủ userId và authorEmail', () {
      const model = DocumentModel(
        id: 'doc-999',
        title: 'Mạng máy tính',
        subject: 'CNTT',
        type: 'exam',
        description: 'Đề thi cuối kỳ',
        fileUrlOrPath: 'https://example.com/exam.pdf',
        tags: ['exam', 'network'],
        isFavorite: false,
        createdAt: '2026-10-10T00:00:00.000',
        updatedAt: '2026-10-10T00:00:00.000',
        userId: 'uid-student-1',
        authorEmail: 'student1@school.edu.vn',
      );

      final json = model.toJson();
      final firestoreJson = model.toFirestoreJson();

      expect(json['id'], 'doc-999');
      expect(json['userId'], 'uid-student-1');
      expect(json['authorEmail'], 'student1@school.edu.vn');

      expect(firestoreJson.containsKey('id'),
          false); // Firestore doc ID tách riêng
      expect(firestoreJson['userId'], 'uid-student-1');
      expect(firestoreJson['authorEmail'], 'student1@school.edu.vn');
    });

    test('fromEntity và toEntity chuyển đổi chính xác qua lại', () {
      final entity = Document(
        id: 'doc-entity-1',
        title: 'Hệ điều hành',
        subject: 'Khoa học máy tính',
        type: DocumentType.lecture,
        description: 'Chương 1 Tiến trình',
        fileUrlOrPath: 'https://drive.google.com/os.pdf',
        tags: const ['process', 'thread'],
        isFavorite: true,
        createdAt: DateTime(2026, 10, 10),
        updatedAt: DateTime(2026, 10, 10),
        userId: 'uid-test-xyz',
        authorEmail: 'nguyenvana@gmail.com',
      );

      final model = DocumentModel.fromEntity(entity);
      expect(model.userId, 'uid-test-xyz');
      expect(model.authorEmail, 'nguyenvana@gmail.com');

      final convertedEntity = model.toEntity();
      expect(convertedEntity.userId, entity.userId);
      expect(convertedEntity.authorEmail, entity.authorEmail);
      expect(convertedEntity.title, entity.title);
    });
  });
}
