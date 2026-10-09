import '../domain/repositories/i_document_storage_repository.dart';

class UploadDocumentFileUseCase {
  UploadDocumentFileUseCase({
    required IDocumentStorageRepository repository,
  }) : _repository = repository;

  final IDocumentStorageRepository _repository;

  Future<String> execute({
    required String fileName,
    required List<int> bytes,
  }) {
    if (fileName.trim().isEmpty) {
      throw ArgumentError('Tên tệp không được để trống.');
    }

    if (bytes.isEmpty) {
      throw ArgumentError('Nội dung tệp không được để trống.');
    }

    return _repository.uploadDocument(
      fileName: fileName,
      bytes: bytes,
    );
  }
}
