import '../models/record.dart';
import '../core/helpers.dart';

/// Service for reconciling data between Main and Sub Excel files
class ReconciliationService {
  /// Reconcile Main file data with Sub file data
  static ReconciliationResult reconcileData({
    required ExcelFileData mainData,
    required List<ExcelFileData> subDataList,
  }) {
    final matchedRecords = <ExcelRecord>[];
    final unmatchedRecords = <ExcelRecord>[];
    final suggestedFills = <String, Map<String, List<dynamic>>>{};
    final matchStatistics = <String, int>{
      'totalMainRecords': mainData.records.length,
      'totalMatches': 0,
      'totalUnmatched': 0,
      'potentialFills': 0,
    };

    // Create a combined lookup map from all sub files
    final subLookup = <String, List<ExcelRecord>>{};
    for (final subData in subDataList) {
      for (final subRecord in subData.records) {
        final refValue = _normalizeReferenceValue(subRecord.referenceValue);
        subLookup.putIfAbsent(refValue, () => []).add(subRecord);
      }
    }

    // Process each main record
    for (final mainRecord in mainData.records) {
      final normalizedRef = _normalizeReferenceValue(mainRecord.referenceValue);
      final matchingSubRecords = subLookup[normalizedRef] ?? [];

      if (matchingSubRecords.isNotEmpty) {
        // Found matches - generate fill suggestions
        final suggestions = _generateFillSuggestions(
            mainRecord, matchingSubRecords, mainData.headers);

        matchedRecords.add(mainRecord);
        if (suggestions.isNotEmpty) {
          suggestedFills[mainRecord.referenceValue] = suggestions;
          matchStatistics['potentialFills'] =
              (matchStatistics['potentialFills'] ?? 0) + 1;
        }
      } else {
        // No exact matches found - try fuzzy matching
        final fuzzyMatches =
            _findFuzzyMatches(normalizedRef, subLookup.keys.toList());
        if (fuzzyMatches.isNotEmpty) {
          // Use best fuzzy match
          final bestMatch = fuzzyMatches.first;
          final matchingRecords = subLookup[bestMatch] ?? [];
          final suggestions = _generateFillSuggestions(
              mainRecord, matchingRecords, mainData.headers);

          matchedRecords.add(mainRecord);
          if (suggestions.isNotEmpty) {
            suggestedFills[mainRecord.referenceValue] = suggestions;
            matchStatistics['potentialFills'] =
                (matchStatistics['potentialFills'] ?? 0) + 1;
          }
        } else {
          unmatchedRecords.add(mainRecord);
        }
      }
    }

    matchStatistics['totalMatches'] = matchedRecords.length;
    matchStatistics['totalUnmatched'] = unmatchedRecords.length;

    return ReconciliationResult(
      matchedRecords: matchedRecords,
      unmatchedRecords: unmatchedRecords,
      suggestedFills: suggestedFills,
      matchStatistics: matchStatistics,
    );
  }

  /// Apply suggested fills to main records
  static List<ExcelRecord> applySuggestedFills({
    required List<ExcelRecord> mainRecords,
    required Map<String, Map<String, dynamic>> fillSuggestions,
  }) {
    final updatedRecords = <ExcelRecord>[];

    for (final record in mainRecords) {
      final suggestions = fillSuggestions[record.referenceValue];
      if (suggestions != null && suggestions.isNotEmpty) {
        var updatedRecord = record;

        // Apply each suggested fill
        for (final entry in suggestions.entries) {
          final fieldName = entry.key;
          final suggestedValue = entry.value;

          // Only fill if current field is missing/empty
          if (updatedRecord.isFieldMissing(fieldName)) {
            updatedRecord =
                updatedRecord.updateField(fieldName, suggestedValue);
          }
        }
        updatedRecords.add(updatedRecord);
      } else {
        updatedRecords.add(record);
      }
    }

    return updatedRecords;
  }

  /// Generate fill suggestions for a main record based on matching sub records
  static Map<String, List<dynamic>> _generateFillSuggestions(
    ExcelRecord mainRecord,
    List<ExcelRecord> matchingSubRecords,
    List<String> mainHeaders,
  ) {
    final suggestions = <String, List<dynamic>>{};

    // Check each field in main record for missing values
    for (final fieldName in mainHeaders) {
      if (mainRecord.isFieldMissing(fieldName)) {
        final possibleValues = <dynamic>[];

        // Collect non-empty values from matching sub records
        for (final subRecord in matchingSubRecords) {
          final subValue = subRecord.getValue(fieldName);
          if (subValue != null && !AppHelpers.isEmptyOrMissing(subValue)) {
            if (!possibleValues.contains(subValue)) {
              possibleValues.add(subValue);
            }
          }
        }

        if (possibleValues.isNotEmpty) {
          suggestions[fieldName] = possibleValues;
        }
      }
    }

    return suggestions;
  }

  /// Normalize reference value for consistent matching
  static String _normalizeReferenceValue(String value) {
    return AppHelpers.normalizeString(value);
  }

  /// Find fuzzy matches for reference values using simple string similarity
  static List<String> _findFuzzyMatches(
      String target, List<String> candidates) {
    final matches = <MapEntry<String, double>>[];

    for (final candidate in candidates) {
      final similarity = _calculateStringSimilarity(target, candidate);
      if (similarity > 0.8) {
        // 80% similarity threshold
        matches.add(MapEntry(candidate, similarity));
      }
    }

    // Sort by similarity score (descending)
    matches.sort((a, b) => b.value.compareTo(a.value));

    // Return top 3 matches
    return matches.take(3).map((e) => e.key).toList();
  }

  /// Calculate string similarity using Levenshtein distance
  static double _calculateStringSimilarity(String s1, String s2) {
    if (s1 == s2) return 1.0;
    if (s1.isEmpty || s2.isEmpty) return 0.0;

    final distance = _levenshteinDistance(s1, s2);
    final maxLength = s1.length > s2.length ? s1.length : s2.length;

    return 1.0 - (distance / maxLength);
  }

  /// Calculate Levenshtein distance between two strings
  static int _levenshteinDistance(String s1, String s2) {
    final len1 = s1.length;
    final len2 = s2.length;

    // Create matrix
    final matrix =
        List.generate(len1 + 1, (i) => List.generate(len2 + 1, (j) => 0));

    // Initialize first row and column
    for (int i = 0; i <= len1; i++) matrix[i][0] = i;
    for (int j = 0; j <= len2; j++) matrix[0][j] = j;

    // Fill matrix
    for (int i = 1; i <= len1; i++) {
      for (int j = 1; j <= len2; j++) {
        final cost = s1[i - 1] == s2[j - 1] ? 0 : 1;

        matrix[i][j] = [
          matrix[i - 1][j] + 1, // deletion
          matrix[i][j - 1] + 1, // insertion
          matrix[i - 1][j - 1] + cost, // substitution
        ].reduce((a, b) => a < b ? a : b);
      }
    }

    return matrix[len1][len2];
  }

  /// Get reconciliation summary statistics
  static Map<String, dynamic> getReconciliationSummary(
      ReconciliationResult result) {
    final totalRecords = result.totalRecords;
    final matchedCount = result.matchedRecords.length;
    final unmatchedCount = result.unmatchedRecords.length;
    final fillableCount = result.suggestedFills.length;

    return {
      'totalRecords': totalRecords,
      'matchedRecords': matchedCount,
      'unmatchedRecords': unmatchedCount,
      'matchPercentage':
          totalRecords > 0 ? (matchedCount / totalRecords * 100).round() : 0,
      'recordsWithSuggestions': fillableCount,
      'fillablePercentage':
          matchedCount > 0 ? (fillableCount / matchedCount * 100).round() : 0,
    };
  }

  /// Find records that can be auto-filled completely
  static List<ExcelRecord> findCompletelyFillableRecords({
    required List<ExcelRecord> mainRecords,
    required Map<String, Map<String, List<dynamic>>> suggestions,
  }) {
    final completelyFillable = <ExcelRecord>[];

    for (final record in mainRecords) {
      final recordSuggestions = suggestions[record.referenceValue];
      if (recordSuggestions == null) continue;

      final missingFields = record.getMissingFields();
      final canFillAll = missingFields.every((field) =>
          recordSuggestions.containsKey(field) &&
          recordSuggestions[field]!.isNotEmpty);

      if (canFillAll && missingFields.isNotEmpty) {
        completelyFillable.add(record);
      }
    }

    return completelyFillable;
  }

  /// Validate reconciliation data consistency
  static List<String> validateReconciliationData({
    required ExcelFileData mainData,
    required List<ExcelFileData> subDataList,
  }) {
    final issues = <String>[];

    // Check if reference field exists in all files
    for (final subData in subDataList) {
      if (!subData.headers.contains(mainData.referenceField)) {
        issues.add(
            'Reference field "${mainData.referenceField}" not found in ${subData.fileName}');
      }
    }

    // Check for duplicate reference values in main data
    final mainRefValues =
        mainData.records.map((r) => r.referenceValue).toList();
    final duplicates = <String>[];
    final seen = <String>{};

    for (final refValue in mainRefValues) {
      if (seen.contains(refValue)) {
        duplicates.add(refValue);
      } else {
        seen.add(refValue);
      }
    }

    if (duplicates.isNotEmpty) {
      issues.add(
          'Duplicate reference values found in main file: ${duplicates.take(5).join(", ")}');
    }

    // Check for empty reference values
    final emptyRefs =
        mainData.records.where((r) => r.referenceValue.trim().isEmpty).length;
    if (emptyRefs > 0) {
      issues.add('$emptyRefs records have empty reference values in main file');
    }

    return issues;
  }
}
