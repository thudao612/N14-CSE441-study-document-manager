import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../domain/entities/document.dart';
import '../../domain/entities/document_type.dart';
import '../../usecases/add_document_usecase.dart';
import '../../usecases/update_document_usecase.dart';
import '../controllers/document_controller.dart';
import '../theme/app_theme.dart';
import '../../services/location_search_service.dart';
import 'document_location_map.dart';

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
  late final TextEditingController _locationNameController;

  late DocumentType _selectedType;
  late bool _isFavorite;
  late List<String> _tags;
  double? _latitude;
  double? _longitude;
  int _selectedUploadMethod =
      0; // 0 = Dán liên kết (nhanh - 0s), 1 = Chọn tệp từ thiết bị

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
    _locationNameController =
        TextEditingController(text: doc?.locationName ?? '');

    _selectedType = doc?.type ?? DocumentType.lecture;
    _isFavorite = doc?.isFavorite ?? false;
    _tags = List<String>.from(doc?.tags ?? []);
    if (doc != null && doc.hasCoordinates) {
      _latitude = doc.latitude;
      _longitude = doc.longitude;
    }

    if (doc != null && doc.fileUrlOrPath.contains('/storage/v1/object/')) {
      _selectedUploadMethod = 1;
    } else {
      _selectedUploadMethod = 0;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subjectController.dispose();
    _descController.dispose();
    _fileController.dispose();
    _tagInputController.dispose();
    _locationNameController.dispose();
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

  Future<void> _pickLocation() async {
    final initialLocation = _latitude != null && _longitude != null
        ? LatLng(_latitude!, _longitude!)
        : null;
    final selection = await showModalBottomSheet<_SelectedLocation>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _LocationPickerSheet(
        initialLocation: initialLocation,
      ),
    );
    if (selection == null || !mounted) return;
    setState(() {
      _latitude = selection.location.latitude;
      _longitude = selection.location.longitude;
      _locationNameController.text = selection.name ?? '';
    });
  }

  bool _isUploading = false;

  Future<void> _pickAndUploadFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'png', 'jpg', 'jpeg'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      final bytes = file.bytes;

      if (bytes == null || bytes.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Không thể đọc dữ liệu tệp được chọn.'),
              backgroundColor: AppTheme.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      setState(() => _isUploading = true);

      final downloadUrl = await widget.controller.uploadDocumentFile(
        fileName: file.name,
        bytes: bytes,
      );

      if (mounted) {
        setState(() {
          _fileController.text = downloadUrl;
          if (_titleController.text.trim().isEmpty) {
            final rawName = file.name;
            final dotIndex = rawName.lastIndexOf('.');
            _titleController.text =
                dotIndex > 0 ? rawName.substring(0, dotIndex) : rawName;
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã tải lên tệp: ${file.name} thành công!'),
            backgroundColor: AppTheme.secondary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tải tệp: $e'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
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
        locationName: _locationNameController.text,
        latitude: _latitude,
        longitude: _longitude,
        clearCoordinates: _latitude == null || _longitude == null,
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
        locationName: _locationNameController.text,
        latitude: _latitude,
        longitude: _longitude,
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
            content: Text(widget.controller.errorMessage ??
                'Có lỗi xảy ra khi lưu tài liệu.'),
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

    return Material(
      color: AppTheme.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      clipBehavior: Clip.antiAlias,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        padding: EdgeInsets.only(bottom: keyboardPadding),
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
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4.0),
                              child: InkWell(
                                onTap: () =>
                                    setState(() => _selectedType = type),
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
                          children:
                              widget.controller.subjects.take(4).map((sub) {
                            return ActionChip(
                              label: Text(sub,
                                  style: const TextStyle(fontSize: 11)),
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
                          Icon(Icons.link_rounded,
                              size: 18, color: AppTheme.primary),
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
                      const SizedBox(height: 8),

                      // Lựa chọn phương thức: Dán link nhanh (0s) HOẶC Chọn tệp tải lên
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () {
                                  setState(() => _selectedUploadMethod = 0);
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(
                                    color: _selectedUploadMethod == 0
                                        ? AppTheme.primary
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.bolt_rounded,
                                        size: 16,
                                        color: _selectedUploadMethod == 0
                                            ? Colors.white
                                            : AppTheme.textSecondary,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Dán link (Nhanh - 0s)',
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w600,
                                          color: _selectedUploadMethod == 0
                                              ? Colors.white
                                              : AppTheme.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            if (widget.controller.canUploadDocumentFile)
                              Expanded(
                                child: InkWell(
                                  onTap: () {
                                    setState(() => _selectedUploadMethod = 1);
                                  },
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 8),
                                    decoration: BoxDecoration(
                                      color: _selectedUploadMethod == 1
                                          ? AppTheme.primary
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.upload_file_rounded,
                                          size: 16,
                                          color: _selectedUploadMethod == 1
                                              ? Colors.white
                                              : AppTheme.textSecondary,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Chọn tệp từ máy',
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w600,
                                            color: _selectedUploadMethod == 1
                                                ? Colors.white
                                                : AppTheme.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Khi chọn chế độ "Chọn tệp từ máy", hiển thị nút upload và trạng thái tiến trình
                      if (_selectedUploadMethod == 1 &&
                          widget.controller.canUploadDocumentFile) ...[
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.primary,
                              side: const BorderSide(
                                  color: AppTheme.primary, width: 1.5),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: _isUploading
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : const Icon(Icons.cloud_upload_outlined,
                                    size: 18),
                            label: Text(
                              _isUploading
                                  ? 'Đang tải tệp lên Supabase Storage...'
                                  : 'Bấm để chọn tệp từ máy tính (Tải lên Supabase)',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            onPressed: _isUploading ? null : _pickAndUploadFile,
                          ),
                        ),
                        if (_isUploading) ...[
                          const SizedBox(height: 8),
                          const LinearProgressIndicator(),
                          const SizedBox(height: 4),
                          const Text(
                            'Đang tải lên Supabase Storage... Vui lòng đợi trong giây lát.',
                            style: TextStyle(
                                fontSize: 11.5, color: AppTheme.textSecondary),
                          ),
                        ],
                        const SizedBox(height: 8),
                      ],

                      TextFormField(
                        controller: _fileController,
                        keyboardType: TextInputType.url,
                        decoration: InputDecoration(
                          hintText: _selectedUploadMethod == 0
                              ? 'https://drive.google.com/... hoặc link tài liệu'
                              : 'Đường link tệp (tự động điền sau khi tải lên)',
                          prefixIcon:
                              const Icon(Icons.insert_link_rounded, size: 20),
                          suffixIcon: ValueListenableBuilder<TextEditingValue>(
                            valueListenable: _fileController,
                            builder: (context, value, _) {
                              if (value.text.isEmpty)
                                return const SizedBox.shrink();
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppTheme.border.withOpacity(0.6),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              _selectedUploadMethod == 0
                                  ? Icons.flash_on_rounded
                                  : Icons.info_outline_rounded,
                              size: 15,
                              color: AppTheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _selectedUploadMethod == 0
                                    ? 'Mẹo nhanh (0s): Dán trực tiếp link Google Drive, Docs, Dropbox, OneDrive hoặc PDF online để lưu ngay mà không mất thời gian chờ tải tệp.'
                                    : 'Tệp tải từ máy tính được lưu trữ an toàn trên Supabase Storage Free (tối đa 50MB/file) và tạo link CDN công khai để xem và tải về.',
                                style: const TextStyle(
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
                          hintText:
                              'Tóm tắt nội dung chính hoặc lưu ý ôn tập...',
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
                                hintText:
                                    'Nhập thẻ (e.g. Flutter, ThiCuoiKy)...',
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

                      const Text(
                        'Tên địa điểm',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _locationNameController,
                        decoration: const InputDecoration(
                          hintText: 'Ví dụ: Phòng học A203, Tủ sách phòng 2',
                          prefixIcon: Icon(Icons.place_outlined, size: 20),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _pickLocation,
                          icon: const Icon(Icons.map_outlined),
                          label: Text(
                            _latitude != null && _longitude != null
                                ? 'Thay đổi vị trí ghim'
                                : 'Chọn vị trí trên bản đồ',
                          ),
                        ),
                      ),
                      if (_latitude != null && _longitude != null) ...[
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: SizedBox(
                            height: 160,
                            child: DocumentLocationMap(
                              center: LatLng(_latitude!, _longitude!),
                              marker: LatLng(_latitude!, _longitude!),
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: () => setState(() {
                              _latitude = null;
                              _longitude = null;
                            }),
                            icon: const Icon(Icons.delete_outline, size: 16),
                            label: const Text('Xóa vị trí'),
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),

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
                          onPressed:
                              widget.controller.isLoading ? null : _submit,
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
      ),
    );
  }
}

class _SelectedLocation {
  final LatLng location;
  final String? name;

  const _SelectedLocation({required this.location, this.name});
}

class _LocationPickerSheet extends StatefulWidget {
  final LatLng? initialLocation;

  const _LocationPickerSheet({this.initialLocation});

  @override
  State<_LocationPickerSheet> createState() => _LocationPickerSheetState();
}

class _LocationPickerSheetState extends State<_LocationPickerSheet> {
  static const _defaultCenter = LatLng(21.0077, 105.8264);
  final _searchController = TextEditingController();
  final _mapController = MapController();
  final _locationSearchService = LocationSearchService();
  late LatLng? _selectedLocation = widget.initialLocation ?? _defaultCenter;
  late String? _selectedLocationName = widget.initialLocation == null
      ? 'Đại học Thủy lợi, Phố Tây Sơn, Phường Đống Đa, thành phố Hà Nội'
      : null;
  List<LocationSearchResult> _searchResults = [];
  bool _isSearching = false;
  String? _searchError;

  @override
  void dispose() {
    _searchController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _searchLocations() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _searchError = 'Nhập tên địa điểm hoặc địa chỉ cần tìm.';
      });
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _isSearching = true;
      _searchError = null;
      _searchResults = [];
    });

    try {
      final results = await _locationSearchService.search(query);
      if (!mounted) return;
      if (results.isEmpty) {
        setState(() {
          _searchResults = [];
          _searchError = 'Không tìm thấy địa điểm phù hợp.';
        });
      } else {
        final bestMatch = results.first;
        setState(() {
          _searchResults = results;
          _selectedLocation = bestMatch.location;
          _selectedLocationName = bestMatch.displayName;
          _searchError = null;
        });
        _mapController.move(bestMatch.location, 16);
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _searchError = 'Không thể tìm địa điểm. Kiểm tra kết nối rồi thử lại.';
      });
      debugPrint('Location search failed: $error');
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  void _selectSearchResult(LocationSearchResult result) {
    setState(() {
      _selectedLocation = result.location;
      _selectedLocationName = result.displayName;
      _searchResults = [];
      _searchError = null;
    });
    _mapController.move(result.location, 16);
  }

  @override
  Widget build(BuildContext context) {
    final center = _selectedLocation ?? _defaultCenter;
    return SafeArea(
      child: Material(
        color: AppTheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          height: (MediaQuery.of(context).size.height -
                  MediaQuery.of(context).viewInsets.bottom) *
              0.88,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Chọn vị trí tài liệu',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Đóng',
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              if (widget.initialLocation == null)
                const Padding(
                  padding: EdgeInsets.fromLTRB(18, 0, 18, 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Vị trí mặc định: Đại học Thủy lợi, Phố Tây Sơn, Phường Đống Đa, thành phố Hà Nội',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: TextField(
                  controller: _searchController,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _searchLocations(),
                  decoration: InputDecoration(
                    hintText: 'Tìm địa chỉ, trường học, tòa nhà...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: IconButton(
                      tooltip: 'Tìm địa điểm',
                      onPressed: _isSearching ? null : _searchLocations,
                      icon: _isSearching
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.arrow_forward_rounded),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              if (_searchError != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _searchError!,
                      style: TextStyle(
                        color: _searchResults.isEmpty
                            ? AppTheme.textSecondary
                            : AppTheme.error,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              if (_searchResults.isNotEmpty)
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 156),
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                    itemCount: _searchResults.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, indent: 48),
                    itemBuilder: (context, index) {
                      final result = _searchResults[index];
                      return ListTile(
                        dense: true,
                        leading: const Icon(
                          Icons.location_on_outlined,
                          color: AppTheme.primary,
                        ),
                        title: Text(
                          result.displayName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () => _selectSearchResult(result),
                      );
                    },
                  ),
                ),
              Expanded(
                child: DocumentLocationMap(
                  center: center,
                  marker: _selectedLocation,
                  mapController: _mapController,
                  onTap: (point) => setState(() {
                    _selectedLocation = point;
                    _selectedLocationName = null;
                  }),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _selectedLocation == null
                        ? null
                        : () => Navigator.pop(
                              context,
                              _SelectedLocation(
                                location: _selectedLocation!,
                                name: _selectedLocationName,
                              ),
                            ),
                    icon: const Icon(Icons.check),
                    label: const Text('Xác nhận vị trí'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
