import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

import '../../core/config/supabase_config.dart';
import '../../domain/repositories/i_document_storage_repository.dart';

/// Triển khai IDocumentStorageRepository sử dụng Supabase Storage (Gói Free Tier)
/// Không yêu cầu nâng cấp Firebase Blaze plan, lưu trữ an toàn với Row Level Security.
class SupabaseDocumentStorageRepository implements IDocumentStorageRepository {
  final SupabaseClient? _customClient;
  final String _bucketName;
  final fb_auth.FirebaseAuth? _customAuth;

  SupabaseDocumentStorageRepository({
    SupabaseClient? client,
    String? bucketName,
    fb_auth.FirebaseAuth? auth,
  })  : _customClient = client,
        _bucketName = bucketName ?? SupabaseConfig.storageBucket,
        _customAuth = auth;

  SupabaseClient get _client {
    final custom = _customClient;
    if (custom != null) return custom;
    return Supabase.instance.client;
  }

  String get _currentUserId {
    try {
      final auth = _customAuth ?? fb_auth.FirebaseAuth.instance;
      return auth.currentUser?.uid ?? 'anonymous';
    } catch (_) {
      return 'anonymous';
    }
  }

  @override
  Future<String> uploadDocument({
    required String fileName,
    required List<int> bytes,
  }) async {
    try {
      final userId = _currentUserId;
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      // Chuẩn hóa tên tệp an toàn (thay thế ký tự đặc biệt)
      final cleanFileName = fileName.replaceAll(RegExp(r'[^\w\.-]'), '_');
      final storagePath = '$userId/${timestamp}_$cleanFileName';

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
      } else if (ext == 'png') {
        contentType = 'image/png';
      } else if (ext == 'jpg' || ext == 'jpeg') {
        contentType = 'image/jpeg';
      }

      debugPrint(
        'Đang tải tệp lên Supabase Storage bucket: $_bucketName path: $storagePath (${bytes.length} bytes)',
      );

      final storage = _client.storage.from(_bucketName);

      // Tải tệp nhị phân lên bucket
      await storage.uploadBinary(
        storagePath,
        Uint8List.fromList(bytes),
        fileOptions: FileOptions(
          contentType: contentType,
          upsert: true,
        ),
      );

      // Lấy URL công khai của tệp để xem và tải về
      final publicUrl = storage.getPublicUrl(storagePath);
      debugPrint('Tải lên Supabase Storage thành công! URL: $publicUrl');

      return publicUrl;
    } on StorageException catch (e) {
      debugPrint('Supabase StorageException [${e.statusCode}]: ${e.message}');
      final msg = e.message.toLowerCase();
      if (e.statusCode == '404' || msg.contains('not found') || msg.contains('bucket')) {
        throw Exception(
          'Bucket "$_bucketName" chưa tồn tại trên Supabase Storage. '
          'Vui lòng vào Supabase Dashboard -> Storage -> New Bucket -> đặt tên là "$_bucketName" '
          'và bật tùy chọn "Public bucket".',
        );
      }
      if (e.statusCode == '403' || msg.contains('row-level security') || msg.contains('policy')) {
        throw Exception(
          'Lỗi chính sách RLS trên Supabase Storage: Chưa cấp quyền tải tệp lên bucket "$_bucketName". '
          'Vui lòng thực hiện tạo Storage Policy theo hướng dẫn đính kèm.',
        );
      }
      throw Exception('Lỗi tải tệp Supabase Storage: ${e.message}');
    } catch (e) {
      debugPrint('General upload error: $e');
      throw Exception('Không thể tải tệp lên Supabase Storage: $e');
    }
  }

  /// Tạo URL có chữ ký bảo mật tạm thời (Signed URL) cho Private Bucket.
  /// Giúp ngăn chặn việc truy cập trái phép khi lộ đường dẫn tệp.
  Future<String> createSignedUrl(
    String storagePath, {
    int expiresIn = 300,
  }) async {
    try {
      final storage = _client.storage.from(_bucketName);
      final signedUrl = await storage.createSignedUrl(storagePath, expiresIn);
      debugPrint(
        'Đã tạo Signed URL bảo mật thành công (hết hạn sau ${expiresIn}s): $signedUrl',
      );
      return signedUrl;
    } on StorageException catch (e) {
      debugPrint('Supabase createSignedUrl error [${e.statusCode}]: ${e.message}');
      throw Exception('Lỗi tạo Signed URL trên Supabase Storage: ${e.message}');
    } catch (e) {
      debugPrint('Lỗi tạo Signed URL: $e');
      throw Exception('Không thể tạo Signed URL bảo mật: $e');
    }
  }
}
