import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/document.dart';
import '../controllers/document_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/document_card.dart';
import '../widgets/document_detail_modal.dart';
import '../widgets/document_filter_bar.dart';
import '../widgets/document_form_modal.dart';
import '../widgets/document_search_bar.dart';
import '../widgets/document_state_views.dart';
import '../widgets/document_stats_overview.dart';

/// Màn hình chính của Ứng dụng Quản lý Tài liệu Học tập
/// Tích hợp Clean Architecture + Responsive LayoutBuilder cho Đa nền tảng (Web, Tablet, Mobile)
class DocumentHomeScreen extends StatelessWidget {
  const DocumentHomeScreen({super.key});

  /// Hộp thoại xác nhận xóa tài liệu - Bọc chống tràn viền và căn giữa trên Web
  void _showDeleteDialog(
    BuildContext context,
    DocumentController controller,
    Document doc,
  ) {
    showDialog(
      context: context,
      builder: (dialogCtx) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            scrollable: true,
            title: const Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: AppTheme.error,
                  size: 24,
                ),
                SizedBox(width: 8),
                Text('Xác nhận xóa tài liệu'),
              ],
            ),
            content: Text(
              'Bạn có chắc chắn muốn xóa "${doc.title}" không?\nHành động này không thể hoàn tác.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text('Hủy'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
                onPressed: () async {
                  Navigator.pop(dialogCtx);
                  final success = await controller.deleteDocument(doc.id);
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
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<DocumentController>();
    final docs = controller.filteredDocuments;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 76,
        title: Row(
          children: [
            // Logo ứng dụng với hiệu ứng gradient Cashew
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primary, Color(0xFF5C6BC0)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.auto_stories_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Tài liệu Học tập',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppTheme.mintAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Cashew Clean Architecture',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 24),
            tooltip: 'Làm mới dữ liệu',
            onPressed: () => controller.loadData(),
          ),
          Builder(
            builder: (context) {
              try {
                return StreamBuilder<User?>(
                  stream: FirebaseAuth.instance.authStateChanges(),
                  builder: (context, snapshot) {
                    final user = snapshot.data;
                    if (user == null) return const SizedBox.shrink();
                    final displayName = user.displayName ??
                        (user.email != null
                            ? user.email!.split('@').first
                            : 'Khách');
                    return PopupMenuButton<String>(
                      tooltip: 'Tài khoản: $displayName',
                      icon: CircleAvatar(
                        radius: 16,
                        backgroundColor: AppTheme.primaryLight,
                        backgroundImage: user.photoURL != null
                            ? NetworkImage(user.photoURL!)
                            : null,
                        child: user.photoURL == null
                            ? Text(
                                displayName.isNotEmpty
                                    ? displayName[0].toUpperCase()
                                    : 'U',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.primary,
                                ),
                              )
                            : null,
                      ),
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          enabled: false,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                displayName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              if (user.email != null)
                                Text(
                                  user.email!,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              const SizedBox(height: 2),
                              Text(
                                'UID: ${user.uid}',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontFamily: 'monospace',
                                  color: AppTheme.textSecondary.withValues(
                                    alpha: 0.8,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const PopupMenuDivider(),
                        const PopupMenuItem(
                          value: 'logout',
                          child: Row(
                            children: [
                              Icon(
                                Icons.logout_rounded,
                                color: AppTheme.error,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Đăng xuất',
                                style: TextStyle(color: AppTheme.error),
                              ),
                            ],
                          ),
                        ),
                      ],
                      onSelected: (value) async {
                        if (value == 'logout') {
                          await FirebaseAuth.instance.signOut();
                        }
                      },
                    );
                  },
                );
              } catch (_) {
                return const SizedBox.shrink();
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      // BƯỚC 1: Bọc nội dung trong SafeArea và sử dụng LayoutBuilder để tự động thích ứng giao diện
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double width = constraints.maxWidth;

            // Xác định số cột hiển thị theo chuẩn Responsive:
            // - width < 600: Mobile (1 cột)
            // - 600 <= width < 1024: Tablet (2 cột)
            // - 1024 <= width < 1440: Desktop / Web (3 cột)
            // - width >= 1440: Màn hình lớn (4 cột)
            final int crossAxisCount;
            if (width < 600) {
              crossAxisCount = 1;
            } else if (width < 1024) {
              crossAxisCount = 2;
            } else if (width < 1440) {
              crossAxisCount = 3;
            } else {
              crossAxisCount = 4;
            }

            // Khoảng đệm (padding) co giãn tự động theo kích thước màn hình
            final double horizontalPadding = width < 600
                ? 16.0
                : (width < 1024 ? 24.0 : 32.0);

            return RefreshIndicator(
              onRefresh: () => controller.loadData(),
              color: AppTheme.primary,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  // 1. Thẻ thống kê tổng quan
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: (horizontalPadding - 16).clamp(0.0, 32.0),
                      ),
                      child: DocumentStatsOverview(controller: controller),
                    ),
                  ),

                  // 2. Thanh tìm kiếm
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: (horizontalPadding - 16).clamp(0.0, 32.0),
                      ),
                      child: DocumentSearchBar(controller: controller),
                    ),
                  ),

                  // 3. Thanh cuộn bộ lọc nhanh (Filter Chips)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: (horizontalPadding - 16).clamp(0.0, 32.0),
                      ),
                      child: DocumentFilterBar(controller: controller),
                    ),
                  ),

                  // 3.1. Banner thông tin "Gợi ý cho bạn" (Checklist 5: Recommendation System)
                  if (controller.sourceFilter == 'recommended')
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: horizontalPadding,
                          vertical: 6.0,
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFF3E5F5), Color(0xFFEDE7F6)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFCE93D8)),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.auto_awesome_rounded,
                                color: Color(0xFF8E24AA),
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Mục gợi ý cho bạn (Recommendation)',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF4A148C),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Đề xuất tài liệu theo thuật toán tương đồng Jaccard & lọc theo Tag/Môn học yêu thích của bạn.',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        color: Colors.purple.shade900.withValues(alpha: 0.85),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),



                  // 4. Thanh báo số lượng kết quả
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding,
                        vertical: 8.0,
                      ),
                      child: Row(
                        children: [
                          Text(
                            'Danh sách (${docs.length})',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const Spacer(),
                          if (controller.filter.isActive)
                            InkWell(
                              onTap: () => controller.resetFilter(),
                              borderRadius: BorderRadius.circular(6),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.filter_alt_off_rounded,
                                      size: 14,
                                      color: AppTheme.primary,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Đặt lại bộ lọc',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  // Thông báo lỗi dạng banner nếu có dữ liệu nhưng tải ngầm thất bại
                  if (controller.errorMessage != null && docs.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: horizontalPadding,
                          vertical: 8.0,
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFFCA5A5)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.warning_amber_rounded,
                                color: AppTheme.error,
                                size: 22,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  controller.errorMessage!,
                                  style: const TextStyle(
                                    color: AppTheme.error,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              IconButton(
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                icon: const Icon(
                                  Icons.refresh_rounded,
                                  size: 20,
                                  color: AppTheme.error,
                                ),
                                tooltip: 'Thử lại',
                                onPressed: () => controller.loadData(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  // BƯỚC 3: Xử lý Trạng thái UI (Loading, Error, Empty, hoặc hiển thị Danh sách/Lưới)
                  if (controller.isLoading && docs.isEmpty)
                    // 1. LoadingState: Hiển thị Shimmer Skeleton theo số cột responsive
                    SliverPadding(
                      padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding,
                        vertical: 8.0,
                      ),
                      sliver: SliverToBoxAdapter(
                        child: DocumentLoadingState(
                          crossAxisCount: crossAxisCount,
                          showSkeleton: true,
                        ),
                      ),
                    )
                  else if (controller.errorMessage != null && docs.isEmpty)
                    // 2. ErrorState: Hiển thị thông báo lỗi và nút Thử lại
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: DocumentErrorState(
                        errorMessage: controller.errorMessage!,
                        onRetry: () => controller.loadData(),
                      ),
                    )
                  else if (docs.isEmpty)
                    // 3. EmptyState: Hiển thị thông báo rỗng kèm nút Thêm tài liệu
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: DocumentEmptyState(
                        hasActiveFilter: controller.filter.isActive,
                        onAddDocument: () => DocumentFormModal.show(
                          context,
                          controller: controller,
                        ),
                        onResetFilter: () => controller.resetFilter(),
                      ),
                    )
                  else if (crossAxisCount == 1)
                    // Mobile (width < 600): Hiển thị dạng danh sách 1 cột (ListView/SliverList)
                    SliverPadding(
                      padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding,
                      ),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final doc = docs[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: DocumentCard(
                                document: doc,
                                controller: controller,
                                onTap: () => DocumentDetailModal.show(
                                  context,
                                  document: doc,
                                  controller: controller,
                                ),
                                onEdit: () => DocumentFormModal.show(
                                  context,
                                  controller: controller,
                                  document: doc,
                                ),
                                onDelete: () => _showDeleteDialog(
                                  context,
                                  controller,
                                  doc,
                                ),
                              ),
                            );
                          },
                          childCount: docs.length,
                        ),
                      ),
                    )
                  else
                    // Tablet & Web/Desktop (width >= 600): Hiển thị dạng GridView 2, 3 hoặc 4 cột
                    SliverPadding(
                      padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding,
                      ),
                      sliver: SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          mainAxisExtent: 275, // Chiều cao thẻ tối ưu chống tràn viền và hiển thị đầy đủ thông tin
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final doc = docs[index];
                            return DocumentCard(
                              document: doc,
                              controller: controller,
                              onTap: () => DocumentDetailModal.show(
                                context,
                                document: doc,
                                controller: controller,
                              ),
                              onEdit: () => DocumentFormModal.show(
                                context,
                                controller: controller,
                                document: doc,
                              ),
                              onDelete: () => _showDeleteDialog(
                                context,
                                controller,
                                doc,
                              ),
                            );
                          },
                          childCount: docs.length,
                        ),
                      ),
                    ),

                  // Khoảng trống đệm cuối trang cho FloatingActionButton
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 84),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => DocumentFormModal.show(
          context,
          controller: controller,
        ),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Thêm tài liệu'),
      ),
    );
  }
}



