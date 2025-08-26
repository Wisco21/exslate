import 'package:exslate_app/core/constants.dart';
import 'package:exslate_app/core/helpers.dart';
import 'package:exslate_app/services/excel_paeser.dart';
import 'package:file_picker/file_picker.dart' as FilePickerLib;
import 'package:flutter/material.dart';

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
