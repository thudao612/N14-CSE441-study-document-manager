import 'package:flutter/material.dart';

/// Phân loại tài liệu học tập trong hệ thống
enum DocumentType {
  lecture,    // Bài giảng
  exercise,   // Bài tập
  reference;  // Tài liệu tham khảo

  /// Tên hiển thị tiếng Việt
  String get displayName {
    switch (this) {
      case DocumentType.lecture:
        return 'Bài giảng';
      case DocumentType.exercise:
        return 'Bài tập';
      case DocumentType.reference:
        return 'Tham khảo';
    }
  }

  /// Mô tả loại tài liệu
  String get description {
    switch (this) {
      case DocumentType.lecture:
        return 'Slide, giáo trình, bài giảng lý thuyết';
      case DocumentType.exercise:
        return 'Đề bài tập thực hành, đồ án, đề thi';
      case DocumentType.reference:
        return 'Sách tham khảo, bài báo, tài liệu mở rộng';
    }
  }

  /// Icon đại diện
  IconData get icon {
    switch (this) {
      case DocumentType.lecture:
        return Icons.menu_book_rounded;
      case DocumentType.exercise:
        return Icons.assignment_rounded;
      case DocumentType.reference:
        return Icons.bookmark_added_rounded;
    }
  }

  /// Màu sắc đặc trưng phong cách Cashew
  Color get primaryColor {
    switch (this) {
      case DocumentType.lecture:
        return const Color(0xFF3F51B5); // Indigo
      case DocumentType.exercise:
        return const Color(0xFF00897B); // Teal
      case DocumentType.reference:
        return const Color(0xFFE65100); // Deep Orange
    }
  }

  /// Màu nền nhạt (accent background) cho badges/chips
  Color get badgeBackgroundColor {
    switch (this) {
      case DocumentType.lecture:
        return const Color(0xFFE8EAF6);
      case DocumentType.exercise:
        return const Color(0xFFE0F2F1);
      case DocumentType.reference:
        return const Color(0xFFFBE9E7);
    }
  }

  /// Chuyển đổi từ chuỗi sang enum
  static DocumentType fromString(String? val) {
    if (val == null) return DocumentType.lecture;
    switch (val.toLowerCase().trim()) {
      case 'exercise':
      case 'bài tập':
      case 'baitap':
        return DocumentType.exercise;
      case 'reference':
      case 'tham khảo':
      case 'thamkhao':
        return DocumentType.reference;
      case 'lecture':
      case 'bài giảng':
      case 'baigiang':
      default:
        return DocumentType.lecture;
    }
  }
}
