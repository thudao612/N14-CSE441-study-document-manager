import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/document.dart';
import '../controllers/document_controller.dart';
import '../theme/app_theme.dart';
import '../utils/file_helper.dart';
import 'document_form_modal.dart';

/// Modal xem chi tiết tài liệu học tập
class DocumentDetailModal extends StatelessWidget {
  final Document document;
  final DocumentController controller;

  const DocumentDetailModal({
    super.key,
    required this.document,
    required this.controller,
  });

  static Future<void> show(
    BuildContext context, {
    required Document document,
    required DocumentController controller,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DocumentDetailModal(
        document: document,
        controller: controller,
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Xác nhận xóa tài liệu'),
        content: Text(
          'Bạn có chắc chắn muốn xóa tài liệu "${document.title}" không? Hành động này không thể hoàn tác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () async {
              Navigator.pop(dialogCtx); // Đóng dialog
              Navigator.pop(context); // Đóng detail sheet
              final success = await controller.deleteDocument(document.id);
              if (context.mounted && success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã xóa tài liệu thành công.'),
                    backgroundColor: AppTheme.secondary,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final type = document.type;
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: type.badgeBackgroundColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(type.icon, size: 16, color: type.primaryColor),
                      const SizedBox(width: 4),
                      Text(
                        type.displayName,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: type.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    document.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: document.isFavorite ? Colors.amber : AppTheme.textSecondary,
                  ),
                  tooltip: document.isFavorite ? 'Bỏ yêu thích' : 'Yêu thích',
                  onPressed: () => controller.toggleFavorite(document.id),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppTheme.border),

          // Content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Môn học
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Môn: ${document.subject}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Tiêu đề
                  SelectableText(
                    document.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Mô tả
                  if (document.description.isNotEmpty) ...[
                    const Text(
                      'Ghi chú nội dung',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: SelectableText(
                        document.description,
                        style: const TextStyle(
                          fontSize: 14.5,
                          height: 1.45,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Liên kết tệp đính kèm
                  if (document.fileUrlOrPath.isNotEmpty) ...[
                    const Text(
                      'Tệp đính kèm học tập',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: FileHelper.getFileBgColor(document.fileUrlOrPath),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: FileHelper.getFileColor(document.fileUrlOrPath).withOpacity(0.35),
                          width: 1.2,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  FileHelper.getFileIcon(document.fileUrlOrPath),
                                  color: FileHelper.getFileColor(document.fileUrlOrPath),
                                  size: 26,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SelectableText(
                                      document.fileName,
                                      style: const TextStyle(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                      decoration: BoxDecoration(
                                        color: FileHelper.getFileColor(document.fileUrlOrPath),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        FileHelper.getFileBadgeLabel(document.fileUrlOrPath),
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.copy_rounded, size: 20),
                                color: FileHelper.getFileColor(document.fileUrlOrPath),
                                tooltip: 'Sao chép đường dẫn',
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(text: document.fileUrlOrPath));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Đã sao chép đường dẫn vào clipboard'),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Nút Mở tệp / Xem tài liệu trực tiếp
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: FileHelper.getFileColor(document.fileUrlOrPath),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: Icon(
                                FileHelper.isWebLink(document.fileUrlOrPath)
                                    ? Icons.open_in_new_rounded
                                    : Icons.file_open_rounded,
                                size: 18,
                              ),
                              label: Text(
                                FileHelper.isWebLink(document.fileUrlOrPath)
                                    ? 'Mở liên kết Web'
                                    : 'Mở tệp xem nội dung',
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              onPressed: () => FileHelper.openDocument(context, document.fileUrlOrPath),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Thẻ Tags
                  if (document.tags.isNotEmpty) ...[
                    const Text(
                      'Thẻ từ khóa',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: document.tags.map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.border),
                          ),
                          child: Text(
                            '#$tag',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primary,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Metadata thời gian
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 14, color: AppTheme.textSecondary),
                      const SizedBox(width: 6),
                      Text(
                        'Tạo lúc: ${dateFormat.format(document.createdAt)}',
                        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                      ),
                      const Spacer(),
                      const Icon(Icons.update_rounded, size: 14, color: AppTheme.textSecondary),
                      const SizedBox(width: 6),
                      Text(
                        'Cập nhật: ${dateFormat.format(document.updatedAt)}',
                        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Bottom Action Buttons: Sửa & Xóa
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.error,
                            side: const BorderSide(color: AppTheme.error),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          icon: const Icon(Icons.delete_outline_rounded, size: 18),
                          label: const Text('Xóa tài liệu'),
                          onPressed: () => _confirmDelete(context),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          icon: const Icon(Icons.edit_rounded, size: 18),
                          label: const Text('Chỉnh sửa'),
                          onPressed: () {
                            Navigator.pop(context); // Đóng detail sheet
                            DocumentFormModal.show(
                              context,
                              controller: controller,
                              document: document,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
