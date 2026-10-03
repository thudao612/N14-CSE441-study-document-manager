import '../entities/document.dart';
import '../entities/document_filter.dart';
import '../entities/document_type.dart';

/// Hợp đồng Repository trừu tượng (Domain Layer)
/// Định nghĩa các thao tác dữ liệu mà tầng Use Cases sử dụng mà không phụ thuộc vào tầng Data
abstract class IDocumentRepository {
  /// Lấy toàn bộ danh sách tài liệu
  Future<List<Document>> getAllDocuments();

  /// Lấy chi tiết tài liệu theo ID
  Future<Document?> getDocumentById(String id);

  /// Thêm tài liệu mới
  Future<Document> addDocument(Document document);

  /// Cập nhật thông tin tài liệu hiện có
  Future<Document> updateDocument(Document document);

  /// Xóa tài liệu theo ID (trả về true nếu xóa thành công)
  Future<bool> deleteDocument(String id);

  /// Tìm kiếm và lọc tài liệu theo bộ lọc tiêu chí
  Future<List<Document>> searchDocuments(DocumentFilter filter);

  /// Lấy danh sách tài liệu theo phân loại (Bài giảng, Bài tập, Tham khảo)
  Future<List<Document>> getDocumentsByType(DocumentType type);

  /// Lấy danh sách tất cả các môn học hiện có
  Future<List<String>> getAllSubjects();

  /// Lấy danh sách tất cả các nhãn (tags) hiện có
  Future<List<String>> getAllTags();
}
