import '../entities/borrow_request.dart';

/// Hợp đồng thao tác với luồng mượn tài liệu.
abstract class IBorrowRequestRepository {
  Future<BorrowRequest> createRequest({required String documentId});

  Future<List<BorrowRequest>> getRequestsForDocument({
    required String documentId,
  });

  Future<BorrowRequest?> getLatestRequestForCurrentUser({
    required String documentId,
  });

  /// [status] chỉ được phép là BorrowRequest.approved hoặc rejected.
  Future<BorrowRequest> reviewRequest({
    required String requestId,
    required String status,
  });

  Future<BorrowRequest> markReturned({required String requestId});
}
