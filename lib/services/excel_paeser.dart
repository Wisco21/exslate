import 'dart:io';
import 'dart:typed_data';
import 'package:excel/excel.dart';
import '../models/record.dart';

/// Service for parsing Excel files and extracting data
class ExcelParserService {
  /// Parse Excel file and return structured data
  static Future<ExcelFileData?> parseExcelFile({
    required String filePath,
    required String fileName,
    required String referenceField,
  }) async {
    try {
      // Read file as bytes
      final file = File(filePath);
      final bytes = await file.readAsBytes();

      // Parse Excel file
      final excel = Excel.decodeBytes(bytes);

      // Get the first sheet (assuming data is in first sheet)
      final sheetName = excel.tables.keys.first;
      final sheet = excel.tables[sheetName];

      if (sheet == null || sheet.rows.isEmpty) {
        throw Exception('No data found in Excel file');
      }

      return _extractDataFromSheet(sheet, fileName, referenceField);
    } catch (e) {
      print('Error parsing Excel file: $e');
      return null;
    }
  }

  /// Parse Excel file from bytes (for web compatibility)
  static Future<ExcelFileData?> parseExcelFromBytes({
    required Uint8List bytes,
    required String fileName,
    required String referenceField,
  }) async {
    try {
      // Parse Excel file
      final excel = Excel.decodeBytes(bytes);

      // Get the first sheet
      final sheetName = excel.tables.keys.first;
      final sheet = excel.tables[sheetName];

      if (sheet == null || sheet.rows.isEmpty) {
        throw Exception('No data found in Excel file');
      }

      return _extractDataFromSheet(sheet, fileName, referenceField);
    } catch (e) {
      print('Error parsing Excel file from bytes: $e');
      return null;
    }
  }

  /// Extract headers from first row of Excel sheet
  static List<String> extractHeaders(Sheet sheet) {
    if (sheet.rows.isEmpty) return [];

    final headerRow = sheet.rows.first;
    final headers = <String>[];

    for (final cell in headerRow) {
      if (cell?.value != null) {
        headers.add(cell!.value.toString().trim());
      } else {
        headers.add(
            'Column ${headers.length + 1}'); // Default name for empty headers
      }
    }

    return headers;
  }

  /// Extract data from Excel sheet and create structured records
  static ExcelFileData _extractDataFromSheet(
    Sheet sheet,
    String fileName,
    String referenceField,
  ) {
    final rows = sheet.rows;
    if (rows.isEmpty) {
      throw Exception('No rows found in sheet');
    }

    // Extract headers from first row
    final headers = extractHeaders(sheet);
    if (headers.isEmpty) {
      throw Exception('No headers found in first row');
    }

    // Find reference field index
    final referenceIndex = headers.indexOf(referenceField);
    if (referenceIndex == -1) {
      throw Exception('Reference field "$referenceField" not found in headers');
    }

    // Process data rows (skip header row)
    final records = <ExcelRecord>[];
    for (int i = 1; i < rows.length; i++) {
      final row = rows[i];

      // Extract cell values for this row
      final rowData = <String, dynamic>{};
      String referenceValue = '';

      for (int j = 0; j < headers.length && j < row.length; j++) {
        final cellValue = _extractCellValue(row[j]);
        rowData[headers[j]] = cellValue;

        // Store reference value for matching
        if (j == referenceIndex) {
          referenceValue = cellValue?.toString().trim() ?? '';
        }
      }

      // Skip rows with empty reference values
      if (referenceValue.isEmpty) continue;

      // Create record
      final record = ExcelRecord(
        id: '${fileName}_${i}', // Unique ID based on file and row
        data: rowData,
        referenceValue: referenceValue,
        originalRowIndex: i,
      );

      records.add(record);
    }

    return ExcelFileData(
      fileName: fileName,
      headers: headers,
      records: records,
      referenceField: referenceField,
    );
  }

  // /// Extract and clean cell value from Excel cell
  // static dynamic _extractCellValue(Data? cell) {
  //   if (cell?.value == null) return null;

  //   final value = cell!.value;

  //   // Handle different cell types
  //   if (value is TextCellValue) {
  //     return value.value.text!.trim();
  //   } else if (value is IntCellValue) {
  //     return value.value;
  //   } else if (value is DoubleCellValue) {
  //     return value.value;
  //   } else if (value is BoolCellValue) {
  //     return value.value;
  //   } else if (value is DateCellValue) {
  //     return value.asDateTime();
  //   } else if (value is TimeCellValue) {
  //     return value.asDateTime();
  //   } else if (value is DateTimeCellValue) {
  //     return value.asDateTime();
  //   } else {
  //     return value.toString().trim();
  //   }
  // }

  static dynamic _extractCellValue(Data? cell) {
    if (cell?.value == null) return null;

    final value = cell!.value;

    if (value is TextCellValue) {
      return value.value.text?.trim(); // TextSpan → String
    } else if (value is IntCellValue) {
      return value.value;
    } else if (value is DoubleCellValue) {
      return value.value;
    } else if (value is BoolCellValue) {
      return value.value;
    } else if (value is DateCellValue) {
      return value.asDateTimeLocal; // directly returns DateTime
    } else if (value is TimeCellValue) {
      return value.asDuration; // TimeCellValue → DateTime
    } else if (value is DateTimeCellValue) {
      return value.asDateTimeLocal; // also exposes .dateTime
    } else {
      return value.toString().trim();
    }
  }

  /// Get available sheets from Excel file
  static Future<List<String>> getSheetNames(String filePath) async {
    try {
      final file = File(filePath);
      final bytes = await file.readAsBytes();
      final excel = Excel.decodeBytes(bytes);

      return excel.tables.keys.toList();
    } catch (e) {
      print('Error getting sheet names: $e');
      return [];
    }
  }

  /// Validate if file can be parsed as Excel
  static Future<bool> validateExcelFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return false;

      final bytes = await file.readAsBytes();
      final excel = Excel.decodeBytes(bytes);

      // Check if at least one sheet exists with data
      return excel.tables.isNotEmpty &&
          excel.tables.values.any((sheet) => sheet.rows.isNotEmpty);
    } catch (e) {
      return false;
    }
  }

  /// Get preview data from Excel file (first 5 rows)
  static Future<Map<String, dynamic>?> getExcelPreview(String filePath) async {
    try {
      final file = File(filePath);
      final bytes = await file.readAsBytes();
      final excel = Excel.decodeBytes(bytes);

      final sheetName = excel.tables.keys.first;
      final sheet = excel.tables[sheetName];

      if (sheet == null || sheet.rows.isEmpty) return null;

      final headers = extractHeaders(sheet);
      final previewRows = <List<dynamic>>[];

      // Get up to 5 data rows for preview
      final maxPreviewRows = 5;
      final actualRowCount = (sheet.rows.length - 1).clamp(0, maxPreviewRows);

      for (int i = 1; i <= actualRowCount; i++) {
        final row = sheet.rows[i];
        final rowData = <dynamic>[];

        for (int j = 0; j < headers.length && j < row.length; j++) {
          rowData.add(_extractCellValue(row[j]));
        }
        previewRows.add(rowData);
      }

      return {
        'headers': headers,
        'rows': previewRows,
        'totalRows': sheet.rows.length - 1, // Exclude header row
        'sheetName': sheetName,
      };
    } catch (e) {
      print('Error getting Excel preview: $e');
      return null;
    }
  }
}
