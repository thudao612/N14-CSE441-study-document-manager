import 'package:flutter/foundation.dart';
import '../../domain/entities/borrow_request.dart';
import '../../domain/entities/document.dart';
import '../../domain/entities/document_filter.dart';
import '../../domain/entities/document_permission.dart';
import '../../domain/entities/document_type.dart';
import '../../usecases/add_document_usecase.dart';
import '../../usecases/delete_document_usecase.dart';
import '../../usecases/get_document_borrow_requests_usecase.dart';
import '../../usecases/get_document_permissions_usecase.dart';
import '../../usecases/get_document_stats_usecase.dart';
import '../../usecases/get_documents_usecase.dart';
import '../../usecases/get_my_borrow_request_usecase.dart';
import '../../usecases/request_document_borrow_usecase.dart';
import '../../usecases/review_borrow_request_usecase.dart';
import '../../usecases/revoke_document_permission_usecase.dart';
import '../../usecases/return_borrow_request_usecase.dart';
import '../../usecases/search_documents_usecase.dart';
import '../../usecases/share_document_usecase.dart';
import '../../usecases/update_document_usecase.dart';
import '../../usecases/upload_document_file_usecase.dart';

/// Controller quản lý trạng thái của ứng dụng theo mô hình Reactive (Presentation Layer)
class DocumentController extends ChangeNotifier {
  final AddDocumentUseCase _addDocumentUseCase;
  final UpdateDocumentUseCase _updateDocumentUseCase;
  final DeleteDocumentUseCase _deleteDocumentUseCase;
  final SearchDocumentsUseCase _searchDocumentsUseCase;
  final GetDocumentsUseCase _getDocumentsUseCase;
  final GetDocumentStatsUseCase _getDocumentStatsUseCase;
  final UploadDocumentFileUseCase? _uploadDocumentFileUseCase;
  final ShareDocumentUseCase? _shareDocumentUseCase;
  final GetDocumentPermissionsUseCase? _getDocumentPermissionsUseCase;
  final RevokeDocumentPermissionUseCase? _revokeDocumentPermissionUseCase;
  final RequestDocumentBorrowUseCase? _requestDocumentBorrowUseCase;
  final GetDocumentBorrowRequestsUseCase? _getDocumentBorrowRequestsUseCase;
  final GetMyBorrowRequestUseCase? _getMyBorrowRequestUseCase;
  final ReviewBorrowRequestUseCase? _reviewBorrowRequestUseCase;
  final ReturnBorrowRequestUseCase? _returnBorrowRequestUseCase;

  DocumentController({
    required AddDocumentUseCase addDocumentUseCase,
    required UpdateDocumentUseCase updateDocumentUseCase,
    required DeleteDocumentUseCase deleteDocumentUseCase,
    required SearchDocumentsUseCase searchDocumentsUseCase,
    required GetDocumentsUseCase getDocumentsUseCase,
    required GetDocumentStatsUseCase getDocumentStatsUseCase,
    UploadDocumentFileUseCase? uploadDocumentFileUseCase,
    ShareDocumentUseCase? shareDocumentUseCase,
    GetDocumentPermissionsUseCase? getDocumentPermissionsUseCase,
    RevokeDocumentPermissionUseCase? revokeDocumentPermissionUseCase,
    RequestDocumentBorrowUseCase? requestDocumentBorrowUseCase,
    GetDocumentBorrowRequestsUseCase? getDocumentBorrowRequestsUseCase,
    GetMyBorrowRequestUseCase? getMyBorrowRequestUseCase,
    ReviewBorrowRequestUseCase? reviewBorrowRequestUseCase,
    ReturnBorrowRequestUseCase? returnBorrowRequestUseCase,
  })  : _addDocumentUseCase = addDocumentUseCase,
        _updateDocumentUseCase = updateDocumentUseCase,
        _deleteDocumentUseCase = deleteDocumentUseCase,
        _searchDocumentsUseCase = searchDocumentsUseCase,
        _getDocumentsUseCase = getDocumentsUseCase,
        _getDocumentStatsUseCase = getDocumentStatsUseCase,
        _uploadDocumentFileUseCase = uploadDocumentFileUseCase,
        _shareDocumentUseCase = shareDocumentUseCase,
        _getDocumentPermissionsUseCase = getDocumentPermissionsUseCase,
        _revokeDocumentPermissionUseCase = revokeDocumentPermissionUseCase,
        _requestDocumentBorrowUseCase = requestDocumentBorrowUseCase,
        _getDocumentBorrowRequestsUseCase = getDocumentBorrowRequestsUseCase,
        _getMyBorrowRequestUseCase = getMyBorrowRequestUseCase,
        _reviewBorrowRequestUseCase = reviewBorrowRequestUseCase,
        _returnBorrowRequestUseCase = returnBorrowRequestUseCase;

  // --- STATE ---
  List<Document> _documents = [];
  List<Document> _filteredDocuments = [];
  DocumentStats _stats = DocumentStats.empty();
  DocumentFilter _filter = DocumentFilter.empty();
  List<String> _subjects = [];
  List<String> _tags = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _sourceFilter = 'all'; // 'all' | 'mine' | 'shared'

  // --- GETTERS ---
  List<Document> get documents => _documents;
  List<Document> get filteredDocuments => _filteredDocuments;
  DocumentStats get stats => _stats;
  DocumentFilter get filter => _filter;
  List<String> get subjects => _subjects;
  List<String> get tags => _tags;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get canUploadDocumentFile => _uploadDocumentFileUseCase != null;
  bool get canManagePermissions => _shareDocumentUseCase != null;
  bool get canRequestBorrow => _requestDocumentBorrowUseCase != null &&
      _getMyBorrowRequestUseCase != null && _returnBorrowRequestUseCase != null;
  bool get canManageBorrowRequests =>
      _getDocumentBorrowRequestsUseCase != null &&
      _reviewBorrowRequestUseCase != null;
  String get sourceFilter => _sourceFilter;

  /// Khởi tạo và nạp dữ liệu ban đầu
  Future<void> init() async {
    await loadData();
  }

  /// Tải toàn bộ dữ liệu, thống kê và cập nhật bộ lọc
  Future<void> loadData() async {
    _setLoading(true);
    _clearError();

    try {
      _documents = await _getDocumentsUseCase.execute();
      _subjects = await _getDocumentsUseCase.getAllSubjects();
      _tags = await _getDocumentsUseCase.getAllTags();
      _stats = await _getDocumentStatsUseCase.execute();
      await _applyFilter();
    } catch (e) {
      _errorMessage = 'Không thể tải danh sách tài liệu: $e';
    } finally {
      _setLoading(false);
    }
  }

  /// Tải tệp lên thông qua UseCase (Firebase Storage)
  Future<String> uploadDocumentFile({
    required String fileName,
    required List<int> bytes,
  }) async {
    final useCase = _uploadDocumentFileUseCase;

    if (useCase == null) {
      throw StateError(
        'UploadDocumentFileUseCase chưa được cấu hình.',
      );
    }

    return useCase.execute(
      fileName: fileName,
      bytes: bytes,
    );
  }

  /// Thêm tài liệu mới thông qua UseCase
  Future<bool> addDocument(AddDocumentParams params) async {
    _setLoading(true);
    _clearError();

    try {
      await _addDocumentUseCase.execute(params);
      await loadData();
      return true;
    } catch (e) {
      _errorMessage = e
          .toString()
          .replaceFirst('Exception: ', '')
          .replaceFirst('ArgumentError: ', '');
      _setLoading(false);
      return false;
    }
  }

  /// Cập nhật tài liệu thông qua UseCase
  Future<bool> updateDocument(UpdateDocumentParams params) async {
    _setLoading(true);
    _clearError();

    try {
      await _updateDocumentUseCase.execute(params);
      await loadData();
      return true;
    } catch (e) {
      _errorMessage = e
          .toString()
          .replaceFirst('Exception: ', '')
          .replaceFirst('ArgumentError: ', '');
      _setLoading(false);
      return false;
    }
  }

  /// Xóa tài liệu thông qua UseCase
  Future<bool> deleteDocument(String id) async {
    _setLoading(true);
    _clearError();

    try {
      final success = await _deleteDocumentUseCase.execute(id);
      if (success) {
        await loadData();
      } else {
        _errorMessage = 'Không thể xóa tài liệu với ID: $id';
      }
      return success;
    } catch (e) {
      _errorMessage = 'Lỗi khi xóa tài liệu: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Bật/tắt trạng thái yêu thích
  Future<void> toggleFavorite(String id) async {
    final doc = _documents.firstWhere((d) => d.id == id);
    final params = UpdateDocumentParams(
      id: doc.id,
      title: doc.title,
      subject: doc.subject,
      type: doc.type,
      description: doc.description,
      fileUrlOrPath: doc.fileUrlOrPath,
      tags: doc.tags,
      isFavorite: !doc.isFavorite,
    );
    await updateDocument(params);
  }

  /// Thay đổi từ khóa tìm kiếm
  Future<void> setSearchQuery(String query) async {
    _filter = _filter.copyWith(searchQuery: query);
    await _applyFilter();
  }

  /// Thay đổi phân loại lọc (Tất cả, Bài giảng, Bài tập, Tham khảo)
  Future<void> setTypeFilter(DocumentType? type) async {
    if (_filter.type == type) {
      // Bấm lần thứ hai để bỏ chọn
      _filter = _filter.copyWith(clearType: true);
    } else {
      _filter = _filter.copyWith(type: type);
    }
    await _applyFilter();
  }

  /// Lọc theo nguồn tài liệu: 'all' (Tất cả), 'mine' (Của tôi), 'shared' (Được chia sẻ)
  Future<void> setSourceFilter(String source) async {
    _sourceFilter = source;
    await _applyFilter();
  }

  /// Bật/tắt lọc chỉ tài liệu yêu thích
  Future<void> toggleFavoriteFilter() async {
    _filter = _filter.copyWith(isFavoriteOnly: !_filter.isFavoriteOnly);
    await _applyFilter();
  }

  /// Đặt bộ lọc môn học
  Future<void> setSubjectFilter(String? subject) async {
    if (subject == null || subject.isEmpty) {
      _filter = _filter.copyWith(clearSubject: true);
    } else {
      _filter = _filter.copyWith(subject: subject);
    }
    await _applyFilter();
  }

  /// Đặt bộ lọc thẻ (Tag)
  Future<void> setTagFilter(String? tag) async {
    if (tag == null || tag.isEmpty) {
      _filter = _filter.copyWith(clearTag: true);
    } else {
      _filter = _filter.copyWith(tag: tag);
    }
    await _applyFilter();
  }

  /// Xóa toàn bộ bộ lọc
  Future<void> resetFilter() async {
    _filter = DocumentFilter.empty();
    _sourceFilter = 'all';
    await _applyFilter();
  }

  // --- QUẢN LÝ QUYỀN CHIA SẺ TÀI LIỆU (SHARING & PERMISSIONS) ---

  /// Lấy danh sách các quyền đã cấp của tài liệu
  Future<List<DocumentPermission>> getDocumentPermissions(String documentId) async {
    if (_getDocumentPermissionsUseCase == null) return [];
    try {
      return await _getDocumentPermissionsUseCase.execute(documentId);
    } catch (e) {
      debugPrint('Error getting permissions: $e');
      return [];
    }
  }

  /// Chia sẻ tài liệu qua email với quyền 'viewer' hoặc 'editor'
  Future<bool> shareDocument({
    required String documentId,
    required String targetEmail,
    required String role,
  }) async {
    if (_shareDocumentUseCase == null) {
      _errorMessage = 'Chức năng chia sẻ chưa được kích hoạt.';
      notifyListeners();
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      await _shareDocumentUseCase.execute(
        documentId: documentId,
        targetEmail: targetEmail,
        role: role,
      );
      return true;
    } catch (e) {
      _errorMessage = e
          .toString()
          .replaceFirst('Exception: ', '')
          .replaceFirst('ArgumentError: ', '');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Thu hồi quyền chia sẻ tài liệu
  Future<bool> revokePermission({
    required String documentId,
    required String targetUserId,
  }) async {
    if (_revokeDocumentPermissionUseCase == null) {
      _errorMessage = 'Chức năng thu hồi quyền chưa được kích hoạt.';
      notifyListeners();
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      final success = await _revokeDocumentPermissionUseCase.execute(
        documentId: documentId,
        targetUserId: targetUserId,
      );
      return success;
    } catch (e) {
      _errorMessage = 'Lỗi thu hồi quyền: $e';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // --- QUẢN LÝ YÊU CẦU MƯỢN TÀI LIỆU ---

  /// Gửi một yêu cầu mượn. Quyền thực tế được xác minh bởi RLS/trigger trên DB.
  Future<bool> requestBorrow(String documentId) async {
    final useCase = _requestDocumentBorrowUseCase;
    if (useCase == null) {
      _errorMessage = 'Chức năng mượn tài liệu chưa được cấu hình.';
      notifyListeners();
      return false;
    }

    _clearError();
    try {
      await useCase.execute(documentId: documentId);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _borrowErrorMessage(e);
      notifyListeners();
      return false;
    }
  }

  /// Danh sách yêu cầu của một tài liệu; RLS chỉ trả về dữ liệu người gọi được xem.
  Future<List<BorrowRequest>> getBorrowRequestsForDocument(
    String documentId,
  ) async {
    final useCase = _getDocumentBorrowRequestsUseCase;
    if (useCase == null) return [];

    _clearError();
    try {
      return await useCase.execute(documentId: documentId);
    } catch (e) {
      _errorMessage = _borrowErrorMessage(e);
      notifyListeners();
      return [];
    }
  }

  /// Trạng thái yêu cầu mới nhất của người dùng hiện tại cho tài liệu này.
  Future<BorrowRequest?> getMyBorrowRequest(String documentId) async {
    final useCase = _getMyBorrowRequestUseCase;
    if (useCase == null) return null;

    _clearError();
    try {
      return await useCase.execute(documentId: documentId);
    } catch (e) {
      _errorMessage = _borrowErrorMessage(e);
      notifyListeners();
      return null;
    }
  }

  /// Chủ sở hữu duyệt hoặc từ chối. RLS/trigger là lớp bảo vệ cuối cùng.
  Future<bool> reviewBorrowRequest({
    required String requestId,
    required String status,
  }) async {
    final useCase = _reviewBorrowRequestUseCase;
    if (useCase == null) {
      _errorMessage = 'Chức năng duyệt yêu cầu mượn chưa được cấu hình.';
      notifyListeners();
      return false;
    }

    _clearError();
    try {
      await useCase.execute(requestId: requestId, status: status);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _borrowErrorMessage(e);
      notifyListeners();
      return false;
    }
  }

  /// Người mượn xác nhận đã trả tài liệu sau khi yêu cầu được duyệt.
  Future<bool> markBorrowRequestReturned(String requestId) async {
    final useCase = _returnBorrowRequestUseCase;
    if (useCase == null) {
      _errorMessage = 'Chức năng xác nhận trả tài liệu chưa được cấu hình.';
      notifyListeners();
      return false;
    }

    _clearError();
    try {
      await useCase.execute(requestId: requestId);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _borrowErrorMessage(e);
      notifyListeners();
      return false;
    }
  }

  String _borrowErrorMessage(Object error) => error
      .toString()
      .replaceFirst('Exception: ', '')
      .replaceFirst('StateError: ', '')
      .replaceFirst('ArgumentError: ', '');

  // --- PRIVATE HELPERS ---
  Future<void> _applyFilter() async {
    try {
      var results = await _searchDocumentsUseCase.execute(_filter);

      // Áp dụng bộ lọc theo nguồn sở hữu / chia sẻ
      if (_sourceFilter == 'mine') {
        results = results.where((d) => d.isOwner).toList();
      } else if (_sourceFilter == 'shared') {
        results = results.where((d) => d.isShared).toList();
      }

      _filteredDocuments = results;
    } catch (e) {
      _errorMessage = 'Lỗi tìm kiếm: $e';
    }
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }
}
