import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import '../../domain/repositories/i_document_storage_repository.dart';

/// Triển khai IDocumentStorageRepository kết nối trực tiếp Firebase Cloud Storage
/// Lưu trữ tệp vật lý (PDF, Word, TXT, ...) trên Cloud Storage an toàn
class FirebaseDocumentStorageRepository implements IDocumentStorageRepository {
  final FirebaseStorage _storage;
  final FirebaseAuth _auth;

  FirebaseDocumentStorageRepository({
    FirebaseStorage? storage,
    FirebaseAuth? auth,
  })  : _storage = storage ?? FirebaseStorage.instance,
        _auth = auth ?? FirebaseAuth.instance;

  @override
  Future<String> uploadDocument({
    required String fileName,
    required List<int> bytes,
  }) async {
    try {
      final user = _auth.currentUser;
      final userId = user?.uid ?? 'anonymous';
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      // Chuẩn hóa tên tệp an toàn
      final cleanFileName = fileName.replaceAll(RegExp(r'[^\w\.-]'), '_');
      final storagePath = 'documents/$userId/${timestamp}_$cleanFileName';

      final storageRef = _storage.ref().child(storagePath);

      // Nhận diện Content-Type phù hợp
      final ext = fileName.split('.').last.toLowerCase();
      String contentType = 'application/octet-stream';
      if (ext == 'pdf') {
        contentType = 'application/pdf';
      } else if (ext == 'doc') {
        contentType = 'application/msword';
      } else if (ext == 'docx') {
        contentType =
            'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      } else if (ext == 'txt') {
        contentType = 'text/plain';
      }

      final metadata = SettableMetadata(
        contentType: contentType,
        customMetadata: {
          'originalName': fileName,
          'uploadedBy': userId,
          'timestamp': timestamp.toString(),
        },
      );

      debugPrint('Uploading to Firebase Storage: $storagePath (${bytes.length} bytes)');

      // Tải tệp lên Firebase Storage
      final uploadTask = await storageRef.putData(
        Uint8List.fromList(bytes),
        metadata,
      );

      // Lấy URL công khai có chữ ký số để xem/tải
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      debugPrint('Firebase Storage upload successful. Download URL: $downloadUrl');

      return downloadUrl;
    } on FirebaseException catch (e) {
      debugPrint('Firebase Storage Error [${e.code}]: ${e.message}');
      if (e.code == 'unauthorized' || e.code == 'permission-denied') {
        throw Exception(
          'Lỗi quyền truy cập Firebase Storage (401/Permission Denied): '
          'Vui lòng kiểm tra Storage Security Rules trong Firebase Console.',
        );
      }
      throw Exception('Lỗi tải tệp Firebase Storage: ${e.message ?? e.code}');
    } catch (e) {
      debugPrint('General upload error: $e');
      throw Exception('Không thể tải tệp lên Firebase Storage: $e');
    }
  }
}
