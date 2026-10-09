import 'package:flutter/material.dart';
import '../../domain/entities/document.dart';
import '../../domain/entities/document_type.dart';
import '../../usecases/add_document_usecase.dart';
import '../../usecases/update_document_usecase.dart';
import '../controllers/document_controller.dart';
import '../theme/app_theme.dart';

/// Modal Bottom Sheet để Thêm mới hoặc Chỉnh sửa tài liệu học tập
/// Sử dụng phương thức nhập Liên kết tài liệu (URL / Google Drive / Dropbox / Web)
/// Dữ liệu được lưu trực tiếp vào collection 'documents' trên Cloud Firestore (field: fileUrlOrPath)
class DocumentFormModal extends StatefulWidget {
  final DocumentController controller;
  final Document? initialDocument;

  const DocumentFormModal({
    super.key,
    required this.controller,
    this.initialDocument,
  });

  static Future<void> show(
    BuildContext context, {
    required DocumentController controller,
    Document? document,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DocumentFormModal(
        controller: controller,
        initialDocument: document,
      ),
    );
  }

  @override
  State<DocumentFormModal> createState() => _DocumentFormModalState();
}

class _DocumentFormModalState extends State<DocumentFormModal> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleController;
  late final TextEditingController _subjectController;
  late final TextEditingController _descController;
  late final TextEditingController _fileController;
  late final TextEditingController _tagInputController;

  late DocumentType _selectedType;
  late bool _isFavorite;
  late List<String> _tags;

  bool get isEditing => widget.initialDocument != null;

  @override
  void initState() {
    super.initState();
    final doc = widget.initialDocument;

    _titleController = TextEditingController(text: doc?.title ?? '');
    _subjectController = TextEditingController(text: doc?.subject ?? '');
    _descController = TextEditingController(text: doc?.description ?? '');
    _fileController = TextEditingController(text: doc?.fileUrlOrPath ?? '');
    _tagInputController = TextEditingController();

    _selectedType = doc?.type ?? DocumentType.lecture;
    _isFavorite = doc?.isFavorite ?? false;
    _tags = List<String>.from(doc?.tags ?? []);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subjectController.dispose();
    _descController.dispose();
    _fileController.dispose();
    _tagInputController.dispose();
    super.dispose();
  }

  void _addTag(String rawTag) {
    final clean = rawTag.trim().replaceAll(',', '').replaceAll('#', '');
    if (clean.isNotEmpty && !_tags.contains(clean)) {
      setState(() {
        _tags.add(clean);
        _tagInputController.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // Tự động thêm tag còn trong ô nhập nếu người dùng chưa nhấn Enter
    if (_tagInputController.text.trim().isNotEmpty) {
      _addTag(_tagInputController.text);
    }

    final link = _fileController.text.trim();

    bool success;
    if (isEditing) {
      final params = UpdateDocumentParams(
        id: widget.initialDocument!.id,
        title: _titleController.text.trim(),
        subject: _subjectController.text.trim(),
        type: _selectedType,
        description: _descController.text.trim(),
        fileUrlOrPath: link,
        tags: _tags,
        isFavorite: _isFavorite,
      );
      success = await widget.controller.updateDocument(params);
    } else {
      final params = AddDocumentParams(
        title: _titleController.text.trim(),
        subject: _subjectController.text.trim(),
        type: _selectedType,
        description: _descController.text.trim(),
        fileUrlOrPath: link,
        tags: _tags,
        isFavorite: _isFavorite,
      );
      success = await widget.controller.addDocument(params);
    }

    if (mounted) {
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEditing
                  ? 'Đã cập nhật tài liệu thành công!'
                  : 'Đã thêm tài liệu mới thành công!',
            ),
            backgroundColor: AppTheme.secondary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.controller.errorMessage ?? 'Có lỗi xảy ra khi lưu tài liệu.'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final keyboardPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      padding: EdgeInsets.only(bottom: keyboardPadding),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle kéo
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isEditing ? 'Chỉnh sửa tài liệu' : 'Thêm tài liệu học tập',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                  splashRadius: 20,
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppTheme.border),

          // Nội dung Form cuộn
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Bộ chọn Loại tài liệu (Segmented Selector)
                    const Text(
                      'Loại tài liệu',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: DocumentType.values.map((type) {
                        final isSelected = _selectedType == type;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4.0),
                            child: InkWell(
                              onTap: () => setState(() => _selectedType = type),
                              borderRadius: BorderRadius.circular(12),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? type.badgeBackgroundColor
                                      : AppTheme.surfaceVariant,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected
                                        ? type.primaryColor
                                        : Colors.transparent,
                                    width: 1.5,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      type.icon,
                                      size: 18,
                                      color: isSelected
                                          ? type.primaryColor
                                          : AppTheme.textSecondary,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      type.displayName,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: isSelected
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        color: isSelected
                                            ? type.primaryColor
                                            : AppTheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 18),

                    // 2. Tiêu đề tài liệu
                    const Text(
                      'Tiêu đề tài liệu *',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        hintText: 'Ví dụ: Bài giảng Chương 3 - Cấu trúc cây',
                        prefixIcon: Icon(Icons.title_rounded, size: 20),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Vui lòng nhập tiêu đề tài liệu';
                        }
                        if (value.trim().length < 2) {
                          return 'Tiêu đề phải có tối thiểu 2 ký tự';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // 3. Môn học
                    const Text(
                      'Môn học *',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _subjectController,
                      decoration: const InputDecoration(
                        hintText: 'Ví dụ: Cấu trúc Dữ liệu & Giải thuật',
                        prefixIcon: Icon(Icons.school_rounded, size: 20),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Vui lòng nhập tên môn học';
                        }
                        return null;
                      },
                    ),
                    // Gợi ý môn học hiện có
                    if (widget.controller.subjects.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        children: widget.controller.subjects.take(4).map((sub) {
                          return ActionChip(
                            label: Text(sub, style: const TextStyle(fontSize: 11)),
                            padding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                            onPressed: () {
                              _subjectController.text = sub;
                            },
                          );
                        }).toList(),
                      ),
                    ],
                    const SizedBox(height: 16),

                    // 4. Liên kết tài liệu (URL / Google Drive / Web)
                    const Row(
                      children: [
                        Icon(Icons.link_rounded, size: 18, color: AppTheme.primary),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Liên kết tài liệu (URL / Google Drive / Web) *',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _fileController,
                      keyboardType: TextInputType.url,
                      decoration: InputDecoration(
                        hintText: 'https://drive.google.com/... hoặc link tài liệu',
                        prefixIcon: const Icon(Icons.insert_link_rounded, size: 20),
                        suffixIcon: ValueListenableBuilder<TextEditingValue>(
                          valueListenable: _fileController,
                          builder: (context, value, _) {
                            if (value.text.isEmpty) return const SizedBox.shrink();
                            return IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              tooltip: 'Xóa link',
                              onPressed: () => _fileController.clear(),
                            );
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Vui lòng nhập đường liên kết tài liệu (URL / Drive / Web)';
                        }
                        final trimmed = value.trim();
                        final uri = Uri.tryParse(trimmed);
                        final isValidUrl = uri != null &&
                            (uri.isScheme('http') || uri.isScheme('https')) &&
                            uri.hasAuthority;
                        if (!isValidUrl) {
                          return 'Đường link không hợp lệ (cần bắt đầu bằng http:// hoặc https://)';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppTheme.border.withOpacity(0.6),
                        ),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline_rounded, size: 15, color: AppTheme.primary),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Dán link Google Drive, Docs, Dropbox, OneDrive hoặc PDF online. Đường link sẽ được lưu trực tiếp vào trường fileUrlOrPath trong Firestore và có thể bấm mở trực tiếp.',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: AppTheme.textSecondary,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 5. Mô tả / Ghi chú nội dung
                    const Text(
                      'Mô tả / Ghi chú nội dung',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _descController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: 'Tóm tắt nội dung chính hoặc lưu ý ôn tập...',
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 6. Thẻ Tags
                    const Text(
                      'Thẻ từ khóa (Tags)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _tagInputController,
                            decoration: const InputDecoration(
                              hintText: 'Nhập thẻ (e.g. Flutter, ThiCuoiKy)...',
                              prefixIcon: Icon(Icons.tag_rounded, size: 20),
                            ),
                            onFieldSubmitted: _addTag,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filled(
                          onPressed: () {
                            if (_tagInputController.text.isNotEmpty) {
                              _addTag(_tagInputController.text);
                            }
                          },
                          icon: const Icon(Icons.add, size: 20),
                        ),
                      ],
                    ),
                    if (_tags.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: _tags.map((t) {
                          return Chip(
                            label: Text(t, style: const TextStyle(fontSize: 12)),
                            deleteIcon: const Icon(Icons.close, size: 14),
                            onDeleted: () => _removeTag(t),
                            visualDensity: VisualDensity.compact,
                          );
                        }).toList(),
                      ),
                    ],
                    const SizedBox(height: 16),

                    // 7. Đánh dấu yêu thích
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Đánh dấu tài liệu yêu thích',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      value: _isFavorite,
                      activeColor: Colors.amber,
                      onChanged: (val) => setState(() => _isFavorite = val),
                    ),
                    const SizedBox(height: 20),

                    // 8. Nút Submit
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: widget.controller.isLoading ? null : _submit,
                        child: widget.controller.isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                isEditing ? 'Lưu cập nhật' : 'Thêm tài liệu',
                                style: const TextStyle(fontSize: 16),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
