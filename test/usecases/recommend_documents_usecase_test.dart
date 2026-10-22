import 'package:flutter_test/flutter_test.dart';
import 'package:study_document_manager/domain/entities/document.dart';
import 'package:study_document_manager/domain/entities/document_type.dart';
import 'package:study_document_manager/usecases/recommend_documents_usecase.dart';

void main() {
  group('RecommendDocumentsUseCase Tests (Checklist 5 - Recommendation Algorithm)', () {
    const useCase = RecommendDocumentsUseCase();

    final doc1 = Document(
      id: 'doc-1',
      title: 'Đề cương môn Trí tuệ Nhân tạo',
      subject: 'Trí tuệ Nhân tạo',
      type: DocumentType.lecture,
      tags: const ['ai', 'machine-learning', 'python'],
      isFavorite: true,
      userId: 'user-a',
      createdAt: DateTime.parse('2026-10-01T10:00:00Z'),
      updatedAt: DateTime.parse('2026-10-01T10:00:00Z'),
    );

    final doc2 = Document(
      id: 'doc-2',
      title: 'Bài tập Deep Learning cơ bản',
      subject: 'Trí tuệ Nhân tạo',
      type: DocumentType.exercise,
      tags: const ['ai', 'deep-learning'],
      isFavorite: false,
      userId: 'user-b',
      createdAt: DateTime.parse('2026-10-02T10:00:00Z'),
      updatedAt: DateTime.parse('2026-10-02T10:00:00Z'),
    );

    final doc3 = Document(
      id: 'doc-3',
      title: 'Giải tích 1 nâng cao',
      subject: 'Toán cao cấp',
      type: DocumentType.lecture,
      tags: const ['toan', 'giai-tich'],
      isFavorite: false,
      userId: 'user-c',
      createdAt: DateTime.parse('2026-10-03T10:00:00Z'),
      updatedAt: DateTime.parse('2026-10-03T10:00:00Z'),
    );

    final doc4 = Document(
      id: 'doc-4',
      title: 'Thực hành Python và Machine Learning',
      subject: 'Khoa học Dữ liệu',
      type: DocumentType.exercise,
      tags: const ['python', 'machine-learning'],
      isFavorite: false,
      userId: 'user-d',
      createdAt: DateTime.parse('2026-10-04T10:00:00Z'),
      updatedAt: DateTime.parse('2026-10-04T10:00:00Z'),
    );

    final allDocs = [doc1, doc2, doc3, doc4];

    test('Gợi ý tài liệu có điểm liên quan cao nhất dựa trên tags và subject yêu thích', () {
      final recommended = useCase.execute(
        allDocuments: allDocs,
        currentUserId: 'user-a',
        limit: 3,
      );

      expect(recommended, isNotEmpty);
      // doc2 trùng subject 'Trí tuệ Nhân tạo' (+3) và trùng tag 'ai' (+2) -> 5 điểm
      // doc4 trùng tag 'python' (+2) và 'machine-learning' (+2) -> 4 điểm
      // doc3 không trùng -> 0 điểm (bị loại)
      expect(recommended.first.id, equals('doc-2'));
      expect(recommended.map((d) => d.id).contains('doc-3'), isFalse);
    });

    test('Trả về danh sách rỗng khi không có tài liệu nào trong hệ thống', () {
      final recommended = useCase.execute(
        allDocuments: [],
        currentUserId: 'user-a',
      );
      expect(recommended, isEmpty);
    });
  });
}
