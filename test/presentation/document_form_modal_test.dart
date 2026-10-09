import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:study_document_manager/presentation/controllers/document_controller.dart';
import 'package:study_document_manager/presentation/widgets/document_form_modal.dart';
import 'package:study_document_manager/usecases/add_document_usecase.dart';
import 'package:study_document_manager/usecases/delete_document_usecase.dart';
import 'package:study_document_manager/usecases/get_document_stats_usecase.dart';
import 'package:study_document_manager/usecases/get_documents_usecase.dart';
import 'package:study_document_manager/usecases/search_documents_usecase.dart';
import 'package:study_document_manager/usecases/update_document_usecase.dart';

import '../mocks/mock_document_repository.dart';

void main() {
  late MockDocumentRepository mockRepo;
  late DocumentController controller;

  setUp(() {
    mockRepo = MockDocumentRepository();
    controller = DocumentController(
      addDocumentUseCase: AddDocumentUseCase(repository: mockRepo),
      updateDocumentUseCase: UpdateDocumentUseCase(repository: mockRepo),
      deleteDocumentUseCase: DeleteDocumentUseCase(repository: mockRepo),
      searchDocumentsUseCase: SearchDocumentsUseCase(repository: mockRepo),
      getDocumentsUseCase: GetDocumentsUseCase(repository: mockRepo),
      getDocumentStatsUseCase: GetDocumentStatsUseCase(repository: mockRepo),
    );
  });

  testWidgets('DocumentFormModal: Giao diện nhập URL duy nhất và kiểm tra validation',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                DocumentFormModal.show(context, controller: controller);
              },
              child: const Text('Open Modal'),
            ),
          ),
        ),
      ),
    );

    // Mở modal
    await tester.tap(find.text('Open Modal'));
    await tester.pumpAndSettle();

    // 1. Kiểm tra tiêu đề modal
    expect(find.text('Thêm tài liệu học tập'), findsOneWidget);

    // 2. Kiểm tra nhãn trường URL là duy nhất (không còn tab upload file trực tiếp)
    expect(
      find.text('Liên kết tài liệu (URL / Google Drive / Web) *'),
      findsOneWidget,
    );
    expect(find.text('Tệp / Cloud'), findsNothing);
    expect(find.text('Bấm để chọn tệp PDF hoặc Word từ máy'), findsNothing);

    // 3. Bấm Submit khi form rỗng -> Kiểm tra validation lỗi
    await tester.tap(find.text('Thêm tài liệu'));
    await tester.pumpAndSettle();

    expect(find.text('Vui lòng nhập tiêu đề tài liệu'), findsOneWidget);
    expect(find.text('Vui lòng nhập tên môn học'), findsOneWidget);
    expect(
      find.text('Vui lòng nhập đường liên kết tài liệu (URL / Drive / Web)'),
      findsOneWidget,
    );

    // 4. Nhập tiêu đề và môn học hợp lệ, nhưng URL không có scheme http/https
    final textFields = find.byType(TextFormField);
    // index 0: title, index 1: subject, index 2: link/fileUrl, index 3: desc, index 4: tag
    await tester.enterText(textFields.at(0), 'Tài liệu Ôn tập Toán rời rạc');
    await tester.enterText(textFields.at(1), 'Toán rời rạc');
    await tester.enterText(textFields.at(2), 'invalid-url-without-http');

    await tester.tap(find.text('Thêm tài liệu'));
    await tester.pumpAndSettle();

    expect(
      find.text('Đường link không hợp lệ (cần bắt đầu bằng http:// hoặc https://)'),
      findsOneWidget,
    );

    // 5. Nhập URL Google Drive hợp lệ
    await tester.enterText(
      textFields.at(2),
      'https://drive.google.com/file/d/1A2B3C4D5E/view',
    );
    await tester.pumpAndSettle();

    // Bấm Submit
    await tester.tap(find.text('Thêm tài liệu'));
    await tester.pumpAndSettle();

    // Modal đã đóng sau khi thêm thành công
    expect(find.text('Thêm tài liệu học tập'), findsNothing);

    // Kiểm tra trong controller / repository
    expect(controller.documents.length, 1);
    final savedDoc = controller.documents.first;
    expect(savedDoc.title, 'Tài liệu Ôn tập Toán rời rạc');
    expect(savedDoc.subject, 'Toán rời rạc');
    expect(
      savedDoc.fileUrlOrPath,
      'https://drive.google.com/file/d/1A2B3C4D5E/view',
    );
  });
}
