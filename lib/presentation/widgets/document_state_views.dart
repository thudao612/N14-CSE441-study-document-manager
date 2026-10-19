import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// ============================================================================
/// BƯỚC 3: CÁC WIDGET TRẠNG THÁI UI (LOADING, EMPTY, ERROR)
/// Hệ thống Quản lý Tài liệu Đa nền tảng Flutter
/// ============================================================================

/// 1. Trạng thái Đang tải (LoadingState):
/// Hỗ trợ hiển thị Skeleton/Shimmer mô phỏng thẻ tài liệu hoặc CircularProgressIndicator
class DocumentLoadingState extends StatefulWidget {
  final int crossAxisCount;
  final bool showSkeleton;

  const DocumentLoadingState({
    super.key,
    this.crossAxisCount = 1,
    this.showSkeleton = true,
  });

  @override
  State<DocumentLoadingState> createState() => _DocumentLoadingStateState();
}

class _DocumentLoadingStateState extends State<DocumentLoadingState>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    // Tạo hiệu ứng shimmer lấp lánh nhẹ nhàng thuần Flutter
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.35, end: 0.85).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Widget _buildShimmerBox({
    double? width,
    required double height,
    double borderRadius = 8,
  }) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: AppTheme.border.withValues(alpha: _animation.value),
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        );
      },
    );
  }

  Widget _buildSkeletonCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppTheme.border, width: 1.2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                _buildShimmerBox(width: 80, height: 24, borderRadius: 8),
                const SizedBox(width: 8),
                _buildShimmerBox(width: 60, height: 24, borderRadius: 8),
                const Spacer(),
                _buildShimmerBox(width: 24, height: 24, borderRadius: 12),
              ],
            ),
            const SizedBox(height: 14),
            _buildShimmerBox(width: double.infinity, height: 18, borderRadius: 6),
            const SizedBox(height: 8),
            _buildShimmerBox(width: 180, height: 14, borderRadius: 6),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildShimmerBox(width: 110, height: 14, borderRadius: 4),
                const Spacer(),
                _buildShimmerBox(width: 70, height: 14, borderRadius: 4),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.showSkeleton) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                color: AppTheme.primary,
                strokeWidth: 3.5,
              ),
              SizedBox(height: 16),
              Text(
                'Đang tải danh sách tài liệu...',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (widget.crossAxisCount <= 1) {
      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 4,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: _buildSkeletonCard(),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: widget.crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        mainAxisExtent: 220,
      ),
      itemCount: widget.crossAxisCount * 2,
      itemBuilder: (context, index) => _buildSkeletonCard(),
    );
  }
}

/// 2. Trạng thái Danh sách Rỗng (EmptyState):
/// Hiển thị icon FolderOpen hoặc SearchOff, thông báo và nút thêm tài liệu mới
class DocumentEmptyState extends StatelessWidget {
  final bool hasActiveFilter;
  final VoidCallback onAddDocument;
  final VoidCallback? onResetFilter;

  const DocumentEmptyState({
    super.key,
    required this.hasActiveFilter,
    required this.onAddDocument,
    this.onResetFilter,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 48.0),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon minh họa lớn với nền tròn phong cách Cashew
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: hasActiveFilter
                      ? AppTheme.primaryLight.withValues(alpha: 0.5)
                      : AppTheme.surfaceVariant,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Icon(
                  hasActiveFilter
                      ? Icons.search_off_rounded
                      : Icons.folder_open_rounded,
                  size: 48,
                  color: hasActiveFilter
                      ? AppTheme.primary
                      : AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 24),

              // Tiêu đề trạng thái
              Text(
                hasActiveFilter
                    ? 'Không tìm thấy tài liệu phù hợp'
                    : 'Chưa có tài liệu học tập nào',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 10),

              // Mô tả chi tiết
              Text(
                hasActiveFilter
                    ? 'Hãy thử thay đổi từ khóa tìm kiếm hoặc bấm đặt lại các bộ lọc bên trên.'
                    : 'Bắt đầu thêm bài giảng, giáo trình, bài tập hoặc tài liệu tham khảo đầu tiên của bạn vào hệ thống!',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13.5,
                  color: AppTheme.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 26),

              // Các nút hành động chính
              Wrap(
                spacing: 12,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: [
                  if (hasActiveFilter && onResetFilter != null)
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: onResetFilter,
                      icon: const Icon(Icons.filter_alt_off_rounded, size: 18),
                      label: const Text('Xóa bộ lọc'),
                    ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 12,
                      ),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: onAddDocument,
                    icon: const Icon(Icons.add_rounded, size: 20),
                    label: const Text('Thêm tài liệu mới'),
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

/// 3. Trạng thái Báo lỗi (ErrorState):
/// Hiển thị icon cảnh báo, thông điệp lỗi cụ thể và nút Thử lại (Retry)
class DocumentErrorState extends StatelessWidget {
  final String errorMessage;
  final VoidCallback onRetry;

  const DocumentErrorState({
    super.key,
    required this.errorMessage,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 40.0),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon cảnh báo lỗi
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.error.withValues(alpha: 0.15),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  size: 44,
                  color: AppTheme.error,
                ),
              ),
              const SizedBox(height: 22),

              const Text(
                'Không thể tải dữ liệu',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 10),

              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Text(
                  errorMessage.isNotEmpty
                      ? errorMessage
                      : 'Đã có lỗi xảy ra trong quá trình kết nối đến máy chủ.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.error,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 26,
                    vertical: 13,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 2,
                ),
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 20),
                label: const Text(
                  'Thử lại ngay',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
