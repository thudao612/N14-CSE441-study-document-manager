import '../domain/entities/document_permission.dart';
import '../domain/repositories/i_document_permission_repository.dart';

class ShareDocumentUseCase {
  final IDocumentPermissionRepository _repository;

  ShareDocumentUseCase({
    required IDocumentPermissionRepository repository,
  }) : _repository = repository;

  Future<DocumentPermission> execute({
    required String documentId,
    required String targetEmail,
    required String role,
  }) {
    if (documentId.trim().isEmpty) {
      throw ArgumentError('Mã tài liệu không được để trống.');
    }
    if (targetEmail.trim().isEmpty) {
      throw ArgumentError('Email người nhận không được để trống.');
    }
    if (role != 'viewer' && role != 'editor') {
      throw ArgumentError('Quyền chia sẻ chỉ có thể là "viewer" hoặc "editor".');
    }

    return _repository.shareDocument(
      documentId: documentId.trim(),
      targetEmail: targetEmail.trim(),
      role: role,
    );
  }
}
