import 'package:flutter_test/flutter_test.dart';
import 'package:study_document_manager/domain/entities/document_type.dart';
import 'package:study_document_manager/usecases/add_document_usecase.dart';

import '../mocks/mock_document_repository.dart';

void main() {
  late MockDocumentRepository mockRepository;
  late AddDocumentUseCase addDocumentUseCase;

  setUp(() {
    mockRepository = MockDocumentRepository();
    addDocumentUseCase = AddDocumentUseCase(repository: mockRepository);
  });

  group('AddDocumentUseCase Tests', () {
    test('Thêm tài liệu hợp lệ thành công và lưu vào repository', () async {
      // Arrange
      const params = AddDocumentParams(
        title: 'Bài giảng Kiến trúc Cashew',
        subject: 'Thiết kế Phần mềm',
        type: DocumentType.lecture,
        description: 'Chi tiết về Clean Architecture',
        fileUrlOrPath: 'https://example.com/slide.pdf',
        tags: ['flutter', 'clean-arch', 'flutter'], // Kiểm tra trùng tag
        isFavorite: true,
      );

      // Act
      final result = await addDocumentUseCase.execute(params);

      // Assert
      expect(result.id, isNotEmpty);
      expect(result.title, 'Bài giảng Kiến trúc Cashew');
      expect(result.subject, 'Thiết kế Phần mềm');
      expect(result.type, DocumentType.lecture);
      expect(result.isFavorite, true);
      expect(result.tags, ['flutter', 'clean-arch']); // Đã deduplicate
      expect(mockRepository.addDocumentCallCount, 1);
      expect(mockRepository.storage.length, 1);
    });

    test('Ném ngoại lệ ArgumentError khi tiêu đề rỗng', () async {
      // Arrange
      const params = AddDocumentParams(
        title: '   ',
        subject: 'Toán cao cấp',
        type: DocumentType.exercise,
      );

      // Act & Assert
      expect(
        () => addDocumentUseCase.execute(params),
        throwsA(isA<ArgumentError>().having(
          (e) => e.message,
          'message',
          contains('Tiêu đề tài liệu không được để trống'),
        )),
      );
      expect(mockRepository.addDocumentCallCount, 0);
    });

    test('Ném ngoại lệ ArgumentError khi tiêu đề ít hơn 2 ký tự', () async {
      // Arrange
      const params = AddDocumentParams(
        title: 'A',
        subject: 'Vật lý',
        type: DocumentType.exercise,
      );

      // Act & Assert
      expect(
        () => addDocumentUseCase.execute(params),
        throwsA(isA<ArgumentError>().having(
          (e) => e.message,
          'message',
          contains('ít nhất 2 ký tự'),
        )),
      );
      expect(mockRepository.addDocumentCallCount, 0);
    });

    test('Ném ngoại lệ ArgumentError khi môn học bị để trống', () async {
      // Arrange
      const params = AddDocumentParams(
        title: 'Tài liệu ôn thi cuối kỳ',
        subject: '   ',
        type: DocumentType.reference,
      );

      // Act & Assert
      expect(
        () => addDocumentUseCase.execute(params),
        throwsA(isA<ArgumentError>().having(
          (e) => e.message,
          'message',
          contains('Môn học không được để trống'),
        )),
      );
      expect(mockRepository.addDocumentCallCount, 0);
    });
  });
}
