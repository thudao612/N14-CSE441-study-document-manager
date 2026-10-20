import '../domain/entities/borrow_request.dart';
import '../domain/repositories/i_borrow_request_repository.dart';

class RequestDocumentBorrowUseCase {
  final IBorrowRequestRepository repository;

  const RequestDocumentBorrowUseCase({required this.repository});

  Future<BorrowRequest> execute({required String documentId}) {
    return repository.createRequest(documentId: documentId);
  }
}
