import 'package:dio/dio.dart';

/// Cấu hình thông số Cloudinary
/// Người dùng có thể điền trực tiếp giá trị vào đây hoặc truyền qua --dart-define
class CloudinaryConfig {
  /// BƯỚC 1: Dán Cloud Name lấy từ Cloudinary Dashboard vào đây:
  static const String cloudName = String.fromEnvironment(
    'CLOUDINARY_CLOUD_NAME',
    defaultValue: 'p3ww2vcn',
  );

  /// BƯỚC 2: Dán tên Upload Preset (chế độ Unsigned) vào đây:
  static const String uploadPreset = String.fromEnvironment(
    'CLOUDINARY_UPLOAD_PRESET',
    defaultValue: 'nhom14_upload',
  );

  /// Kiểm tra xem đã được cấu hình giá trị hợp lệ chưa
  static bool get isConfigured =>
      cloudName.isNotEmpty &&
      !cloudName.startsWith('DÁN_') &&
      uploadPreset.isNotEmpty &&
      !uploadPreset.startsWith('DÁN_');
}

/// Dịch vụ tải tệp lên Cloudinary thông qua Dio POST request (Unsigned Upload)
/// Endpoint: https://api.cloudinary.com/v1_1/[cloud_name]/auto/upload
class CloudinaryService {
  final Dio _dio;
  final String cloudName;
  final String uploadPreset;

  CloudinaryService({
    Dio? dio,
    String? cloudName,
    String? uploadPreset,
  })  : _dio = dio ?? Dio(),
        cloudName = cloudName ?? CloudinaryConfig.cloudName,
        uploadPreset = uploadPreset ?? CloudinaryConfig.uploadPreset;

  /// Tải tệp (PDF, Word, Docx, TXT) lên Cloudinary và trả về đường dẫn secure_url
  Future<String> uploadFile({
    required List<int> bytes,
    required String fileName,
    void Function(int sent, int total)? onProgress,
  }) async {
    if (fileName.trim().isEmpty) {
      throw ArgumentError('Tên tệp không được để trống.');
    }
    if (bytes.isEmpty) {
      throw ArgumentError('Nội dung tệp không được để trống.');
    }

    if (!CloudinaryConfig.isConfigured &&
        (cloudName.contains('Dán') || uploadPreset.contains('Dán'))) {
      throw Exception(
        'Chưa cấu hình Cloud Name hoặc Upload Preset hợp lệ trong CloudinaryConfig. '
        'Vui lòng điền thông số hoặc sử dụng tab "Link Drive/Web".',
      );
    }

    final safeName = _sanitizeFileName(fileName);
    final endpoint = 'https://api.cloudinary.com/v1_1/$cloudName/auto/upload';

    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(
        bytes,
        filename: safeName,
      ),
      'upload_preset': uploadPreset,
      'folder': 'study_documents',
    });

    try {
      final response = await _dio.post(
        endpoint,
        data: formData,
        onSendProgress: onProgress,
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final secureUrl =
            data['secure_url'] as String? ?? data['url'] as String?;
        if (secureUrl != null && secureUrl.isNotEmpty) {
          return secureUrl;
        }
      }

      throw Exception('Không nhận được secure_url từ phản hồi Cloudinary.');
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        final errorMsg =
            e.response?.data?['error']?['message'] ?? 'Unauthorized';
        throw Exception(
          'Lỗi 401 Unauthorized từ Cloudinary: $errorMsg.\n'
          'Vui lòng kiểm tra lại: Cloud Name ($cloudName) và đảm bảo Upload Preset ($uploadPreset) '
          'được tạo với Signing Mode là "Unsigned" trong Cloudinary Console.',
        );
      } else if (e.response?.statusCode == 400) {
        final errorMsg =
            e.response?.data?['error']?['message'] ?? 'Bad Request';
        throw Exception('Lỗi Cloudinary (400): $errorMsg');
      }

      throw Exception('Lỗi kết nối tải tệp lên Cloudinary: ${e.message}');
    } catch (e) {
      throw Exception('Lỗi trong quá trình upload: $e');
    }
  }

  String _sanitizeFileName(String fileName) {
    final name = fileName.replaceAll('\\', '/').split('/').last.trim();
    final safeName = name.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    return safeName.isEmpty ? 'document' : safeName;
  }
}
