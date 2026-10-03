import 'package:study_document_manager/domain/entities/document.dart';
import 'package:study_document_manager/domain/entities/document_filter.dart';
import 'package:study_document_manager/domain/entities/document_type.dart';
import 'package:study_document_manager/domain/repositories/i_document_repository.dart';

/// Mock Repository độc lập phục vụ kiểm thử đơn vị tầng Use Cases
/// Không phụ thuộc vào bất kỳ thư viện ngoài hay Tầng Data
class MockDocumentRepository implements IDocumentRepository {
  final List<Document> storage = [];

  // Theo dõi số lần phương thức được gọi
  int getAllDocumentsCallCount = 0;
  int getDocumentByIdCallCount = 0;
  int addDocumentCallCount = 0;
  int updateDocumentCallCount = 0;
  int deleteDocumentCallCount = 0;
  int searchDocumentsCallCount = 0;

  @override
  Future<List<Document>> getAllDocuments() async {
    getAllDocumentsCallCount++;
    return List<Document>.from(storage);
  }

  @override
  Future<Document?> getDocumentById(String id) async {
    getDocumentByIdCallCount++;
    try {
      return storage.firstWhere((doc) => doc.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Document> addDocument(Document document) async {
    addDocumentCallCount++;
    storage.removeWhere((doc) => doc.id == document.id);
    storage.insert(0, document);
    return document;
  }

  @override
  Future<Document> updateDocument(Document document) async {
    updateDocumentCallCount++;
    final index = storage.indexWhere((doc) => doc.id == document.id);
    if (index >= 0) {
      storage[index] = document;
      return document;
    }
    throw StateError('Không tìm thấy tài liệu ID: ${document.id}');
  }

  @override
  Future<bool> deleteDocument(String id) async {
    deleteDocumentCallCount++;
    final initial = storage.length;
    storage.removeWhere((doc) => doc.id == id);
    return storage.length < initial;
  }

  @override
  Future<List<Document>> searchDocuments(DocumentFilter filter) async {
    searchDocumentsCallCount++;
    return storage.where((doc) {
      if (filter.type != null && doc.type != filter.type) return false;
      if (filter.isFavoriteOnly && !doc.isFavorite) return false;
      if (filter.subject != null &&
          filter.subject!.isNotEmpty &&
          doc.subject.toLowerCase() != filter.subject!.toLowerCase()) {
        return false;
      }
      if (filter.tag != null &&
          filter.tag!.isNotEmpty &&
          !doc.tags.any((t) => t.toLowerCase() == filter.tag!.toLowerCase())) {
        return false;
      }
      if (filter.searchQuery != null && filter.searchQuery!.isNotEmpty) {
        final query = filter.searchQuery!.toLowerCase();
        final match = doc.title.toLowerCase().contains(query) ||
            doc.subject.toLowerCase().contains(query) ||
            doc.tags.any((t) => t.toLowerCase().contains(query));
        if (!match) return false;
      }
      return true;
    }).toList();
  }

  @override
  Future<List<Document>> getDocumentsByType(DocumentType type) async {
    return storage.where((doc) => doc.type == type).toList();
  }

  @override
  Future<List<String>> getAllSubjects() async {
    return storage.map((e) => e.subject).toSet().toList();
  }

  @override
  Future<List<String>> getAllTags() async {
    final tags = <String>{};
    for (final doc in storage) {
      tags.addAll(doc.tags);
    }
    return tags.toList();
  }
}
