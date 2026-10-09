import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/datasources/document_firestore_datasource.dart';
import 'data/datasources/document_local_datasource.dart';
import 'data/repositories/document_repository_impl.dart';
import 'data/repositories/firebase_document_storage_repository.dart';
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

  const useFirebase = bool.fromEnvironment(
    'USE_FIREBASE',
    defaultValue: false,
  );

  if (useFirebase) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  final DocumentLocalDataSource dataSource = useFirebase
      ? DocumentFirestoreDataSource()
      : DocumentLocalDataSourceImpl(autoSeed: true);

  final documentRepository = DocumentRepositoryImpl(
    localDataSource: dataSource,
  );

  final UploadDocumentFileUseCase? uploadDocumentFileUseCase = useFirebase
      ? UploadDocumentFileUseCase(
          repository: FirebaseDocumentStorageRepository(),
        )
      : null;

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

  // Nạp dữ liệu sớm ở chế độ local.
  // Khi sử dụng Firebase, FirebaseAuthGate sẽ nạp sau khi đăng nhập.
  if (!useFirebase) {
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
        useFirebase: useFirebase,
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
      title: 'Quản lý Tài liệu Học tập',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: useFirebase
          ? FirebaseAuthGate(controller: controller)
          : const DocumentHomeScreen(),
    );
  }
}
