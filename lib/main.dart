import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/supabase_config.dart';
import 'data/datasources/document_local_datasource.dart';
import 'data/repositories/document_repository_impl.dart';
import 'data/repositories/firebase_document_storage_repository.dart';
import 'data/repositories/firestore_document_repository.dart';
import 'data/repositories/supabase_document_repository.dart';
import 'data/repositories/supabase_document_storage_repository.dart';
import 'domain/repositories/i_document_permission_repository.dart';
import 'domain/repositories/i_document_repository.dart';
import 'domain/repositories/i_document_storage_repository.dart';
import 'firebase_options.dart';
import 'presentation/controllers/document_controller.dart';
import 'presentation/screens/document_home_screen.dart';
import 'presentation/screens/firebase_auth_gate.dart';
import 'presentation/theme/app_theme.dart';
import 'usecases/add_document_usecase.dart';
import 'usecases/delete_document_usecase.dart';
import 'usecases/get_document_permissions_usecase.dart';
import 'usecases/get_document_stats_usecase.dart';
import 'usecases/get_documents_usecase.dart';
import 'usecases/revoke_document_permission_usecase.dart';
import 'usecases/search_documents_usecase.dart';
import 'usecases/share_document_usecase.dart';
import 'usecases/update_document_usecase.dart';
import 'usecases/upload_document_file_usecase.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Khởi tạo Firebase SDK (Google Identity Auth & Firebase Storage)
  bool isFirebaseReady = false;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    isFirebaseReady = true;
    debugPrint('Firebase initialized successfully.');
  } catch (e) {
    debugPrint('Firebase init notice: $e');
  }

  // 2. Khởi tạo Supabase SDK (PostgreSQL Database & Row Level Security)
  // Tích hợp Third-Party Auth: truyền accessToken async callback để Supabase Client
  // tự động gắn Firebase ID Token (JWT) vào header Authorization trên mọi truy vấn PostgREST.
  bool isSupabaseReady = false;
  if (SupabaseConfig.isConfigured) {
    try {
      await Supabase.initialize(
        url: SupabaseConfig.supabaseUrl,
        publishableKey: SupabaseConfig.supabaseAnonKey,
        accessToken: () async {
          final user = FirebaseAuth.instance.currentUser;
          if (user == null) return null;
          try {
            // Lấy ID Token đã được ký số bởi Firebase
            // Supabase Third-Party Auth sẽ giải mã và xác minh chữ ký này qua Google JWKS
            return await user.getIdToken();
          } catch (e) {
            debugPrint('Lỗi trích xuất Firebase ID Token cho Supabase: $e');
            return null;
          }
        },
      );
      isSupabaseReady = true;
      debugPrint(
        'Supabase initialized successfully với Firebase Third-Party Auth: ${SupabaseConfig.supabaseUrl}',
      );
    } catch (e) {
      debugPrint('Supabase init notice: $e');
    }
  }

  // 3. Khởi tạo Storage Repository: Ưu tiên Supabase Storage (Free Tier)
  // Lưu trữ tệp miễn phí, an toàn, không yêu cầu nâng cấp Firebase Blaze
  final IDocumentStorageRepository storageRepository = isSupabaseReady
      ? SupabaseDocumentStorageRepository()
      : FirebaseDocumentStorageRepository();
  final uploadDocumentFileUseCase = (isSupabaseReady || isFirebaseReady)
      ? UploadDocumentFileUseCase(repository: storageRepository)
      : null;

  // 4. Khởi tạo Database Repository:
  // Ưu tiên Supabase (3 bảng users, documents, permissions + RLS)
  // Dự phòng Firestore hoặc Local DataSource khi chưa có kết nối mạng
  late final IDocumentRepository documentRepository;
  IDocumentPermissionRepository? permissionRepository;

  if (isSupabaseReady) {
    final supabaseRepo = SupabaseDocumentRepository();
    documentRepository = supabaseRepo;
    permissionRepository = supabaseRepo;
    debugPrint('Using SupabaseDocumentRepository (Multi-tenant RLS active).');
  } else if (isFirebaseReady) {
    documentRepository = FirestoreDocumentRepository();
    debugPrint('Using FirestoreDocumentRepository fallback.');
  } else {
    documentRepository = DocumentRepositoryImpl(
      localDataSource: DocumentLocalDataSourceImpl(autoSeed: true),
    );
    debugPrint('Using DocumentRepositoryImpl in-memory fallback.');
  }

  // 5. Khởi tạo Tầng Use Cases
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

  final shareDocumentUseCase = permissionRepository != null
      ? ShareDocumentUseCase(repository: permissionRepository)
      : null;
  final getDocumentPermissionsUseCase = permissionRepository != null
      ? GetDocumentPermissionsUseCase(repository: permissionRepository)
      : null;
  final revokeDocumentPermissionUseCase = permissionRepository != null
      ? RevokeDocumentPermissionUseCase(repository: permissionRepository)
      : null;

  // 6. Khởi tạo DocumentController
  final documentController = DocumentController(
    addDocumentUseCase: addDocumentUseCase,
    updateDocumentUseCase: updateDocumentUseCase,
    deleteDocumentUseCase: deleteDocumentUseCase,
    searchDocumentsUseCase: searchDocumentsUseCase,
    getDocumentsUseCase: getDocumentsUseCase,
    getDocumentStatsUseCase: getDocumentStatsUseCase,
    uploadDocumentFileUseCase: uploadDocumentFileUseCase,
    shareDocumentUseCase: shareDocumentUseCase,
    getDocumentPermissionsUseCase: getDocumentPermissionsUseCase,
    revokeDocumentPermissionUseCase: revokeDocumentPermissionUseCase,
  );

  // Ở chế độ local chưa có Auth, nạp dữ liệu sớm
  // Ở chế độ Cloud, FirebaseAuthGate sẽ nạp sau khi người dùng đăng nhập thành công
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
      title: 'Quản lý Tài liệu Học tập (Firebase + Supabase)',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: useFirebase
          ? FirebaseAuthGate(controller: controller)
          : const DocumentHomeScreen(),
    );
  }
}
