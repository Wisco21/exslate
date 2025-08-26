import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/data_provider.dart';
import '../widgets/data_table_widget.dart';
import '../core/styles.dart';
import '../core/constants.dart';

/// Table view for displaying and filtering Excel data
class TableView extends StatefulWidget {
  const TableView({Key? key}) : super(key: key);

  @override
  State<TableView> createState() => _TableViewState();
}

class _TableViewState extends State<TableView> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final provider = Provider.of<DataProvider>(context, listen: false);
    provider.setSearchQuery(_searchController.text);
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

        return Column(
          children: [
            // Filter and search bar
            _buildFilterBar(provider),

            // Data table
            Expanded(
              child: provider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : DataTableWidget(
                      records: provider.displayRecords,
                      headers: provider.availableHeaders,
                      onCellTap: (recordId, fieldName) {
                        _handleCellTap(context, provider, recordId, fieldName);
                      },
                      onSort: (columnName) {
                        provider.sortByColumn(columnName);
                      },
                      sortColumn: provider.sortColumn,
                      sortAscending: provider.sortAscending,
                    ),
            ),

            // Bottom info bar
            _buildInfoBar(provider),
          ],
        );
      },
    );
  }

  Widget _buildFilterBar(DataProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey, width: 0.5),
        ),
      ),
      child: Column(
        children: [
          // Search bar
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Search records...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Filter toggle button
              FilterChip(
                label: const Text('Show Missing Only'),
                selected: provider.showOnlyMissingFields,
                onSelected: (_) => provider.toggleShowOnlyMissingFields(),
                backgroundColor: Colors.grey[200],
                selectedColor: AppColors.warning.withOpacity(0.3),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Quick stats
          Row(
            children: [
              _buildQuickStat(
                'Displaying: ${provider.displayRecords.length}',
                Icons.visibility,
              ),
              const SizedBox(width: 16),
              _buildQuickStat(
                'Total: ${provider.totalRecords}',
                Icons.dataset,
              ),
              const SizedBox(width: 16),
              _buildQuickStat(
                'With Missing: ${provider.recordsWithMissingFields}',
                Icons.warning,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStat(String text, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          text,
          style: AppStyles.captionTextStyle,
        ),
      ],
    );
  }

  Widget _buildInfoBar(DataProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: Colors.grey,
        border: Border(
          top: BorderSide(color: Colors.grey, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Text(
            'Records: ${provider.displayRecords.length} of ${provider.totalRecords}',
            style: AppStyles.captionTextStyle,
          ),
          const Spacer(),

          if (provider.hasReconciliationResults) ...[
            Text(
              'Reconciliation: ${provider.reconciliationResult!.matchedRecords.length} matches',
              style: AppStyles.captionTextStyle,
            ),
            const SizedBox(width: 16),
          ],

          // Clear filters button
          if (provider.searchQuery.isNotEmpty || provider.showOnlyMissingFields)
            TextButton.icon(
              onPressed: () {
                _searchController.clear();
                provider.setSearchQuery('');
                if (provider.showOnlyMissingFields) {
                  provider.toggleShowOnlyMissingFields();
                }
              },
              icon: const Icon(Icons.clear, size: 16),
              label: const Text('Clear Filters'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
            ),
        ],
      ),
    );
  }

  void _handleCellTap(
    BuildContext context,
    DataProvider provider,
    String recordId,
    String fieldName,
  ) {
    // Get suggestions for this field
    final suggestions = provider.getSuggestionsForField(recordId, fieldName);

    if (suggestions != null && suggestions.isNotEmpty) {
      _showSuggestionsDialog(
          context, provider, recordId, fieldName, suggestions);
    } else {
      _showEditDialog(context, provider, recordId, fieldName);
    }
  }

  void _showSuggestionsDialog(
    BuildContext context,
    DataProvider provider,
    String recordId,
    String fieldName,
    List<dynamic> suggestions,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Suggestions for $fieldName'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Choose a value to fill this field:'),
            const SizedBox(height: 12),
            ...suggestions.map((suggestion) => ListTile(
                  title: Text(suggestion.toString()),
                  onTap: () {
                    provider.applySuggestedFill(
                        recordId, fieldName, suggestion);
                    Navigator.of(context).pop();
                  },
                  trailing: const Icon(Icons.add),
                )),
            const Divider(),
            ListTile(
              title: const Text('Enter custom value...'),
              leading: const Icon(Icons.edit),
              onTap: () {
                Navigator.of(context).pop();
                _showEditDialog(context, provider, recordId, fieldName);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(
    BuildContext context,
    DataProvider provider,
    String recordId,
    String fieldName,
  ) {
    final record = provider.displayRecords.firstWhere((r) => r.id == recordId);
    final currentValue = record.getValue(fieldName)?.toString() ?? '';
    final controller = TextEditingController(text: currentValue);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit $fieldName'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Value',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              provider.updateCellValue(recordId, fieldName, controller.text);
              Navigator.of(context).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
