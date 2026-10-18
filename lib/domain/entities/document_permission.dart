/// Entity biểu diễn quyền truy cập tài liệu được chia sẻ (Domain Layer)
class DocumentPermission {
  final String id;
  final String documentId;
  final String userId;
  final String userEmail;
  final String role; // 'viewer' | 'editor'
  final DateTime createdAt;

  const DocumentPermission({
    required this.id,
    required this.documentId,
    required this.userId,
    required this.userEmail,
    required this.role,
    required this.createdAt,
  });

  bool get isEditor => role == 'editor';
  bool get isViewer => role == 'viewer';

  DocumentPermission copyWith({
    String? id,
    String? documentId,
    String? userId,
    String? userEmail,
    String? role,
    DateTime? createdAt,
  }) {
    return DocumentPermission(
      id: id ?? this.id,
      documentId: documentId ?? this.documentId,
      userId: userId ?? this.userId,
      userEmail: userEmail ?? this.userEmail,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DocumentPermission &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          documentId == other.documentId &&
          userId == other.userId &&
          role == other.role;

  @override
  int get hashCode =>
      id.hashCode ^ documentId.hashCode ^ userId.hashCode ^ role.hashCode;

  @override
  String toString() {
    return 'DocumentPermission(id: $id, doc: $documentId, user: $userEmail, role: $role)';
  }
}
