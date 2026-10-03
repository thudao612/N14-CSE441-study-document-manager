import 'package:flutter/material.dart';
import '../../domain/entities/document_type.dart';
import '../controllers/document_controller.dart';
import '../theme/app_theme.dart';

/// Thanh cuộn bộ lọc nhanh (Quick Filters) dạng Pill Chips phong cách Cashew
class DocumentFilterBar extends StatelessWidget {
  final DocumentController controller;

  const DocumentFilterBar({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final filter = controller.filter;
    final stats = controller.stats;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Row(
        children: [
          // Nút "Tất cả"
          _FilterChipItem(
            label: 'Tất cả (${stats.totalCount})',
            isSelected: filter.type == null && !filter.isFavoriteOnly && filter.subject == null && filter.tag == null,
            onTap: () => controller.resetFilter(),
          ),
          const SizedBox(width: 8),

          // Nút "Yêu thích"
          _FilterChipItem(
            label: 'Yêu thích (${stats.favoriteCount})',
            icon: Icons.star_rounded,
            iconColor: Colors.amber,
            isSelected: filter.isFavoriteOnly,
            onTap: () => controller.toggleFavoriteFilter(),
          ),
          const SizedBox(width: 8),

          // Lọc Bài giảng
          _FilterChipItem(
            label: 'Bài giảng (${stats.lectureCount})',
            icon: DocumentType.lecture.icon,
            iconColor: DocumentType.lecture.primaryColor,
            isSelected: filter.type == DocumentType.lecture,
            onTap: () => controller.setTypeFilter(DocumentType.lecture),
          ),
          const SizedBox(width: 8),

          // Lọc Bài tập
          _FilterChipItem(
            label: 'Bài tập (${stats.exerciseCount})',
            icon: DocumentType.exercise.icon,
            iconColor: DocumentType.exercise.primaryColor,
            isSelected: filter.type == DocumentType.exercise,
            onTap: () => controller.setTypeFilter(DocumentType.exercise),
          ),
          const SizedBox(width: 8),

          // Lọc Tham khảo
          _FilterChipItem(
            label: 'Tham khảo (${stats.referenceCount})',
            icon: DocumentType.reference.icon,
            iconColor: DocumentType.reference.primaryColor,
            isSelected: filter.type == DocumentType.reference,
            onTap: () => controller.setTypeFilter(DocumentType.reference),
          ),

          // Nếu có chọn Subject
          if (filter.subject != null) ...[
            const SizedBox(width: 8),
            _FilterChipItem(
              label: 'Môn: ${filter.subject}',
              isSelected: true,
              onTap: () => controller.setSubjectFilter(null),
              trailing: const Icon(Icons.close, size: 14),
            ),
          ],

          // Nếu có chọn Tag
          if (filter.tag != null) ...[
            const SizedBox(width: 8),
            _FilterChipItem(
              label: '#${filter.tag}',
              isSelected: true,
              onTap: () => controller.setTagFilter(null),
              trailing: const Icon(Icons.close, size: 14),
            ),
          ],
        ],
      ),
    );
  }
}

class _FilterChipItem extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color? iconColor;
  final bool isSelected;
  final VoidCallback onTap;
  final Widget? trailing;

  const _FilterChipItem({
    required this.label,
    this.icon,
    this.iconColor,
    required this.isSelected,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(26),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : AppTheme.surface,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color: isSelected ? AppTheme.primary : AppTheme.border,
            width: isSelected ? 1.8 : 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 18,
                color: isSelected ? Colors.white : (iconColor ?? AppTheme.textSecondary),
              ),
              const SizedBox(width: 7),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? Colors.white : AppTheme.textPrimary,
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 4),
              IconTheme(
                data: IconThemeData(
                  color: isSelected ? Colors.white : AppTheme.textSecondary,
                  size: 14,
                ),
                child: trailing!,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
