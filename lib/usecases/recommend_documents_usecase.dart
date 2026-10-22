import '../domain/entities/document.dart';

/// Thuật toán Recommendation (Gợi ý tài liệu) - Tầng Nghiệp vụ Use Cases
/// Đề xuất các tài liệu phù hợp cho người dùng dựa trên:
/// 1. Các thẻ tags từ tài liệu yêu thích và tài liệu người dùng đã tương tác.
/// 2. Môn học (Subject) và phân loại tài liệu (DocumentType) thường xem.
class RecommendDocumentsUseCase {
  const RecommendDocumentsUseCase();

  /// Thực thi thuật toán gợi ý tài liệu
  /// - [allDocuments]: Toàn bộ danh sách tài liệu hiện có trong hệ thống
  /// - [currentUserId]: Mã định danh Firebase UID của người dùng hiện tại
  /// - [limit]: Số lượng tài liệu gợi ý tối đa cần lấy (mặc định 5)
  List<Document> execute({
    required List<Document> allDocuments,
    required String? currentUserId,
    int limit = 5,
  }) {
    if (allDocuments.isEmpty) return [];

    // 1. Xây dựng Hồ sơ Sở thích (User Interest Profile) của người dùng
    final userFavoriteTags = <String>{};
    final userFavoriteSubjects = <String>{};

    for (final doc in allDocuments) {
      final isOwner = currentUserId != null &&
          currentUserId.isNotEmpty &&
          doc.userId == currentUserId;
      // Thu thập thông tin từ tài liệu người dùng yêu thích hoặc do chính họ tạo
      if (doc.isFavorite || isOwner) {
        if (doc.subject.trim().isNotEmpty) {
          userFavoriteSubjects.add(doc.subject.trim().toLowerCase());
        }
        for (final tag in doc.tags) {
          if (tag.trim().isNotEmpty) {
            userFavoriteTags.add(tag.trim().toLowerCase());
          }
        }
      }
    }

    // 2. Tính điểm tương đồng (Relevance Score) cho từng tài liệu khác
    final scoredDocs = <_ScoredDocument>[];

    for (final doc in allDocuments) {
      // Bỏ qua các tài liệu người dùng đã đánh dấu yêu thích (người dùng đã biết tài liệu này)
      if (doc.isFavorite) continue;

      int score = 0;

      // Cộng 3 điểm nếu trùng môn học người dùng quan tâm
      if (userFavoriteSubjects.contains(doc.subject.trim().toLowerCase())) {
        score += 3;
      }

      // Cộng 2 điểm cho mỗi tag trùng khớp
      for (final tag in doc.tags) {
        if (userFavoriteTags.contains(tag.trim().toLowerCase())) {
          score += 2;
        }
      }

      // Chỉ đề xuất tài liệu có điểm liên quan > 0
      if (score > 0) {
        // Cộng 1 điểm nếu tài liệu có đính kèm tệp học tập
        if (doc.fileUrlOrPath.isNotEmpty) {
          score += 1;
        }
        scoredDocs.add(_ScoredDocument(document: doc, score: score));
      }
    }

    // 3. Sắp xếp giảm dần theo điểm số (nếu bằng điểm thì ưu tiên tài liệu mới cập nhật)
    scoredDocs.sort((a, b) {
      if (b.score != a.score) {
        return b.score.compareTo(a.score);
      }
      return b.document.updatedAt.compareTo(a.document.updatedAt);
    });

    // 4. Nếu người dùng chưa có lịch sử tương tác nào (Cold-start), fallback đề xuất các tài liệu mới nhất
    if (scoredDocs.isEmpty && userFavoriteSubjects.isEmpty && userFavoriteTags.isEmpty) {
      final fallbackDocs = allDocuments.where((d) => !d.isFavorite).toList();
      fallbackDocs.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return fallbackDocs.take(limit).toList();
    }

    // 5. Lấy Top N tài liệu gợi ý tốt nhất
    return scoredDocs.take(limit).map((s) => s.document).toList();
  }
}

class _ScoredDocument {
  final Document document;
  final int score;

  const _ScoredDocument({required this.document, required this.score});
}
