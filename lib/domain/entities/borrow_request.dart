/// Trạng thái và dữ liệu của một yêu cầu mượn tài liệu.
class BorrowRequest {
  static const String pending = 'pending';
  static const String approved = 'approved';
  static const String rejected = 'rejected';
  static const String returned = 'returned';

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

  const BorrowRequest({
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

  bool get isPending => status == pending;
  bool get isApproved => status == approved;
  bool get isRejected => status == rejected;
  bool get isReturned => status == returned;
  bool get isActive => isPending || isApproved;

  String get statusLabel {
    switch (status) {
      case pending:
        return 'Chờ duyệt';
      case approved:
        return 'Được đồng ý – đang mượn';
      case rejected:
        return 'Đã từ chối';
      case returned:
        return 'Đã trả tài liệu';
      default:
        return 'Không xác định';
    }
  }
}
