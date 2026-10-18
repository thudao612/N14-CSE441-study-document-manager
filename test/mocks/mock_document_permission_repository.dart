import 'package:study_document_manager/domain/entities/app_user.dart';
import 'package:study_document_manager/domain/entities/document.dart';
import 'package:study_document_manager/domain/entities/document_permission.dart';
import 'package:study_document_manager/domain/repositories/i_document_permission_repository.dart';

/// Mock Repository mô phỏng cơ chế Row Level Security (RLS) của Supabase
/// Dùng để kiểm thử các kịch bản phân quyền cho 3 tài khoản A, B, C
class MockDocumentPermissionRepository implements IDocumentPermissionRepository {
  String currentUserId = 'uid-a'; // Giả lập người dùng đang đăng nhập

  final Map<String, AppUser> usersTable = {
    'uid-a': const AppUser(
      id: 'uid-a',
      email: 'user_a@school.edu.vn',
      displayName: 'Nguyễn Văn A (Owner)',
    ),
    'uid-b': const AppUser(
      id: 'uid-b',
      email: 'user_b@school.edu.vn',
      displayName: 'Trần Thị B (Editor)',
    ),
    'uid-c': const AppUser(
      id: 'uid-c',
      email: 'user_c@school.edu.vn',
      displayName: 'Lê Văn C (Viewer)',
    ),
  };

  final Map<String, Document> documentsTable = {};
  final List<DocumentPermission> permissionsTable = [];

  void reset() {
    documentsTable.clear();
    permissionsTable.clear();
    currentUserId = 'uid-a';
  }

  // --- RLS PERMISSION CHECKERS ---

  bool isOwner(String documentId) {
    final doc = documentsTable[documentId];
    return doc != null && doc.userId == currentUserId;
  }

  bool isEditor(String documentId) {
    if (isOwner(documentId)) return true;
    return permissionsTable.any(
      (p) =>
          p.documentId == documentId &&
          p.userId == currentUserId &&
          p.role == 'editor',
    );
  }

  bool canView(String documentId) {
    if (isOwner(documentId)) return true;
    return permissionsTable.any(
      (p) => p.documentId == documentId && p.userId == currentUserId,
    );
  }

  // --- REPOSITORY IMPLEMENTATIONS ---

  @override
  Future<List<DocumentPermission>> getPermissions(String documentId) async {
    // RLS: Chỉ Owner hoặc người được chia sẻ mới xem được danh sách permissions
    if (!canView(documentId)) {
      throw Exception('RLS Permission Denied: Không thể xem danh sách quyền.');
    }
    return permissionsTable.where((p) => p.documentId == documentId).toList();
  }

  @override
  Future<DocumentPermission> shareDocument({
    required String documentId,
    required String targetEmail,
    required String role,
  }) async {
    // RLS: Duy nhất Chủ sở hữu mới có quyền cấp chia sẻ
    if (!isOwner(documentId)) {
      throw Exception(
        'RLS 42501: Chỉ Chủ sở hữu (Owner) mới có quyền cấp chia sẻ tài liệu.',
      );
    }

    final targetUser = usersTable.values.firstWhere(
      (u) => u.email.toLowerCase() == targetEmail.toLowerCase(),
      orElse: () => throw Exception('Không tìm thấy người dùng với email: $targetEmail'),
    );

    permissionsTable.removeWhere(
      (p) => p.documentId == documentId && p.userId == targetUser.id,
    );

    final perm = DocumentPermission(
      id: 'perm-${DateTime.now().millisecondsSinceEpoch}',
      documentId: documentId,
      userId: targetUser.id,
      userEmail: targetUser.email,
      role: role,
      createdAt: DateTime.now(),
    );

    permissionsTable.add(perm);
    return perm;
  }

  @override
  Future<bool> revokePermission({
    required String documentId,
    required String targetUserId,
  }) async {
    // RLS: Duy nhất Chủ sở hữu mới có quyền thu hồi chia sẻ
    if (!isOwner(documentId)) {
      throw Exception(
        'RLS 42501: Chỉ Chủ sở hữu (Owner) mới có quyền thu hồi chia sẻ.',
      );
    }

    final initialCount = permissionsTable.length;
    permissionsTable.removeWhere(
      (p) => p.documentId == documentId && p.userId == targetUserId,
    );
    return permissionsTable.length < initialCount;
  }

  @override
  Future<List<AppUser>> searchUsers(String query) async {
    final clean = query.toLowerCase();
    return usersTable.values
        .where((u) => u.email.toLowerCase().contains(clean))
        .toList();
  }

  @override
  Future<void> syncUserProfile({
    required String uid,
    required String email,
    String? displayName,
    String? photoUrl,
  }) async {
    usersTable[uid] = AppUser(
      id: uid,
      email: email,
      displayName: displayName ?? '',
      photoUrl: photoUrl ?? '',
    );
  }
}
