import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/entities/document.dart';
import '../../domain/entities/document_filter.dart';
import '../../domain/entities/document_type.dart';
import '../../domain/repositories/i_document_repository.dart';
import '../models/document_model.dart';

/// Triển khai IDocumentRepository kết nối trực tiếp Cloud Firestore
/// Đọc và ghi dữ liệu từ collection 'documents' trên Cloud
class FirestoreDocumentRepository implements IDocumentRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  FirestoreDocumentRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('documents');

  @override
  Future<List<Document>> getAllDocuments() async {
    try {
      final snapshot = await _collection.get();
      final entities = snapshot.docs.map((doc) {
        final model = DocumentModel.fromJson({
          ...doc.data(),
          'id': doc.id,
        });
        return model.toEntity();
      }).toList();

      // Sắp xếp theo ngày cập nhật mới nhất
      entities.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return entities;
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw Exception(
          'Lỗi Permission Denied: Tài khoản chưa có quyền đọc dữ liệu từ Firestore collection "documents". '
          'Vui lòng đảm bảo đã đăng nhập và Security Rules cho phép "request.auth != null".',
        );
      }
      throw Exception('Lỗi Firestore [${e.code}]: ${e.message ?? e.toString()}');
    } catch (e) {
      throw Exception('Lỗi đọc dữ liệu Firestore: $e');
    }
  }

  @override
  Future<Document?> getDocumentById(String id) async {
    try {
      final doc = await _collection.doc(id).get();
      if (!doc.exists || doc.data() == null) return null;
      final model = DocumentModel.fromJson({
        ...doc.data()!,
        'id': doc.id,
      });
      return model.toEntity();
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw Exception(
          'Lỗi Permission Denied: Không thể đọc tài liệu $id do quy tắc bảo mật.',
        );
      }
      rethrow;
    }
  }

  @override
  Future<Document> addDocument(Document document) async {
    try {
      // 1. Tự động lấy thông tin người dùng đang đăng nhập từ Firebase Auth
      final currentUser = _auth.currentUser;
      final currentUserId = currentUser?.uid ?? document.userId;
      final authorEmail = currentUser?.email ??
          (currentUser?.displayName != null && currentUser!.displayName!.isNotEmpty
              ? currentUser.displayName!
              : (currentUser?.isAnonymous == true
                  ? 'Khách ẩn danh'
                  : document.authorEmail));

      // 2. Thêm userId và authorEmail vào Document
      final updatedDocument = document.copyWith(
        userId: currentUserId,
        authorEmail: authorEmail,
      );

      final model = DocumentModel.fromEntity(updatedDocument);
      final firestoreData = model.toFirestoreJson();

      if (updatedDocument.id.isNotEmpty) {
        await _collection.doc(updatedDocument.id).set(firestoreData);
        return updatedDocument;
      } else {
        final docRef = await _collection.add(firestoreData);
        return updatedDocument.copyWith(id: docRef.id);
      }
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw Exception(
          'Lỗi Permission Denied: Bạn không có quyền thêm tài liệu vào Firestore. '
          'Vui lòng kiểm tra lại trạng thái đăng nhập hoặc Security Rules trên Firebase Console.',
        );
      }
      throw Exception('Lỗi ghi Firestore [${e.code}]: ${e.message ?? e.toString()}');
    }
  }

  @override
  Future<Document> updateDocument(Document document) async {
    try {
      var docToSave = document;
      if (docToSave.userId.isEmpty && _auth.currentUser != null) {
        final currentUser = _auth.currentUser!;
        docToSave = docToSave.copyWith(
          userId: currentUser.uid,
          authorEmail: currentUser.email ?? currentUser.displayName ?? '',
        );
      }
      final model = DocumentModel.fromEntity(docToSave);
      await _collection.doc(docToSave.id).update(model.toFirestoreJson());
      return docToSave;
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw Exception(
          'Lỗi Permission Denied: Bạn không có quyền cập nhật tài liệu này.',
        );
      }
      rethrow;
    }
  }

  @override
  Future<bool> deleteDocument(String id) async {
    try {
      await _collection.doc(id).delete();
      return true;
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw Exception(
          'Lỗi Permission Denied: Bạn không có quyền xóa tài liệu này.',
        );
      }
      rethrow;
    }
  }

  @override
  Future<List<Document>> searchDocuments(DocumentFilter filter) async {
    final allDocs = await getAllDocuments();

    return allDocs.where((doc) {
      // 1. Lọc theo Phân loại tài liệu
      if (filter.type != null && doc.type != filter.type) {
        return false;
      }

      // 2. Lọc theo Yêu thích
      if (filter.isFavoriteOnly && !doc.isFavorite) {
        return false;
      }

      // 3. Lọc theo Môn học
      if (filter.subject != null && filter.subject!.trim().isNotEmpty) {
        if (doc.subject.toLowerCase() != filter.subject!.toLowerCase().trim()) {
          return false;
        }
      }

      // 4. Lọc theo Thẻ (Tag)
      if (filter.tag != null && filter.tag!.trim().isNotEmpty) {
        final targetTag = filter.tag!.toLowerCase().trim();
        final hasTag = doc.tags.any((t) => t.toLowerCase() == targetTag);
        if (!hasTag) {
          return false;
        }
      }

      // 5. Tìm kiếm từ khóa đa trường
      if (filter.searchQuery != null && filter.searchQuery!.trim().isNotEmpty) {
        final query = filter.searchQuery!.toLowerCase().trim();
        final titleMatch = doc.title.toLowerCase().contains(query);
        final subjectMatch = doc.subject.toLowerCase().contains(query);
        final descMatch = doc.description.toLowerCase().contains(query);
        final tagMatch =
            doc.tags.any((tag) => tag.toLowerCase().contains(query));

        if (!titleMatch && !subjectMatch && !descMatch && !tagMatch) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  @override
  Future<List<Document>> getDocumentsByType(DocumentType type) async {
    final allDocs = await getAllDocuments();
    return allDocs.where((doc) => doc.type == type).toList();
  }

  @override
  Future<List<String>> getAllSubjects() async {
    final allDocs = await getAllDocuments();
    final subjects = allDocs
        .map((e) => e.subject.trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();
    subjects.sort((a, b) => a.compareTo(b));
    return subjects;
  }

  @override
  Future<List<String>> getAllTags() async {
    final allDocs = await getAllDocuments();
    final tags = <String>{};
    for (final doc in allDocs) {
      tags.addAll(doc.tags);
    }
    final sortedTags = tags.toList()..sort();
    return sortedTags;
  }
}
