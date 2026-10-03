import '../domain/entities/document.dart';
import '../domain/entities/document_filter.dart';
import '../domain/repositories/i_document_repository.dart';

/// Use Case: Tìm kiếm và lọc tài liệu học tập đa tiêu chí
class SearchDocumentsUseCase {
  final IDocumentRepository _repository;

  SearchDocumentsUseCase({required IDocumentRepository repository})
      : _repository = repository;

  Future<List<Document>> execute(DocumentFilter filter) async {
    return await _repository.searchDocuments(filter);
  }
}
