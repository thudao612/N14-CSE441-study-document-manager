import 'package:flutter_test/flutter_test.dart';
import 'package:study_document_manager/domain/entities/borrow_request.dart';
import 'package:study_document_manager/domain/repositories/i_borrow_request_repository.dart';
import 'package:study_document_manager/usecases/get_document_borrow_requests_usecase.dart';
import 'package:study_document_manager/usecases/get_my_borrow_request_usecase.dart';
import 'package:study_document_manager/usecases/request_document_borrow_usecase.dart';
import 'package:study_document_manager/usecases/review_borrow_request_usecase.dart';
import 'package:study_document_manager/usecases/return_borrow_request_usecase.dart';

class _FakeBorrowRequestRepository implements IBorrowRequestRepository {
  String? createdDocumentId;
  String? reviewedRequestId;
  String? reviewedStatus;
  String? returnedRequestId;
  String? queriedDocumentId;
  final List<BorrowRequest> requests = <BorrowRequest>[];
  BorrowRequest? latestRequest;

  BorrowRequest createResult(String documentId) => BorrowRequest(
        id: 'request-1',
        documentId: documentId,
        requesterId: 'user-1',
        status: BorrowRequest.pending,
        requestedAt: DateTime.utc(2026, 10, 20),
        updatedAt: DateTime.utc(2026, 10, 20),
      );

  @override
  Future<BorrowRequest> createRequest({required String documentId}) async {
    createdDocumentId = documentId;
    return createResult(documentId);
  }

  @override
  Future<List<BorrowRequest>> getRequestsForDocument({
    required String documentId,
  }) async {
    queriedDocumentId = documentId;
    return requests;
  }

  @override
  Future<BorrowRequest?> getLatestRequestForCurrentUser({
    required String documentId,
  }) async {
    queriedDocumentId = documentId;
    return latestRequest;
  }

  @override
  Future<BorrowRequest> reviewRequest({
    required String requestId,
    required String status,
  }) async {
    reviewedRequestId = requestId;
    reviewedStatus = status;
    return createResult('document-1');
  }

  @override
  Future<BorrowRequest> markReturned({required String requestId}) async {
    returnedRequestId = requestId;
    return BorrowRequest(
      id: requestId,
      documentId: 'document-1',
      requesterId: 'user-1',
      status: BorrowRequest.returned,
      requestedAt: DateTime.utc(2026, 10, 20),
      reviewedAt: DateTime.utc(2026, 10, 20, 1),
      returnedAt: DateTime.utc(2026, 10, 20, 2),
      updatedAt: DateTime.utc(2026, 10, 20, 2),
    );
  }
}

void main() {
  late _FakeBorrowRequestRepository repository;

  setUp(() => repository = _FakeBorrowRequestRepository());

  test('request use case sends the document id to repository', () async {
    final useCase = RequestDocumentBorrowUseCase(repository: repository);
    final request = await useCase.execute(documentId: 'document-42');

    expect(repository.createdDocumentId, 'document-42');
    expect(request.status, BorrowRequest.pending);
  });

  test('list and latest-request use cases query the requested document', () async {
    final expected = repository.createResult('document-7');
    repository.requests.add(expected);
    repository.latestRequest = expected;

    final list = await GetDocumentBorrowRequestsUseCase(repository: repository)
        .execute(documentId: 'document-7');
    final latest = await GetMyBorrowRequestUseCase(repository: repository)
        .execute(documentId: 'document-7');

    expect(list, <BorrowRequest>[expected]);
    expect(latest, expected);
    expect(repository.queriedDocumentId, 'document-7');
  });

  test('review use case accepts only approved or rejected', () async {
    final useCase = ReviewBorrowRequestUseCase(repository: repository);
    await useCase.execute(
      requestId: 'request-9',
      status: BorrowRequest.approved,
    );
    expect(repository.reviewedRequestId, 'request-9');
    expect(repository.reviewedStatus, BorrowRequest.approved);

    expect(
      () => useCase.execute(requestId: 'request-9', status: BorrowRequest.returned),
      throwsArgumentError,
    );
  });

  test('return use case marks the chosen request as returned', () async {
    final result = await ReturnBorrowRequestUseCase(repository: repository)
        .execute(requestId: 'request-10');

    expect(repository.returnedRequestId, 'request-10');
    expect(result.status, BorrowRequest.returned);
    expect(result.returnedAt, isNotNull);
  });
}
