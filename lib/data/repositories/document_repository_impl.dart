import '../../domain/entities/document.dart';
import '../../domain/entities/document_filter.dart';
import '../../domain/entities/document_type.dart';
import '../../domain/repositories/i_document_repository.dart';
import '../datasources/document_local_datasource.dart';
import '../models/document_model.dart';

/// Triển khai IDocumentRepository tại Tầng Data
/// Chịu trách nhiệm kết nối Nguồn dữ liệu (DataSource) và ánh xạ với Tầng Domain
class DocumentRepositoryImpl implements IDocumentRepository {
  final DocumentLocalDataSource _localDataSource;

  DocumentRepositoryImpl({required DocumentLocalDataSource localDataSource})
      : _localDataSource = localDataSource;

  @override
  Future<List<Document>> getAllDocuments() async {
    final models = await _localDataSource.getDocuments();
    final entities = models.map((m) => m.toEntity()).toList();
    // Mặc định sắp xếp theo ngày cập nhật mới nhất
    entities.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return entities;
  }

  @override
  Future<Document?> getDocumentById(String id) async {
    final model = await _localDataSource.getDocumentById(id);
    return model?.toEntity();
  }

  @override
  Future<Document> addDocument(Document document) async {
    final model = DocumentModel.fromEntity(document);
    final savedModel = await _localDataSource.insertDocument(model);
    return savedModel.toEntity();
  }

  @override
  Future<Document> updateDocument(Document document) async {
    final model = DocumentModel.fromEntity(document);
    final updatedModel = await _localDataSource.updateDocument(model);
    return updatedModel.toEntity();
  }

  @override
  Future<bool> deleteDocument(String id) async {
    return await _localDataSource.deleteDocument(id);
  }

  @override
  Future<List<Document>> searchDocuments(DocumentFilter filter) async {
    final allDocs = await getAllDocuments();

    return allDocs.where((doc) {
      // 1. Lọc theo Phân loại tài liệu (lecture / exercise / reference)
      if (filter.type != null && doc.type != filter.type) {
        return false;
      }

      // 2. Lọc theo Yêu thích
      if (filter.isFavoriteOnly && !doc.isFavorite) {
        return false;
      }

      // 3. Lọc theo Môn học
      if (filter.subject != null && filter.subject!.trim().isNotEmpty) {
        if (doc.subject.toLowerCase() != filter.subject!.toLowerCase().trim()) {
          return false;
        }
      }

      // 4. Lọc theo Thẻ (Tag)
      if (filter.tag != null && filter.tag!.trim().isNotEmpty) {
        final targetTag = filter.tag!.toLowerCase().trim();
        final hasTag = doc.tags.any((t) => t.toLowerCase() == targetTag);
        if (!hasTag) {
          return false;
        }
      }

      // 5. Tìm kiếm từ khóa đa trường (Title, Subject, Description, Tags)
      if (filter.searchQuery != null && filter.searchQuery!.trim().isNotEmpty) {
        final query = filter.searchQuery!.toLowerCase().trim();
        final titleMatch = doc.title.toLowerCase().contains(query);
        final subjectMatch = doc.subject.toLowerCase().contains(query);
        final descMatch = doc.description.toLowerCase().contains(query);
        final tagMatch =
            doc.tags.any((tag) => tag.toLowerCase().contains(query));

        if (!titleMatch && !subjectMatch && !descMatch && !tagMatch) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  @override
  Future<List<Document>> getDocumentsByType(DocumentType type) async {
    final allDocs = await getAllDocuments();
    return allDocs.where((doc) => doc.type == type).toList();
  }

  @override
  Future<List<String>> getAllSubjects() async {
    final allDocs = await getAllDocuments();
    final subjects = allDocs
        .map((e) => e.subject.trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();
    subjects.sort((a, b) => a.compareTo(b));
    return subjects;
  }

  @override
  Future<List<String>> getAllTags() async {
    final allDocs = await getAllDocuments();
    final tags = <String>{};
    for (final doc in allDocs) {
      tags.addAll(doc.tags);
    }
    final sortedTags = tags.toList()..sort();
    return sortedTags;
  }
}
