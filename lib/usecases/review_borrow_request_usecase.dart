import '../domain/entities/borrow_request.dart';
import '../domain/repositories/i_borrow_request_repository.dart';

class ReviewBorrowRequestUseCase {
  final IBorrowRequestRepository repository;

  const ReviewBorrowRequestUseCase({required this.repository});

  Future<BorrowRequest> execute({
    required String requestId,
    required String status,
  }) {
    if (status != BorrowRequest.approved && status != BorrowRequest.rejected) {
      throw ArgumentError.value(status, 'status');
    }
    return repository.reviewRequest(requestId: requestId, status: status);
  }
}
