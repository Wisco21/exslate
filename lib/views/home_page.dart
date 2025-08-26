import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/data_provider.dart';
import '../widgets/file_upload_button.dart';
import '../core/constants.dart';
import '../core/styles.dart';
import '../core/helpers.dart';
import 'table_view.dart';
import 'compare_view.dart';
import 'edit_view.dart';

/// Main home page with upload functionality and navigation
class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            const Text(AppConstants.appTitle),
            Text(
              AppConstants.appSubtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ],
        ),
        actions: [
          Consumer<DataProvider>(
            builder: (context, provider, child) {
              if (!provider.hasMainData) return const SizedBox.shrink();

              return PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) => _handleMenuAction(context, value),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'export_excel',
                    child: ListTile(
                      leading: Icon(Icons.table_chart),
                      title: Text('Export as Excel'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'export_csv',
                    child: ListTile(
                      leading: Icon(Icons.description),
                      title: Text('Export as CSV'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'clear_all',
                    child: ListTile(
                      leading: Icon(Icons.clear_all),
                      title: Text('Clear All Data'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: Consumer<DataProvider>(
        builder: (context, provider, child) {
          return Column(
            children: [
              // Status bar
              if (provider.statusMessage.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  color: provider.isLoading
                      ? AppColors.warning
                      : AppColors.success,
                  child: Row(
                    children: [
                      if (provider.isLoading)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                      if (provider.isLoading) const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          provider.statusMessage,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),

              // Main content
              Expanded(
                child: provider.hasMainData
                    ? _buildMainContent(context, provider)
                    : _buildWelcomeScreen(context),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildWelcomeScreen(BuildContext context) {
    return SingleChildScrollView(
      padding:
          AppStyles.getResponsivePadding(MediaQuery.of(context).size.width),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 40),

          // Welcome header
          const Icon(
            Icons.upload_file,
            size: 80,
            color: AppColors.primary,
          ),
          const SizedBox(height: 24),

          Text(
            'Welcome to ${AppConstants.appTitle}',
            style: AppStyles.headerTextStyle,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          Text(
            'Upload your Excel files to start reconciliation',
            style: AppStyles.bodyTextStyle.copyWith(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),

          // Upload section
          Container(
            padding: const EdgeInsets.all(24),
            decoration: AppStyles.cardDecoration,
            child: Column(
              children: [
                Text(
                  'Get Started',
                  style: AppStyles.subHeaderTextStyle,
                ),
                const SizedBox(height: 16),
                Text(
                  'Upload your main Excel file to begin. You can then add sub files for reconciliation.',
                  style: AppStyles.bodyTextStyle,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FileUploadButton(
                  label: AppConstants.uploadMainLabel,
                  onFileSelected: (filePath, referenceField) {
                    _uploadMainFile(context, filePath, referenceField);
                  },
                  isPrimary: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Instructions
          _buildInstructions(),
        ],
      ),
    );
  }

  Widget _buildMainContent(BuildContext context, DataProvider provider) {
    return Column(
      children: [
        // Summary cards
        _buildSummaryCards(provider),

        // Tab bar
        Container(
          color: Colors.grey[100],
          child: TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: Colors.grey[600],
            indicatorColor: AppColors.primary,
            tabs: const [
              Tab(
                icon: Icon(Icons.table_chart),
                text: 'Table View',
              ),
              Tab(
                icon: Icon(Icons.edit),
                text: 'Edit View',
              ),
              Tab(
                icon: Icon(Icons.compare),
                text: 'Compare',
              ),
            ],
          ),
        ),

        // Tab content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              const TableView(),
              const EditView(),
              const CompareView(),
            ],
          ),
        ),

        // Action buttons
        _buildActionButtons(context, provider),
      ],
    );
  }

  Widget _buildSummaryCards(DataProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryCard(
              'Total Records',
              provider.totalRecords.toString(),
              Icons.dataset,
              AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSummaryCard(
              'Missing Fields',
              provider.recordsWithMissingFields.toString(),
              Icons.warning,
              AppColors.warning,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSummaryCard(
              'Sub Files',
              provider.subDataList.length.toString(),
              Icons.file_copy,
              AppColors.secondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppStyles.cardDecoration,
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: AppStyles.captionTextStyle,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, DataProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Add Sub File button
          Expanded(
            child: FileUploadButton(
              label: AppConstants.uploadSubLabel,
              onFileSelected: (filePath, referenceField) {
                _uploadSubFile(context, filePath, referenceField);
              },
              isPrimary: false,
            ),
          ),
          const SizedBox(width: 12),

          // Reconcile button
          if (provider.hasSubData)
            Expanded(
              child: ElevatedButton.icon(
                onPressed: provider.isLoading
                    ? null
                    : () {
                        provider.performReconciliation();
                      },
                icon: const Icon(Icons.sync),
                label: const Text('Reconcile'),
              ),
            ),

          // Auto-fill button
          if (provider.hasReconciliationResults) ...[
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: provider.isLoading
                    ? null
                    : () {
                        _showAutoFillDialog(context, provider);
                      },
                icon: const Icon(Icons.auto_fix_high),
                label: const Text('Auto Fill'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInstructions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info, color: Colors.blue[700]),
              const SizedBox(width: 8),
              Text(
                'How it works',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInstructionStep(
            '1.',
            'Upload your main Excel file and select a reference field for matching',
          ),
          _buildInstructionStep(
            '2.',
            'Add sub files containing additional data to fill missing values',
          ),
          _buildInstructionStep(
            '3.',
            'Review reconciliation results and apply suggested fills',
          ),
          _buildInstructionStep(
            '4.',
            'Export your completed dataset as Excel or CSV',
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: AppStyles.bodyTextStyle,
            ),
          ),
        ],
      ),
    );
  }

  void _uploadMainFile(
      BuildContext context, String filePath, String referenceField) async {
    final provider = Provider.of<DataProvider>(context, listen: false);
    final success = await provider.uploadMainFile(
      filePath: filePath,
      referenceField: referenceField,
    );

    if (success && mounted) {
      AppHelpers.showSnackBar(context, AppConstants.fileUploadSuccess);
    }
  }

  void _uploadSubFile(
      BuildContext context, String filePath, String referenceField) async {
    final provider = Provider.of<DataProvider>(context, listen: false);
    final success = await provider.uploadSubFile(
      filePath: filePath,
      referenceField: referenceField,
    );

    if (success && mounted) {
      AppHelpers.showSnackBar(context, 'Sub file added successfully');
    }
  }

  void _handleMenuAction(BuildContext context, String action) async {
    final provider = Provider.of<DataProvider>(context, listen: false);

    switch (action) {
      case 'export_excel':
        final filePath = await provider.exportData(format: 'excel');
        if (filePath != null && mounted) {
          AppHelpers.showSnackBar(context, 'Exported to: $filePath');
        }
        break;
      case 'export_csv':
        final filePath = await provider.exportData(format: 'csv');
        if (filePath != null && mounted) {
          AppHelpers.showSnackBar(context, 'Exported to: $filePath');
        }
        break;
      case 'clear_all':
        final confirmed = await AppHelpers.showConfirmationDialog(
          context,
          'Clear All Data',
          'Are you sure you want to clear all uploaded data? This action cannot be undone.',
        );
        if (confirmed) {
          provider.clearAllData();
          AppHelpers.showSnackBar(context, 'All data cleared');
        }
        break;
    }
  }

  void _showAutoFillDialog(BuildContext context, DataProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Auto Fill Missing Values'),
        content: const Text(
            'This will automatically fill all missing values using suggestions from sub files. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              provider.applyAllSuggestedFillsBulk();
            },
            child: const Text('Apply All'),
          ),
        ],
      ),
    );
  }
}
