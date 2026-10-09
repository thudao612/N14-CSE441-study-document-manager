import '../../domain/entities/document.dart';
import '../../domain/entities/document_type.dart';

/// Data Transfer Object (DTO) cho Document tại Tầng Data
class DocumentModel {
  final String id;
  final String title;
  final String subject;
  final String type;
  final String description;
  final String fileUrlOrPath;
  final List<String> tags;
  final bool isFavorite;
  final String createdAt;
  final String updatedAt;
  final String userId;
  final String authorEmail;

  const DocumentModel({
    required this.id,
    required this.title,
    required this.subject,
    required this.type,
    required this.description,
    required this.fileUrlOrPath,
    required this.tags,
    required this.isFavorite,
    required this.createdAt,
    required this.updatedAt,
    this.userId = '',
    this.authorEmail = '',
  });

  static String _parseDate(dynamic val) {
    if (val == null) return DateTime.now().toIso8601String();
    if (val is String && val.isNotEmpty) return val;
    try {
      final date = (val as dynamic).toDate();
      if (date is DateTime) return date.toIso8601String();
    } catch (_) {}
    return DateTime.now().toIso8601String();
  }

  /// Chuyển đổi từ JSON Map sang Model (hỗ trợ cả Firestore Document data)
  factory DocumentModel.fromJson(Map<String, dynamic> json) {
    return DocumentModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      subject: json['subject'] as String? ?? '',
      type: json['type'] as String? ?? 'lecture',
      description: json['description'] as String? ?? '',
      fileUrlOrPath: json['fileUrlOrPath'] as String? ?? '',
      tags: (json['tags'] as List<dynamic>?)
              ?.map((e) => e.toString().trim())
              .where((e) => e.isNotEmpty)
              .toList() ??
          const [],
      isFavorite: json['isFavorite'] as bool? ?? false,
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
      userId: json['userId'] as String? ?? '',
      authorEmail: json['authorEmail'] as String? ??
          (json['authorName'] as String? ?? ''),
    );
  }

  /// Chuyển đổi Model sang JSON Map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subject': subject,
      'type': type,
      'description': description,
      'fileUrlOrPath': fileUrlOrPath,
      'tags': tags,
      'isFavorite': isFavorite,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'userId': userId,
      'authorEmail': authorEmail,
    };
  }

  /// Chuẩn hóa JSON lưu trữ trực tiếp trên Firestore (loại bỏ id vì id đã là Document ID)
  Map<String, dynamic> toFirestoreJson() {
    return {
      'title': title,
      'subject': subject,
      'type': type,
      'description': description,
      'fileUrlOrPath': fileUrlOrPath,
      'tags': tags,
      'isFavorite': isFavorite,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'userId': userId,
      'authorEmail': authorEmail,
    };
  }

  /// Chuyển đổi từ Domain Entity sang Data Model
  factory DocumentModel.fromEntity(Document entity) {
    return DocumentModel(
      id: entity.id,
      title: entity.title,
      subject: entity.subject,
      type: entity.type.name,
      description: entity.description,
      fileUrlOrPath: entity.fileUrlOrPath,
      tags: entity.tags,
      isFavorite: entity.isFavorite,
      createdAt: entity.createdAt.toIso8601String(),
      updatedAt: entity.updatedAt.toIso8601String(),
      userId: entity.userId,
      authorEmail: entity.authorEmail,
    );
  }

  /// Chuyển đổi từ Data Model sang Domain Entity
  Document toEntity() {
    return Document(
      id: id,
      title: title,
      subject: subject,
      type: DocumentType.fromString(type),
      description: description,
      fileUrlOrPath: fileUrlOrPath,
      tags: tags,
      isFavorite: isFavorite,
      createdAt: DateTime.tryParse(createdAt) ?? DateTime.now(),
      updatedAt: DateTime.tryParse(updatedAt) ?? DateTime.now(),
      userId: userId,
      authorEmail: authorEmail,
    );
  }
}
