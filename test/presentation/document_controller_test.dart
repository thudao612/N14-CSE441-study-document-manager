import 'package:flutter_test/flutter_test.dart';
import 'package:study_document_manager/domain/entities/document_type.dart';
import 'package:study_document_manager/presentation/controllers/document_controller.dart';
import 'package:study_document_manager/usecases/add_document_usecase.dart';
import 'package:study_document_manager/usecases/delete_document_usecase.dart';
import 'package:study_document_manager/usecases/get_document_stats_usecase.dart';
import 'package:study_document_manager/usecases/get_documents_usecase.dart';
import 'package:study_document_manager/usecases/search_documents_usecase.dart';
import 'package:study_document_manager/usecases/update_document_usecase.dart';

import '../mocks/mock_document_repository.dart';

void main() {
  late MockDocumentRepository mockRepository;
  late DocumentController controller;

  setUp(() {
    mockRepository = MockDocumentRepository();
    controller = DocumentController(
      addDocumentUseCase: AddDocumentUseCase(repository: mockRepository),
      updateDocumentUseCase: UpdateDocumentUseCase(repository: mockRepository),
      deleteDocumentUseCase: DeleteDocumentUseCase(repository: mockRepository),
      searchDocumentsUseCase: SearchDocumentsUseCase(repository: mockRepository),
      getDocumentsUseCase: GetDocumentsUseCase(repository: mockRepository),
      getDocumentStatsUseCase: GetDocumentStatsUseCase(repository: mockRepository),
    );
  });

  group('DocumentController (Presentation Layer) Tests', () {
    test('Khởi tạo và tải dữ liệu rỗng thành công', () async {
      await controller.init();

      expect(controller.documents.isEmpty, true);
      expect(controller.stats.totalCount, 0);
      expect(controller.isLoading, false);
      expect(controller.errorMessage, isNull);
    });

    test('Thêm tài liệu qua Controller cập nhật state và stats', () async {
      await controller.init();

      const params = AddDocumentParams(
        title: 'Tài liệu Controller Test',
        subject: 'Kiểm thử Phần mềm',
        type: DocumentType.lecture,
      );

      final success = await controller.addDocument(params);

      expect(success, true);
      expect(controller.documents.length, 1);
      expect(controller.stats.totalCount, 1);
      expect(controller.stats.lectureCount, 1);
      expect(controller.filteredDocuments.length, 1);
    });

    test('Thay đổi từ khóa tìm kiếm lọc danh sách kết quả', () async {
      await controller.init();

      await controller.addDocument(const AddDocumentParams(
        title: 'Lập trình Dart Cơ bản',
        subject: 'Mobile',
        type: DocumentType.lecture,
      ));
      await controller.addDocument(const AddDocumentParams(
        title: 'Bài tập Giải tích 1',
        subject: 'Toán',
        type: DocumentType.exercise,
      ));

      expect(controller.documents.length, 2);

      // Tìm kiếm "Dart"
      await controller.setSearchQuery('Dart');
      expect(controller.filteredDocuments.length, 1);
      expect(controller.filteredDocuments.first.title, contains('Dart'));

      // Xóa tìm kiếm
      await controller.setSearchQuery('');
      expect(controller.filteredDocuments.length, 2);
    });

    test('Lọc theo DocumentType', () async {
      await controller.init();

      await controller.addDocument(const AddDocumentParams(
        title: 'Bài giảng 1',
        subject: 'Môn A',
        type: DocumentType.lecture,
      ));
      await controller.addDocument(const AddDocumentParams(
        title: 'Bài tập 1',
        subject: 'Môn A',
        type: DocumentType.exercise,
      ));

      await controller.setTypeFilter(DocumentType.exercise);
      expect(controller.filteredDocuments.length, 1);
      expect(controller.filteredDocuments.first.type, DocumentType.exercise);

      // Nhấn lại để bỏ chọn
      await controller.setTypeFilter(DocumentType.exercise);
      expect(controller.filteredDocuments.length, 2);
    });

    test('Xóa tài liệu cập nhật danh sách và stats', () async {
      await controller.init();

      await controller.addDocument(const AddDocumentParams(
        title: 'Tài liệu cần xóa',
        subject: 'Môn B',
        type: DocumentType.reference,
      ));

      final docId = controller.documents.first.id;
      final deleted = await controller.deleteDocument(docId);

      expect(deleted, true);
      expect(controller.documents.isEmpty, true);
      expect(controller.stats.totalCount, 0);
    });
  });
}
