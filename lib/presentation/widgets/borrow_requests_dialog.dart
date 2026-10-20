import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/borrow_request.dart';
import '../../domain/entities/document.dart';
import '../controllers/document_controller.dart';
import '../theme/app_theme.dart';

/// Popup để chủ sở hữu xem và duyệt/từ chối yêu cầu mượn tài liệu.
class BorrowRequestsDialog extends StatefulWidget {
  final Document document;
  final DocumentController controller;

  const BorrowRequestsDialog({
    super.key,
    required this.document,
    required this.controller,
  });

  static Future<void> show(
    BuildContext context, {
    required Document document,
    required DocumentController controller,
  }) {
    return showDialog<void>(
      context: context,
      builder: (_) => BorrowRequestsDialog(
        document: document,
        controller: controller,
      ),
    );
  }

  @override
  State<BorrowRequestsDialog> createState() => _BorrowRequestsDialogState();
}

class _BorrowRequestsDialogState extends State<BorrowRequestsDialog> {
  late Future<List<BorrowRequest>> _requestsFuture;
  final Set<String> _busyRequestIds = <String>{};

  @override
  void initState() {
    super.initState();
    _requestsFuture = widget.controller.getBorrowRequestsForDocument(
      widget.document.id,
    );
  }

  void _reload() {
    setState(() {
      _requestsFuture = widget.controller.getBorrowRequestsForDocument(
        widget.document.id,
      );
    });
  }

  Future<void> _review(BorrowRequest request, String status) async {
    setState(() => _busyRequestIds.add(request.id));
    final success = await widget.controller.reviewBorrowRequest(
      requestId: request.id,
      status: status,
    );
    if (!mounted) return;

    setState(() => _busyRequestIds.remove(request.id));
    if (!success) {
      _showMessage(
        widget.controller.errorMessage ?? 'Không thể xử lý yêu cầu mượn.',
        isError: true,
      );
      return;
    }

    _reload();
    _showMessage(
      status == BorrowRequest.approved
          ? 'Đã đồng ý yêu cầu mượn.'
          : 'Đã từ chối yêu cầu mượn.',
    );
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppTheme.error : AppTheme.secondary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Color _statusColor(BorrowRequest request) {
    if (request.isApproved || request.isReturned) return AppTheme.secondary;
    if (request.isRejected) return AppTheme.error;
    return AppTheme.accent;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 620),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.library_books_outlined,
                      color: AppTheme.primary, size: 26),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Yêu cầu mượn tài liệu',
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
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Tải lại',
                    onPressed: _reload,
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                  IconButton(
                    tooltip: 'Đóng',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const Divider(height: 24, color: AppTheme.border),
              Expanded(
                child: FutureBuilder<List<BorrowRequest>>(
                  future: _requestsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final requests = snapshot.data ?? const <BorrowRequest>[];
                    if (requests.isEmpty) {
                      final error = widget.controller.errorMessage;
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                error == null
                                    ? Icons.inbox_outlined
                                    : Icons.error_outline_rounded,
                                size: 36,
                                color: AppTheme.textSecondary,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                error ?? 'Chưa có yêu cầu mượn nào cho tài liệu này.',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return ListView.separated(
                      itemCount: requests.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 16, color: AppTheme.border),
                      itemBuilder: (context, index) {
                        final request = requests[index];
                        final displayName = request.requesterName.trim().isNotEmpty
                            ? request.requesterName.trim()
                            : request.requesterEmail.trim().isNotEmpty
                                ? request.requesterEmail.trim()
                                : request.requesterId;
                        final isBusy = _busyRequestIds.contains(request.id);

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    backgroundColor: AppTheme.primaryLight,
                                    child: const Icon(
                                      Icons.person_outline_rounded,
                                      color: AppTheme.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
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
                                        if (request.requesterEmail.isNotEmpty &&
                                            request.requesterEmail != displayName)
                                          Text(
                                            request.requesterEmail,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: AppTheme.textSecondary,
                                            ),
                                          ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Gửi lúc ${DateFormat('dd/MM/yyyy HH:mm').format(request.requestedAt.toLocal())}',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: AppTheme.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _statusColor(request).withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        request.statusLabel,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: _statusColor(request),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (request.isPending) ...[
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: isBusy
                                            ? null
                                            : () => _review(
                                                  request,
                                                  BorrowRequest.rejected,
                                                ),
                                        icon: const Icon(Icons.close_rounded, size: 18),
                                        label: const Text('Từ chối'),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: AppTheme.error,
                                          side: const BorderSide(color: AppTheme.error),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: isBusy
                                            ? null
                                            : () => _review(
                                                  request,
                                                  BorrowRequest.approved,
                                                ),
                                        icon: isBusy
                                            ? const SizedBox(
                                                width: 15,
                                                height: 15,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: Colors.white,
                                                ),
                                              )
                                            : const Icon(Icons.check_rounded, size: 18),
                                        label: const Text('Đồng ý'),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              if (request.reviewedAt != null) ...[
                                const SizedBox(height: 5),
                                Text(
                                  'Xử lý lúc ${DateFormat('dd/MM/yyyy HH:mm').format(request.reviewedAt!.toLocal())}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                              if (request.returnedAt != null) ...[
                                const SizedBox(height: 3),
                                Text(
                                  'Trả lúc ${DateFormat('dd/MM/yyyy HH:mm').format(request.returnedAt!.toLocal())}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ],
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
