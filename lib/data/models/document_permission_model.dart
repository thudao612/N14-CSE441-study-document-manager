import '../../domain/entities/document_permission.dart';

/// DTO chuyển đổi dữ liệu quyền chia sẻ từ bảng permissions trên Supabase
class DocumentPermissionModel {
  final String id;
  final String documentId;
  final String userId;
  final String userEmail;
  final String role;
  final String createdAt;

  const DocumentPermissionModel({
    required this.id,
    required this.documentId,
    required this.userId,
    required this.userEmail,
    required this.role,
    required this.createdAt,
  });

  factory DocumentPermissionModel.fromJson(Map<String, dynamic> json) {
    // Xử lý thông tin user nếu được JOIN từ bảng users (e.g. users(email))
    String email = json['userEmail'] as String? ??
        (json['user_email'] as String? ?? '');
    if (email.isEmpty && json['users'] != null && json['users'] is Map) {
      email = (json['users'] as Map)['email'] as String? ?? '';
    }

    return DocumentPermissionModel(
      id: json['id'] as String? ?? '',
      documentId: json['documentId'] as String? ??
          (json['document_id'] as String? ?? ''),
      userId: json['userId'] as String? ?? (json['user_id'] as String? ?? ''),
      userEmail: email,
      role: json['role'] as String? ?? 'viewer',
      createdAt: json['createdAt'] as String? ??
          (json['created_at'] as String? ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'document_id': documentId,
      'user_id': userId,
      'role': role,
      'created_at': createdAt,
    };
  }

  DocumentPermission toEntity() {
    return DocumentPermission(
      id: id,
      documentId: documentId,
      userId: userId,
      userEmail: userEmail,
      role: role,
      createdAt: DateTime.tryParse(createdAt) ?? DateTime.now(),
    );
  }
}
