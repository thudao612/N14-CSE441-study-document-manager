import 'package:flutter_test/flutter_test.dart';
import 'package:study_document_manager/domain/entities/document.dart';
import 'package:study_document_manager/domain/entities/document_type.dart';
import 'package:study_document_manager/usecases/update_document_usecase.dart';

import '../mocks/mock_document_repository.dart';

void main() {
  late MockDocumentRepository mockRepository;
  late UpdateDocumentUseCase updateDocumentUseCase;

  setUp(() {
    mockRepository = MockDocumentRepository();
    updateDocumentUseCase = UpdateDocumentUseCase(repository: mockRepository);
  });

  group('UpdateDocumentUseCase Tests', () {
    test('Cập nhật tài liệu thành công khi dữ liệu hợp lệ', () async {
      // Arrange
      final initialDoc = Document(
        id: 'doc-123',
        title: 'Tiêu đề cũ',
        subject: 'Môn học cũ',
        type: DocumentType.lecture,
        locationName: 'Phòng học A203',
        latitude: 21.0285,
        longitude: 105.8542,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
      );
      mockRepository.storage.add(initialDoc);

      const params = UpdateDocumentParams(
        id: 'doc-123',
        title: 'Tiêu đề mới đã sửa',
        subject: 'Môn học mới',
        type: DocumentType.exercise,
        description: 'Mô tả đã bổ sung',
        fileUrlOrPath: 'https://new-url.com',
        tags: ['updated', 'test'],
        isFavorite: true,
      );

      // Act
      final result = await updateDocumentUseCase.execute(params);

      // Assert
      expect(result.id, 'doc-123');
      expect(result.title, 'Tiêu đề mới đã sửa');
      expect(result.subject, 'Môn học mới');
      expect(result.type, DocumentType.exercise);
      expect(result.isFavorite, true);
      expect(result.locationName, 'Phòng học A203');
      expect(result.latitude, 21.0285);
      expect(result.longitude, 105.8542);
      expect(result.updatedAt.isAfter(initialDoc.updatedAt), true);
      expect(mockRepository.updateDocumentCallCount, 1);
    });

    test('Xóa vị trí ghim theo yêu cầu cập nhật', () async {
      final initialDoc = Document(
        id: 'doc-location',
        title: 'Tài liệu có vị trí',
        subject: 'Môn học',
        type: DocumentType.lecture,
        locationName: 'Phòng học A203',
        latitude: 21.0285,
        longitude: 105.8542,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      mockRepository.storage.add(initialDoc);

      final result = await updateDocumentUseCase.execute(
        const UpdateDocumentParams(
          id: 'doc-location',
          title: 'Tài liệu có vị trí',
          subject: 'Môn học',
          type: DocumentType.lecture,
          locationName: '',
          clearCoordinates: true,
        ),
      );

      expect(result.locationName, isEmpty);
      expect(result.latitude, isNull);
      expect(result.longitude, isNull);
    });

    test('Thay thế địa điểm cũ khi cập nhật sang địa điểm mới', () async {
      final initialDoc = Document(
        id: 'doc-location-update',
        title: 'Tài liệu',
        subject: 'Môn học',
        type: DocumentType.lecture,
        locationName: 'Học viện Kỹ thuật Mật mã',
        latitude: 20.9841,
        longitude: 105.7998,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      mockRepository.storage.add(initialDoc);

      final result = await updateDocumentUseCase.execute(
        const UpdateDocumentParams(
          id: 'doc-location-update',
          title: 'Tài liệu',
          subject: 'Môn học',
          type: DocumentType.lecture,
          locationName: 'Đại học Thủy lợi',
          latitude: 21.0077,
          longitude: 105.8264,
        ),
      );

      expect(result.locationName, 'Đại học Thủy lợi');
      expect(result.latitude, 21.0077);
      expect(result.longitude, 105.8264);
    });

    test('Ném ngoại lệ StateError khi ID không tồn tại', () async {
      // Arrange
      const params = UpdateDocumentParams(
        id: 'non-existing-id',
        title: 'Tài liệu không có',
        subject: 'Môn học',
        type: DocumentType.lecture,
      );

      // Act & Assert
      expect(
        () => updateDocumentUseCase.execute(params),
        throwsA(isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('Không tìm thấy tài liệu với ID'),
        )),
      );
    });

    test('Ném ngoại lệ ArgumentError khi tiêu đề cập nhật bị rỗng', () async {
      // Arrange
      final initialDoc = Document(
        id: 'doc-123',
        title: 'Tiêu đề hợp lệ',
        subject: 'Môn học',
        type: DocumentType.lecture,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      mockRepository.storage.add(initialDoc);

      const params = UpdateDocumentParams(
        id: 'doc-123',
        title: '   ',
        subject: 'Môn học',
        type: DocumentType.lecture,
      );

      // Act & Assert
      expect(
        () => updateDocumentUseCase.execute(params),
        throwsA(isA<ArgumentError>().having(
          (e) => e.message,
          'message',
          contains('Tiêu đề tài liệu không được để trống'),
        )),
      );
    });
  });
}
