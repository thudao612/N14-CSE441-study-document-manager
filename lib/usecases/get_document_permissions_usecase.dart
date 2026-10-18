import '../domain/entities/document_permission.dart';
import '../domain/repositories/i_document_permission_repository.dart';

class GetDocumentPermissionsUseCase {
  final IDocumentPermissionRepository _repository;

  GetDocumentPermissionsUseCase({
    required IDocumentPermissionRepository repository,
  }) : _repository = repository;

  Future<List<DocumentPermission>> execute(String documentId) {
    if (documentId.trim().isEmpty) {
      throw ArgumentError('Mã tài liệu không được để trống.');
    }
    return _repository.getPermissions(documentId.trim());
  }
}
