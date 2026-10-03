import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:url_launcher/url_launcher.dart';

/// Tiện ích nhận diện và mở tệp tài liệu (PDF, Word, Web Link)
class FileHelper {
  /// Kiểm tra xem có phải định dạng PDF
  static bool isPdf(String path) {
    final lower = path.trim().toLowerCase();
    return lower.endsWith('.pdf');
  }

  /// Kiểm tra xem có phải định dạng Microsoft Word (.doc, .docx)
  static bool isWord(String path) {
    final lower = path.trim().toLowerCase();
    return lower.endsWith('.doc') || lower.endsWith('.docx');
  }

  /// Kiểm tra xem có phải liên kết web (URL)
  static bool isWebLink(String path) {
    final lower = path.trim().toLowerCase();
    return lower.startsWith('http://') || lower.startsWith('https://');
  }

  /// Lấy tên tệp từ đường dẫn
  static String getFileName(String path) {
    final trimmed = path.trim();
    if (trimmed.isEmpty) return '';
    if (isWebLink(trimmed)) return trimmed;
    final normalized = trimmed.replaceAll(r'\', '/');
    return normalized.split('/').last;
  }

  /// Định dạng dung lượng tệp
  static String formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB'];
    var i = 0;
    double size = bytes.toDouble();
    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }
    return '${size.toStringAsFixed(1)} ${suffixes[i]}';
  }

  /// Lấy icon phù hợp cho từng định dạng tệp
  static IconData getFileIcon(String path) {
    if (isPdf(path)) return Icons.picture_as_pdf_rounded;
    if (isWord(path)) return Icons.description_rounded;
    if (isWebLink(path)) return Icons.link_rounded;
    return Icons.insert_drive_file_rounded;
  }

  /// Màu sắc đặc trưng cho loại tệp
  static Color getFileColor(String path) {
    if (isPdf(path)) return const Color(0xFFDC2626); // Đỏ PDF
    if (isWord(path)) return const Color(0xFF1D4ED8); // Xanh Word
    if (isWebLink(path)) return const Color(0xFF0D9488); // Teal Link
    return const Color(0xFF475569); // Xám tệp khác
  }

  /// Màu nền nhạt cho badge tệp
  static Color getFileBgColor(String path) {
    if (isPdf(path)) return const Color(0xFFFEE2E2);
    if (isWord(path)) return const Color(0xFFDBEAFE);
    if (isWebLink(path)) return const Color(0xFFCCFBF1);
    return const Color(0xFFF1F5F9);
  }

  /// Nhãn hiển thị loại tệp (PDF, WORD, LINK, FILE)
  static String getFileBadgeLabel(String path) {
    if (isPdf(path)) return 'PDF';
    if (isWord(path)) return 'WORD';
    if (isWebLink(path)) return 'LINK';
    final parts = path.split('.');
    if (parts.length > 1) {
      final ext = parts.last.trim();
      if (ext.isNotEmpty && ext.length <= 4) {
        return ext.toUpperCase();
      }
    }
    return 'TỆP';
  }

  /// Mở tệp cục bộ hoặc điều hướng liên kết web
  static Future<void> openDocument(BuildContext context, String path) async {
    final cleanPath = path.trim();
    if (cleanPath.isEmpty) return;

    try {
      if (isWebLink(cleanPath)) {
        final uri = Uri.parse(cleanPath);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          return;
        }
      } else {
        final result = await OpenFilex.open(cleanPath);
        if (result.type == ResultType.done) {
          return;
        }
      }
    } catch (_) {
      // Bỏ qua lỗi và chuyển sang hiển thị SnackBar
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã chọn tệp: ${getFileName(cleanPath)}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
