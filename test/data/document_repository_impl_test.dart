import 'package:flutter_test/flutter_test.dart';
import 'package:study_document_manager/data/datasources/document_local_datasource.dart';
import 'package:study_document_manager/data/repositories/document_repository_impl.dart';
import 'package:study_document_manager/domain/entities/document.dart';
import 'package:study_document_manager/domain/entities/document_filter.dart';
import 'package:study_document_manager/domain/entities/document_type.dart';

void main() {
  late DocumentLocalDataSource dataSource;
  late DocumentRepositoryImpl repository;

  setUp(() {
    dataSource = DocumentLocalDataSourceImpl(autoSeed: false);
    repository = DocumentRepositoryImpl(localDataSource: dataSource);
  });

  group('DocumentRepositoryImpl (Data Layer) Tests', () {
    test('Thêm tài liệu và lấy lại chính xác qua ID (Model <-> Entity)', () async {
      // Arrange
      final newDoc = Document(
        id: 'repo-test-1',
        title: 'Giáo trình Mạng Máy Tính',
        subject: 'Mạng Máy Tính',
        type: DocumentType.lecture,
        description: 'Tổng quan mô hình OSI & TCP/IP',
        fileUrlOrPath: 'https://example.com/network.pdf',
        tags: const ['network', 'osi', 'tcp'],
        isFavorite: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Act
      final savedDoc = await repository.addDocument(newDoc);
      final fetchedDoc = await repository.getDocumentById('repo-test-1');

      // Assert
      expect(savedDoc.id, 'repo-test-1');
      expect(fetchedDoc, isNotNull);
      expect(fetchedDoc!.title, 'Giáo trình Mạng Máy Tính');
      expect(fetchedDoc.type, DocumentType.lecture);
      expect(fetchedDoc.tags.length, 3);
      expect(fetchedDoc.isFavorite, true);
    });

    test('Cập nhật tài liệu trong Data Layer thành công', () async {
      // Arrange
      final initialDoc = Document(
        id: 'repo-test-2',
        title: 'Bài tập SQL Cơ bản',
        subject: 'Cơ sở Dữ liệu',
        type: DocumentType.exercise,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await repository.addDocument(initialDoc);

      // Act
      final updated = initialDoc.copyWith(
        title: 'Bài tập SQL Nâng cao (JOIN & GROUP BY)',
        isFavorite: true,
      );
      final result = await repository.updateDocument(updated);

      // Assert
      expect(result.title, 'Bài tập SQL Nâng cao (JOIN & GROUP BY)');
      expect(result.isFavorite, true);
      final retrieved = await repository.getDocumentById('repo-test-2');
      expect(retrieved?.title, 'Bài tập SQL Nâng cao (JOIN & GROUP BY)');
    });

    test('Xóa tài liệu khỏi Data Layer thành công', () async {
      // Arrange
      final doc = Document(
        id: 'repo-test-3',
        title: 'Tài liệu chuẩn bị xóa',
        subject: 'Hóa đại cương',
        type: DocumentType.reference,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await repository.addDocument(doc);

      // Act
      final deleted = await repository.deleteDocument('repo-test-3');
      final fetched = await repository.getDocumentById('repo-test-3');

      // Assert
      expect(deleted, true);
      expect(fetched, isNull);
    });

    test('Lấy danh sách tất cả môn học và thẻ tags', () async {
      // Arrange
      await repository.addDocument(Document(
        id: '1',
        title: 'Doc 1',
        subject: 'Toán',
        type: DocumentType.lecture,
        tags: const ['tagA', 'tagB'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
      await repository.addDocument(Document(
        id: '2',
        title: 'Doc 2',
        subject: 'Lý',
        type: DocumentType.exercise,
        tags: const ['tagB', 'tagC'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      // Act
      final subjects = await repository.getAllSubjects();
      final tags = await repository.getAllTags();

      // Assert
      expect(subjects, containsAll(['Toán', 'Lý']));
      expect(tags, containsAll(['tagA', 'tagB', 'tagC']));
    });

    test('Lọc tài liệu theo DocumentFilter', () async {
      // Arrange
      await repository.addDocument(Document(
        id: '1',
        title: 'Đề thi Lý thuyết',
        subject: 'Toán',
        type: DocumentType.lecture,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
      await repository.addDocument(Document(
        id: '2',
        title: 'Đề thi Thực hành',
        subject: 'Toán',
        type: DocumentType.exercise,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      // Act
      final results = await repository.searchDocuments(
        const DocumentFilter(type: DocumentType.exercise),
      );

      // Assert
      expect(results.length, 1);
      expect(results.first.id, '2');
    });
  });
}
