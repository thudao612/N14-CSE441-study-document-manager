import 'dart:async';
import '../models/document_model.dart';

/// Hợp đồng trừu tượng cho nguồn dữ liệu cục bộ (Data Source)
abstract class DocumentLocalDataSource {
  Future<List<DocumentModel>> getDocuments();
  Future<DocumentModel?> getDocumentById(String id);
  Future<DocumentModel> insertDocument(DocumentModel doc);
  Future<DocumentModel> updateDocument(DocumentModel doc);
  Future<bool> deleteDocument(String id);
  Future<void> seedInitialData();
}

/// Triển khai nguồn dữ liệu cục bộ (In-Memory với cơ chế khởi tạo dữ liệu mẫu chuẩn)
class DocumentLocalDataSourceImpl implements DocumentLocalDataSource {
  final List<DocumentModel> _storage = [];
  bool _isInitialized = false;

  DocumentLocalDataSourceImpl({bool autoSeed = true}) {
    if (autoSeed) {
      seedInitialData();
    }
  }

  @override
  Future<void> seedInitialData() async {
    if (_isInitialized && _storage.isNotEmpty) return;

    final now = DateTime.now();
    _storage.clear();
    _storage.addAll([
      DocumentModel(
        id: 'doc-001',
        title: 'Bài giảng Kiến trúc Phần mềm: Clean Architecture & Cashew',
        subject: 'Thiết kế Hệ thống',
        type: 'lecture',
        description:
            'Phân tích chi tiết mô hình phân tầng, nguyên lý Dependency Inversion và ứng dụng trong Flutter Mobile.',
        fileUrlOrPath: 'GiaoTrinh_KienTruc_Cashew_CleanArch.pdf',
        tags: ['CleanArchitecture', 'Cashew', 'Flutter', 'DesignPatterns'],
        isFavorite: true,
        createdAt: now.subtract(const Duration(days: 3)).toIso8601String(),
        updatedAt: now.subtract(const Duration(hours: 12)).toIso8601String(),
      ),
      DocumentModel(
        id: 'doc-002',
        title: 'Đề bài tập thực hành: Xây dựng CRUD App với Provider',
        subject: 'Lập trình Di động',
        type: 'exercise',
        description:
            'Yêu cầu hoàn thành chức năng thêm, sửa, xóa, tìm kiếm tài liệu học tập theo kiến trúc 4 tầng.',
        fileUrlOrPath: 'DeBaiTap_ThucHanh_CRUD_Provider.docx',
        tags: ['Exercise', 'Provider', 'CRUD', 'UnitTesting'],
        isFavorite: true,
        createdAt: now.subtract(const Duration(days: 2)).toIso8601String(),
        updatedAt: now.subtract(const Duration(days: 1)).toIso8601String(),
      ),
      DocumentModel(
        id: 'doc-003',
        title: 'Tài liệu tham khảo: Design Patterns - Elements of Reusable Object-Oriented Software',
        subject: 'Công nghệ Phần mềm',
        type: 'reference',
        description:
            'Tài liệu kinh điển của Gang of Four (GoF) về 23 mẫu thiết kế phần mềm cốt lõi (Creational, Structural, Behavioral).',
        fileUrlOrPath: 'https://refactoring.guru/design-patterns',
        tags: ['GoF', 'OOP', 'SoftwareEngineering', 'Reference'],
        isFavorite: false,
        createdAt: now.subtract(const Duration(days: 5)).toIso8601String(),
        updatedAt: now.subtract(const Duration(days: 4)).toIso8601String(),
      ),
      DocumentModel(
        id: 'doc-004',
        title: 'Bài giảng Cấu trúc Dữ liệu: Cây Đỏ Đen & Đồ thị',
        subject: 'Cấu trúc Dữ liệu & Giải thuật',
        type: 'lecture',
        description:
            'Slide bài giảng chi tiết về cấu trúc Red-Black Tree, thuật toán BFS/DFS và thuật toán Dijkstra tìm đường đi ngắn nhất.',
        fileUrlOrPath: 'Slide_CayDoDen_DoThi_Dijkstra.pdf',
        tags: ['Algorithms', 'DataStructures', 'Graph', 'Tree'],
        isFavorite: false,
        createdAt: now.subtract(const Duration(days: 6)).toIso8601String(),
        updatedAt: now.subtract(const Duration(days: 3)).toIso8601String(),
      ),
      DocumentModel(
        id: 'doc-005',
        title: 'Bộ đề thi thử môn Cơ sở Dữ liệu & Tối ưu hóa Truy vấn',
        subject: 'Cơ sở Dữ liệu',
        type: 'exercise',
        description:
            'Tổng hợp 10 đề thi cuối kỳ môn RDBMS, chuẩn hóa dạng 3NF/BCNF và thực hành viết Query SQL phức tạp.',
        fileUrlOrPath: 'DeThiThu_RDBMS_Optimization_2026.docx',
        tags: ['SQL', 'Database', 'ExamPrep', 'Optimization'],
        isFavorite: true,
        createdAt: now.subtract(const Duration(days: 8)).toIso8601String(),
        updatedAt: now.subtract(const Duration(days: 2)).toIso8601String(),
      ),
      DocumentModel(
        id: 'doc-006',
        title: 'Tài liệu nghiên cứu: Flutter Engine Architecture & Rendering Pipeline',
        subject: 'Lập trình Di động',
        type: 'reference',
        description:
            'Nghiên cứu cơ chế Skia/Impeller, RenderObjects và vòng đời Widget trong Flutter Framework.',
        fileUrlOrPath: 'https://flutter.dev/docs/resources/inside-flutter',
        tags: ['Flutter', 'Internals', 'Performance', 'Rendering'],
        isFavorite: false,
        createdAt: now.subtract(const Duration(days: 10)).toIso8601String(),
        updatedAt: now.subtract(const Duration(days: 7)).toIso8601String(),
      ),
    ]);

    _isInitialized = true;
  }

  @override
  Future<List<DocumentModel>> getDocuments() async {
    return List<DocumentModel>.unmodifiable(_storage);
  }

  @override
  Future<DocumentModel?> getDocumentById(String id) async {
    try {
      return _storage.firstWhere((doc) => doc.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<DocumentModel> insertDocument(DocumentModel doc) async {
    _storage.removeWhere((item) => item.id == doc.id);
    _storage.insert(0, doc); // Thêm vào đầu danh sách
    return doc;
  }

  @override
  Future<DocumentModel> updateDocument(DocumentModel doc) async {
    final index = _storage.indexWhere((item) => item.id == doc.id);
    if (index >= 0) {
      _storage[index] = doc;
      return doc;
    } else {
      throw Exception('Không tìm thấy tài liệu với ID: ${doc.id} để cập nhật');
    }
  }

  @override
  Future<bool> deleteDocument(String id) async {
    final initialLength = _storage.length;
    _storage.removeWhere((doc) => doc.id == id);
    return _storage.length < initialLength;
  }
}
