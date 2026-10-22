import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/document.dart';
import '../controllers/document_controller.dart';
import '../theme/app_theme.dart';
import '../utils/file_helper.dart';
import 'share_document_dialog.dart';

/// Thẻ hiển thị một tài liệu học tập chuẩn phong cách Cashew
/// Tích hợp nhận diện vai trò: Chủ sở hữu (Owner), Biên tập (Editor), Chỉ xem (Viewer)
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

  Widget _buildRoleBadge() {
    if (document.isOwner) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3E0),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFFFB74D)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.workspace_premium_rounded,
                size: 12, color: Color(0xFFE65100)),
            SizedBox(width: 3),
            Text(
              'Chủ sở hữu',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFFE65100),
              ),
            ),
          ],
        ),
      );
    } else if (document.userRole == 'editor') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFE0F2F1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFF80CBC4)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.edit_note_rounded, size: 13, color: Color(0xFF00695C)),
            SizedBox(width: 3),
            Text(
              'Biên tập',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF00695C),
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFEDE7F6),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFB39DDB)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.visibility_outlined, size: 12, color: Color(0xFF4527A0)),
            SizedBox(width: 3),
            Text(
              'Chỉ xem',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF4527A0),
              ),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final type = document.type;
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Hàng Header: Badges bên trái + Nút Hành động bên phải (được neo cố định)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        // Badge phân loại
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3.5,
                          ),
                          decoration: BoxDecoration(
                            color: type.badgeBackgroundColor,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                type.icon,
                                size: 13,
                                color: type.primaryColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                type.displayName,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: type.primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Huy hiệu vai trò
                        _buildRoleBadge(),

                        // Chip môn học: giới hạn độ rộng và tự động cắt ngắn nếu dài
                        Container(
                          constraints: const BoxConstraints(maxWidth: 130),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3.5,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            document.subject,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 4),

                  // Nút yêu thích + Menu tùy chọn cố định góc phải trên
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          document.isFavorite
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          color: document.isFavorite
                              ? Colors.amber
                              : AppTheme.textSecondary,
                          size: 22,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        splashRadius: 18,
                        tooltip:
                            document.isFavorite ? 'Bỏ yêu thích' : 'Yêu thích',
                        onPressed: () => controller.toggleFavorite(document.id),
                      ),
                      const SizedBox(width: 4),
                      PopupMenuButton<String>(
                        icon: const Icon(
                          Icons.more_vert_rounded,
                          size: 20,
                          color: AppTheme.textSecondary,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        splashRadius: 18,
                        onSelected: (value) {
                          if (value == 'edit') onEdit();
                          if (value == 'delete') onDelete();
                          if (value == 'share') {
                            ShareDocumentDialog.show(
                              context,
                              document: document,
                              controller: controller,
                            );
                          }
                        },
                        itemBuilder: (context) => [
                          // Chỉ chủ sở hữu được chia sẻ
                          if (document.isOwner &&
                              controller.canManagePermissions)
                            const PopupMenuItem(
                              value: 'share',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.share_outlined,
                                    size: 18,
                                    color: AppTheme.primary,
                                  ),
                                  SizedBox(width: 8),
                                  Text('Chia sẻ quyền'),
                                ],
                              ),
                            ),

                          // Chủ sở hữu và Editor được sửa
                          if (document.canEdit)
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.edit_outlined,
                                    size: 18,
                                    color: AppTheme.primary,
                                  ),
                                  SizedBox(width: 8),
                                  Text('Chỉnh sửa'),
                                ],
                              ),
                            ),

                          // Chỉ chủ sở hữu được xóa
                          if (document.isOwner)
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.delete_outline_rounded,
                                    size: 18,
                                    color: AppTheme.error,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Xóa tài liệu',
                                    style: TextStyle(
                                      color: AppTheme.error,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Tiêu đề tài liệu
              Text(
                document.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                  height: 1.25,
                ),
              ),

              // Mô tả tóm tắt nếu có
              if (document.description.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  document.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppTheme.textSecondary,
                    height: 1.3,
                  ),
                ),
              ],

              // Thẻ tác giả nếu là tài liệu được chia sẻ
              if (document.isShared && document.authorEmail.isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.person_pin_rounded,
                        size: 13, color: AppTheme.textSecondary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Chia sẻ bởi: ${document.authorEmail}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              // Tệp đính kèm / Liên kết nếu có
              if (document.hasFileOrLink) ...[
                const SizedBox(height: 6),
                InkWell(
                  onTap: () =>
                      FileHelper.openDocument(context, document.fileUrlOrPath),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          FileHelper.getFileIcon(document.fileUrlOrPath),
                          size: 14,
                          color: AppTheme.primary,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            document.fileName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.open_in_new_rounded,
                          size: 12,
                          color: AppTheme.primary,
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              // Danh sách Tags
              if (document.tags.isNotEmpty) ...[
                const SizedBox(height: 6),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: document.tags.take(3).map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '#$tag',
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],

              const SizedBox(height: 8),

              // Footer: Ngày cập nhật
              Row(
                children: [
                  const Icon(
                    Icons.access_time_rounded,
                    size: 12,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      dateFormat.format(document.updatedAt),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
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
