import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

import '../../domain/repositories/i_document_storage_repository.dart';

class FirebaseDocumentStorageRepository implements IDocumentStorageRepository {
  FirebaseDocumentStorageRepository({
    FirebaseStorage? storage,
    Uuid? uuid,
  })  : _storageOverride = storage,
        _uuid = uuid ?? const Uuid();

  final FirebaseStorage? _storageOverride;
  final Uuid _uuid;

  // Chỉ lấy FirebaseStorage.instance khi thực sự upload.
  // Nhờ vậy có thể khởi tạo đối tượng trước khi cấu hình Firebase thật.
  FirebaseStorage get _storage => _storageOverride ?? FirebaseStorage.instance;

  @override
  Future<String> uploadDocument({
    required String fileName,
    required List<int> bytes,
  }) async {
    if (fileName.trim().isEmpty) {
      throw ArgumentError('Tên tệp không được để trống.');
    }

    if (bytes.isEmpty) {
      throw ArgumentError('Nội dung tệp không được để trống.');
    }

    final safeName = _sanitizeFileName(fileName);
    final reference = _storage.ref().child('documents/${_uuid.v4()}/$safeName');

    final metadata = SettableMetadata(
      contentType: _contentTypeFor(safeName),
    );

    await reference.putData(
      Uint8List.fromList(bytes),
      metadata,
    );

    return reference.getDownloadURL();
  }

  String _sanitizeFileName(String fileName) {
    final name = fileName.replaceAll('\\', '/').split('/').last.trim();

    final safeName = name.replaceAll(
      RegExp(r'[^a-zA-Z0-9._-]'),
      '_',
    );

    return safeName.isEmpty ? 'attachment' : safeName;
  }

  String _contentTypeFor(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();

    return switch (extension) {
      'pdf' => 'application/pdf',
      'doc' => 'application/msword',
      'docx' =>
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'txt' => 'text/plain',
      _ => 'application/octet-stream',
    };
  }
}
