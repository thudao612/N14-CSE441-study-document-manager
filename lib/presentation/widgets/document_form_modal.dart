import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../domain/entities/document.dart';
import '../../domain/entities/document_type.dart';
import '../../usecases/add_document_usecase.dart';
import '../../usecases/update_document_usecase.dart';
import '../controllers/document_controller.dart';
import '../theme/app_theme.dart';
import '../utils/file_helper.dart';

/// Modal Bottom Sheet để Thêm mới hoặc Chỉnh sửa tài liệu học tập
/// Hỗ trợ chọn tệp trực tiếp từ máy (PDF, Word) hoặc liên kết Web
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

  // 0: Chọn tệp máy (PDF / Word), 1: Nhập liên kết web URL
  int _attachmentMode = 0;
  String? _pickedFileName;
  int? _pickedFileSize;
  Uint8List? _pickedFileBytes;

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

    final existingFile = doc?.fileUrlOrPath ?? '';
    if (existingFile.isNotEmpty) {
      if (FileHelper.isWebLink(existingFile)) {
        _attachmentMode = 1;
      } else {
        _attachmentMode = 0;
        _pickedFileName = FileHelper.getFileName(existingFile);
      }
    }
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

  /// Mở cửa sổ chọn tệp PDF hoặc Word từ thiết bị
  Future<void> _pickDocumentFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final platformFile = result.files.first;
        final bytes = platformFile.bytes;

        if (bytes == null || bytes.isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Không đọc được nội dung tệp đã chọn.'),
              ),
            );
          }
          return;
        }
        final path =
            kIsWeb ? platformFile.name : platformFile.path ?? platformFile.name;

        setState(() {
          _fileController.text = path;
          _pickedFileName = platformFile.name;
          _pickedFileSize = platformFile.size;
          _pickedFileBytes = bytes;
          _pickedFileBytes = platformFile.bytes;

          // Gợi ý tiêu đề tài liệu tự động từ tên tệp nếu người dùng chưa nhập
          if (_titleController.text.trim().isEmpty) {
            final cleanName = platformFile.name
                .replaceAll(RegExp(r'\.[a-zA-Z0-9]+$'), '')
                .replaceAll('_', ' ')
                .replaceAll('-', ' ');
            _titleController.text = cleanName;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi chọn tệp: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  void _clearSelectedFile() {
    setState(() {
      _fileController.clear();
      _pickedFileName = null;
      _pickedFileSize = null;
      _pickedFileBytes = null;
    });
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

    var attachmentUrl = _fileController.text.trim();

    final bytes = _pickedFileBytes;

    if (bytes != null && widget.controller.canUploadDocumentFile) {
      final fileName = _pickedFileName;

      if (fileName == null || fileName.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tên tệp không hợp lệ.'),
          ),
        );
        return;
      }

      try {
        attachmentUrl = await widget.controller.uploadDocumentFile(
          fileName: fileName,
          bytes: bytes,
        );

        if (!mounted) return;

        _fileController.text = attachmentUrl;
        _pickedFileBytes = null;
      } catch (e) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể tải tệp lên: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
        return;
      }
    }
    bool success;
    if (isEditing) {
      final params = UpdateDocumentParams(
        id: widget.initialDocument!.id,
        title: _titleController.text,
        subject: _subjectController.text,
        type: _selectedType,
        description: _descController.text,
        fileUrlOrPath: attachmentUrl,
        tags: _tags,
        isFavorite: _isFavorite,
      );
      success = await widget.controller.updateDocument(params);
    } else {
      final params = AddDocumentParams(
        title: _titleController.text,
        subject: _subjectController.text,
        type: _selectedType,
        description: _descController.text,
        fileUrlOrPath: attachmentUrl,
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
            content: Text(widget.controller.errorMessage ?? 'Có lỗi xảy ra.'),
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
    final hasAttachedFile = _fileController.text.trim().isNotEmpty;

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
                    // Bộ chọn Loại tài liệu (Segmented Selector)
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
                            padding:
                                const EdgeInsets.symmetric(horizontal: 4.0),
                            child: InkWell(
                              onTap: () => setState(() => _selectedType = type),
                              borderRadius: BorderRadius.circular(12),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
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

                    // Tiêu đề
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

                    // Môn học
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
                            label:
                                Text(sub, style: const TextStyle(fontSize: 11)),
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

                    // --- KHỐI ĐÍNH KÈM TỆP (PDF / WORD / LIÊN KẾT) ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Tệp đính kèm học tập',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        // Nút chuyển chế độ: Tệp máy hoặc Link
                        Row(
                          children: [
                            _ModeTabButton(
                              icon: Icons.upload_file_rounded,
                              label: 'Tệp PDF/Word',
                              isSelected: _attachmentMode == 0,
                              onTap: () => setState(() => _attachmentMode = 0),
                            ),
                            const SizedBox(width: 6),
                            _ModeTabButton(
                              icon: Icons.link_rounded,
                              label: 'Link Web',
                              isSelected: _attachmentMode == 1,
                              onTap: () => setState(() => _attachmentMode = 1),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Chế độ 0: Đính kèm tệp PDF hoặc Word từ máy
                    if (_attachmentMode == 0) ...[
                      if (!hasAttachedFile) ...[
                        // Khung chọn tệp phong cách Cashew
                        InkWell(
                          onTap: _pickDocumentFile,
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              vertical: 20,
                              horizontal: 16,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceVariant,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppTheme.mintAccent.withOpacity(0.5),
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFEE2E2),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(
                                        Icons.picture_as_pdf_rounded,
                                        color: Color(0xFFDC2626),
                                        size: 26,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFDBEAFE),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(
                                        Icons.description_rounded,
                                        color: Color(0xFF1D4ED8),
                                        size: 26,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'Bấm để chọn tệp PDF hoặc Word từ máy',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Hỗ trợ tệp: .pdf, .docx, .doc, .txt',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ] else ...[
                        // Thẻ hiển thị tệp đã chọn
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color:
                                FileHelper.getFileBgColor(_fileController.text),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color:
                                  FileHelper.getFileColor(_fileController.text)
                                      .withOpacity(0.4),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  FileHelper.getFileIcon(_fileController.text),
                                  color: FileHelper.getFileColor(
                                      _fileController.text),
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _pickedFileName ??
                                          FileHelper.getFileName(
                                              _fileController.text),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 1),
                                          decoration: BoxDecoration(
                                            color: FileHelper.getFileColor(
                                                _fileController.text),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            FileHelper.getFileBadgeLabel(
                                                _fileController.text),
                                            style: const TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                        if (_pickedFileSize != null) ...[
                                          const SizedBox(width: 6),
                                          Text(
                                            FileHelper.formatBytes(
                                                _pickedFileSize!),
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: AppTheme.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.sync_rounded,
                                    color: AppTheme.primary),
                                tooltip: 'Đổi tệp khác',
                                onPressed: _pickDocumentFile,
                              ),
                              IconButton(
                                icon: const Icon(Icons.close_rounded,
                                    color: AppTheme.error),
                                tooltip: 'Xóa tệp',
                                onPressed: _clearSelectedFile,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ] else ...[
                      // Chế độ 1: Nhập liên kết Web URL
                      TextFormField(
                        controller: _fileController,
                        decoration: const InputDecoration(
                          hintText: 'https://example.com/tai-lieu-hoc-tap',
                          prefixIcon: Icon(Icons.link_rounded, size: 20),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),

                    // Mô tả tóm tắt
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

                    // Thẻ Tags
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
                            label:
                                Text(t, style: const TextStyle(fontSize: 12)),
                            deleteIcon: const Icon(Icons.close, size: 14),
                            onDeleted: () => _removeTag(t),
                            visualDensity: VisualDensity.compact,
                          );
                        }).toList(),
                      ),
                    ],
                    const SizedBox(height: 16),

                    // Đánh dấu yêu thích
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

                    // Nút Submit
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

/// Nút chuyển đổi chế độ đính kèm (Tệp máy / Web link)
class _ModeTabButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeTabButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : AppTheme.surfaceVariant,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? Colors.white : AppTheme.textSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
