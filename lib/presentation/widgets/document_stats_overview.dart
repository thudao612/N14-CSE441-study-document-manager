import 'package:flutter/material.dart';
import '../../domain/entities/document_type.dart';
import '../controllers/document_controller.dart';
import '../theme/app_theme.dart';

/// Khối nút lọc thống kê tổng quan với kích thước lớn và hiệu ứng nổi bật (Cashew Style)
class DocumentStatsOverview extends StatelessWidget {
  final DocumentController controller;

  const DocumentStatsOverview({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final stats = controller.stats;
    final activeType = controller.filter.type;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
      child: Row(
        children: [
          // Nút lọc: Tổng số tài liệu
          Expanded(
            child: _ProminentStatFilterCard(
              title: 'Tổng số',
              count: stats.totalCount,
              icon: Icons.folder_copy_rounded,
              color: AppTheme.primary,
              isSelected: activeType == null && !controller.filter.isFavoriteOnly,
              onTap: () => controller.setTypeFilter(null),
            ),
          ),
          const SizedBox(width: 8),

          // Nút lọc: Bài giảng
          Expanded(
            child: _ProminentStatFilterCard(
              title: 'Bài giảng',
              count: stats.lectureCount,
              icon: DocumentType.lecture.icon,
              color: DocumentType.lecture.primaryColor,
              isSelected: activeType == DocumentType.lecture,
              onTap: () => controller.setTypeFilter(DocumentType.lecture),
            ),
          ),
          const SizedBox(width: 8),

          // Nút lọc: Bài tập
          Expanded(
            child: _ProminentStatFilterCard(
              title: 'Bài tập',
              count: stats.exerciseCount,
              icon: DocumentType.exercise.icon,
              color: DocumentType.exercise.primaryColor,
              isSelected: activeType == DocumentType.exercise,
              onTap: () => controller.setTypeFilter(DocumentType.exercise),
            ),
          ),
          const SizedBox(width: 8),

          // Nút lọc: Tham khảo
          Expanded(
            child: _ProminentStatFilterCard(
              title: 'Tham khảo',
              count: stats.referenceCount,
              icon: DocumentType.reference.icon,
              color: DocumentType.reference.primaryColor,
              isSelected: activeType == DocumentType.reference,
              onTap: () => controller.setTypeFilter(DocumentType.reference),
            ),
          ),
        ],
      ),
    );
  }
}

/// Thẻ nút lọc kích thước lớn, icon nổi bật, đổ bóng phát quang khi chọn
class _ProminentStatFilterCard extends StatelessWidget {
  final String title;
  final int count;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _ProminentStatFilterCard({
    required this.title,
    required this.count,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 6),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.12) : AppTheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? color : AppTheme.border,
              width: isSelected ? 2.2 : 1.2,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.28),
                      blurRadius: 14,
                      spreadRadius: 1,
                      offset: const Offset(0, 5),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Hộp icon kích thước lớn với nền màu pastel nhẹ
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: isSelected ? color : color.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: color.withOpacity(0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          )
                        ]
                      : null,
                ),
                child: Icon(
                  icon,
                  size: 26,
                  color: isSelected ? Colors.white : color,
                ),
              ),
              const SizedBox(height: 10),

              // Số lượng nổi bật (kích thước lớn)
              Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: isSelected ? color : AppTheme.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 3),

              // Nhãn tên nút lọc
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? color : AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
