import '../../domain/entities/document.dart';
import '../../domain/entities/document_type.dart';

/// Data Transfer Object (DTO) cho Document tại Tầng Data
/// Tương thích đồng thời: Cloud Firestore, Supabase PostgreSQL và Local In-Memory
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
  final String userRole; // 'owner' | 'editor' | 'viewer'
  final String rawFileName;
  final int fileSize;
  final String locationName;
  final double? latitude;
  final double? longitude;

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
    this.userRole = 'owner',
    this.rawFileName = '',
    this.fileSize = 0,
    this.locationName = '',
    this.latitude,
    this.longitude,
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

  static double? _parseCoordinate(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  /// Chuyển đổi từ JSON Map sang Model
  /// Hỗ trợ linh hoạt cả định dạng camelCase và snake_case (Supabase)
  factory DocumentModel.fromJson(Map<String, dynamic> json) {
    final tagsRaw = json['tags'];
    List<String> parsedTags = [];
    if (tagsRaw is List) {
      parsedTags = tagsRaw
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }

    final fileUrl =
        json['fileUrlOrPath'] as String? ?? (json['file_url'] as String? ?? '');

    final ownerId =
        json['userId'] as String? ?? (json['owner_id'] as String? ?? '');

    final fileName =
        json['rawFileName'] as String? ?? (json['file_name'] as String? ?? '');

    final size = json['fileSize'] as int? ?? (json['file_size'] as int? ?? 0);

    final role = json['userRole'] as String? ??
        (json['user_role'] as String? ?? 'owner');

    return DocumentModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      subject: json['subject'] as String? ?? '',
      type: json['type'] as String? ?? 'lecture',
      description: json['description'] as String? ?? '',
      fileUrlOrPath: fileUrl,
      tags: parsedTags,
      isFavorite: json['isFavorite'] as bool? ??
          (json['is_favorite'] as bool? ?? false),
      createdAt: _parseDate(json['createdAt'] ?? json['created_at']),
      updatedAt: _parseDate(json['updatedAt'] ?? json['updated_at']),
      userId: ownerId,
      authorEmail: json['authorEmail'] as String? ??
          (json['author_email'] as String? ??
              (json['authorName'] as String? ?? '')),
      userRole: role,
      rawFileName: fileName,
      fileSize: size,
      locationName: json['locationName'] as String? ??
          (json['location_name'] as String? ?? ''),
      latitude: _parseCoordinate(json['latitude'] ?? json['lat']),
      longitude: _parseCoordinate(json['longitude'] ?? json['long']),
    );
  }

  /// Chuyển đổi Model sang JSON Map (camelCase chuẩn)
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
      'userRole': userRole,
      'rawFileName': rawFileName,
      'fileSize': fileSize,
      'locationName': locationName,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  /// Chuẩn hóa JSON lưu trữ trực tiếp trên Cloud Firestore
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
      'locationName': locationName,
      'lat': latitude,
      'long': longitude,
    };
  }

  /// Chuẩn hóa JSON tương thích với bảng documents trên Supabase PostgreSQL
  Map<String, dynamic> toSupabaseJson() {
    return {
      'id': id,
      'title': title,
      'subject': subject,
      'type': type,
      'description': description,
      'file_url': fileUrlOrPath,
      'file_name': rawFileName.isNotEmpty
          ? rawFileName
          : (fileUrlOrPath.isNotEmpty ? fileUrlOrPath.split('/').last : ''),
      'file_size': fileSize,
      'tags': tags,
      'is_favorite': isFavorite,
      'owner_id': userId,
      'author_email': authorEmail,
      'location_name': locationName,
      'lat': latitude,
      'long': longitude,
      'created_at': createdAt,
      'updated_at': updatedAt,
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
      userRole: entity.userRole,
      rawFileName: entity.rawFileName,
      fileSize: entity.fileSize,
      locationName: entity.locationName,
      latitude: entity.latitude,
      longitude: entity.longitude,
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
      userRole: userRole,
      rawFileName: rawFileName,
      fileSize: fileSize,
      locationName: locationName,
      latitude: latitude,
      longitude: longitude,
    );
  }
}
