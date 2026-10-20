import 'package:flutter_test/flutter_test.dart';
import 'package:study_document_manager/core/config/supabase_config.dart';
import 'package:study_document_manager/data/repositories/supabase_document_storage_repository.dart';
import 'package:study_document_manager/domain/repositories/i_document_storage_repository.dart';

void main() {
  group('SupabaseDocumentStorageRepository Unit Tests', () {
    test('Cấu hình SupabaseConfig: storageBucket mặc định là "documents"', () {
      expect(SupabaseConfig.storageBucket, 'documents');
    });

    test('SupabaseDocumentStorageRepository khởi tạo hợp lệ và triển khai IDocumentStorageRepository', () {
      final repo = SupabaseDocumentStorageRepository(
        bucketName: 'documents',
      );
      expect(repo, isA<IDocumentStorageRepository>());
    });

    test('createSignedUrl: Ném ngoại lệ khi chưa kết nối client hoặc path không tồn tại', () async {
      final repo = SupabaseDocumentStorageRepository(
        bucketName: 'documents',
      );
      expect(
        () async => await repo.createSignedUrl('invalid_path/file.pdf', expiresIn: 300),
        throwsA(isA<Exception>()),
      );
    });
  });
}
