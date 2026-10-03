import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:study_document_manager/domain/entities/document_type.dart';
import 'package:study_document_manager/main.dart';
import 'package:study_document_manager/presentation/controllers/document_controller.dart';
import 'package:study_document_manager/usecases/add_document_usecase.dart';
import 'package:study_document_manager/usecases/delete_document_usecase.dart';
import 'package:study_document_manager/usecases/get_document_stats_usecase.dart';
import 'package:study_document_manager/usecases/get_documents_usecase.dart';
import 'package:study_document_manager/usecases/search_documents_usecase.dart';
import 'package:study_document_manager/usecases/update_document_usecase.dart';

import 'mocks/mock_document_repository.dart';

void main() {
  testWidgets('Khởi tạo giao diện ứng dụng hiển thị đầy đủ các thành phần Cashew',
      (WidgetTester tester) async {
    final mockRepo = MockDocumentRepository();
    final controller = DocumentController(
      addDocumentUseCase: AddDocumentUseCase(repository: mockRepo),
      updateDocumentUseCase: UpdateDocumentUseCase(repository: mockRepo),
      deleteDocumentUseCase: DeleteDocumentUseCase(repository: mockRepo),
      searchDocumentsUseCase: SearchDocumentsUseCase(repository: mockRepo),
      getDocumentsUseCase: GetDocumentsUseCase(repository: mockRepo),
      getDocumentStatsUseCase: GetDocumentStatsUseCase(repository: mockRepo),
    );

    // Thêm 1 tài liệu mẫu
    await controller.addDocument(const AddDocumentParams(
      title: 'Tài liệu Widget Test',
      subject: 'Flutter',
      type: DocumentType.lecture,
    ));

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<DocumentController>.value(value: controller),
        ],
        child: const StudyDocumentManagerApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Kiểm tra AppBar
    expect(find.text('Tài liệu Học tập'), findsOneWidget);

    // Kiểm tra thanh tìm kiếm
    expect(find.byType(TextField), findsOneWidget);

    // Kiểm tra nút Thêm tài liệu
    expect(find.text('Thêm tài liệu'), findsOneWidget);

    // Kiểm tra tài liệu đã hiển thị
    expect(find.text('Tài liệu Widget Test'), findsOneWidget);
  });
}
