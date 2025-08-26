import 'dart:io';

import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import '../models/record.dart';
import '../core/helpers.dart';
import '../core/constants.dart';

/// Service for exporting reconciled data to Excel or CSV formats
class ExportService {
  /// Export records to Excel format
  static Future<String?> exportToExcel({
    required List<ExcelRecord> records,
    required List<String> headers,
    String? fileName,
    bool includeMetadata = true,
  }) async {
    try {
      final excel = Excel.createExcel();
      final sheetName = 'Reconciled Data';

      // Remove default sheet and create new one
      excel.delete('Sheet1');
      excel[sheetName];

      final sheet = excel[sheetName];

      // Add headers row
      for (int i = 0; i < headers.length; i++) {
        final cell =
            sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
        cell.value = TextCellValue(headers[i]);

        // Style header cells
        cell.cellStyle = CellStyle(
          bold: true,
          backgroundColorHex: ExcelColor.fromHexString('#E3F2FD'),
          horizontalAlign: HorizontalAlign.Center,
        );
      }

      // Add data rows
      for (int rowIndex = 0; rowIndex < records.length; rowIndex++) {
        final record = records[rowIndex];

        for (int colIndex = 0; colIndex < headers.length; colIndex++) {
          final header = headers[colIndex];
          final cell = sheet.cell(CellIndex.indexByColumnRow(
            columnIndex: colIndex,
            rowIndex: rowIndex + 1,
          ));

          final value = record.getValue(header);
          _setCellValue(cell, value);

          // Highlight cells that were originally missing
          if (record.isFieldMissing(header) &&
              value != null &&
              !AppHelpers.isEmptyOrMissing(value)) {
            cell.cellStyle = CellStyle(
                backgroundColorHex: ExcelColor.fromHexString('#C8E6C9')
                // Light green for filled values
                );
          }
        }
      }

      // Add metadata sheet if requested
      if (includeMetadata) {
        _addMetadataSheet(excel, records, headers);
      }

      // Save file
      final directory = await getApplicationDocumentsDirectory();
      final finalFileName = fileName ??
          AppHelpers.generateTimestampedFileName(
            AppConstants.defaultExportFileName,
            'xlsx',
          );
      final filePath = '${directory.path}/$finalFileName';

      final fileBytes = excel.save();
      if (fileBytes != null) {
        final file = File(filePath);
        await file.writeAsBytes(fileBytes);
        return filePath;
      }

      return null;
    } catch (e) {
      print('Error exporting to Excel: $e');
      return null;
    }
  }

  /// Export records to CSV format
  static Future<String?> exportToCSV({
    required List<ExcelRecord> records,
    required List<String> headers,
    String? fileName,
  }) async {
    try {
      final csvContent = StringBuffer();

      // Add headers
      csvContent.writeln(headers.map((h) => _escapeCsvValue(h)).join(','));

      // Add data rows
      for (final record in records) {
        final rowValues = headers.map((header) {
          final value = record.getValue(header);
          return _escapeCsvValue(value?.toString() ?? '');
        }).join(',');

        csvContent.writeln(rowValues);
      }

      // Save file
      final directory = await getApplicationDocumentsDirectory();
      final finalFileName = fileName ??
          AppHelpers.generateTimestampedFileName(
            AppConstants.defaultExportFileName,
            'csv',
          );
      final filePath = '${directory.path}/$finalFileName';

      final file = File(filePath);
      await file.writeAsString(csvContent.toString());

      return filePath;
    } catch (e) {
      print('Error exporting to CSV: $e');
      return null;
    }
  }

  /// Export reconciliation summary report
  static Future<String?> exportSummaryReport({
    required ExcelFileData mainData,
    required List<ExcelFileData> subDataList,
    required Map<String, dynamic> reconciliationSummary,
    String? fileName,
  }) async {
    try {
      final excel = Excel.createExcel();
      excel.delete('Sheet1');

      // Create summary sheet
      _createSummarySheet(excel, mainData, subDataList, reconciliationSummary);

      // Create field analysis sheet
      _createFieldAnalysisSheet(excel, mainData);

      // Save file
      final directory = await getApplicationDocumentsDirectory();
      final finalFileName = fileName ??
          AppHelpers.generateTimestampedFileName(
            'reconciliation_summary',
            'xlsx',
          );
      final filePath = '${directory.path}/$finalFileName';

      final fileBytes = excel.save();
      if (fileBytes != null) {
        final file = File(filePath);
        await file.writeAsBytes(fileBytes);
        return filePath;
      }

      return null;
    } catch (e) {
      print('Error exporting summary report: $e');
      return null;
    }
  }

  // /// Set cell value based on data type
  // static void _setCellValue(Data? cell, dynamic value) {
  //   if (value == null || AppHelpers.isEmptyOrMissing(value)) {
  //     cell.value = TextCellValue('');
  //   } else if (value is int) {
  //     cell.value = IntCellValue(value);
  //   } else if (value is double) {
  //     cell.value = DoubleCellValue(value);
  //   } else if (value is bool) {
  //     cell.value = BoolCellValue(value);
  //   } else if (value is DateTime) {
  //     cell.value = DateTimeCellValue.fromDateTime(value);
  //   } else {
  //     cell.value = TextCellValue(value.toString());
  //   }
  // }

  /// Set cell value based on data type (uses the same `Data` type as your extractor)
  static void _setCellValue(Data? cell, dynamic value) {
    if (cell == null) return;

    if (value == null || AppHelpers.isEmptyOrMissing(value)) {
      cell.value = TextCellValue('');
    } else if (value is int) {
      cell.value = IntCellValue(value);
    } else if (value is double) {
      cell.value = DoubleCellValue(value);
    } else if (value is bool) {
      cell.value = BoolCellValue(value);
    } else if (value is DateTime) {
      // use the Date/DateTime cell type your package exposes
      // adjust constructor if your package uses a different name/ctor
      cell.value = DateTimeCellValue.fromDateTime(value);
    } else {
      cell.value = TextCellValue(value.toString());
    }
  }

  /// Escape CSV value to handle commas, quotes, and newlines
  static String _escapeCsvValue(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  /// Add metadata sheet to Excel file
  static void _addMetadataSheet(
      Excel excel, List<ExcelRecord> records, List<String> headers) {
    const sheetName = 'Metadata';
    excel[sheetName];
    final sheet = excel[sheetName];

    int rowIndex = 0;

    // Export information
    _addMetadataRow(
        sheet, rowIndex++, 'Export Date:', DateTime.now().toString());
    _addMetadataRow(
        sheet, rowIndex++, 'Total Records:', records.length.toString());
    _addMetadataRow(
        sheet, rowIndex++, 'Total Fields:', headers.length.toString());

    rowIndex++; // Empty row

    // Field statistics
    _addMetadataRow(sheet, rowIndex++, 'Field Statistics:', '');
    _addMetadataRow(sheet, rowIndex++, 'Field Name', 'Missing Count');

    for (final header in headers) {
      final missingCount =
          records.where((r) => r.isFieldMissing(header)).length;
      _addMetadataRow(sheet, rowIndex++, header, missingCount.toString());
    }
  }

  /// Add a metadata row to the sheet
  static void _addMetadataRow(
      Sheet sheet, int rowIndex, String label, String value) {
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
        .value = TextCellValue(label);
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex))
        .value = TextCellValue(value);
  }

  /// Create summary sheet for reconciliation report
  static void _createSummarySheet(
    Excel excel,
    ExcelFileData mainData,
    List<ExcelFileData> subDataList,
    Map<String, dynamic> summary,
  ) {
    const sheetName = 'Summary';
    excel[sheetName];
    final sheet = excel[sheetName];

    int rowIndex = 0;

    // Title
    final titleCell = sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex++));
    titleCell.value = TextCellValue('Reconciliation Summary Report');
    titleCell.cellStyle = CellStyle(
      bold: true,
      fontSize: 16,
      horizontalAlign: HorizontalAlign.Center,
    );

    rowIndex++; // Empty row

    // Basic statistics
    _addSummaryRow(
        sheet, rowIndex++, 'Generated On:', DateTime.now().toString());
    _addSummaryRow(sheet, rowIndex++, 'Main File:', mainData.fileName);
    _addSummaryRow(sheet, rowIndex++, 'Sub Files:',
        subDataList.map((s) => s.fileName).join(', '));
    _addSummaryRow(
        sheet, rowIndex++, 'Reference Field:', mainData.referenceField);

    rowIndex++; // Empty row

    // Reconciliation results
    _addSummaryRow(sheet, rowIndex++, 'Total Records:',
        summary['totalRecords'].toString());
    _addSummaryRow(sheet, rowIndex++, 'Matched Records:',
        summary['matchedRecords'].toString());
    _addSummaryRow(sheet, rowIndex++, 'Unmatched Records:',
        summary['unmatchedRecords'].toString());
    _addSummaryRow(sheet, rowIndex++, 'Match Percentage:',
        '${summary['matchPercentage']}%');
    _addSummaryRow(sheet, rowIndex++, 'Records with Suggestions:',
        summary['recordsWithSuggestions'].toString());
    _addSummaryRow(sheet, rowIndex++, 'Fillable Percentage:',
        '${summary['fillablePercentage']}%');
  }

  /// Create field analysis sheet
  static void _createFieldAnalysisSheet(Excel excel, ExcelFileData mainData) {
    const sheetName = 'Field Analysis';
    excel[sheetName];
    final sheet = excel[sheetName];

    int rowIndex = 0;

    // Headers
    _addSummaryRow(sheet, rowIndex++, 'Field Name', 'Total Records');
    _addSummaryRow(sheet, rowIndex++, '', 'Missing Count');
    _addSummaryRow(sheet, rowIndex++, '', 'Completion %');

    // Field statistics
    for (final header in mainData.headers) {
      final totalRecords = mainData.records.length;
      final missingCount =
          mainData.records.where((r) => r.isFieldMissing(header)).length;
      final completionPercentage = totalRecords > 0
          ? ((totalRecords - missingCount) / totalRecords * 100).round()
          : 0;

      _addSummaryRow(sheet, rowIndex++, header, totalRecords.toString());
      _addSummaryRow(sheet, rowIndex++, '', missingCount.toString());
      _addSummaryRow(sheet, rowIndex++, '', '$completionPercentage%');
      rowIndex++; // Empty row between fields
    }
  }

  /// Add a summary row to the sheet
  static void _addSummaryRow(
      Sheet sheet, int rowIndex, String label, String value) {
    final labelCell = sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex));
    labelCell.value = TextCellValue(label);
    if (label.isNotEmpty) {
      labelCell.cellStyle = CellStyle(bold: true);
    }

    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex))
        .value = TextCellValue(value);
  }

  /// Get default export directory
  static Future<String> getExportDirectory() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final exportDir = Directory('${directory.path}/ExSlate_Exports');

      if (!await exportDir.exists()) {
        await exportDir.create(recursive: true);
      }

      return exportDir.path;
    } catch (e) {
      // Fallback to documents directory
      final directory = await getApplicationDocumentsDirectory();
      return directory.path;
    }
  }

  /// Get file size of export
  static Future<int> getExportFileSize(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        return await file.length();
      }
    } catch (e) {
      print('Error getting file size: $e');
    }
    return 0;
  }
}
