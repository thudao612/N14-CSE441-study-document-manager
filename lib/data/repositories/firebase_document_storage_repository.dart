import '../../domain/repositories/i_document_storage_repository.dart';
import 'cloudinary_document_storage_repository.dart';

/// Adapter thay thế Firebase Storage bằng Cloudinary Storage
/// Đáp ứng Checklist 6 (Cách 2): Không dùng SDK firebase_storage để tránh yêu cầu Blaze Plan
class FirebaseDocumentStorageRepository implements IDocumentStorageRepository {
  final IDocumentStorageRepository _storage;

  FirebaseDocumentStorageRepository({
    IDocumentStorageRepository? storage,
  }) : _storage = storage ?? CloudinaryDocumentStorageRepository();

  @override
  Future<String> uploadDocument({
    required String fileName,
    required List<int> bytes,
  }) {
    return _storage.uploadDocument(
      fileName: fileName,
      bytes: bytes,
    );
  }
}
