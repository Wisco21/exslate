import 'package:exslate_app/services/excel_paeser.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/record.dart';
import '../services/reconciliation.dart';
import '../services/export_service.dart';
import '../core/constants.dart';

/// Main state provider for ExSlate application data management
class DataProvider with ChangeNotifier {
  // Core data
  ExcelFileData? _mainData;
  List<ExcelFileData> _subDataList = [];

  // Reconciliation results
  ReconciliationResult? _reconciliationResult;
  List<ExcelRecord>? _processedRecords;

  // UI state
  bool _isLoading = false;
  String _statusMessage = '';
  ViewMode _currentViewMode = ViewMode.table;
  String _searchQuery = '';
  bool _showOnlyMissingFields = false;
  String? _selectedRecordId;

  // Filtering and sorting
  String? _sortColumn;
  bool _sortAscending = true;

  // Getters
  ExcelFileData? get mainData => _mainData;
  List<ExcelFileData> get subDataList => _subDataList;
  ReconciliationResult? get reconciliationResult => _reconciliationResult;
  List<ExcelRecord>? get processedRecords => _processedRecords;

  bool get isLoading => _isLoading;
  String get statusMessage => _statusMessage;
  ViewMode get currentViewMode => _currentViewMode;
  String get searchQuery => _searchQuery;
  bool get showOnlyMissingFields => _showOnlyMissingFields;
  String? get selectedRecordId => _selectedRecordId;
  String? get sortColumn => _sortColumn;
  bool get sortAscending => _sortAscending;

  // Computed getters
  bool get hasMainData => _mainData != null;
  bool get hasSubData => _subDataList.isNotEmpty;
  bool get canReconcile => hasMainData && hasSubData;
  bool get hasReconciliationResults => _reconciliationResult != null;

  List<String> get availableHeaders => _mainData?.headers ?? [];

  int get totalRecords => _mainData?.records.length ?? 0;
  int get recordsWithMissingFields =>
      _mainData?.recordsWithMissingFields.length ?? 0;

  /// Get filtered and sorted records for display
  List<ExcelRecord> get displayRecords {
    var records = _processedRecords ?? _mainData?.records ?? [];

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      records = records.where((record) {
        return record.data.values.any((value) =>
                value
                    ?.toString()
                    .toLowerCase()
                    .contains(_searchQuery.toLowerCase()) ??
                false) ||
            record.referenceValue
                .toLowerCase()
                .contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Apply missing fields filter
    if (_showOnlyMissingFields) {
      records = records.where((record) => record.hasMissingFields).toList();
    }

    // Apply sorting
    if (_sortColumn != null) {
      records.sort((a, b) {
        final aValue = a.getValue(_sortColumn!) ?? '';
        final bValue = b.getValue(_sortColumn!) ?? '';

        int comparison = aValue.toString().compareTo(bValue.toString());
        return _sortAscending ? comparison : -comparison;
      });
    }

    return records;
  }

  /// Upload and parse main Excel file
  Future<bool> uploadMainFile({
    required String filePath,
    required String referenceField,
  }) async {
    return _uploadFile(
      filePath: filePath,
      referenceField: referenceField,
      isMainFile: true,
    );
  }

  /// Upload and parse sub Excel file
  Future<bool> uploadSubFile({
    required String filePath,
    required String referenceField,
  }) async {
    return _uploadFile(
      filePath: filePath,
      referenceField: referenceField,
      isMainFile: false,
    );
  }

  /// Generic file upload method
  Future<bool> _uploadFile({
    required String filePath,
    required String referenceField,
    required bool isMainFile,
  }) async {
    try {
      _setLoading(true);
      _setStatusMessage(
          isMainFile ? 'Parsing main file...' : 'Parsing sub file...');

      final fileName = filePath.split('/').last;
      final fileData = await ExcelParserService.parseExcelFile(
        filePath: filePath,
        fileName: fileName,
        referenceField: referenceField,
      );

      if (fileData == null) {
        _setStatusMessage(AppConstants.fileParsingError);
        return false;
      }

      if (fileData.records.isEmpty) {
        _setStatusMessage(AppConstants.noDataFound);
        return false;
      }

      if (isMainFile) {
        _mainData = fileData;
        _clearReconciliationResults(); // Clear previous reconciliation
        _setStatusMessage(
            'Main file loaded: ${fileData.records.length} records');
      } else {
        _subDataList.add(fileData);
        _setStatusMessage('Sub file added: ${fileData.records.length} records');

        // Auto-reconcile if we have main data
        if (hasMainData) {
          await performReconciliation();
        }
      }

      return true;
    } catch (e) {
      _setStatusMessage('Error uploading file: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Perform reconciliation between main and sub files
  Future<void> performReconciliation() async {
    if (!canReconcile) return;

    try {
      _setLoading(true);
      _setStatusMessage('Performing reconciliation...');

      _reconciliationResult = ReconciliationService.reconcileData(
        mainData: _mainData!,
        subDataList: _subDataList,
      );

      _setStatusMessage(
          'Reconciliation complete: ${_reconciliationResult!.matchedRecords.length} matches found');

      notifyListeners();
    } catch (e) {
      _setStatusMessage('Error during reconciliation: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  /// Apply suggested fills to a specific record
  void applySuggestedFill(String recordId, String fieldName, dynamic value) {
    if (_mainData == null) return;

    final recordIndex = _mainData!.records.indexWhere((r) => r.id == recordId);
    if (recordIndex == -1) return;

    // Update the record
    final updatedRecord =
        _mainData!.records[recordIndex].updateField(fieldName, value);
    final updatedRecords = List<ExcelRecord>.from(_mainData!.records);
    updatedRecords[recordIndex] = updatedRecord;

    _mainData = _mainData!.copyWith(records: updatedRecords);

    // Update processed records if they exist
    if (_processedRecords != null) {
      final processedIndex =
          _processedRecords!.indexWhere((r) => r.id == recordId);
      if (processedIndex != -1) {
        _processedRecords![processedIndex] = updatedRecord;
      }
    }

    _setStatusMessage('Field "$fieldName" updated for record $recordId');
    notifyListeners();
  }

  /// Apply all suggested fills for a record
  void applyAllSuggestedFills(String recordId) {
    if (_reconciliationResult == null || _mainData == null) return;

    final record = _mainData!.records.firstWhere((r) => r.id == recordId);
    final suggestions =
        _reconciliationResult!.suggestedFills[record.referenceValue];

    if (suggestions == null || suggestions.isEmpty) return;

    var updatedRecord = record;
    int fillCount = 0;

    for (final entry in suggestions.entries) {
      final fieldName = entry.key;
      final possibleValues = entry.value;

      if (possibleValues.isNotEmpty &&
          updatedRecord.isFieldMissing(fieldName)) {
        // Use first suggested value
        updatedRecord =
            updatedRecord.updateField(fieldName, possibleValues.first);
        fillCount++;
      }
    }

    if (fillCount > 0) {
      // Update in main data
      final recordIndex =
          _mainData!.records.indexWhere((r) => r.id == recordId);
      if (recordIndex != -1) {
        final updatedRecords = List<ExcelRecord>.from(_mainData!.records);
        updatedRecords[recordIndex] = updatedRecord;
        _mainData = _mainData!.copyWith(records: updatedRecords);

        // Update processed records
        if (_processedRecords != null) {
          final processedIndex =
              _processedRecords!.indexWhere((r) => r.id == recordId);
          if (processedIndex != -1) {
            _processedRecords![processedIndex] = updatedRecord;
          }
        }

        _setStatusMessage('Auto-filled $fillCount fields for record');
        notifyListeners();
      }
    }
  }

  /// Bulk apply all suggested fills
  Future<void> applyAllSuggestedFillsBulk() async {
    if (_reconciliationResult == null || _mainData == null) return;

    try {
      _setLoading(true);
      _setStatusMessage('Applying suggested fills...');

      final fillSuggestions = <String, Map<String, dynamic>>{};

      // Convert suggestions format
      for (final entry in _reconciliationResult!.suggestedFills.entries) {
        final refValue = entry.key;
        final suggestions = entry.value;
        final singleValueSuggestions = <String, dynamic>{};

        for (final suggestionEntry in suggestions.entries) {
          final fieldName = suggestionEntry.key;
          final values = suggestionEntry.value;
          if (values.isNotEmpty) {
            singleValueSuggestions[fieldName] = values.first;
          }
        }

        if (singleValueSuggestions.isNotEmpty) {
          fillSuggestions[refValue] = singleValueSuggestions;
        }
      }

      _processedRecords = ReconciliationService.applySuggestedFills(
        mainRecords: _mainData!.records,
        fillSuggestions: fillSuggestions,
      );

      // Update main data with processed records
      _mainData = _mainData!.copyWith(records: _processedRecords!);

      final fillCount = fillSuggestions.length;
      _setStatusMessage('Applied suggested fills to $fillCount records');
    } catch (e) {
      _setStatusMessage('Error applying fills: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  /// Export current data
  Future<String?> exportData({
    required String format, // 'excel' or 'csv'
    String? fileName,
  }) async {
    if (_mainData == null) return null;

    try {
      _setLoading(true);
      _setStatusMessage('Exporting data...');

      final recordsToExport = _processedRecords ?? _mainData!.records;
      String? filePath;

      if (format.toLowerCase() == 'excel') {
        filePath = await ExportService.exportToExcel(
          records: recordsToExport,
          headers: _mainData!.headers,
          fileName: fileName,
        );
      } else if (format.toLowerCase() == 'csv') {
        filePath = await ExportService.exportToCSV(
          records: recordsToExport,
          headers: _mainData!.headers,
          fileName: fileName,
        );
      }

      if (filePath != null) {
        _setStatusMessage(AppConstants.exportSuccess);
      } else {
        _setStatusMessage('Export failed');
      }

      return filePath;
    } catch (e) {
      _setStatusMessage('Export error: ${e.toString()}');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Update a cell value directly
  void updateCellValue(String recordId, String fieldName, dynamic value) {
    if (_mainData == null) return;

    final recordIndex = _mainData!.records.indexWhere((r) => r.id == recordId);
    if (recordIndex == -1) return;

    final updatedRecord =
        _mainData!.records[recordIndex].updateField(fieldName, value);
    final updatedRecords = List<ExcelRecord>.from(_mainData!.records);
    updatedRecords[recordIndex] = updatedRecord;

    _mainData = _mainData!.copyWith(records: updatedRecords);

    // Update processed records if they exist
    if (_processedRecords != null) {
      final processedIndex =
          _processedRecords!.indexWhere((r) => r.id == recordId);
      if (processedIndex != -1) {
        _processedRecords![processedIndex] = updatedRecord;
      }
    }

    notifyListeners();
  }

  /// Set view mode
  void setViewMode(ViewMode mode) {
    _currentViewMode = mode;
    notifyListeners();
  }

  /// Set search query
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  /// Toggle show only missing fields filter
  void toggleShowOnlyMissingFields() {
    _showOnlyMissingFields = !_showOnlyMissingFields;
    notifyListeners();
  }

  /// Set selected record for comparison
  void setSelectedRecord(String? recordId) {
    _selectedRecordId = recordId;
    notifyListeners();
  }

  /// Sort by column
  void sortByColumn(String columnName) {
    if (_sortColumn == columnName) {
      _sortAscending = !_sortAscending;
    } else {
      _sortColumn = columnName;
      _sortAscending = true;
    }
    notifyListeners();
  }

  /// Clear all data
  void clearAllData() {
    _mainData = null;
    _subDataList.clear();
    _clearReconciliationResults();
    _resetUIState();
    _setStatusMessage('All data cleared');
    notifyListeners();
  }

  /// Remove a sub file
  void removeSubFile(int index) {
    if (index >= 0 && index < _subDataList.length) {
      final fileName = _subDataList[index].fileName;
      _subDataList.removeAt(index);

      // Re-run reconciliation if we still have data
      if (hasMainData && hasSubData) {
        performReconciliation();
      } else {
        _clearReconciliationResults();
      }

      _setStatusMessage('Removed sub file: $fileName');
      notifyListeners();
    }
  }

  /// Get reconciliation summary
  Map<String, dynamic>? getReconciliationSummary() {
    if (_reconciliationResult == null) return null;
    return ReconciliationService.getReconciliationSummary(
        _reconciliationResult!);
  }

  /// Get suggestions for a specific record and field
  List<dynamic>? getSuggestionsForField(String recordId, String fieldName) {
    if (_reconciliationResult == null || _mainData == null) return null;

    final record = _mainData!.records.firstWhere((r) => r.id == recordId);
    final suggestions =
        _reconciliationResult!.suggestedFills[record.referenceValue];

    return suggestions?[fieldName];
  }

  /// Private helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setStatusMessage(String message) {
    _statusMessage = message;
    notifyListeners();
  }

  void _clearReconciliationResults() {
    _reconciliationResult = null;
    _processedRecords = null;
  }

  void _resetUIState() {
    _currentViewMode = ViewMode.table;
    _searchQuery = '';
    _showOnlyMissingFields = false;
    _selectedRecordId = null;
    _sortColumn = null;
    _sortAscending = true;
  }

  /// Get file preview before uploading
  Future<Map<String, dynamic>?> getFilePreview(String filePath) async {
    try {
      return await ExcelParserService.getExcelPreview(filePath);
    } catch (e) {
      return null;
    }
  }

  /// Validate file before processing
  Future<bool> validateFile(String filePath) async {
    return await ExcelParserService.validateExcelFile(filePath);
  }
}
