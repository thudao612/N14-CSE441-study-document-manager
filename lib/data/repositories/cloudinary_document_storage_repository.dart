import '../../domain/repositories/i_document_storage_repository.dart';
import '../services/cloudinary_service.dart';

/// Triển khai IDocumentStorageRepository sử dụng CloudinaryService (Dio POST)
/// Tải tệp lên Cloudinary miễn phí, không yêu cầu Firebase Blaze Plan
class CloudinaryDocumentStorageRepository implements IDocumentStorageRepository {
  final CloudinaryService _service;

  CloudinaryDocumentStorageRepository({
    CloudinaryService? service,
    String? cloudName,
    String? uploadPreset,
  }) : _service = service ??
            CloudinaryService(
              cloudName: cloudName,
              uploadPreset: uploadPreset,
            );

  @override
  Future<String> uploadDocument({
    required String fileName,
    required List<int> bytes,
  }) {
    return _service.uploadFile(
      bytes: bytes,
      fileName: fileName,
    );
  }
}
