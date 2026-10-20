import 'package:flutter_test/flutter_test.dart';
import 'package:study_document_manager/data/models/borrow_request_model.dart';
import 'package:study_document_manager/domain/entities/borrow_request.dart';

void main() {
  group('BorrowRequestModel', () {
    test('maps database columns and joined requester/document data', () {
      final model = BorrowRequestModel.fromJson({
        'id': 'request-1',
        'document_id': 'document-1',
        'requester_id': 'firebase-user-1',
        'status': 'approved',
        'requested_at': '2026-10-20T08:00:00Z',
        'reviewed_at': '2026-10-20T09:00:00Z',
        'returned_at': null,
        'updated_at': '2026-10-20T09:00:00Z',
        'requester': {
          'email': 'student@example.com',
          'display_name': 'Student One',
        },
        'document': {'title': 'Flutter Basics'},
      });

      final entity = model.toEntity();
      expect(entity.id, 'request-1');
      expect(entity.documentId, 'document-1');
      expect(entity.requesterId, 'firebase-user-1');
      expect(entity.status, BorrowRequest.approved);
      expect(entity.requesterEmail, 'student@example.com');
      expect(entity.requesterName, 'Student One');
      expect(entity.documentTitle, 'Flutter Basics');
      expect(entity.reviewedAt, DateTime.parse('2026-10-20T09:00:00Z'));
      expect(entity.returnedAt, isNull);
    });

    test('handles missing joined data without throwing', () {
      final entity = BorrowRequestModel.fromJson({
        'id': 'request-2',
        'document_id': 'document-2',
        'requester_id': 'firebase-user-2',
        'status': 'pending',
        'requested_at': '2026-10-20T08:00:00Z',
        'updated_at': '2026-10-20T08:00:00Z',
      }).toEntity();

      expect(entity.requesterEmail, isEmpty);
      expect(entity.requesterName, isEmpty);
      expect(entity.documentTitle, isEmpty);
      expect(entity.isPending, isTrue);
    });
  });

  group('BorrowRequest status helpers', () {
    BorrowRequest createRequest(String status) => BorrowRequest(
          id: 'request-1',
          documentId: 'document-1',
          requesterId: 'user-1',
          status: status,
          requestedAt: DateTime.utc(2026, 10, 20),
          updatedAt: DateTime.utc(2026, 10, 20),
        );

    test('labels and active state reflect workflow statuses', () {
      expect(createRequest(BorrowRequest.pending).statusLabel, 'Chờ duyệt');
      expect(createRequest(BorrowRequest.pending).isActive, isTrue);
      expect(createRequest(BorrowRequest.approved).isActive, isTrue);
      expect(createRequest(BorrowRequest.rejected).isRejected, isTrue);
      expect(createRequest(BorrowRequest.returned).isReturned, isTrue);
      expect(createRequest(BorrowRequest.returned).isActive, isFalse);
    });
  });
}
