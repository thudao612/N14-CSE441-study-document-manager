import 'document_type.dart';

/// Bộ tiêu chí tìm kiếm và lọc tài liệu học tập
class DocumentFilter {
  final String? searchQuery;
  final DocumentType? type;
  final String? subject;
  final String? tag;
  final bool isFavoriteOnly;

  const DocumentFilter({
    this.searchQuery,
    this.type,
    this.subject,
    this.tag,
    this.isFavoriteOnly = false,
  });

  /// Tạo bộ lọc mặc định (không lọc)
  factory DocumentFilter.empty() {
    return const DocumentFilter();
  }

  /// Kiểm tra xem bộ lọc có đang được áp dụng hay không
  bool get isActive =>
      (searchQuery != null && searchQuery!.trim().isNotEmpty) ||
      type != null ||
      (subject != null && subject!.trim().isNotEmpty) ||
      (tag != null && tag!.trim().isNotEmpty) ||
      isFavoriteOnly;

  DocumentFilter copyWith({
    String? searchQuery,
    DocumentType? type,
    String? subject,
    String? tag,
    bool? isFavoriteOnly,
    bool clearType = false,
    bool clearSubject = false,
    bool clearTag = false,
    bool clearSearch = false,
  }) {
    return DocumentFilter(
      searchQuery: clearSearch ? null : (searchQuery ?? this.searchQuery),
      type: clearType ? null : (type ?? this.type),
      subject: clearSubject ? null : (subject ?? this.subject),
      tag: clearTag ? null : (tag ?? this.tag),
      isFavoriteOnly: isFavoriteOnly ?? this.isFavoriteOnly,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DocumentFilter &&
          runtimeType == other.runtimeType &&
          searchQuery == other.searchQuery &&
          type == other.type &&
          subject == other.subject &&
          tag == other.tag &&
          isFavoriteOnly == other.isFavoriteOnly;

  @override
  int get hashCode =>
      searchQuery.hashCode ^
      type.hashCode ^
      subject.hashCode ^
      tag.hashCode ^
      isFavoriteOnly.hashCode;
}
