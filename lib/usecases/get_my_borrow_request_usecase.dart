import '../domain/entities/borrow_request.dart';
import '../domain/repositories/i_borrow_request_repository.dart';

class GetMyBorrowRequestUseCase {
  final IBorrowRequestRepository repository;

  const GetMyBorrowRequestUseCase({required this.repository});

  Future<BorrowRequest?> execute({required String documentId}) {
    return repository.getLatestRequestForCurrentUser(documentId: documentId);
  }
}
