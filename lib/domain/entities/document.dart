import 'document_type.dart';

/// Entity cốt lõi biểu diễn một Tài liệu học tập (Domain Layer)
class Document {
  final String id;
  final String title;
  final String subject;
  final DocumentType type;
  final String description;
  final String fileUrlOrPath;
  final List<String> tags;
  final bool isFavorite;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String userId;
  final String authorEmail;

  const Document({
    required this.id,
    required this.title,
    required this.subject,
    required this.type,
    this.description = '',
    this.fileUrlOrPath = '',
    this.tags = const [],
    this.isFavorite = false,
    required this.createdAt,
    required this.updatedAt,
    this.userId = '',
    this.authorEmail = '',
  });

  /// Tạo bản sao với các thuộc tính được cập nhật (Immutability pattern)
  Document copyWith({
    String? id,
    String? title,
    String? subject,
    DocumentType? type,
    String? description,
    String? fileUrlOrPath,
    List<String>? tags,
    bool? isFavorite,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? userId,
    String? authorEmail,
  }) {
    return Document(
      id: id ?? this.id,
      title: title ?? this.title,
      subject: subject ?? this.subject,
      type: type ?? this.type,
      description: description ?? this.description,
      fileUrlOrPath: fileUrlOrPath ?? this.fileUrlOrPath,
      tags: tags ?? this.tags,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userId: userId ?? this.userId,
      authorEmail: authorEmail ?? this.authorEmail,
    );
  }

  /// Tiện ích nhận diện định dạng tệp đính kèm
  bool get hasFileOrLink => fileUrlOrPath.trim().isNotEmpty;

  bool get isPdf => fileUrlOrPath.trim().toLowerCase().endsWith('.pdf');

  bool get isWord {
    final lower = fileUrlOrPath.trim().toLowerCase();
    return lower.endsWith('.doc') || lower.endsWith('.docx');
  }

  bool get isWebLink {
    final lower = fileUrlOrPath.trim().toLowerCase();
    return lower.startsWith('http://') || lower.startsWith('https://');
  }

  String get fileName {
    final trimmed = fileUrlOrPath.trim();
    if (trimmed.isEmpty) return '';
    if (isWebLink) return trimmed;
    final normalized = trimmed.replaceAll(r'\', '/');
    return normalized.split('/').last;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Document &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          subject == other.subject &&
          type == other.type &&
          description == other.description &&
          fileUrlOrPath == other.fileUrlOrPath &&
          isFavorite == other.isFavorite &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode =>
      id.hashCode ^
      title.hashCode ^
      subject.hashCode ^
      type.hashCode ^
      description.hashCode ^
      fileUrlOrPath.hashCode ^
      isFavorite.hashCode ^
      createdAt.hashCode ^
      updatedAt.hashCode;

  @override
  String toString() {
    return 'Document(id: $id, title: $title, subject: $subject, type: ${type.displayName}, isFavorite: $isFavorite)';
  }
}
