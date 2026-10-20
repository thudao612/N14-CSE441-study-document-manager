import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

import '../../domain/entities/app_user.dart';
import '../../domain/entities/document.dart';
import '../../domain/entities/document_filter.dart';
import '../../domain/entities/document_permission.dart';
import '../../domain/entities/document_type.dart';
import '../../domain/repositories/i_document_permission_repository.dart';
import '../../domain/repositories/i_document_repository.dart';
import '../models/app_user_model.dart';
import '../models/document_model.dart';
import '../models/document_permission_model.dart';

/// Triển khai IDocumentRepository & IDocumentPermissionRepository kết nối Supabase PostgreSQL
/// Tận dụng Row Level Security (RLS) để phân quyền: Owner, Editor, Viewer
/// Tuyệt đối KHÔNG sử dụng service_role key; bảo mật 100% qua anon key & RLS policies
class SupabaseDocumentRepository
    implements IDocumentRepository, IDocumentPermissionRepository {
  final SupabaseClient? _clientOverride;
  final FirebaseAuth? _authOverride;

  SupabaseDocumentRepository({
    SupabaseClient? client,
    FirebaseAuth? auth,
  })  : _clientOverride = client,
        _authOverride = auth;

  /// Lấy FirebaseAuth an toàn
  FirebaseAuth? get _auth {
    final override = _authOverride;
    if (override != null) return override;
    try {
      return FirebaseAuth.instance;
    } catch (_) {
      return null;
    }
  }

  /// Lấy User hiện tại an toàn, không ném lỗi no-app khi chạy unit tests
  User? get _currentUser {
    try {
      return _auth?.currentUser;
    } catch (_) {
      return null;
    }
  }

  /// Lấy SupabaseClient đang hoạt động
  SupabaseClient get _client {
    final override = _clientOverride;
    if (override != null) return override;
    try {
      return Supabase.instance.client;
    } catch (e) {
      throw StateError(
        'Supabase chưa được khởi tạo. Vui lòng kiểm tra SupabaseConfig trong lib/core/config/supabase_config.dart.',
      );
    }
  }

  /// ID của người dùng Firebase hiện tại
  String? get _currentUserId => _currentUser?.uid;

  // ===========================================================================
  // 1. CÁC THAO TÁC TÀI LIỆU (IDocumentRepository)
  // ===========================================================================

  @override
  Future<List<Document>> getAllDocuments() async {
    try {
      final currentUid = _currentUserId;

      // Đảm bảo user profile đã được đồng bộ vào bảng users
      await _syncCurrentAuthUserSilently();

      // Truy vấn bảng documents kết hợp bảng permissions
      // Row Level Security (RLS) trên Supabase tự động lọc:
      // - Tài liệu do người dùng sở hữu (owner_id = current_user_id())
      // - Tài liệu được chia sẻ (nằm trong permissions)
      final response = await _client
          .from('documents')
          .select('*, permissions(role, user_id)')
          .order('updated_at', ascending: false);

      final List<dynamic> data = response as List<dynamic>;

      final documents = data.map((json) {
        final Map<String, dynamic> docMap = Map<String, dynamic>.from(json);

        // Xác định vai trò của người dùng trên tài liệu này:
        // 1. Nếu là chủ sở hữu (owner_id == currentUid) -> 'owner'
        // 2. Nếu không, tra cứu role từ permissions -> 'editor' hoặc 'viewer'
        String userRole = 'owner';
        final ownerId = docMap['owner_id'] as String? ?? docMap['userId'] ?? '';

        if (currentUid != null && ownerId.isNotEmpty && ownerId != currentUid) {
          userRole = 'viewer'; // Mặc định nếu được chia sẻ
          final permissionsRaw = docMap['permissions'];
          if (permissionsRaw is List && permissionsRaw.isNotEmpty) {
            for (final p in permissionsRaw) {
              if (p is Map && p['user_id'] == currentUid) {
                userRole = p['role'] as String? ?? 'viewer';
                break;
              }
            }
          }
        }

        docMap['user_role'] = userRole;
        final model = DocumentModel.fromJson(docMap);
        return model.toEntity();
      }).toList();

      return documents;
    } on PostgrestException catch (e) {
      debugPrint('Supabase PostgrestException [${e.code}]: ${e.message}');
      if (e.code == '42501' || e.message.contains('permission denied')) {
        throw Exception(
          'Lỗi bảo mật RLS: Không có quyền đọc tài liệu. '
          'Chi tiết: ${e.message}',
        );
      }
      throw Exception('Lỗi đọc tài liệu từ Supabase: ${e.message}');
    } catch (e) {
      debugPrint('Supabase getAllDocuments error: $e');
      throw Exception('Không thể tải danh sách tài liệu từ Supabase: $e');
    }
  }

  @override
  Future<Document?> getDocumentById(String id) async {
    try {
      final currentUid = _currentUserId;
      final response = await _client
          .from('documents')
          .select('*, permissions(role, user_id)')
          .eq('id', id)
          .maybeSingle();

      if (response == null) return null;

      final Map<String, dynamic> docMap = Map<String, dynamic>.from(response);
      final ownerId = docMap['owner_id'] as String? ?? docMap['userId'] ?? '';

      String userRole = 'owner';
      if (currentUid != null && ownerId.isNotEmpty && ownerId != currentUid) {
        userRole = 'viewer';
        final permissionsRaw = docMap['permissions'];
        if (permissionsRaw is List) {
          for (final p in permissionsRaw) {
            if (p is Map && p['user_id'] == currentUid) {
              userRole = p['role'] as String? ?? 'viewer';
              break;
            }
          }
        }
      }

      docMap['user_role'] = userRole;
      return DocumentModel.fromJson(docMap).toEntity();
    } catch (e) {
      debugPrint('Supabase getDocumentById error: $e');
      return null;
    }
  }

  @override
  Future<Document> addDocument(Document document) async {
    try {
      final user = _currentUser;
      if (user == null) {
        throw Exception(
          'Chỉ người dùng đã xác thực mới được tạo tài liệu mới. Vui lòng đăng nhập.',
        );
      }

      final currentUid = user.uid;
      final authorEmail = user.email ??
          (document.authorEmail.isNotEmpty
              ? document.authorEmail
              : '$currentUid@user.app');

      // 1. Đồng bộ người dùng vào bảng users trước để thỏa mãn khóa ngoại
      await syncUserProfile(
        uid: currentUid,
        email: authorEmail,
        displayName: user.displayName,
        photoUrl: user.photoURL,
      );

      // 2. Chuẩn bị entity hoàn chỉnh với thông tin chủ sở hữu
      final docToInsert = document.copyWith(
        userId: currentUid,
        authorEmail: authorEmail,
        userRole: 'owner',
      );

      final model = DocumentModel.fromEntity(docToInsert);
      final supabaseJson = model.toSupabaseJson();

      debugPrint(
          'Inserting document to Supabase: ${model.id} (owner: $currentUid)');
      await _client.from('documents').insert(supabaseJson);

      return docToInsert;
    } on PostgrestException catch (e) {
      debugPrint(
        'Supabase addDocument PostgrestException: [${e.code}] ${e.message} (details: ${e.details})',
      );
      if (e.code == '42501') {
        throw Exception(
          'Lỗi bảo mật RLS: Chỉ người dùng đã xác thực mới được tạo tài liệu mới.',
        );
      }
      throw Exception('Lỗi thêm tài liệu: ${e.message}');
    } catch (e) {
      debugPrint('Supabase addDocument error: $e');
      if (e is Exception) rethrow;
      throw Exception('Không thể tạo tài liệu trên Supabase: $e');
    }
  }

  @override
  Future<Document> updateDocument(Document document) async {
    try {
      final model = DocumentModel.fromEntity(document);
      final updateData = {
        'title': model.title,
        'subject': model.subject,
        'type': model.type,
        'description': model.description,
        'file_url': model.fileUrlOrPath,
        'file_name': model.rawFileName,
        'tags': model.tags,
        'is_favorite': model.isFavorite,
        'location_name': model.locationName,
        'lat': model.latitude,
        'long': model.longitude,
        'updated_at': DateTime.now().toIso8601String(),
      };

      debugPrint('Updating document on Supabase: ${document.id}');
      // RLS Policy "Update document as owner or editor" sẽ kiểm tra quyền ở tầng DB:
      // - Chủ sở hữu (owner_id = current_user_id()) -> THÀNH CÔNG
      // - Người được chia sẻ quyền 'editor' -> THÀNH CÔNG
      // - Người được chia sẻ quyền 'viewer' hoặc người lạ -> BỊ CHẶN!
      final res = await _client
          .from('documents')
          .update(updateData)
          .eq('id', document.id)
          .select();

      if ((res as List).isEmpty) {
        throw Exception(
          'Không thể cập nhật: Bạn không có quyền chỉnh sửa tài liệu này (Cần quyền Owner hoặc Editor) hoặc tài liệu không tồn tại.',
        );
      }

      return document;
    } on PostgrestException catch (e) {
      debugPrint('Supabase updateDocument PostgrestException: ${e.message}');
      if (e.code == '42501' || e.message.contains('permission denied')) {
        throw Exception(
          'Từ chối truy cập (RLS 42501): Bạn chỉ có quyền Xem (Viewer) nên không thể sửa tài liệu này.',
        );
      }
      throw Exception('Lỗi cập nhật tài liệu: ${e.message}');
    } catch (e) {
      debugPrint('Supabase updateDocument error: $e');
      throw Exception('Không thể cập nhật tài liệu trên Supabase: $e');
    }
  }

  @override
  Future<bool> deleteDocument(String id) async {
    try {
      debugPrint('Deleting document on Supabase: $id');
      // RLS Policy "Delete document only as owner":
      // Duy nhất chủ sở hữu mới có quyền xóa. Editor và Viewer bị RLS chặn!
      final res =
          await _client.from('documents').delete().eq('id', id).select();

      if ((res as List).isEmpty) {
        throw Exception(
          'Không thể xóa: Chỉ Chủ sở hữu (Owner) mới có quyền xóa tài liệu.',
        );
      }

      return true;
    } on PostgrestException catch (e) {
      debugPrint('Supabase deleteDocument PostgrestException: ${e.message}');
      if (e.code == '42501') {
        throw Exception(
          'Từ chối truy cập (RLS 42501): Chỉ Chủ sở hữu mới được phép xóa tài liệu.',
        );
      }
      return false;
    } catch (e) {
      debugPrint('Supabase deleteDocument error: $e');
      rethrow;
    }
  }

  @override
  Future<List<Document>> searchDocuments(DocumentFilter filter) async {
    final all = await getAllDocuments();
    return all.where((doc) => filter.matches(doc)).toList();
  }

  @override
  Future<List<Document>> getDocumentsByType(DocumentType type) async {
    final all = await getAllDocuments();
    return all.where((doc) => doc.type == type).toList();
  }

  @override
  Future<List<String>> getAllSubjects() async {
    final all = await getAllDocuments();
    final subjects = all
        .map((doc) => doc.subject.trim())
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList();
    subjects.sort();
    return subjects;
  }

  @override
  Future<List<String>> getAllTags() async {
    final all = await getAllDocuments();
    final tags = all
        .expand((doc) => doc.tags)
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toSet()
        .toList();
    tags.sort();
    return tags;
  }

  // ===========================================================================
  // 2. CÁC THAO TÁC QUẢN LÝ QUYỀN CHIA SẺ (IDocumentPermissionRepository)
  // ===========================================================================

  @override
  Future<List<DocumentPermission>> getPermissions(String documentId) async {
    try {
      final response = await _client
          .from('permissions')
          .select('*, users(email, display_name)')
          .eq('document_id', documentId);

      final List<dynamic> data = response as List<dynamic>;
      return data.map((json) {
        return DocumentPermissionModel.fromJson(Map<String, dynamic>.from(json))
            .toEntity();
      }).toList();
    } catch (e) {
      debugPrint('Supabase getPermissions error: $e');
      return [];
    }
  }

  @override
  Future<DocumentPermission> shareDocument({
    required String documentId,
    required String targetEmail,
    required String role,
  }) async {
    final cleanEmail = targetEmail.trim().toLowerCase();
    if (cleanEmail.isEmpty) {
      throw ArgumentError('Email người nhận không được để trống.');
    }
    if (role != 'viewer' && role != 'editor') {
      throw ArgumentError(
          'Quyền chia sẻ chỉ có thể là "viewer" hoặc "editor".');
    }

    try {
      // 1. Tìm thông tin người dùng trong bảng users theo email
      final userRecord = await _client
          .from('users')
          .select()
          .eq('email', cleanEmail)
          .maybeSingle();

      String targetUserId;
      if (userRecord != null) {
        targetUserId = userRecord['id'] as String;
      } else {
        // Nếu người dùng chưa từng đăng nhập, kiểm tra hoặc thông báo rõ ràng
        throw Exception(
          'Không tìm thấy tài khoản với email "$cleanEmail". '
          'Người dùng này cần đăng nhập vào ứng dụng ít nhất một lần để khởi tạo tài khoản trên hệ thống.',
        );
      }

      // 2. Không cho phép tự chia sẻ tài liệu cho chính mình
      if (targetUserId == _currentUserId) {
        throw Exception(
            'Bạn là Chủ sở hữu tài liệu này, không cần chia sẻ cho chính mình.');
      }

      // 3. Upsert quyền vào bảng permissions
      // RLS Policy "Grant permission only by document owner" kiểm tra người gọi có phải là chủ sở hữu
      final payload = {
        'document_id': documentId,
        'user_id': targetUserId,
        'role': role,
        'created_at': DateTime.now().toIso8601String(),
      };

      final response = await _client
          .from('permissions')
          .upsert(
            payload,
            onConflict: 'document_id,user_id',
          )
          .select('*, users(email, display_name)')
          .single();

      final model = DocumentPermissionModel.fromJson(
        Map<String, dynamic>.from(response),
      );
      return model.toEntity().copyWith(userEmail: cleanEmail);
    } on PostgrestException catch (e) {
      debugPrint(
          'Supabase shareDocument PostgrestException: ${e.message} (${e.code})');
      if (e.code == '42501') {
        throw Exception(
          'Lỗi phân quyền RLS: Chỉ Chủ sở hữu (Owner) mới có quyền chia sẻ tài liệu này.',
        );
      }
      throw Exception('Lỗi chia sẻ tài liệu: ${e.message}');
    } catch (e) {
      debugPrint('Supabase shareDocument error: $e');
      rethrow;
    }
  }

  @override
  Future<bool> revokePermission({
    required String documentId,
    required String targetUserId,
  }) async {
    try {
      debugPrint(
          'Revoking permission on doc $documentId for user $targetUserId');
      // RLS Policy "Revoke permission by document owner or self" kiểm tra quyền
      await _client
          .from('permissions')
          .delete()
          .eq('document_id', documentId)
          .eq('user_id', targetUserId);
      return true;
    } on PostgrestException catch (e) {
      debugPrint('Supabase revokePermission error: ${e.message}');
      if (e.code == '42501') {
        throw Exception(
          'Lỗi phân quyền RLS: Chỉ Chủ sở hữu mới có quyền thu hồi chia sẻ.',
        );
      }
      return false;
    } catch (e) {
      debugPrint('Supabase revokePermission error: $e');
      return false;
    }
  }

  @override
  Future<List<AppUser>> searchUsers(String query) async {
    final clean = query.trim().toLowerCase();
    if (clean.isEmpty) return [];

    try {
      final response = await _client
          .from('users')
          .select()
          .ilike('email', '%$clean%')
          .limit(10);

      final List<dynamic> data = response as List<dynamic>;
      return data
          .map((json) =>
              AppUserModel.fromJson(Map<String, dynamic>.from(json)).toEntity())
          .where((u) => u.id != _currentUserId)
          .toList();
    } catch (e) {
      debugPrint('Supabase searchUsers error: $e');
      return [];
    }
  }

  @override
  Future<void> syncUserProfile({
    required String uid,
    required String email,
    String? displayName,
    String? photoUrl,
    String? fcmToken,
  }) async {
    final cleanUid = uid.trim();
    final cleanEmail = email.trim().toLowerCase();
    if (cleanUid.isEmpty || cleanEmail.isEmpty) {
      throw ArgumentError(
        'UID và Email không được để trống khi đồng bộ hồ sơ người dùng.',
      );
    }

    try {
      final payload = <String, dynamic>{
        'id': cleanUid,
        'email': cleanEmail,
        'display_name': displayName ?? '',
        'photo_url': photoUrl ?? '',
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (fcmToken != null && fcmToken.trim().isNotEmpty) {
        payload['fcm_token'] = fcmToken.trim();
      }

      await _client.from('users').upsert(payload, onConflict: 'id');
      debugPrint('User profile synced to Supabase: $cleanEmail ($cleanUid)');
    } on PostgrestException catch (e) {
      debugPrint(
        'Supabase syncUserProfile PostgrestException: [${e.code}] ${e.message}',
      );
      if (e.code == '42501') {
        throw Exception(
          'Lỗi bảo mật RLS khi đồng bộ người dùng: Token Firebase chưa được Supabase xác thực.',
        );
      }
      throw Exception(
          'Lỗi đồng bộ hồ sơ người dùng lên Supabase: ${e.message}');
    } catch (e) {
      debugPrint('Supabase syncUserProfile error: $e');
      rethrow;
    }
  }

  /// Đồng bộ ngầm người dùng đang đăng nhập nếu có
  Future<void> _syncCurrentAuthUserSilently() async {
    final user = _currentUser;
    if (user != null) {
      final email = user.email ?? '${user.uid}@user.app';
      try {
        await syncUserProfile(
          uid: user.uid,
          email: email,
          displayName: user.displayName,
          photoUrl: user.photoURL,
        );
      } catch (e) {
        debugPrint('Thông báo đồng bộ nền: $e');
      }
    }
  }
}
