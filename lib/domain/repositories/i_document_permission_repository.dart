import '../entities/app_user.dart';
import '../entities/document_permission.dart';

/// Hợp đồng Repository quản lý quyền chia sẻ tài liệu (Domain Layer)
abstract class IDocumentPermissionRepository {
  /// Lấy danh sách các quyền đã cấp của một tài liệu
  Future<List<DocumentPermission>> getPermissions(String documentId);

  /// Chia sẻ tài liệu cho một người dùng qua email với vai trò 'viewer' hoặc 'editor'
  Future<DocumentPermission> shareDocument({
    required String documentId,
    required String targetEmail,
    required String role,
  });

  /// Thu hồi quyền chia sẻ tài liệu của một người dùng
  Future<bool> revokePermission({
    required String documentId,
    required String targetUserId,
  });

  /// Tìm kiếm người dùng theo email để hỗ trợ chia sẻ
  Future<List<AppUser>> searchUsers(String query);

  /// Đồng bộ hồ sơ người dùng đang đăng nhập vào bảng users trên Supabase
  Future<void> syncUserProfile({
    required String uid,
    required String email,
    String? displayName,
    String? photoUrl,
  });
}
