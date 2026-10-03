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
  });

  /// Chuyển đổi từ JSON Map sang Model
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
      createdAt: json['createdAt'] as String? ??
          DateTime.now().toIso8601String(),
      updatedAt: json['updatedAt'] as String? ??
          DateTime.now().toIso8601String(),
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
    );
  }
}
