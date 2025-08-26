import 'package:exslate_app/models/record.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/data_provider.dart';
import '../core/styles.dart';
import '../core/constants.dart';

/// Edit view for inline editing of records with missing values
class EditView extends StatefulWidget {
  const EditView({Key? key}) : super(key: key);

  @override
  State<EditView> createState() => _EditViewState();
}

class _EditViewState extends State<EditView> {
  final ScrollController _scrollController = ScrollController();
  int _currentRecordIndex = 0;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DataProvider>(
      builder: (context, provider, child) {
        if (!provider.hasMainData) {
          return const Center(
            child: Text('No data to display. Upload a main file first.'),
          );
        }

        final recordsWithMissing =
            provider.displayRecords.where((r) => r.hasMissingFields).toList();

        if (recordsWithMissing.isEmpty) {
          return _buildNoMissingFieldsView();
        }

        return Column(
          children: [
            // Navigation header
            _buildNavigationHeader(recordsWithMissing.length),

            // Current record editor
            Expanded(
              child: _buildRecordEditor(provider, recordsWithMissing),
            ),

            // Navigation footer
            _buildNavigationFooter(recordsWithMissing.length),
          ],
        );
      },
    );
  }

  Widget _buildNoMissingFieldsView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle,
            size: 80,
            color: AppColors.success,
          ),
          const SizedBox(height: 16),
          Text(
            'All Fields Complete!',
            style: AppStyles.subHeaderTextStyle,
          ),
          const SizedBox(height: 8),
          Text(
            'No records have missing fields that need editing.',
            style: AppStyles.bodyTextStyle,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationHeader(int totalRecords) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Text(
            'Editing Record ${_currentRecordIndex + 1} of $totalRecords',
            style: AppStyles.subHeaderTextStyle,
          ),
          const Spacer(),

          // Progress indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '${((_currentRecordIndex + 1) / totalRecords * 100).round()}%',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordEditor(
      DataProvider provider, List<ExcelRecord> recordsWithMissing) {
    if (_currentRecordIndex >= recordsWithMissing.length) {
      _currentRecordIndex = 0;
    }

    final currentRecord = recordsWithMissing[_currentRecordIndex];
    final missingFields = currentRecord.getMissingFields();

    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Record identifier
          Container(
            padding: const EdgeInsets.all(16),
            decoration: AppStyles.cardDecoration,
            child: Row(
              children: [
                Icon(
                  Icons.person,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reference: ${currentRecord.referenceValue}',
                      style: AppStyles.subHeaderTextStyle,
                    ),
                    Text(
                      'Record ID: ${currentRecord.id}',
                      style: AppStyles.captionTextStyle,
                    ),
                  ],
                ),
                const Spacer(),

                // Auto-fill button for this record
                if (provider.hasReconciliationResults)
                  ElevatedButton.icon(
                    onPressed: () {
                      provider.applyAllSuggestedFills(currentRecord.id);
                    },
                    icon: const Icon(Icons.auto_fix_high),
                    label: const Text('Auto Fill'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Missing fields section
          Text(
            'Missing Fields (${missingFields.length})',
            style: AppStyles.subHeaderTextStyle.copyWith(
              color: AppColors.warning,
            ),
          ),
          const SizedBox(height: 12),

          ...missingFields.map((fieldName) =>
              _buildMissingFieldEditor(provider, currentRecord, fieldName)),

          const SizedBox(height: 24),

          // All fields section (for context)
          Text(
            'All Fields',
            style: AppStyles.subHeaderTextStyle,
          ),
          const SizedBox(height: 12),

          ...provider.availableHeaders.map((fieldName) =>
              _buildFieldViewer(provider, currentRecord, fieldName)),
        ],
      ),
    );
  }

  Widget _buildMissingFieldEditor(
      DataProvider provider, ExcelRecord record, String fieldName) {
    final suggestions = provider.getSuggestionsForField(record.id, fieldName);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: AppStyles.missingValueDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning,
                color: AppColors.warning,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                fieldName,
                style: AppStyles.bodyTextStyle.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Current value (should be empty/missing)
          TextField(
            decoration: InputDecoration(
              labelText: 'Enter value',
              hintText: 'This field is missing a value',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: const Icon(Icons.save),
                onPressed: () {
                  // Implementation handled by onSubmitted
                },
              ),
            ),
            onSubmitted: (value) {
              if (value.isNotEmpty) {
                provider.updateCellValue(record.id, fieldName, value);
              }
            },
          ),

          // Suggestions
          if (suggestions != null && suggestions.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Suggestions:',
              style: AppStyles.captionTextStyle.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: suggestions
                  .take(5)
                  .map(
                    (suggestion) => ActionChip(
                      label: Text(suggestion.toString()),
                      onPressed: () {
                        provider.applySuggestedFill(
                            record.id, fieldName, suggestion);
                      },
                      backgroundColor: AppColors.success.withOpacity(0.1),
                      side: BorderSide(color: AppColors.success),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFieldViewer(
      DataProvider provider, ExcelRecord record, String fieldName) {
    final value = record.getValue(fieldName);
    final isMissing = record.isFieldMissing(fieldName);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isMissing ? AppColors.missingValueBg : Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isMissing ? AppColors.missingValueBorder : Colors.grey[300]!,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              fieldName,
              style: AppStyles.bodyTextStyle.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value?.toString() ?? '(empty)',
              style: AppStyles.bodyTextStyle.copyWith(
                color: isMissing ? AppColors.error : null,
                fontStyle: isMissing ? FontStyle.italic : null,
              ),
            ),
          ),
          if (isMissing)
            Icon(
              Icons.error,
              color: AppColors.error,
              size: 16,
            ),
        ],
      ),
    );
  }

  Widget _buildNavigationFooter(int totalRecords) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          // Previous button
          ElevatedButton.icon(
            onPressed: _currentRecordIndex > 0 ? _previousRecord : null,
            icon: const Icon(Icons.arrow_back),
            label: const Text('Previous'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[600],
            ),
          ),

          const SizedBox(width: 16),

          // Progress bar
          Expanded(
            child: Column(
              children: [
                LinearProgressIndicator(
                  value: (_currentRecordIndex + 1) / totalRecords,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
                const SizedBox(height: 4),
                Text(
                  'Record ${_currentRecordIndex + 1} of $totalRecords',
                  style: AppStyles.captionTextStyle,
                ),
              ],
            ),
          ),

          const SizedBox(width: 16),

          // Next button
          ElevatedButton.icon(
            onPressed:
                _currentRecordIndex < totalRecords - 1 ? _nextRecord : null,
            icon: const Icon(Icons.arrow_forward),
            label: const Text('Next'),
          ),
        ],
      ),
    );
  }

  void _previousRecord() {
    if (_currentRecordIndex > 0) {
      setState(() {
        _currentRecordIndex--;
      });
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _nextRecord() {
    setState(() {
      _currentRecordIndex++;
    });
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }
}
