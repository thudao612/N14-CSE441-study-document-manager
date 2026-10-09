import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/document.dart';
import '../controllers/document_controller.dart';
import '../theme/app_theme.dart';
import '../utils/file_helper.dart';

/// Thẻ hiển thị một tài liệu học tập chuẩn phong cách Cashew
class DocumentCard extends StatelessWidget {
  final Document document;
  final DocumentController controller;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const DocumentCard({
    super.key,
    required this.document,
    required this.controller,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final type = document.type;
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hàng Header: Badge phân loại + Môn học + Favorite + Menu
              Row(
                children: [
                  // Badge Phân loại
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: type.badgeBackgroundColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(type.icon, size: 14, color: type.primaryColor),
                        const SizedBox(width: 4),
                        Text(
                          type.displayName,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: type.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Chip Môn học
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        document.subject,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Nút Favorite
                  IconButton(
                    icon: Icon(
                      document.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: document.isFavorite ? Colors.amber : AppTheme.textSecondary,
                      size: 22,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    splashRadius: 20,
                    tooltip: document.isFavorite ? 'Bỏ yêu thích' : 'Yêu thích',
                    onPressed: () => controller.toggleFavorite(document.id),
                  ),
                  const SizedBox(width: 8),

                  // Menu tùy chọn (Sửa / Xóa)
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert_rounded, size: 20, color: AppTheme.textSecondary),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    splashRadius: 20,
                    onSelected: (value) {
                      if (value == 'edit') onEdit();
                      if (value == 'delete') onDelete();
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, size: 18, color: AppTheme.primary),
                            SizedBox(width: 8),
                            Text('Chỉnh sửa'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline_rounded, size: 18, color: AppTheme.error),
                            SizedBox(width: 8),
                            Text('Xóa tài liệu', style: TextStyle(color: AppTheme.error)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Tiêu đề tài liệu
              Text(
                document.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                  height: 1.3,
                ),
              ),

              // Mô tả tóm tắt nếu có
              if (document.description.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  document.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: AppTheme.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],

              // Thẻ Tags nếu có
              if (document.tags.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: document.tags.take(4).map((tag) {
                    return InkWell(
                      onTap: () => controller.setTagFilter(tag),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '#$tag',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],

              const SizedBox(height: 12),

              // Footer: Ngày cập nhật + Liên kết (nếu có)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.access_time_rounded, size: 13, color: AppTheme.textSecondary),
                            const SizedBox(width: 4),
                            Text(
                              'Cập nhật: ${dateFormat.format(document.updatedAt)}',
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        if (document.authorEmail.isNotEmpty)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.person_outline_rounded, size: 13, color: AppTheme.primary),
                              const SizedBox(width: 3),
                              Text(
                                document.authorEmail,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.primary,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  if (document.hasFileOrLink)
                    InkWell(
                      onTap: () => FileHelper.openDocument(context, document.fileUrlOrPath),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: FileHelper.getFileBgColor(document.fileUrlOrPath),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              FileHelper.getFileIcon(document.fileUrlOrPath),
                              size: 13,
                              color: FileHelper.getFileColor(document.fileUrlOrPath),
                            ),
                            const SizedBox(width: 4),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 130),
                              child: Text(
                                FileHelper.isWebLink(document.fileUrlOrPath)
                                    ? 'Mở liên kết'
                                    : document.fileName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: FileHelper.getFileColor(document.fileUrlOrPath),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
