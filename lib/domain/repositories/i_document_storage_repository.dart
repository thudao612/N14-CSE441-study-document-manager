abstract class IDocumentStorageRepository {
  Future<String> uploadDocument({
    required String fileName,
    required List<int> bytes,
  });
}
