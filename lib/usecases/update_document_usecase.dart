import '../domain/entities/document.dart';
import '../domain/entities/document_type.dart';
import '../domain/repositories/i_document_repository.dart';

/// Tham số đầu vào để cập nhật tài liệu
class UpdateDocumentParams {
  final String id;
  final String title;
  final String subject;
  final DocumentType type;
  final String description;
  final String fileUrlOrPath;
  final List<String> tags;
  final bool isFavorite;

  const UpdateDocumentParams({
    required this.id,
    required this.title,
    required this.subject,
    required this.type,
    this.description = '',
    this.fileUrlOrPath = '',
    this.tags = const [],
    this.isFavorite = false,
  });
}

/// Use Case: Cập nhật tài liệu học tập
class UpdateDocumentUseCase {
  final IDocumentRepository _repository;

  UpdateDocumentUseCase({required IDocumentRepository repository})
      : _repository = repository;

  Future<Document> execute(UpdateDocumentParams params) async {
    // 1. Kiểm tra ID
    if (params.id.trim().isEmpty) {
      throw ArgumentError('Mã định danh (ID) tài liệu không hợp lệ.');
    }

    // 2. Kiểm tra tồn tại trong kho dữ liệu
    final existingDoc = await _repository.getDocumentById(params.id);
    if (existingDoc == null) {
      throw StateError('Không tìm thấy tài liệu với ID: ${params.id}');
    }

    // 3. Kiểm tra tiêu đề và môn học
    final trimmedTitle = params.title.trim();
    if (trimmedTitle.isEmpty) {
      throw ArgumentError('Tiêu đề tài liệu không được để trống.');
    }
    if (trimmedTitle.length < 2) {
      throw ArgumentError('Tiêu đề tài liệu phải có ít nhất 2 ký tự.');
    }

    final trimmedSubject = params.subject.trim();
    if (trimmedSubject.isEmpty) {
      throw ArgumentError('Môn học không được để trống.');
    }

    // 4. Chuẩn hóa tags
    final cleanTags = params.tags
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toSet()
        .toList();

    // 5. Cập nhật thực thể với ngày cập nhật mới nhất
    final updatedDoc = existingDoc.copyWith(
      title: trimmedTitle,
      subject: trimmedSubject,
      type: params.type,
      description: params.description.trim(),
      fileUrlOrPath: params.fileUrlOrPath.trim(),
      tags: cleanTags,
      isFavorite: params.isFavorite,
      updatedAt: DateTime.now(),
    );

    return await _repository.updateDocument(updatedDoc);
  }
}
