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
import '../widgets/document_stats_overview.dart';

/// Màn hình chính của Ứng dụng Quản lý Tài liệu Học tập (Cashew Style)
class DocumentHomeScreen extends StatelessWidget {
  const DocumentHomeScreen({super.key});

  void _showDeleteDialog(BuildContext context, DocumentController controller, Document doc) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Xác nhận xóa tài liệu'),
        content: Text('Bạn có chắc chắn muốn xóa "${doc.title}" không?'),
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
            // Logo ứng dụng kích thước lớn với hiệu ứng gradient nổi bật
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primary, Color(0xFF5C6BC0)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withOpacity(0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.auto_stories_rounded,
                color: Colors.white,
                size: 30,
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
                        (user.email != null ? user.email!.split('@').first : 'Khách');
                    return PopupMenuButton<String>(
                      tooltip: 'Tài khoản: $displayName',
                      icon: CircleAvatar(
                        radius: 16,
                        backgroundColor: AppTheme.primaryLight,
                        backgroundImage:
                            user.photoURL != null ? NetworkImage(user.photoURL!) : null,
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
                            ],
                          ),
                        ),
                        const PopupMenuDivider(),
                        const PopupMenuItem(
                          value: 'logout',
                          child: Row(
                            children: [
                              Icon(Icons.logout_rounded, color: AppTheme.error, size: 20),
                              SizedBox(width: 8),
                              Text('Đăng xuất', style: TextStyle(color: AppTheme.error)),
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
      body: RefreshIndicator(
        onRefresh: () => controller.loadData(),
        color: AppTheme.primary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            // 1. Thẻ thống kê tổng quan
            SliverToBoxAdapter(
              child: DocumentStatsOverview(controller: controller),
            ),

            // 2. Thanh tìm kiếm
            SliverToBoxAdapter(
              child: DocumentSearchBar(controller: controller),
            ),

            // 3. Thanh cuộn bộ lọc nhanh (Filter Chips)
            SliverToBoxAdapter(
              child: DocumentFilterBar(controller: controller),
            ),

            // 4. Thanh báo số lượng kết quả
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
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
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          child: Row(
                            children: [
                              Icon(Icons.filter_alt_off_rounded, size: 14, color: AppTheme.primary),
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

            // Thông báo lỗi nếu có (ví dụ: Permission Denied từ Firestore)
            if (controller.errorMessage != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
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

            // 5. Nội dung: Loading / Empty State / Danh sách tài liệu
            if (controller.isLoading && docs.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: CircularProgressIndicator(color: AppTheme.primary),
                ),
              )
            else if (docs.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptyStateWidget(
                  hasActiveFilter: controller.filter.isActive,
                  onResetFilter: () => controller.resetFilter(),
                  onAddDocument: () => DocumentFormModal.show(
                    context,
                    controller: controller,
                  ),
                ),
              )
            else
              SliverList(
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
                      onDelete: () => _showDeleteDialog(context, controller, doc),
                    );
                  },
                  childCount: docs.length,
                ),
              ),

            // Khoảng trống đệm cuối trang cho FloatingActionButton
            const SliverToBoxAdapter(
              child: SizedBox(height: 80),
            ),
          ],
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

/// Widget hiển thị trạng thái rỗng khi chưa có tài liệu hoặc tìm kiếm không thấy
class _EmptyStateWidget extends StatelessWidget {
  final bool hasActiveFilter;
  final VoidCallback onResetFilter;
  final VoidCallback onAddDocument;

  const _EmptyStateWidget({
    required this.hasActiveFilter,
    required this.onResetFilter,
    required this.onAddDocument,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: AppTheme.surfaceVariant,
                shape: BoxShape.circle,
              ),
              child: Icon(
                hasActiveFilter
                    ? Icons.search_off_rounded
                    : Icons.folder_open_rounded,
                size: 54,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              hasActiveFilter
                  ? 'Không tìm thấy tài liệu phù hợp'
                  : 'Chưa có tài liệu học tập nào',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hasActiveFilter
                  ? 'Thử thay đổi từ khóa tìm kiếm hoặc chọn lại các bộ lọc bên trên.'
                  : 'Bắt đầu thêm bài giảng, bài tập hoặc tài liệu tham khảo đầu tiên của bạn!',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13.5,
                color: AppTheme.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            if (hasActiveFilter)
              OutlinedButton.icon(
                onPressed: onResetFilter,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Xóa bộ lọc'),
              )
            else
              ElevatedButton.icon(
                onPressed: onAddDocument,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Thêm tài liệu ngay'),
              ),
          ],
        ),
      ),
    );
  }
}
