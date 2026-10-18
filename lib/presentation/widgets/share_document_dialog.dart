import 'package:flutter/material.dart';
import '../../domain/entities/document.dart';
import '../../domain/entities/document_permission.dart';
import '../controllers/document_controller.dart';
import '../theme/app_theme.dart';

/// Hộp thoại quản lý chia sẻ tài liệu và phân quyền (Viewer / Editor)
class ShareDocumentDialog extends StatefulWidget {
  final Document document;
  final DocumentController controller;

  const ShareDocumentDialog({
    super.key,
    required this.document,
    required this.controller,
  });

  static Future<void> show(
    BuildContext context, {
    required Document document,
    required DocumentController controller,
  }) {
    return showDialog(
      context: context,
      builder: (context) => ShareDocumentDialog(
        document: document,
        controller: controller,
      ),
    );
  }

  @override
  State<ShareDocumentDialog> createState() => _ShareDocumentDialogState();
}

class _ShareDocumentDialogState extends State<ShareDocumentDialog> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _selectedRole = 'viewer'; // 'viewer' | 'editor'
  bool _isSharing = false;
  String? _statusMessage;
  bool _isError = false;

  late Future<List<DocumentPermission>> _permissionsFuture;

  @override
  void initState() {
    super.initState();
    _loadPermissions();
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _loadPermissions() {
    setState(() {
      _permissionsFuture =
          widget.controller.getDocumentPermissions(widget.document.id);
    });
  }

  Future<void> _handleShare() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSharing = true;
      _statusMessage = null;
    });

    final email = _emailController.text.trim();
    final success = await widget.controller.shareDocument(
      documentId: widget.document.id,
      targetEmail: email,
      role: _selectedRole,
    );

    if (mounted) {
      setState(() {
        _isSharing = false;
        if (success) {
          _isError = false;
          _statusMessage =
              'Đã chia sẻ quyền ${_selectedRole == "editor" ? "Biên tập" : "Chỉ xem"} cho $email';
          _emailController.clear();
          _loadPermissions();
        } else {
          _isError = true;
          _statusMessage = widget.controller.errorMessage ??
              'Không thể chia sẻ tài liệu.';
        }
      });
    }
  }

  Future<void> _handleRevoke(DocumentPermission permission) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận thu hồi quyền'),
        content: Text(
          'Bạn có chắc chắn muốn thu hồi quyền truy cập của "${permission.userEmail}" không?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Thu hồi', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await widget.controller.revokePermission(
        documentId: widget.document.id,
        targetUserId: permission.userId,
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã thu hồi quyền của ${permission.userEmail}'),
              backgroundColor: AppTheme.secondary,
              behavior: SnackBarBehavior.floating,
            ),
          );
          _loadPermissions();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.controller.errorMessage ?? 'Lỗi khi thu hồi quyền.'),
              backgroundColor: AppTheme.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 620),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.share_rounded,
                        color: AppTheme.primary, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Chia sẻ tài liệu',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          widget.document.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1, color: AppTheme.border),
              const SizedBox(height: 16),

              // Form nhập email & chọn quyền
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Thêm người nhận qua Email',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        hintText: 'Nhập email sinh viên/đồng nghiệp...',
                        prefixIcon: Icon(Icons.email_outlined, size: 20),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Vui lòng nhập địa chỉ email.';
                        }
                        if (!val.contains('@') || !val.contains('.')) {
                          return 'Email không hợp lệ.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    // Chọn quyền: Viewer / Editor
                    Row(
                      children: [
                        const Text(
                          'Vai trò:',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        ChoiceChip(
                          label: const Text('Chỉ xem (Viewer)'),
                          selected: _selectedRole == 'viewer',
                          avatar: const Icon(Icons.visibility_outlined, size: 16),
                          onSelected: (selected) {
                            if (selected) setState(() => _selectedRole = 'viewer');
                          },
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('Biên tập (Editor)'),
                          selected: _selectedRole == 'editor',
                          avatar: const Icon(Icons.edit_outlined, size: 16),
                          onSelected: (selected) {
                            if (selected) setState(() => _selectedRole = 'editor');
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Nút Chia sẻ
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: _isSharing
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.person_add_alt_1_rounded, size: 18),
                        label: Text(_isSharing ? 'Đang cấp quyền...' : 'Cấp quyền chia sẻ'),
                        onPressed: _isSharing ? null : _handleShare,
                      ),
                    ),
                  ],
                ),
              ),

              // Thông báo trạng thái
              if (_statusMessage != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _isError
                        ? AppTheme.error.withOpacity(0.1)
                        : AppTheme.secondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isError
                            ? Icons.error_outline_rounded
                            : Icons.check_circle_outline_rounded,
                        size: 16,
                        color: _isError ? AppTheme.error : AppTheme.secondary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _statusMessage!,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _isError ? AppTheme.error : AppTheme.secondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),
              const Text(
                'Danh sách người đã được chia sẻ',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),

              // Danh sách quyền đã cấp
              Expanded(
                child: FutureBuilder<List<DocumentPermission>>(
                  future: _permissionsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final permissions = snapshot.data ?? [];
                    if (permissions.isEmpty) {
                      return Center(
                        child: Text(
                          'Tài liệu này hiện chỉ có bạn có quyền truy cập.',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary.withOpacity(0.8),
                          ),
                        ),
                      );
                    }

                    return ListView.separated(
                      shrinkWrap: true,
                      itemCount: permissions.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, color: AppTheme.border),
                      itemBuilder: (context, index) {
                        final perm = permissions[index];
                        final isEditor = perm.role == 'editor';

                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            radius: 16,
                            backgroundColor: isEditor
                                ? AppTheme.mintAccent.withOpacity(0.2)
                                : AppTheme.primaryLight,
                            child: Icon(
                              isEditor ? Icons.edit_rounded : Icons.visibility_rounded,
                              size: 16,
                              color: isEditor ? AppTheme.mintAccent : AppTheme.primary,
                            ),
                          ),
                          title: Text(
                            perm.userEmail.isNotEmpty ? perm.userEmail : perm.userId,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            isEditor ? 'Biên tập (Editor)' : 'Chỉ xem (Viewer)',
                            style: TextStyle(
                              fontSize: 11,
                              color: isEditor
                                  ? const Color(0xFF00796B)
                                  : AppTheme.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.remove_circle_outline_rounded,
                              color: AppTheme.error,
                              size: 20,
                            ),
                            tooltip: 'Thu hồi quyền',
                            onPressed: () => _handleRevoke(perm),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
