import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/data_provider.dart';
import '../models/record.dart';
import '../core/styles.dart';
import '../core/constants.dart';

/// Compare view for side-by-side comparison of Main vs Sub records
class CompareView extends StatefulWidget {
  const CompareView({Key? key}) : super(key: key);

  @override
  State<CompareView> createState() => _CompareViewState();
}

class _CompareViewState extends State<CompareView> {
  String? _selectedReferenceValue;

  @override
  Widget build(BuildContext context) {
    return Consumer<DataProvider>(
      builder: (context, provider, child) {
        if (!provider.hasMainData) {
          return const Center(
            child: Text('No data to display. Upload a main file first.'),
          );
        }

        if (!provider.hasSubData) {
          return _buildNoSubDataView();
        }

        return Column(
          children: [
            // Reference value selector
            _buildReferenceSelector(provider),

            // Comparison content
            Expanded(
              child: _selectedReferenceValue != null
                  ? _buildComparisonContent(provider)
                  : _buildSelectPrompt(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildNoSubDataView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.compare_arrows,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Sub Files Available',
            style: AppStyles.subHeaderTextStyle,
          ),
          const SizedBox(height: 8),
          Text(
            'Upload sub files to compare records with main data.',
            style: AppStyles.bodyTextStyle,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildReferenceSelector(DataProvider provider) {
    final referenceValues = provider.mainData!.referenceValues.toList()..sort();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey, width: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Record to Compare',
            style: AppStyles.subHeaderTextStyle,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _selectedReferenceValue,
            decoration: const InputDecoration(
              labelText: 'Reference Value',
              border: OutlineInputBorder(),
            ),
            items: referenceValues
                .map((ref) => DropdownMenuItem(
                      value: ref,
                      child: Text(ref),
                    ))
                .toList(),
            onChanged: (value) {
              setState(() {
                _selectedReferenceValue = value;
              });
            },
          ),
          if (_selectedReferenceValue != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.info,
                  size: 16,
                  color: Colors.blue[600],
                ),
                const SizedBox(width: 8),
                Text(
                  'Comparing record: $_selectedReferenceValue',
                  style: AppStyles.captionTextStyle.copyWith(
                    color: Colors.blue[600],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSelectPrompt() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.arrow_upward,
            size: 60,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Select a record above to compare',
            style: AppStyles.bodyTextStyle.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonContent(DataProvider provider) {
    final mainRecord =
        provider.mainData!.findByReference(_selectedReferenceValue!);
    if (mainRecord == null) {
      return const Center(
        child: Text('Main record not found'),
      );
    }

    // Find matching sub records
    final matchingSubRecords = <ExcelRecord>[];
    for (final subData in provider.subDataList) {
      final subRecord = subData.findByReference(_selectedReferenceValue!);
      if (subRecord != null) {
        matchingSubRecords.add(subRecord);
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary header
          _buildComparisonSummary(mainRecord, matchingSubRecords),
          const SizedBox(height: 24),

          // Field-by-field comparison
          _buildFieldComparison(provider, mainRecord, matchingSubRecords),
        ],
      ),
    );
  }

  Widget _buildComparisonSummary(
      ExcelRecord mainRecord, List<ExcelRecord> subRecords) {
    final missingFieldsCount = mainRecord.getMissingFields().length;
    final totalFields = mainRecord.data.keys.length;
    final completionPercentage =
        ((totalFields - missingFieldsCount) / totalFields * 100).round();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppStyles.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Comparison Summary',
            style: AppStyles.subHeaderTextStyle,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Main Record',
                  '${totalFields - missingFieldsCount}/$totalFields fields',
                  '$completionPercentage% complete',
                  AppColors.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryCard(
                  'Sub Records',
                  '${subRecords.length} matches found',
                  subRecords.isNotEmpty ? 'Data available' : 'No matches',
                  subRecords.isNotEmpty ? AppColors.success : AppColors.warning,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
      String title, String value, String subtitle, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppStyles.captionTextStyle.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppStyles.bodyTextStyle.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            subtitle,
            style: AppStyles.captionTextStyle,
          ),
        ],
      ),
    );
  }

  Widget _buildFieldComparison(
    DataProvider provider,
    ExcelRecord mainRecord,
    List<ExcelRecord> subRecords,
  ) {
    final headers = provider.availableHeaders;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Field Comparison',
          style: AppStyles.subHeaderTextStyle,
        ),
        const SizedBox(height: 12),

        // Table header
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  'Field Name',
                  style: AppStyles.bodyTextStyle
                      .copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  'Main Value',
                  style: AppStyles.bodyTextStyle
                      .copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  'Sub Values',
                  style: AppStyles.bodyTextStyle
                      .copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: Text(
                  'Action',
                  style: AppStyles.bodyTextStyle
                      .copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),

        // Field rows
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius:
                const BorderRadius.vertical(bottom: Radius.circular(8)),
          ),
          child: Column(
            children: headers
                .map((fieldName) => _buildFieldComparisonRow(
                    provider, mainRecord, subRecords, fieldName))
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildFieldComparisonRow(
    DataProvider provider,
    ExcelRecord mainRecord,
    List<ExcelRecord> subRecords,
    String fieldName,
  ) {
    final mainValue = mainRecord.getValue(fieldName);
    final isMissingInMain = mainRecord.isFieldMissing(fieldName);

    // Get values from sub records
    final subValues = <dynamic>[];
    for (final subRecord in subRecords) {
      final value = subRecord.getValue(fieldName);
      if (value != null &&
          !provider
                  .getSuggestionsForField(subRecord.id, fieldName)!
                  .contains(value) !=
              true) {
        if (!subValues.contains(value)) {
          subValues.add(value);
        }
      }
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isMissingInMain ? AppColors.missingValueBg : null,
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Row(
        children: [
          // Field name
          Expanded(
            flex: 2,
            child: Row(
              children: [
                if (isMissingInMain)
                  Icon(
                    Icons.warning,
                    color: AppColors.warning,
                    size: 16,
                  ),
                if (isMissingInMain) const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    fieldName,
                    style: AppStyles.bodyTextStyle.copyWith(
                      fontWeight: isMissingInMain ? FontWeight.bold : null,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Main value
          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isMissingInMain
                    ? AppColors.error.withOpacity(0.1)
                    : Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                mainValue?.toString() ?? '(empty)',
                style: AppStyles.bodyTextStyle.copyWith(
                  color: isMissingInMain ? AppColors.error : Colors.green[700],
                  fontStyle: isMissingInMain ? FontStyle.italic : null,
                ),
              ),
            ),
          ),

          // Sub values
          Expanded(
            flex: 3,
            child: subValues.isEmpty
                ? Text(
                    'No data',
                    style: AppStyles.captionTextStyle.copyWith(
                      color: Colors.grey[500],
                      fontStyle: FontStyle.italic,
                    ),
                  )
                : Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: subValues
                        .map((value) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.secondary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color:
                                        AppColors.secondary.withOpacity(0.3)),
                              ),
                              child: Text(
                                value.toString(),
                                style: AppStyles.captionTextStyle.copyWith(
                                  color: AppColors.secondary,
                                ),
                              ),
                            ))
                        .toList(),
                  ),
          ),

          // Action button
          Expanded(
            child: isMissingInMain && subValues.isNotEmpty
                ? PopupMenuButton<dynamic>(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Fill',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    itemBuilder: (context) => [
                      ...subValues.map((value) => PopupMenuItem(
                            value: value,
                            child: Text('Use: ${value.toString()}'),
                          )),
                    ],
                    onSelected: (value) {
                      provider.applySuggestedFill(
                          mainRecord.id, fieldName, value);
                    },
                  )
                : isMissingInMain
                    ? Icon(Icons.error, color: AppColors.error, size: 16)
                    : Icon(Icons.check, color: AppColors.success, size: 16),
          ),
        ],
      ),
    );
  }
}
