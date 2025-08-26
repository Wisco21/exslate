import 'package:flutter/material.dart';
import '../models/record.dart';
import '../core/constants.dart';
import '../core/styles.dart';

/// Reusable data table widget for displaying Excel records
class DataTableWidget extends StatefulWidget {
  final List<ExcelRecord> records;
  final List<String> headers;
  final Function(String recordId, String fieldName)? onCellTap;
  final Function(String columnName)? onSort;
  final String? sortColumn;
  final bool sortAscending;

  const DataTableWidget({
    Key? key,
    required this.records,
    required this.headers,
    this.onCellTap,
    this.onSort,
    this.sortColumn,
    this.sortAscending = true,
  }) : super(key: key);

  @override
  State<DataTableWidget> createState() => _DataTableWidgetState();
}

class _DataTableWidgetState extends State<DataTableWidget> {
  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();

  @override
  void dispose() {
    _horizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.records.isEmpty) {
      return _buildEmptyState();
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // Header
          _buildTableHeader(),

          // Body
          Expanded(
            child: _buildTableBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.table_chart,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No data to display',
            style: AppStyles.bodyTextStyle.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Scrollbar(
        controller: _horizontalController,
        scrollbarOrientation: ScrollbarOrientation.bottom,
        child: SingleChildScrollView(
          controller: _horizontalController,
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              // Row number header
              _buildHeaderCell('#', 60, false),

              // Data headers
              ...widget.headers.map((header) => _buildHeaderCell(
                  header, AppConstants.defaultColumnWidth, true)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCell(String text, double width, bool sortable) {
    final isCurrentSortColumn = widget.sortColumn == text;

    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: sortable
          ? InkWell(
              onTap: widget.onSort != null ? () => widget.onSort!(text) : null,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      text,
                      style: AppStyles.bodyTextStyle.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isCurrentSortColumn)
                    Icon(
                      widget.sortAscending
                          ? Icons.arrow_upward
                          : Icons.arrow_downward,
                      size: 16,
                      color: AppColors.primary,
                    ),
                ],
              ),
            )
          : Text(
              text,
              style: AppStyles.bodyTextStyle.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
    );
  }

  Widget _buildTableBody() {
    return Scrollbar(
      controller: _verticalController,
      child: SingleChildScrollView(
        controller: _verticalController,
        child: Column(
          children: widget.records.asMap().entries.map((entry) {
            final index = entry.key;
            final record = entry.value;
            return _buildTableRow(record, index);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildTableRow(ExcelRecord record, int index) {
    return Container(
      decoration: BoxDecoration(
        color: index.isEven ? Colors.white : Colors.grey[50],
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: IntrinsicHeight(
        child: SingleChildScrollView(
          controller: _horizontalController,
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              // Row number
              _buildRowNumberCell(index + 1),

              // Data cells
              ...widget.headers.map((header) => _buildDataCell(record, header)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRowNumberCell(int rowNumber) {
    return Container(
      width: 60,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(
          right: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Text(
        rowNumber.toString(),
        style: AppStyles.captionTextStyle.copyWith(
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildDataCell(ExcelRecord record, String header) {
    final value = record.getValue(header);
    final isMissing = record.isFieldMissing(header);

    return Container(
      width: AppConstants.defaultColumnWidth,
      constraints: const BoxConstraints(minHeight: 40),
      decoration: BoxDecoration(
        color: isMissing ? AppColors.missingValueBg : null,
        border: Border(
          right: BorderSide(color: Colors.grey[200]!),
          left: isMissing
              ? const BorderSide(color: AppColors.missingValueBorder, width: 3)
              : BorderSide.none,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onCellTap != null
              ? () => widget.onCellTap!(record.id, header)
              : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value?.toString() ?? '',
                    style: AppStyles.bodyTextStyle.copyWith(
                      color: isMissing ? AppColors.error : null,
                      fontStyle: isMissing ? FontStyle.italic : null,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
                if (isMissing)
                  Icon(
                    Icons.warning,
                    size: 16,
                    color: AppColors.warning,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
