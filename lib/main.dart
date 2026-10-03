import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/datasources/document_local_datasource.dart';
import 'data/repositories/document_repository_impl.dart';
import 'presentation/controllers/document_controller.dart';
import 'presentation/screens/document_home_screen.dart';
import 'presentation/theme/app_theme.dart';
import 'usecases/add_document_usecase.dart';
import 'usecases/delete_document_usecase.dart';
import 'usecases/get_document_stats_usecase.dart';
import 'usecases/get_documents_usecase.dart';
import 'usecases/search_documents_usecase.dart';
import 'usecases/update_document_usecase.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Khởi tạo Tầng Data (Data Source & Repository Implementation)
  final localDataSource = DocumentLocalDataSourceImpl(autoSeed: true);
  final documentRepository = DocumentRepositoryImpl(
    localDataSource: localDataSource,
  );

  // 2. Khởi tạo Tầng Use Cases (Business Logic / Interactors)
  final addDocumentUseCase = AddDocumentUseCase(repository: documentRepository);
  final updateDocumentUseCase = UpdateDocumentUseCase(repository: documentRepository);
  final deleteDocumentUseCase = DeleteDocumentUseCase(repository: documentRepository);
  final searchDocumentsUseCase = SearchDocumentsUseCase(repository: documentRepository);
  final getDocumentsUseCase = GetDocumentsUseCase(repository: documentRepository);
  final getDocumentStatsUseCase = GetDocumentStatsUseCase(repository: documentRepository);

  // 3. Khởi tạo Tầng Presentation Controller với Dependency Injection
  final documentController = DocumentController(
    addDocumentUseCase: addDocumentUseCase,
    updateDocumentUseCase: updateDocumentUseCase,
    deleteDocumentUseCase: deleteDocumentUseCase,
    searchDocumentsUseCase: searchDocumentsUseCase,
    getDocumentsUseCase: getDocumentsUseCase,
    getDocumentStatsUseCase: getDocumentStatsUseCase,
  )..init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<DocumentController>.value(
          value: documentController,
        ),
      ],
      child: const StudyDocumentManagerApp(),
    ),
  );
}

class StudyDocumentManagerApp extends StatelessWidget {
  const StudyDocumentManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quản lý Tài liệu Học tập',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const DocumentHomeScreen(),
    );
  }
}
