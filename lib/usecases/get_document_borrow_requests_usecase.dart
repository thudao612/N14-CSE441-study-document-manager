import '../domain/entities/borrow_request.dart';
import '../domain/repositories/i_borrow_request_repository.dart';

class GetDocumentBorrowRequestsUseCase {
  final IBorrowRequestRepository repository;

  const GetDocumentBorrowRequestsUseCase({required this.repository});

  Future<List<BorrowRequest>> execute({required String documentId}) {
    return repository.getRequestsForDocument(documentId: documentId);
  }
}
