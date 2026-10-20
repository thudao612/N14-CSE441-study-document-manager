import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

import '../../domain/entities/borrow_request.dart';
import '../../domain/repositories/i_borrow_request_repository.dart';
import '../models/borrow_request_model.dart';

/// Supabase implementation; RLS and database triggers remain the authority
/// for identity, approval permissions, and allowed status transitions.
class SupabaseBorrowRequestRepository implements IBorrowRequestRepository {
  final SupabaseClient? _clientOverride;
  final FirebaseAuth? _authOverride;

  SupabaseBorrowRequestRepository({
    SupabaseClient? client,
    FirebaseAuth? auth,
  })  : _clientOverride = client,
        _authOverride = auth;

  static const String _selectWithRelations =
      '*, requester:users!borrow_requests_requester_id_fkey(email, display_name), '
      'document:documents!borrow_requests_document_id_fkey(title)';

  FirebaseAuth? get _auth {
    if (_authOverride != null) return _authOverride;
    try {
      return FirebaseAuth.instance;
    } catch (_) {
      return null;
    }
  }

  User? get _currentUser {
    try {
      return _auth?.currentUser;
    } catch (_) {
      return null;
    }
  }

  SupabaseClient get _client {
    if (_clientOverride != null) return _clientOverride;
    try {
      return Supabase.instance.client;
    } catch (_) {
      throw StateError('Supabase chưa được khởi tạo.');
    }
  }

  User _requireCurrentUser() {
    final user = _currentUser;
    if (user == null) {
      throw StateError('Bạn cần đăng nhập để sử dụng chức năng mượn tài liệu.');
    }
    return user;
  }

  Future<void> _syncUserProfile(User user) async {
    final email = user.email?.trim().toLowerCase();
    await _client.from('users').upsert(
      <String, dynamic>{
        'id': user.uid,
        'email': (email != null && email.isNotEmpty)
            ? email
            : '${user.uid}@user.app',
        'display_name': user.displayName,
        'photo_url': user.photoURL,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      },
      onConflict: 'id',
    );
  }

  BorrowRequest _toEntity(dynamic json) =>
      BorrowRequestModel.fromJson(Map<String, dynamic>.from(json as Map))
          .toEntity();

  Exception _friendlyError(PostgrestException error) {
    debugPrint(
      'Supabase borrow request error [${error.code}]: ${error.message}',
    );
    if (error.code == '42501') {
      return Exception(
        'Bạn không có quyền thực hiện thao tác này. Hãy kiểm tra quyền chia sẻ hoặc quyền chủ sở hữu.',
      );
    }
    if (error.code == '23505') {
      return Exception(
        'Bạn đã có yêu cầu đang chờ duyệt hoặc đang mượn tài liệu này.',
      );
    }
    if (error.code == '23503') {
      return Exception(
        'Không tìm thấy tài liệu hoặc hồ sơ người dùng trên Supabase.',
      );
    }
    if (error.code == '22023') {
      return Exception('Trạng thái mượn trả không hợp lệ: ${error.message}');
    }
    if (error.code == 'PGRST116') {
      return Exception(
        'Không tìm thấy yêu cầu hoặc bạn không có quyền thực hiện thao tác này.',
      );
    }
    return Exception('Lỗi xử lý yêu cầu mượn: ${error.message}');
  }

  @override
  Future<BorrowRequest> createRequest({required String documentId}) async {
    final user = _requireCurrentUser();
    try {
      // Ensure requester_id satisfies the foreign key to public.users.
      await _syncUserProfile(user);
      final response = await _client
          .from('borrow_requests')
          .insert(<String, dynamic>{
            'document_id': documentId,
            'requester_id': user.uid,
          })
          .select(_selectWithRelations)
          .single();
      return _toEntity(response);
    } on PostgrestException catch (error) {
      throw _friendlyError(error);
    } catch (error) {
      debugPrint('Create borrow request failed: $error');
      rethrow;
    }
  }

  @override
  Future<List<BorrowRequest>> getRequestsForDocument({
    required String documentId,
  }) async {
    _requireCurrentUser();
    try {
      final response = await _client
          .from('borrow_requests')
          .select(_selectWithRelations)
          .eq('document_id', documentId)
          .order('requested_at', ascending: false);
      return (response as List)
          .map((row) => _toEntity(row))
          .toList(growable: false);
    } on PostgrestException catch (error) {
      throw _friendlyError(error);
    }
  }

  @override
  Future<BorrowRequest?> getLatestRequestForCurrentUser({
    required String documentId,
  }) async {
    final user = _requireCurrentUser();
    try {
      final response = await _client
          .from('borrow_requests')
          .select(_selectWithRelations)
          .eq('document_id', documentId)
          .eq('requester_id', user.uid)
          .order('requested_at', ascending: false)
          .limit(1)
          .maybeSingle();
      if (response == null) return null;
      return _toEntity(response);
    } on PostgrestException catch (error) {
      throw _friendlyError(error);
    }
  }

  @override
  Future<BorrowRequest> reviewRequest({
    required String requestId,
    required String status,
  }) async {
    if (status != BorrowRequest.approved && status != BorrowRequest.rejected) {
      throw ArgumentError.value(
        status,
        'status',
        'Chỉ được duyệt bằng approved hoặc rejected.',
      );
    }
    _requireCurrentUser();
    try {
      final response = await _client
          .from('borrow_requests')
          .update(<String, dynamic>{'status': status})
          .eq('id', requestId)
          .select(_selectWithRelations)
          .single();
      return _toEntity(response);
    } on PostgrestException catch (error) {
      throw _friendlyError(error);
    }
  }

  @override
  Future<BorrowRequest> markReturned({required String requestId}) async {
    _requireCurrentUser();
    try {
      final response = await _client
          .from('borrow_requests')
          .update(<String, dynamic>{'status': BorrowRequest.returned})
          .eq('id', requestId)
          .select(_selectWithRelations)
          .single();
      return _toEntity(response);
    } on PostgrestException catch (error) {
      throw _friendlyError(error);
    }
  }
}
