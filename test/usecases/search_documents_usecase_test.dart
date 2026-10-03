import 'package:flutter_test/flutter_test.dart';
import 'package:study_document_manager/domain/entities/document.dart';
import 'package:study_document_manager/domain/entities/document_filter.dart';
import 'package:study_document_manager/domain/entities/document_type.dart';
import 'package:study_document_manager/usecases/search_documents_usecase.dart';

import '../mocks/mock_document_repository.dart';

void main() {
  late MockDocumentRepository mockRepository;
  late SearchDocumentsUseCase searchDocumentsUseCase;

  setUp(() {
    mockRepository = MockDocumentRepository();
    searchDocumentsUseCase = SearchDocumentsUseCase(repository: mockRepository);

    final now = DateTime.now();
    mockRepository.storage.addAll([
      Document(
        id: '1',
        title: 'Bài giảng Cấu trúc Dữ liệu & Giải thuật',
        subject: 'Khoa học Máy tính',
        type: DocumentType.lecture,
        tags: const ['algorithms', 'tree'],
        isFavorite: true,
        createdAt: now,
        updatedAt: now,
      ),
      Document(
        id: '2',
        title: 'Đề bài tập thực hành Flutter',
        subject: 'Lập trình Di động',
        type: DocumentType.exercise,
        tags: const ['flutter', 'mobile', 'dart'],
        isFavorite: false,
        createdAt: now,
        updatedAt: now,
      ),
      Document(
        id: '3',
        title: 'Sách tham khảo Clean Architecture',
        subject: 'Thiết kế Phần mềm',
        type: DocumentType.reference,
        tags: const ['clean-arch', 'patterns'],
        isFavorite: true,
        createdAt: now,
        updatedAt: now,
      ),
      Document(
        id: '4',
        title: 'Bài tập Giải thuật Dijkstra & Đồ thị',
        subject: 'Khoa học Máy tính',
        type: DocumentType.exercise,
        tags: const ['algorithms', 'graph'],
        isFavorite: false,
        createdAt: now,
        updatedAt: now,
      ),
    ]);
  });

  group('SearchDocumentsUseCase Tests', () {
    test('Tìm kiếm theo từ khóa trong tiêu đề (không phân biệt chữ hoa thường)', () async {
      // Act
      final results = await searchDocumentsUseCase.execute(
        const DocumentFilter(searchQuery: 'flutter'),
      );

      // Assert
      expect(results.length, 1);
      expect(results.first.id, '2');
      expect(mockRepository.searchDocumentsCallCount, 1);
    });

    test('Tìm kiếm theo thẻ tag', () async {
      // Act
      final results = await searchDocumentsUseCase.execute(
        const DocumentFilter(searchQuery: 'algorithms'),
      );

      // Assert: Có 2 tài liệu chứa tag algorithms (id: 1 và id: 4)
      expect(results.length, 2);
      expect(results.map((e) => e.id), containsAll(['1', '4']));
    });

    test('Lọc theo phân loại DocumentType (chỉ lấy Bài tập - exercise)', () async {
      // Act
      final results = await searchDocumentsUseCase.execute(
        const DocumentFilter(type: DocumentType.exercise),
      );

      // Assert
      expect(results.length, 2);
      expect(results.every((e) => e.type == DocumentType.exercise), true);
    });

    test('Lọc chỉ tài liệu yêu thích (isFavoriteOnly = true)', () async {
      // Act
      final results = await searchDocumentsUseCase.execute(
        const DocumentFilter(isFavoriteOnly: true),
      );

      // Assert
      expect(results.length, 2);
      expect(results.every((e) => e.isFavorite), true);
    });

    test('Kết hợp nhiều điều kiện: Bài tập + Môn học "Khoa học Máy tính"', () async {
      // Act
      final results = await searchDocumentsUseCase.execute(
        const DocumentFilter(
          type: DocumentType.exercise,
          subject: 'Khoa học Máy tính',
        ),
      );

      // Assert
      expect(results.length, 1);
      expect(results.first.id, '4');
    });

    test('Trả về danh sách rỗng khi không khớp tiêu chí nào', () async {
      // Act
      final results = await searchDocumentsUseCase.execute(
        const DocumentFilter(searchQuery: 'Không tồn tại từ khóa này xyz'),
      );

      // Assert
      expect(results.isEmpty, true);
    });
  });
}
