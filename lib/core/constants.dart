import 'dart:ui';

/// Application-wide constants for ExSlate
class AppConstants {
  // File types
  static const List<String> allowedFileTypes = ['xlsx', 'xls'];

  // UI strings
  static const String appTitle = 'ExSlate';
  static const String appSubtitle = 'Excel Reconciliation Tool';

  static const String uploadMainLabel = 'Upload Main File';
  static const String uploadSubLabel = 'Upload Sub File';
  static const String selectReferenceField = 'Select Reference Field';
  static const String chooseFileType = 'Choose File Type';

  // Error messages
  static const String fileParsingError =
      'Error parsing file. Please check the format.';
  static const String noDataFound = 'No data found in the uploaded file.';
  static const String duplicateReferenceError =
      'Duplicate reference values found.';

  // Success messages
  static const String fileUploadSuccess = 'File uploaded successfully';
  static const String exportSuccess = 'Data exported successfully';

  // Table settings
  static const double defaultColumnWidth = 120.0;
  static const double minColumnWidth = 80.0;
  static const double maxColumnWidth = 200.0;

  // Export settings
  static const String defaultExportFileName = 'reconciled_data';
}

/// Enum for file types in the reconciliation process
enum FileType { main, sub }

/// Enum for view modes in the application
enum ViewMode { table, edit, compare }

/// App color scheme
class AppColors {
  static const Color primary = Color(0xFF2196F3);
  static const Color secondary = Color(0xFF03DAC6);
  static const Color error = Color(0xFFB00020);
  static const Color warning = Color(0xFFFF9800);
  static const Color success = Color(0xFF4CAF50);

  // Missing value highlighting
  static const Color missingValueBg = Color(0xFFFFEBEE);
  static const Color missingValueBorder = Color(0xFFE57373);

  // Comparison colors
  static const Color matchedRow = Color(0xFFE8F5E8);
  static const Color unmatchedRow = Color(0xFFFFF3E0);
}
