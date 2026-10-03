import '../domain/repositories/i_document_repository.dart';

/// Use Case: Xóa tài liệu học tập
class DeleteDocumentUseCase {
  final IDocumentRepository _repository;

  DeleteDocumentUseCase({required IDocumentRepository repository})
      : _repository = repository;

  Future<bool> execute(String id) async {
    final trimmedId = id.trim();
    if (trimmedId.isEmpty) {
      throw ArgumentError('Mã định danh (ID) tài liệu không được để trống.');
    }

    return await _repository.deleteDocument(trimmedId);
  }
}
