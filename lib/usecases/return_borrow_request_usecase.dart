import '../domain/entities/borrow_request.dart';
import '../domain/repositories/i_borrow_request_repository.dart';

class ReturnBorrowRequestUseCase {
  final IBorrowRequestRepository repository;

  const ReturnBorrowRequestUseCase({required this.repository});

  Future<BorrowRequest> execute({required String requestId}) {
    return repository.markReturned(requestId: requestId);
  }
}
