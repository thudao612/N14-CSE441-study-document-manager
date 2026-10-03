import 'package:uuid/uuid.dart';
import '../domain/entities/document.dart';
import '../domain/entities/document_type.dart';
import '../domain/repositories/i_document_repository.dart';

/// Tham số đầu vào để thêm tài liệu mới
class AddDocumentParams {
  final String title;
  final String subject;
  final DocumentType type;
  final String description;
  final String fileUrlOrPath;
  final List<String> tags;
  final bool isFavorite;

  const AddDocumentParams({
    required this.title,
    required this.subject,
    required this.type,
    this.description = '',
    this.fileUrlOrPath = '',
    this.tags = const [],
    this.isFavorite = false,
  });
}

/// Use Case: Thêm tài liệu học tập mới
/// Đóng gói các quy tắc nghiệp vụ khi tạo tài liệu theo chuẩn Clean Architecture
class AddDocumentUseCase {
  final IDocumentRepository _repository;
  final Uuid _uuid;

  AddDocumentUseCase({
    required IDocumentRepository repository,
    Uuid? uuid,
  })  : _repository = repository,
        _uuid = uuid ?? const Uuid();

  Future<Document> execute(AddDocumentParams params) async {
    // 1. Kiểm tra quy tắc nghiệp vụ: Tiêu đề
    final trimmedTitle = params.title.trim();
    if (trimmedTitle.isEmpty) {
      throw ArgumentError('Tiêu đề tài liệu không được để trống.');
    }
    if (trimmedTitle.length < 2) {
      throw ArgumentError('Tiêu đề tài liệu phải có ít nhất 2 ký tự.');
    }

    // 2. Kiểm tra quy tắc nghiệp vụ: Môn học
    final trimmedSubject = params.subject.trim();
    if (trimmedSubject.isEmpty) {
      throw ArgumentError('Môn học không được để trống.');
    }

    // 3. Chuẩn hóa danh sách thẻ tags (loại bỏ trùng lặp và khoảng trắng)
    final cleanTags = params.tags
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toSet()
        .toList();

    // 4. Khởi tạo đối tượng Entity hoàn chỉnh
    final now = DateTime.now();
    final newDocument = Document(
      id: _uuid.v4(),
      title: trimmedTitle,
      subject: trimmedSubject,
      type: params.type,
      description: params.description.trim(),
      fileUrlOrPath: params.fileUrlOrPath.trim(),
      tags: cleanTags,
      isFavorite: params.isFavorite,
      createdAt: now,
      updatedAt: now,
    );

    // 5. Lưu xuống qua Repository hợp đồng
    return await _repository.addDocument(newDocument);
  }
}
