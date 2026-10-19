import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// ============================================================================
/// BƯỚC 2: WIDGET WRAPPER CHO FORM & DIALOG CHỐNG TRÀN VIỀN (RENDERFLEX OVERFLOW)
/// Hỗ trợ Responsive đa nền tảng (Web, Desktop, Tablet, Mobile)
/// ============================================================================

/// Một Dialog chuẩn được tối ưu hóa cho màn hình Web & Mobile:
/// - Tự động căn giữa màn hình (Center / Alignment.center)
/// - Giới hạn chiều rộng tối đa (mặc định maxWidth = 600)
/// - Bọc nội dung trong SingleChildScrollView chống lỗi RenderFlex overflowed khi bật bàn phím
class ResponsiveDialog extends StatelessWidget {
  /// Tiêu đề hiển thị ở đầu dialog
  final String title;

  /// Icon đại diện ở tiêu đề (tùy chọn)
  final IconData? titleIcon;

  /// Nội dung chính (Form, Danh sách, Chi tiết...)
  final Widget content;

  /// Các nút hành động ở chân dialog (Hủy, Lưu, Xác nhận...)
  final List<Widget>? actions;

  /// Chiều rộng tối đa (Mặc định: 600.0)
  final double maxWidth;

  /// Chiều cao tối đa (Mặc định: 90% chiều cao màn hình)
  final double? maxHeight;

  /// Padding bên trong nội dung
  final EdgeInsetsGeometry contentPadding;

  /// Nút đóng 'X' ở góc phải tiêu đề
  final bool showCloseButton;

  const ResponsiveDialog({
    super.key,
    required this.title,
    required this.content,
    this.titleIcon,
    this.actions,
    this.maxWidth = 600.0,
    this.maxHeight,
    this.contentPadding = const EdgeInsets.all(20.0),
    this.showCloseButton = true,
  });

  /// Hàm tiện ích mở Dialog căn giữa một cách nhanh chóng và an toàn
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    bool barrierDismissible = true,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (ctx) => child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final calculatedMaxHeight = maxHeight ?? (mediaQuery.size.height * 0.9);

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth,
          maxHeight: calculatedMaxHeight,
        ),
        child: Dialog(
          backgroundColor: AppTheme.surface,
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24.0),
          ),
          clipBehavior: Clip.antiAlias,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16.0,
            vertical: 24.0,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Header Dialog
              Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: AppTheme.border, width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    if (titleIcon != null) ...[
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(titleIcon, size: 20, color: AppTheme.primary),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    if (showCloseButton)
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 22),
                        color: AppTheme.textSecondary,
                        tooltip: 'Đóng',
                        onPressed: () => Navigator.of(context).pop(),
                        splashRadius: 20,
                      ),
                  ],
                ),
              ),

              // 2. Nội dung chính bọc trong SingleChildScrollView chống RenderFlex overflowed
              Flexible(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: contentPadding,
                  child: content,
                ),
              ),

              // 3. Actions Footer (nếu có)
              if (actions != null && actions!.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20.0,
                    vertical: 14.0,
                  ),
                  decoration: const BoxDecoration(
                    color: AppTheme.surfaceVariant,
                    border: Border(
                      top: BorderSide(color: AppTheme.border, width: 1),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: actions!
                        .map(
                          (action) => Padding(
                            padding: const EdgeInsets.only(left: 10.0),
                            child: action,
                          ),
                        )
                        .toList(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tiện ích bọc AlertDialog chuẩn chống tràn viền
class ResponsiveAlertDialog extends StatelessWidget {
  final String title;
  final Widget content;
  final List<Widget> actions;
  final double maxWidth;

  const ResponsiveAlertDialog({
    super.key,
    required this.title,
    required this.content,
    required this.actions,
    this.maxWidth = 500.0,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: content,
          ),
          actions: actions,
        ),
      ),
    );
  }
}
