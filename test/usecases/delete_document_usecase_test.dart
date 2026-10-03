import 'package:flutter_test/flutter_test.dart';
import 'package:study_document_manager/domain/entities/document.dart';
import 'package:study_document_manager/domain/entities/document_type.dart';
import 'package:study_document_manager/usecases/delete_document_usecase.dart';

import '../mocks/mock_document_repository.dart';

void main() {
  late MockDocumentRepository mockRepository;
  late DeleteDocumentUseCase deleteDocumentUseCase;

  setUp(() {
    mockRepository = MockDocumentRepository();
    deleteDocumentUseCase = DeleteDocumentUseCase(repository: mockRepository);
  });

  group('DeleteDocumentUseCase Tests', () {
    test('Xóa tài liệu thành công với ID hợp lệ', () async {
      // Arrange
      final doc = Document(
        id: 'doc-to-delete',
        title: 'Tài liệu cần xóa',
        subject: 'Hệ điều hành',
        type: DocumentType.lecture,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      mockRepository.storage.add(doc);
      expect(mockRepository.storage.length, 1);

      // Act
      final result = await deleteDocumentUseCase.execute('doc-to-delete');

      // Assert
      expect(result, true);
      expect(mockRepository.deleteDocumentCallCount, 1);
      expect(mockRepository.storage.isEmpty, true);
    });

    test('Ném ngoại lệ ArgumentError khi ID truyền vào bị để trống', () async {
      // Act & Assert
      expect(
        () => deleteDocumentUseCase.execute('   '),
        throwsA(isA<ArgumentError>().having(
          (e) => e.message,
          'message',
          contains('Mã định danh (ID) tài liệu không được để trống'),
        )),
      );
      expect(mockRepository.deleteDocumentCallCount, 0);
    });
  });
}
