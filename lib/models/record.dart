/// Represents a single row from an Excel file
class ExcelRecord {
  final String id; // Unique identifier for this record
  final Map<String, dynamic> data; // Column name -> cell value mapping
  final String referenceValue; // Value of the reference field for matching
  final int originalRowIndex; // Original row number from Excel (0-based)

  ExcelRecord({
    required this.id,
    required this.data,
    required this.referenceValue,
    required this.originalRowIndex,
  });

  /// Create a copy of this record with updated data
  ExcelRecord copyWith({
    String? id,
    Map<String, dynamic>? data,
    String? referenceValue,
    int? originalRowIndex,
  }) {
    return ExcelRecord(
      id: id ?? this.id,
      data: data ?? Map<String, dynamic>.from(this.data),
      referenceValue: referenceValue ?? this.referenceValue,
      originalRowIndex: originalRowIndex ?? this.originalRowIndex,
    );
  }

  /// Update a specific field value
  ExcelRecord updateField(String fieldName, dynamic value) {
    final newData = Map<String, dynamic>.from(data);
    newData[fieldName] = value;
    return copyWith(data: newData);
  }

  /// Get value for a specific field
  dynamic getValue(String fieldName) {
    return data[fieldName];
  }

  /// Check if a field has a missing/empty value
  bool isFieldMissing(String fieldName) {
    final value = data[fieldName];
    if (value == null) return true;
    if (value is String) {
      final cleaned = value.trim();
      return cleaned.isEmpty ||
          cleaned.toLowerCase() == 'null' ||
          cleaned.toLowerCase() == 'n/a' ||
          cleaned == '-';
    }
    return false;
  }

  /// Get all missing field names
  List<String> getMissingFields() {
    return data.keys.where((key) => isFieldMissing(key)).toList();
  }

  /// Check if this record has any missing fields
  bool get hasMissingFields => getMissingFields().isNotEmpty;

  /// Convert to JSON for serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'data': data,
      'referenceValue': referenceValue,
      'originalRowIndex': originalRowIndex,
    };
  }

  /// Create from JSON
  factory ExcelRecord.fromJson(Map<String, dynamic> json) {
    return ExcelRecord(
      id: json['id'],
      data: Map<String, dynamic>.from(json['data']),
      referenceValue: json['referenceValue'],
      originalRowIndex: json['originalRowIndex'],
    );
  }

  @override
  String toString() {
    return 'ExcelRecord(id: $id, referenceValue: $referenceValue, data: $data)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ExcelRecord &&
        other.id == id &&
        other.referenceValue == referenceValue;
  }

  @override
  int get hashCode => id.hashCode ^ referenceValue.hashCode;
}

/// Represents the metadata and records from an Excel file
class ExcelFileData {
  final String fileName;
  final List<String> headers; // Column headers from first row
  final List<ExcelRecord> records; // Data rows
  final String referenceField; // Selected reference field for matching
  final DateTime uploadTime;

  ExcelFileData({
    required this.fileName,
    required this.headers,
    required this.records,
    required this.referenceField,
    DateTime? uploadTime,
  }) : uploadTime = uploadTime ?? DateTime.now();

  /// Get all unique reference values
  Set<String> get referenceValues {
    return records.map((r) => r.referenceValue).toSet();
  }

  /// Find record by reference value
  ExcelRecord? findByReference(String referenceValue) {
    try {
      return records.firstWhere((r) => r.referenceValue == referenceValue);
    } catch (e) {
      return null;
    }
  }

  /// Get records with missing fields
  List<ExcelRecord> get recordsWithMissingFields {
    return records.where((r) => r.hasMissingFields).toList();
  }

  /// Get statistics about the data
  Map<String, dynamic> getStatistics() {
    final totalRecords = records.length;
    final recordsWithMissing = recordsWithMissingFields.length;
    final completionPercentage = totalRecords > 0
        ? ((totalRecords - recordsWithMissing) / totalRecords * 100).round()
        : 0;

    final fieldMissingCounts = <String, int>{};
    for (final header in headers) {
      fieldMissingCounts[header] =
          records.where((r) => r.isFieldMissing(header)).length;
    }

    return {
      'totalRecords': totalRecords,
      'recordsWithMissing': recordsWithMissing,
      'completionPercentage': completionPercentage,
      'fieldMissingCounts': fieldMissingCounts,
    };
  }

  /// Create a copy with updated records
  ExcelFileData copyWith({
    String? fileName,
    List<String>? headers,
    List<ExcelRecord>? records,
    String? referenceField,
    DateTime? uploadTime,
  }) {
    return ExcelFileData(
      fileName: fileName ?? this.fileName,
      headers: headers ?? this.headers,
      records: records ?? this.records,
      referenceField: referenceField ?? this.referenceField,
      uploadTime: uploadTime ?? this.uploadTime,
    );
  }
}

/// Represents reconciliation results between Main and Sub files
class ReconciliationResult {
  final List<ExcelRecord> matchedRecords; // Records that have matches
  final List<ExcelRecord> unmatchedRecords; // Records without matches
  final Map<String, Map<String, List<dynamic>>>
      suggestedFills; // Reference -> field suggestions
  final Map<String, int> matchStatistics; // Various match statistics

  ReconciliationResult({
    required this.matchedRecords,
    required this.unmatchedRecords,
    required this.suggestedFills,
    required this.matchStatistics,
  });

  /// Get total number of records processed
  int get totalRecords => matchedRecords.length + unmatchedRecords.length;

  /// Get match percentage
  double get matchPercentage {
    if (totalRecords == 0) return 0;
    return (matchedRecords.length / totalRecords * 100);
  }

  /// Check if a record has suggested fills
  bool hasAnyRecordGotSuggestions(String referenceValue) {
    return suggestedFills.containsKey(referenceValue) &&
        suggestedFills[referenceValue]!.isNotEmpty;
  }
}
