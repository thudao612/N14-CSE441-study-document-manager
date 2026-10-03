import 'package:flutter/material.dart';
import '../controllers/document_controller.dart';
import '../theme/app_theme.dart';

/// Thanh tìm kiếm tài liệu chuẩn UX với tính năng xóa nhanh
class DocumentSearchBar extends StatefulWidget {
  final DocumentController controller;

  const DocumentSearchBar({super.key, required this.controller});

  @override
  State<DocumentSearchBar> createState() => _DocumentSearchBarState();
}

class _DocumentSearchBarState extends State<DocumentSearchBar> {
  late final TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(
      text: widget.controller.filter.searchQuery ?? '',
    );
  }

  @override
  void didUpdateWidget(covariant DocumentSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    final currentQuery = widget.controller.filter.searchQuery ?? '';
    if (_textController.text != currentQuery) {
      _textController.text = currentQuery;
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasText = _textController.text.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: _textController,
          onChanged: (val) {
            setState(() {});
            widget.controller.setSearchQuery(val);
          },
          decoration: InputDecoration(
            hintText: 'Tìm theo tiêu đề, môn học, thẻ, từ khóa...',
            hintStyle: const TextStyle(
              fontSize: 13.5,
              color: AppTheme.textSecondary,
            ),
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: AppTheme.primary,
              size: 22,
            ),
            suffixIcon: hasText
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded, size: 20),
                    color: AppTheme.textSecondary,
                    onPressed: () {
                      _textController.clear();
                      setState(() {});
                      widget.controller.setSearchQuery('');
                    },
                  )
                : null,
            filled: false,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
          ),
        ),
      ),
    );
  }
}
