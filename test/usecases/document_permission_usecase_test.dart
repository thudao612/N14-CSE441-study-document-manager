import 'package:flutter_test/flutter_test.dart';
import 'package:study_document_manager/domain/entities/document.dart';
import 'package:study_document_manager/domain/entities/document_type.dart';
import 'package:study_document_manager/usecases/get_document_permissions_usecase.dart';
import 'package:study_document_manager/usecases/revoke_document_permission_usecase.dart';
import 'package:study_document_manager/usecases/share_document_usecase.dart';

import '../mocks/mock_document_permission_repository.dart';

void main() {
  group('Kịch bản kiểm thử phân quyền 3 Tài khoản A, B, C (Supabase RLS & Permissions)', () {
    late MockDocumentPermissionRepository permissionRepo;
    late ShareDocumentUseCase shareUseCase;
    late GetDocumentPermissionsUseCase getPermissionsUseCase;
    late RevokeDocumentPermissionUseCase revokeUseCase;

    // Thiết lập tài liệu mẫu do Tài khoản A (Owner) sở hữu
    final testDoc = Document(
      id: 'doc-database-security-101',
      title: 'Giáo trình An toàn Cơ sở Dữ liệu & RLS',
      subject: 'An toàn thông tin',
      type: DocumentType.lecture,
      description: 'Chuyên đề Row Level Security và xác thực JWT',
      fileUrlOrPath:
          'https://firebasestorage.googleapis.com/v0/b/nhom14.appspot.com/o/documents%2Fuid-a%2Fsec.pdf',
      tags: const ['security', 'rls', 'supabase'],
      createdAt: DateTime(2026, 10, 13),
      updatedAt: DateTime(2026, 10, 13),
      userId: 'uid-a',
      authorEmail: 'user_a@school.edu.vn',
      userRole: 'owner',
    );

    setUp(() {
      permissionRepo = MockDocumentPermissionRepository();
      shareUseCase = ShareDocumentUseCase(repository: permissionRepo);
      getPermissionsUseCase =
          GetDocumentPermissionsUseCase(repository: permissionRepo);
      revokeUseCase = RevokeDocumentPermissionUseCase(repository: permissionRepo);

      // Đưa tài liệu vào mock database
      permissionRepo.documentsTable[testDoc.id] = testDoc;
    });

    test('1. Tài khoản A (Owner) chia sẻ tài liệu cho B (Editor) và C (Viewer) thành công',
        () async {
      // Đang đăng nhập là Tài khoản A
      permissionRepo.currentUserId = 'uid-a';

      // A chia sẻ cho B với vai trò 'editor'
      final permB = await shareUseCase.execute(
        documentId: testDoc.id,
        targetEmail: 'user_b@school.edu.vn',
        role: 'editor',
      );

      expect(permB.userId, 'uid-b');
      expect(permB.role, 'editor');
      expect(permB.isEditor, true);

      // A chia sẻ cho C với vai trò 'viewer'
      final permC = await shareUseCase.execute(
        documentId: testDoc.id,
        targetEmail: 'user_c@school.edu.vn',
        role: 'viewer',
      );

      expect(permC.userId, 'uid-c');
      expect(permC.role, 'viewer');
      expect(permC.isViewer, true);

      // A kiểm tra danh sách quyền
      final list = await getPermissionsUseCase.execute(testDoc.id);
      expect(list.length, 2);
    });

    test('2. Xác minh quyền xem và quyền sửa giữa Tài khoản A, B và C', () async {
      permissionRepo.currentUserId = 'uid-a';
      await shareUseCase.execute(
        documentId: testDoc.id,
        targetEmail: 'user_b@school.edu.vn',
        role: 'editor',
      );
      await shareUseCase.execute(
        documentId: testDoc.id,
        targetEmail: 'user_c@school.edu.vn',
        role: 'viewer',
      );

      // Tài khoản A (Owner): Xem được, Sửa được, Xóa được
      permissionRepo.currentUserId = 'uid-a';
      expect(permissionRepo.isOwner(testDoc.id), true);
      expect(permissionRepo.isEditor(testDoc.id), true);
      expect(permissionRepo.canView(testDoc.id), true);

      // Chuyển sang Tài khoản B (Editor): Xem được, Sửa được, KHÔNG phải Owner
      permissionRepo.currentUserId = 'uid-b';
      expect(permissionRepo.isOwner(testDoc.id), false);
      expect(permissionRepo.isEditor(testDoc.id), true);
      expect(permissionRepo.canView(testDoc.id), true);

      // Chuyển sang Tài khoản C (Viewer): Xem được, KHÔNG sửa được, KHÔNG phải Owner
      permissionRepo.currentUserId = 'uid-c';
      expect(permissionRepo.isOwner(testDoc.id), false);
      expect(permissionRepo.isEditor(testDoc.id), false); // Bị RLS chặn sửa
      expect(permissionRepo.canView(testDoc.id), true);
    });

    test('3. Tài khoản B (Editor) hoặc C (Viewer) cố tình chia sẻ quyền -> Bị RLS chặn',
        () async {
      permissionRepo.currentUserId = 'uid-a';
      await shareUseCase.execute(
        documentId: testDoc.id,
        targetEmail: 'user_b@school.edu.vn',
        role: 'editor',
      );

      // Tài khoản B (Editor) cố tình chia sẻ tài liệu cho người khác
      permissionRepo.currentUserId = 'uid-b';
      expect(
        () => shareUseCase.execute(
          documentId: testDoc.id,
          targetEmail: 'user_c@school.edu.vn',
          role: 'viewer',
        ),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'error message',
          contains('RLS 42501'),
        )),
      );
    });

    test('4. Tài khoản A thu hồi quyền của C -> C lập tức mất quyền truy cập tài liệu',
        () async {
      permissionRepo.currentUserId = 'uid-a';
      await shareUseCase.execute(
        documentId: testDoc.id,
        targetEmail: 'user_c@school.edu.vn',
        role: 'viewer',
      );

      // C hiện tại xem được
      permissionRepo.currentUserId = 'uid-c';
      expect(permissionRepo.canView(testDoc.id), true);

      // A tiến hành thu hồi quyền của C
      permissionRepo.currentUserId = 'uid-a';
      final revoked = await revokeUseCase.execute(
        documentId: testDoc.id,
        targetUserId: 'uid-c',
      );
      expect(revoked, true);

      // Sau khi thu hồi: C chuyển sang unshared -> Mất quyền xem!
      permissionRepo.currentUserId = 'uid-c';
      expect(permissionRepo.canView(testDoc.id), false);
    });

    test('5. Người lạ D (hoặc chưa xác thực) -> Bị RLS chặn truy cập hoàn toàn', () async {
      // Người dùng lạ có UID 'uid-stranger-d'
      permissionRepo.currentUserId = 'uid-stranger-d';

      expect(permissionRepo.isOwner(testDoc.id), false);
      expect(permissionRepo.isEditor(testDoc.id), false);
      expect(permissionRepo.canView(testDoc.id), false);

      expect(
        () => getPermissionsUseCase.execute(testDoc.id),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'error message',
          contains('Permission Denied'),
        )),
      );
    });
  });
}
