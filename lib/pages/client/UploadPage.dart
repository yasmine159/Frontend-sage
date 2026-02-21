import 'package:flutter/material.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';

class UploadPage extends StatefulWidget {
  @override
  _UploadPageState createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage> with SingleTickerProviderStateMixin {
  File? selectedFile;
  bool isUploading = false;
  double uploadProgress = 0.0;
  String? uploadStatus;
  late AnimationController _animationController;

  // Recent uploads (mock data)
  final List<Map<String, dynamic>> recentUploads = [
    {
      'name': 'inventory_data_jan.xlsx',
      'date': '2 hours ago',
      'status': 'Success',
      'size': '2.4 MB',
      'icon': Icons.check_circle,
      'color': Color(0xFF10b981),
    },
    {
      'name': 'production_report.xlsx',
      'date': 'Yesterday',
      'status': 'Success',
      'size': '1.8 MB',
      'icon': Icons.check_circle,
      'color': Color(0xFF10b981),
    },
    {
      'name': 'quality_metrics.xlsx',
      'date': '2 days ago',
      'status': 'Failed',
      'size': '3.1 MB',
      'icon': Icons.error,
      'color': Color(0xFFef4444),
    },
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _selectFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
    );

    if (result != null) {
      setState(() {
        selectedFile = File(result.files.single.path!);
        uploadStatus = null;
      });
    }
  }

  Future<void> _uploadFile() async {
    if (selectedFile == null) return;

    setState(() {
      isUploading = true;
      uploadProgress = 0.0;
      uploadStatus = null;
    });

    // Simulate upload with progress
    for (int i = 0; i <= 100; i += 10) {
      await Future.delayed(Duration(milliseconds: 200));
      setState(() {
        uploadProgress = i / 100;
      });
    }

    // Simulate processing
    await Future.delayed(Duration(seconds: 1));

    setState(() {
      isUploading = false;
      uploadStatus = 'success';
    });

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Expanded(
              child: Text('File uploaded successfully!'),
            ),
          ],
        ),
        backgroundColor: Color(0xFF10b981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.all(16),
      ),
    );

    // Reset after delay
    Future.delayed(Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          selectedFile = null;
          uploadStatus = null;
          uploadProgress = 0.0;
        });
      }
    });
  }

  void _removeFile() {
    setState(() {
      selectedFile = null;
      uploadStatus = null;
      uploadProgress = 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.scaffoldBackgroundColor,
              theme.brightness == Brightness.light
                  ? Color(0xFFe2e8f0)
                  : Color(0xFF0F172A),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildCustomAppBar(context),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoBanner(),
                      SizedBox(height: 24),
                      _buildUploadArea(),
                      if (selectedFile != null) ...[
                        SizedBox(height: 24),
                        _buildFilePreview(),
                      ],
                      if (isUploading) ...[
                        SizedBox(height: 24),
                        _buildProgressIndicator(),
                      ],
                      SizedBox(height: 32),
                      _buildRecentUploads(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomAppBar(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: theme.brightness == Brightness.light
                ? Colors.black12
                : Colors.black54,
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
            onPressed: () => Navigator.pop(context),
          ),
          SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Upload File',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              Text(
                'Import your Excel data',
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
          Spacer(),
          IconButton(
            icon: Icon(Icons.help_outline, color: colorScheme.primary),
            onPressed: () => _showHelpDialog(),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBanner() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.primary.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: colorScheme.primary),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Accepted File Formats',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Excel files (.xlsx, .xls) up to 10MB',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadArea() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: isUploading ? null : _selectFile,
      child: Container(
        padding: EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selectedFile != null
                ? colorScheme.primary
                : theme.dividerColor,
            width: 2,
            style: BorderStyle.solid,
          ),
          boxShadow: [
            BoxShadow(
              color: colorScheme.primary.withOpacity(0.1),
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.cloud_upload_rounded,
                size: 64,
                color: colorScheme.primary,
              ),
            ),
            SizedBox(height: 20),
            Text(
              selectedFile == null
                  ? 'Tap to select Excel file'
                  : 'File selected',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 8),
            Text(
              selectedFile == null
                  ? 'or drag and drop your file here'
                  : 'Tap to change file',
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            if (selectedFile == null) ...[
              SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: isUploading ? null : _selectFile,
                icon: Icon(Icons.folder_open),
                label: Text('Browse Files'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFilePreview() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final fileName = selectedFile!.path.split('/').last;
    final fileSize = (selectedFile!.lengthSync() / (1024 * 1024)).toStringAsFixed(2);

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.brightness == Brightness.light
                ? Colors.black12
                : Colors.black54,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Color(0xFF10b981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.insert_drive_file,
                  color: Color(0xFF10b981),
                  size: 32,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fileName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    Text(
                      '$fileSize MB',
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              if (!isUploading)
                IconButton(
                  icon: Icon(Icons.close, color: colorScheme.error),
                  onPressed: _removeFile,
                ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: isUploading ? null : _uploadFile,
                  icon: Icon(Icons.upload_rounded),
                  label: Text('Upload File'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: isUploading ? null : _selectFile,
                icon: Icon(Icons.refresh),
                label: Text('Change'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colorScheme.primary,
                  padding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: BorderSide(color: colorScheme.primary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.brightness == Brightness.light
                ? Colors.black12
                : Colors.black54,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: colorScheme.primary,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Uploading file...',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '${(uploadProgress * 100).toInt()}% complete',
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: uploadProgress,
              minHeight: 8,
              backgroundColor: theme.brightness == Brightness.light
                  ? Color(0xFFf1f5f9)
                  : colorScheme.surface.withOpacity(0.5),
              color: colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentUploads() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Uploads',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            TextButton(
              onPressed: () {
                // TODO: Navigate to full history
              },
              child: Text(
                'View All',
                style: TextStyle(color: colorScheme.primary),
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        ...recentUploads.map((upload) => _buildUploadHistoryItem(upload)),
      ],
    );
  }

  Widget _buildUploadHistoryItem(Map<String, dynamic> upload) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.brightness == Brightness.light
                ? Colors.black12
                : Colors.black54,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (upload['color'] as Color).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              upload['icon'] as IconData,
              color: upload['color'] as Color,
              size: 24,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  upload['name'],
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      upload['date'],
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      '•',
                      style: TextStyle(color: colorScheme.onSurface.withOpacity(0.5)),
                    ),
                    SizedBox(width: 8),
                    Text(
                      upload['size'],
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: (upload['color'] as Color).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              upload['status'],
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: upload['color'] as Color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: colorScheme.surface,
        title: Row(
          children: [
            Icon(Icons.help, color: colorScheme.primary),
            SizedBox(width: 8),
            Text(
              'Upload Help',
              style: TextStyle(color: colorScheme.onSurface),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'How to upload files:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                )
            ),
            SizedBox(height: 8),
            _buildHelpItem('1. Select an Excel file (.xlsx or .xls)'),
            _buildHelpItem('2. Preview the file details'),
            _buildHelpItem('3. Click "Upload File" to import'),
            _buildHelpItem('4. Wait for processing to complete'),
            SizedBox(height: 12),
            Text(
                'File should be:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                )
            ),
            SizedBox(height: 8),
            _buildHelpItem('• In Excel format'),
            _buildHelpItem('• Less than 10MB'),
            _buildHelpItem('• Properly formatted'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Got it',
              style: TextStyle(color: colorScheme.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpItem(String text) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          color: colorScheme.onSurface.withOpacity(0.7),
        ),
      ),
    );
  }
}