# ExSlate - Excel Reconciliation App

A comprehensive Flutter application for uploading, parsing, displaying, and reconciling Excel files with dynamic reference fields. Built as a scalable MVP ready for future AI integration.

## Features

### 📊 Core Functionality
- **Dynamic Excel Parsing**: Automatically extracts headers and data from first row
- **Reference Field Selection**: User chooses unique identifier fields for matching
- **Multi-File Reconciliation**: Match Main file with multiple Sub files
- **Smart Autofill**: Suggests values from Sub files for missing Main file fields
- **Real-time Validation**: Highlights missing values and reconciliation issues

### 🎯 User Interface
- **Responsive Design**: Optimized for desktop, tablet, and mobile
- **Table View**: Dynamic DataTable with sorting and filtering
- **Edit View**: Inline editing mode for missing values
- **Compare View**: Side-by-side Main vs Sub record comparison
- **Progress Tracking**: Visual indicators for completion status

### 🔧 Technical Features
- **State Management**: Provider pattern for reactive UI updates
- **File Export**: Save reconciled data as Excel or CSV
- **Search & Filter**: Find specific records and show missing fields only
- **Fuzzy Matching**: Intelligent matching using string similarity
- **Error Handling**: Comprehensive validation and user feedback

## Project Structure

```
lib/
├── main.dart                     # App entry point
├── core/                         # Utilities & constants
│   ├── constants.dart           # App constants and enums
│   ├── helpers.dart             # Utility functions
│   └── styles.dart              # Theming and responsive styles
├── models/                       # Data classes
│   └── record.dart              # ExcelRecord and related models
├── services/                     # Business logic
│   ├── excel_parser.dart        # Excel file parsing
│   ├── reconciliation.dart      # Matching and autofill logic
│   └── export_service.dart      # Export functionality
├── providers/                    # State management
│   └── data_provider.dart       # Main app state provider
├── views/                        # UI screens
│   ├── home_page.dart           # Main interface with tabs
│   ├── table_view.dart          # Data table display
│   ├── edit_view.dart           # Record editing interface
│   └── compare_view.dart        # Side-by-side comparison
└── widgets/                      # Reusable components
    ├── data_table_widget.dart   # Responsive data table
    ├── missing_value_highlight.dart # Visual indicators
    └── file_upload_button.dart  # File selection with preview
```

## Getting Started

### Prerequisites
- Flutter SDK (>=3.10.0)
- Dart SDK (>=3.0.0)
- Android Studio / VS Code

### Installation

1. **Clone and setup**
   ```bash
   flutter create exslate
   cd exslate
   ```

2. **Add dependencies** - Copy the contents of the provided `pubspec.yaml`

3. **Install packages**
   ```bash
   flutter pub get
   ```

4. **Copy source files** - Replace the default files with the provided source code

5. **Run the app**
   ```bash
   flutter run
   ```

## Usage Guide

### 1. Upload Main File
- Click "Upload Main File" on the welcome screen
- Select your primary Excel file (.xlsx or .xls)
- Choose a reference field from the dropdown (unique identifier)
- Review the file preview before confirming

### 2. Add Sub Files
- Click "Upload Sub File" to add supporting data
- Select the same reference field as used in Main file
- Multiple sub files can be added for comprehensive data enrichment

### 3. View and Edit Data
- **Table View**: See all records with sorting and search
- **Edit View**: Step through records with missing fields
- **Compare View**: Side-by-side comparison of matching records

### 4. Apply Suggestions
- Click on highlighted missing cells to see suggestions
- Use "Auto Fill" for individual records or bulk operations
- Manual editing available for custom values

### 5. Export Results
- Export reconciled data as Excel or CSV
- Includes metadata and completion statistics
- Highlighted cells show originally missing values that were filled

## Key Features Explained

### Dynamic Reference Fields
Unlike fixed-column systems, ExSlate lets users choose any column as the matching key, making it flexible for various data structures.

### Intelligent Reconciliation
- **Exact Matching**: Primary matching method using normalized strings
- **Fuzzy Matching**: Backup matching using Levenshtein distance
- **Multi-Source**: Combines data from multiple sub files
- **Conflict Resolution**: Shows all available options when conflicts exist

### Missing Value Detection
Automatically identifies empty, null, "N/A", and "-" values as missing data requiring attention.

### Scalability for AI Integration
The modular architecture supports future enhancements:
- Column mapping algorithms
- Smart field suggestions
- Automated data cleaning
- Pattern recognition for data quality

## Dependencies

```yaml
dependencies:
  flutter: sdk: flutter
  provider: ^6.1.1              # State management
  excel: ^4.0.3                 # Excel file parsing
  file_picker: ^6.1.1           # Cross-platform file selection
  path_provider: ^2.1.1         # File system access
  syncfusion_flutter_datagrid: ^24.1.41  # Advanced data tables
  collection: ^1.17.2           # Utility collections
```

## Architecture Decisions

### State Management
**Provider** was chosen for its simplicity and Flutter team support, making the codebase accessible to developers at all levels.

### File Processing
**Excel package** provides robust parsing capabilities with good cross-platform support for both .xlsx and .xls formats.

### UI Components
**Syncfusion DataGrid** offers advanced table features like sorting, filtering, and cell editing while maintaining performance with large datasets.

### Responsive Design
Mobile-first approach with breakpoint-based layouts ensures usability across all device sizes.

## Performance Considerations

- **Lazy Loading**: Large datasets are processed incrementally
- **Memory Management**: Files are processed in chunks when possible
- **UI Optimization**: Virtual scrolling for large tables
- **Async Operations**: All file operations are non-blocking

## Error Handling

- **File Validation**: Comprehensive format and structure checking
- **User Feedback**: Clear error messages and success indicators
- **Graceful Degradation**: App remains functional with partial data
- **Recovery Options**: Ability to retry failed operations

## Future AI Integration Points

The app is designed to support these AI enhancements:

1. **Smart Column Mapping**: Automatically suggest reference fields
2. **Fuzzy Data Matching**: ML-based similarity scoring
3. **Data Quality Assessment**: Intelligent validation rules
4. **Automated Suggestions**: Context-aware value recommendations
5. **Pattern Learning**: User behavior analysis for better UX

## Contributing

This is a Phase 1 MVP focused on core functionality. Future phases will expand capabilities based on user feedback and AI integration requirements.

## License

This project is licensed under the MIT License - see the LICENSE file for details.