import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/borrow_request.dart';
import '../../domain/entities/document.dart';
import '../controllers/document_controller.dart';
import '../theme/app_theme.dart';

/// Nút mượn/trả hiển thị cho người không phải chủ sở hữu tài liệu.
class BorrowRequestAction extends StatefulWidget {
  final Document document;
  final DocumentController controller;

  const BorrowRequestAction({
    super.key,
    required this.document,
    required this.controller,
  });

  @override
  State<BorrowRequestAction> createState() => _BorrowRequestActionState();
}

class _BorrowRequestActionState extends State<BorrowRequestAction> {
  BorrowRequest? _request;
  bool _isLoading = true;
  bool _isBusy = false;

  @override
  void initState() {
    super.initState();
    _loadRequest();
  }

  Future<void> _loadRequest({bool showLoading = false}) async {
    if (showLoading && mounted) {
      setState(() => _isLoading = true);
    }
    final request =
        await widget.controller.getMyBorrowRequest(widget.document.id);
    if (!mounted) return;
    setState(() {
      _request = request;
      _isLoading = false;
    });
  }

  Future<void> _requestBorrow() async {
    setState(() => _isBusy = true);
    final success = await widget.controller.requestBorrow(widget.document.id);
    if (!mounted) return;

    if (!success) {
      setState(() => _isBusy = false);
      _showMessage(
        widget.controller.errorMessage ?? 'Không thể gửi yêu cầu mượn.',
        isError: true,
      );
      return;
    }

    final request =
        await widget.controller.getMyBorrowRequest(widget.document.id);
    if (!mounted) return;
    setState(() {
      _request = request;
      _isBusy = false;
      _isLoading = false;
    });
    _showMessage('Đã gửi yêu cầu mượn đến chủ sở hữu.');
  }

  Future<void> _markReturned() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xác nhận trả tài liệu'),
        content: Text(
          'Bạn xác nhận đã trả tài liệu "${widget.document.title}" cho chủ sở hữu?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Chưa trả'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Đã trả'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final request = _request;
    if (request == null) return;
    setState(() => _isBusy = true);
    final success =
        await widget.controller.markBorrowRequestReturned(request.id);
    if (!mounted) return;

    if (!success) {
      setState(() => _isBusy = false);
      _showMessage(
        widget.controller.errorMessage ?? 'Không thể cập nhật trạng thái trả.',
        isError: true,
      );
      return;
    }

    final latest =
        await widget.controller.getMyBorrowRequest(widget.document.id);
    if (!mounted) return;
    setState(() {
      _request = latest;
      _isBusy = false;
      _isLoading = false;
    });
    _showMessage('Đã ghi nhận trạng thái trả tài liệu.');
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return OutlinedButton.icon(
        onPressed: null,
        icon: const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        label: const Text('Đang kiểm tra yêu cầu mượn...'),
      );
    }

    final request = _request;
    if (request?.isPending == true) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: null,
                  icon: const Icon(Icons.hourglass_top_rounded),
                  label: const Text('Đang chờ chủ sở hữu duyệt'),
                ),
              ),
              IconButton(
                tooltip: 'Kiểm tra trạng thái mới',
                onPressed: _isBusy ? null : () => _loadRequest(showLoading: true),
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Đã gửi ngày ${DateFormat('dd/MM/yyyy HH:mm').format(request!.requestedAt.toLocal())}.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
          ),
        ],
      );
    }

    if (request?.isApproved == true) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _isBusy ? null : _markReturned,
          icon: _isBusy
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.assignment_turned_in_outlined),
          label: Text(_isBusy ? 'Đang cập nhật...' : 'Xác nhận đã trả tài liệu'),
        ),
      );
    }

    final canRequestAgain =
        request?.isRejected == true || request?.isReturned == true;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (canRequestAgain) ...[
          Text(
            'Yêu cầu gần nhất: ${request!.statusLabel.toLowerCase()}.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
        ],
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _isBusy ? null : _requestBorrow,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primary,
              side: const BorderSide(color: AppTheme.primary),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: _isBusy
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.menu_book_rounded, size: 18),
            label: Text(
              _isBusy
                  ? 'Đang gửi yêu cầu...'
                  : canRequestAgain
                      ? 'Yêu cầu mượn lại'
                      : 'Yêu cầu mượn',
            ),
          ),
        ),
      ],
    );
  }
}
