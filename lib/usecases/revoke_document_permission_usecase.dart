import '../domain/repositories/i_document_permission_repository.dart';

class RevokeDocumentPermissionUseCase {
  final IDocumentPermissionRepository _repository;

  RevokeDocumentPermissionUseCase({
    required IDocumentPermissionRepository repository,
  }) : _repository = repository;

  Future<bool> execute({
    required String documentId,
    required String targetUserId,
  }) {
    if (documentId.trim().isEmpty) {
      throw ArgumentError('Mã tài liệu không được để trống.');
    }
    if (targetUserId.trim().isEmpty) {
      throw ArgumentError('Mã người dùng cần thu hồi không được để trống.');
    }
    return _repository.revokePermission(
      documentId: documentId.trim(),
      targetUserId: targetUserId.trim(),
    );
  }
}
