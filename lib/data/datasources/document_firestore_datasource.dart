import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/document_model.dart';
import 'document_local_datasource.dart';

/// Firestore implementation for the existing document data source contract.
///
/// Uses the "documents" collection.
/// Dates remain ISO 8601 strings to match DocumentModel.
class DocumentFirestoreDataSource implements DocumentLocalDataSource {
  DocumentFirestoreDataSource({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('documents');

  @override
  Future<List<DocumentModel>> getDocuments() async {
    final snapshot = await _collection.get();

    return snapshot.docs
        .map(
          (document) => DocumentModel.fromJson({
            ...document.data(),
            'id': document.id,
          }),
        )
        .toList(growable: false);
  }

  @override
  Future<DocumentModel?> getDocumentById(String id) async {
    final snapshot = await _collection.doc(id).get();

    if (!snapshot.exists) {
      return null;
    }

    final data = snapshot.data();
    if (data == null) {
      return null;
    }

    return DocumentModel.fromJson({
      ...data,
      'id': snapshot.id,
    });
  }

  @override
  Future<DocumentModel> insertDocument(DocumentModel doc) async {
    await _collection.doc(doc.id).set(_toFirestore(doc));
    return doc;
  }

  @override
  Future<DocumentModel> updateDocument(DocumentModel doc) async {
    final reference = _collection.doc(doc.id);
    final existing = await reference.get();

    if (!existing.exists) {
      throw StateError(
        'Cannot update document: ID ${doc.id} does not exist.',
      );
    }

    await reference.update(_toFirestore(doc));
    return doc;
  }

  @override
  Future<bool> deleteDocument(String id) async {
    final reference = _collection.doc(id);
    final existing = await reference.get();

    if (!existing.exists) {
      return false;
    }

    await reference.delete();
    return true;
  }

  /// Do not seed sample documents into the shared cloud database.
  ///
  /// The local implementation keeps its sample data for development and tests.
  @override
  Future<void> seedInitialData() async {}

  Map<String, dynamic> _toFirestore(DocumentModel doc) {
    final json = doc.toJson();

    // The document ID is stored as the Firestore document ID,
    // rather than duplicating it in the document fields.
    json.remove('id');

    return json;
  }
}
