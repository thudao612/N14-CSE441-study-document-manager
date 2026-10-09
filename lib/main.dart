import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/datasources/document_local_datasource.dart';
import 'data/repositories/document_repository_impl.dart';
import 'data/repositories/firestore_document_repository.dart';
import 'domain/repositories/i_document_repository.dart';
import 'firebase_options.dart';
import 'presentation/controllers/document_controller.dart';
import 'presentation/screens/document_home_screen.dart';
import 'presentation/screens/firebase_auth_gate.dart';
import 'presentation/theme/app_theme.dart';
import 'usecases/add_document_usecase.dart';
import 'usecases/delete_document_usecase.dart';
import 'usecases/get_document_stats_usecase.dart';
import 'usecases/get_documents_usecase.dart';
import 'usecases/search_documents_usecase.dart';
import 'usecases/update_document_usecase.dart';
import 'usecases/upload_document_file_usecase.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Khởi tạo Firebase SDK kết nối Cloud
  bool isFirebaseReady = false;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    isFirebaseReady = true;
  } catch (e) {
    debugPrint('Firebase init notice: $e');
  }

  // 1. Chuyển đổi Data Source / Repository sang FirestoreDocumentRepository
  // Kết nối và đồng bộ trực tiếp collection 'documents' trên Cloud Firestore
  final IDocumentRepository documentRepository = isFirebaseReady
      ? FirestoreDocumentRepository()
      : DocumentRepositoryImpl(
          localDataSource: DocumentLocalDataSourceImpl(autoSeed: true),
        );

  // 2. Chế độ tài liệu: Sử dụng liên kết trực tiếp (Google Drive / Web URL) lưu trên Cloud Firestore
  // Loại bỏ hoàn toàn upload tệp trực tiếp để tránh lỗi 401 Unauthorized
  const UploadDocumentFileUseCase? uploadDocumentFileUseCase = null;

  final addDocumentUseCase = AddDocumentUseCase(
    repository: documentRepository,
  );
  final updateDocumentUseCase = UpdateDocumentUseCase(
    repository: documentRepository,
  );
  final deleteDocumentUseCase = DeleteDocumentUseCase(
    repository: documentRepository,
  );
  final searchDocumentsUseCase = SearchDocumentsUseCase(
    repository: documentRepository,
  );
  final getDocumentsUseCase = GetDocumentsUseCase(
    repository: documentRepository,
  );
  final getDocumentStatsUseCase = GetDocumentStatsUseCase(
    repository: documentRepository,
  );

  final documentController = DocumentController(
    addDocumentUseCase: addDocumentUseCase,
    updateDocumentUseCase: updateDocumentUseCase,
    deleteDocumentUseCase: deleteDocumentUseCase,
    searchDocumentsUseCase: searchDocumentsUseCase,
    getDocumentsUseCase: getDocumentsUseCase,
    getDocumentStatsUseCase: getDocumentStatsUseCase,
    uploadDocumentFileUseCase: uploadDocumentFileUseCase,
  );

  // Ở chế độ local chưa có Auth, nạp dữ liệu sớm
  // Ở chế độ Firebase, FirebaseAuthGate sẽ nạp sau khi người dùng đăng nhập thành công
  if (!isFirebaseReady) {
    await documentController.init();
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<DocumentController>.value(
          value: documentController,
        ),
      ],
      child: StudyDocumentManagerApp(
        useFirebase: isFirebaseReady,
      ),
    ),
  );
}

class StudyDocumentManagerApp extends StatelessWidget {
  final bool useFirebase;

  const StudyDocumentManagerApp({
    super.key,
    this.useFirebase = false,
  });

  @override
  Widget build(BuildContext context) {
    final controller = context.read<DocumentController>();

    return MaterialApp(
      title: 'Quản lý Tài liệu Học tập (Firebase)',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: useFirebase
          ? FirebaseAuthGate(controller: controller)
          : const DocumentHomeScreen(),
    );
  }
}
