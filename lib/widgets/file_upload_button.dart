import 'package:exslate_app/services/excel_paeser.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart' as FilePickerLib;
import '../core/constants.dart';
import '../core/styles.dart';
import '../core/helpers.dart';

/// Reusable file upload button with reference field selection
class FileUploadButton extends StatefulWidget {
  final String label;
  final Function(String filePath, String referenceField) onFileSelected;
  final bool isPrimary;
  final List<String>? allowedExtensions;

  const FileUploadButton({
    Key? key,
    required this.label,
    required this.onFileSelected,
    this.isPrimary = false,
    this.allowedExtensions,
  }) : super(key: key);

  @override
  State<FileUploadButton> createState() => _FileUploadButtonState();
}

class _FileUploadButtonState extends State<FileUploadButton> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _handleFileUpload,
        icon: _isLoading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.upload_file),
        label: Text(widget.label),
        style: ElevatedButton.styleFrom(
          backgroundColor:
              widget.isPrimary ? AppColors.primary : Colors.grey[600],
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        ),
      ),
    );
  }

  Future<void> _handleFileUpload() async {
    setState(() => _isLoading = true);
    await FileUploadService.pickAndUploadFile(
      context: context,
      allowedExtensions:
          widget.allowedExtensions ?? AppConstants.allowedFileTypes,
      onFileSelected: widget.onFileSelected,
    );
    if (mounted) setState(() => _isLoading = false);
  }

  Future<String?> _showReferenceFieldDialog(
    BuildContext context,
    List<String> headers,
    String fileName,
    Map<String, dynamic> preview,
  ) async {
    String? selectedField;

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Configure Upload: $fileName'),
              const SizedBox(height: 4),
              Text(
                '${preview['totalRows']} rows found',
                style: AppStyles.captionTextStyle,
              ),
            ],
          ),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppConstants.selectReferenceField,
                  style: AppStyles.bodyTextStyle
                      .copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                Text(
                  'This field will be used to match records between files.',
                  style: AppStyles.captionTextStyle,
                ),
                const SizedBox(height: 16),

                // Reference field dropdown
                DropdownButtonFormField<String>(
                  value: selectedField,
                  decoration: const InputDecoration(
                    labelText: 'Reference Field',
                    border: OutlineInputBorder(),
                    helperText: 'Choose the unique identifier field',
                  ),
                  items: headers
                      .map((header) => DropdownMenuItem(
                            value: header,
                            child: Text(header),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() => selectedField = value);
                  },
                ),
                const SizedBox(height: 16),

                // File preview
                Text(
                  'Preview (First 3 rows):',
                  style: AppStyles.captionTextStyle
                      .copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: SingleChildScrollView(
                    child: _buildPreviewTable(headers, preview['rows']),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: selectedField != null
                  ? () => Navigator.of(context).pop(selectedField)
                  : null,
              child: const Text('Upload'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewTable(List<String> headers, List<List<dynamic>> rows) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          // Headers
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(4)),
            ),
            child: Row(
              children: headers
                  .map((header) => Expanded(
                        child: Text(
                          header,
                          style: AppStyles.captionTextStyle.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ))
                  .toList(),
            ),
          ),

          // Rows (limit to 3 for preview)
          ...rows.take(3).map((row) => Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Colors.grey[200]!),
                  ),
                ),
                child: Row(
                  children: List.generate(headers.length, (index) {
                    final value = index < row.length ? row[index] : '';
                    return Expanded(
                      child: Text(
                        value?.toString() ?? '',
                        style: AppStyles.captionTextStyle,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }),
                ),
              )),
        ],
      ),
    );
  }
}

/// Specialized upload button for drag and drop functionality
class DragDropUploadButton extends StatefulWidget {
  final String label;
  final Function(String filePath, String referenceField) onFileSelected;
  final bool isPrimary;

  const DragDropUploadButton({
    Key? key,
    required this.label,
    required this.onFileSelected,
    this.isPrimary = false,
  }) : super(key: key);

  @override
  State<DragDropUploadButton> createState() => _DragDropUploadButtonState();
}

class _DragDropUploadButtonState extends State<DragDropUploadButton> {
  bool _isDragOver = false;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        border: Border.all(
          color: _isDragOver ? AppColors.primary : Colors.grey[300]!,
          width: _isDragOver ? 2 : 1,
          style: BorderStyle.solid,
        ),
        borderRadius: BorderRadius.circular(8),
        color:
            _isDragOver ? AppColors.primary.withOpacity(0.05) : Colors.grey[50],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isLoading ? null : _handleFileUpload,
          borderRadius: BorderRadius.circular(8),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isLoading)
                  const CircularProgressIndicator()
                else
                  Icon(
                    Icons.cloud_upload,
                    size: 32,
                    color: _isDragOver ? AppColors.primary : Colors.grey[600],
                  ),
                const SizedBox(height: 8),
                Text(
                  widget.label,
                  style: AppStyles.bodyTextStyle.copyWith(
                    color: _isDragOver ? AppColors.primary : Colors.grey[600],
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Click to browse or drag & drop',
                  style: AppStyles.captionTextStyle,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Future<void> _handleFileUpload() async {
  //   // Use the same logic as FileUploadButton
  //   final uploadButton = FileUploadButton(
  //     label: widget.label,
  //     onFileSelected: widget.onFileSelected,
  //     isPrimary: widget.isPrimary,
  //   );

  //   // Create a temporary state to handle the upload
  //   final state = uploadButton.createState();
  //   // state.mounted = mounted;
  //   await FileUploadService.pickAndUploadFile(
  //     context: context,
  //     allowedExtensions: AppConstants.allowedFileTypes,
  //     onFileSelected: (filePath, referenceField) {
  //       // handle file
  //     },
  //   );
  // }
  Future<void> _handleFileUpload() async {
    await FileUploadService.pickAndUploadFile(
      context: context,
      allowedExtensions: AppConstants.allowedFileTypes,
      onFileSelected: widget.onFileSelected, // reuse your widget’s callback
    );
  }
}

/// Quick upload button for when reference field is already known
class QuickUploadButton extends StatelessWidget {
  final String label;
  final String referenceField;
  final Function(String filePath) onFileSelected;
  final IconData? icon;

  const QuickUploadButton({
    Key? key,
    required this.label,
    required this.referenceField,
    required this.onFileSelected,
    this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () => _handleQuickUpload(context),
      icon: Icon(icon ?? Icons.add),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.secondary,
      ),
    );
  }

  Future<void> _handleQuickUpload(BuildContext context) async {
    try {
      final result = await FilePickerLib.FilePicker.platform.pickFiles(
        type: FilePickerLib.FileType.custom,
        allowedExtensions: AppConstants.allowedFileTypes,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      final filePath = file.path;

      if (filePath == null) {
        AppHelpers.showSnackBar(context, 'Could not access file path',
            isError: true);
        return;
      }

      if (!AppHelpers.isValidFileType(
          filePath, AppConstants.allowedFileTypes)) {
        AppHelpers.showSnackBar(
          context,
          'Please select a valid Excel file (.xlsx or .xls)',
          isError: true,
        );
        return;
      }

      onFileSelected(filePath);
    } catch (e) {
      AppHelpers.showSnackBar(context, 'Error uploading file: ${e.toString()}',
          isError: true);
    }
  }
}

class FileUploadService {
  static Future<void> pickAndUploadFile({
    required BuildContext context,
    required List<String> allowedExtensions,
    required Function(String filePath, String referenceField) onFileSelected,
  }) async {
    try {
      // Pick file
      final result = await FilePickerLib.FilePicker.platform.pickFiles(
        type: FilePickerLib.FileType.custom,
        allowedExtensions: allowedExtensions,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        return;
      }

      final file = result.files.first;
      final filePath = file.path;

      if (filePath == null) {
        AppHelpers.showSnackBar(context, 'Could not access file path',
            isError: true);
        return;
      }

      // Validate file type
      if (!AppHelpers.isValidFileType(
          filePath, AppConstants.allowedFileTypes)) {
        AppHelpers.showSnackBar(
          context,
          'Please select a valid Excel file (.xlsx or .xls)',
          isError: true,
        );
        return;
      }

      // Get file preview to extract headers
      final preview = await ExcelParserService.getExcelPreview(filePath);
      if (preview == null) {
        AppHelpers.showSnackBar(context, AppConstants.fileParsingError,
            isError: true);
        return;
      }

      final headers = preview['headers'] as List<String>;
      if (headers.isEmpty) {
        AppHelpers.showSnackBar(context, 'No headers found in the file',
            isError: true);
        return;
      }

      // Show reference field selection dialog
      final referenceField =
          await _showReferenceFieldDialog(context, headers, file.name, preview);
      if (referenceField != null) {
        onFileSelected(filePath, referenceField);
      }
    } catch (e) {
      AppHelpers.showSnackBar(context, 'Error uploading file: $e',
          isError: true);
    }
  }

  // Move your dialog method here too
  static Future<String?> _showReferenceFieldDialog(
      BuildContext context,
      List<String> headers,
      String fileName,
      Map<String, dynamic> preview) async {
    // TODO: implement your dialog UI
    return null;
  }
}
