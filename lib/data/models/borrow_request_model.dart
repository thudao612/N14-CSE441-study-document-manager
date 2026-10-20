import '../../domain/entities/borrow_request.dart';

/// DTO ánh xạ borrow_requests và dữ liệu liên quan từ Supabase.
class BorrowRequestModel {
  final String id;
  final String documentId;
  final String requesterId;
  final String status;
  final DateTime requestedAt;
  final DateTime? reviewedAt;
  final DateTime? returnedAt;
  final DateTime updatedAt;
  final String requesterEmail;
  final String requesterName;
  final String documentTitle;

  const BorrowRequestModel({
    required this.id,
    required this.documentId,
    required this.requesterId,
    required this.status,
    required this.requestedAt,
    required this.updatedAt,
    this.reviewedAt,
    this.returnedAt,
    this.requesterEmail = '',
    this.requesterName = '',
    this.documentTitle = '',
  });

  factory BorrowRequestModel.fromJson(Map<String, dynamic> json) {
    final requester = _asMap(json['requester']);
    final document = _asMap(json['document']);

    return BorrowRequestModel(
      id: json['id']?.toString() ?? '',
      documentId: json['document_id']?.toString() ?? '',
      requesterId: json['requester_id']?.toString() ?? '',
      status: json['status']?.toString() ?? BorrowRequest.pending,
      requestedAt: _parseDate(json['requested_at']) ?? DateTime.now(),
      reviewedAt: _parseDate(json['reviewed_at']),
      returnedAt: _parseDate(json['returned_at']),
      updatedAt: _parseDate(json['updated_at']) ?? DateTime.now(),
      requesterEmail: requester['email']?.toString() ?? '',
      requesterName: requester['display_name']?.toString() ?? '',
      documentTitle: document['title']?.toString() ?? '',
    );
  }

  BorrowRequest toEntity() => BorrowRequest(
        id: id,
        documentId: documentId,
        requesterId: requesterId,
        status: status,
        requestedAt: requestedAt,
        reviewedAt: reviewedAt,
        returnedAt: returnedAt,
        updatedAt: updatedAt,
        requesterEmail: requesterEmail,
        requesterName: requesterName,
        documentTitle: documentTitle,
      );

  static Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return const <String, dynamic>{};
  }

  static DateTime? _parseDate(dynamic value) {
    if (value is DateTime) return value;
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}
