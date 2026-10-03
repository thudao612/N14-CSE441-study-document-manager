import '../domain/entities/document.dart';
import '../domain/repositories/i_document_repository.dart';

/// Use Case: Lấy danh sách tài liệu hoặc tài liệu theo ID
class GetDocumentsUseCase {
  final IDocumentRepository _repository;

  GetDocumentsUseCase({required IDocumentRepository repository})
      : _repository = repository;

  Future<List<Document>> execute() async {
    return await _repository.getAllDocuments();
  }

  Future<Document?> getById(String id) async {
    if (id.trim().isEmpty) return null;
    return await _repository.getDocumentById(id.trim());
  }

  Future<List<String>> getAllSubjects() async {
    return await _repository.getAllSubjects();
  }

  Future<List<String>> getAllTags() async {
    return await _repository.getAllTags();
  }
}
