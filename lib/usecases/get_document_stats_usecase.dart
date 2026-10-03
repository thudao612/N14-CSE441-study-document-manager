import '../domain/entities/document.dart';
import '../domain/entities/document_type.dart';
import '../domain/repositories/i_document_repository.dart';

/// Đối tượng chứa các chỉ số thống kê về tài liệu học tập
class DocumentStats {
  final int totalCount;
  final int lectureCount;
  final int exerciseCount;
  final int referenceCount;
  final int favoriteCount;
  final int subjectCount;

  const DocumentStats({
    required this.totalCount,
    required this.lectureCount,
    required this.exerciseCount,
    required this.referenceCount,
    required this.favoriteCount,
    required this.subjectCount,
  });

  factory DocumentStats.empty() {
    return const DocumentStats(
      totalCount: 0,
      lectureCount: 0,
      exerciseCount: 0,
      referenceCount: 0,
      favoriteCount: 0,
      subjectCount: 0,
    );
  }

  factory DocumentStats.fromDocuments(List<Document> docs) {
    int lectures = 0;
    int exercises = 0;
    int references = 0;
    int favorites = 0;
    final subjects = <String>{};

    for (final doc in docs) {
      switch (doc.type) {
        case DocumentType.lecture:
          lectures++;
          break;
        case DocumentType.exercise:
          exercises++;
          break;
        case DocumentType.reference:
          references++;
          break;
      }

      if (doc.isFavorite) {
        favorites++;
      }

      if (doc.subject.trim().isNotEmpty) {
        subjects.add(doc.subject.trim().toLowerCase());
      }
    }

    return DocumentStats(
      totalCount: docs.length,
      lectureCount: lectures,
      exerciseCount: exercises,
      referenceCount: references,
      favoriteCount: favorites,
      subjectCount: subjects.length,
    );
  }
}

/// Use Case: Tính toán thống kê dữ liệu học tập
class GetDocumentStatsUseCase {
  final IDocumentRepository _repository;

  GetDocumentStatsUseCase({required IDocumentRepository repository})
      : _repository = repository;

  Future<DocumentStats> execute() async {
    final docs = await _repository.getAllDocuments();
    return DocumentStats.fromDocuments(docs);
  }
}
