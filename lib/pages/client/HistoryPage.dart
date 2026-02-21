import 'package:flutter/material.dart';

class HistoryPage extends StatefulWidget {
  @override
  _HistoryPageState createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  String _selectedFilter = 'All';
  String _searchQuery = '';

  // Simulated history data
  final List<Map<String, dynamic>> _historyItems = [
    {
      'id': '1',
      'user': 'John Doe',
      'action': 'Download',
      'details': 'Downloaded template MES01',
      'file': 'MES01_template.xlsx',
      'date': DateTime.now().subtract(Duration(hours: 2)),
      'status': 'Success',
      'icon': Icons.download,
      'color': Color(0xFF1e3a8a),
    },
    {
      'id': '2',
      'user': 'Jane Smith',
      'action': 'Upload',
      'details': 'Uploaded inventory data file',
      'file': 'inventory_data.xlsx',
      'date': DateTime.now().subtract(Duration(hours: 5)),
      'status': 'Success',
      'icon': Icons.cloud_upload,
      'color': Color(0xFF10b981),
    },
    {
      'id': '3',
      'user': 'Bob Johnson',
      'action': 'Processing',
      'details': 'Processing failed for production report',
      'file': 'production_report.xlsx',
      'date': DateTime.now().subtract(Duration(hours: 8)),
      'status': 'Failed',
      'icon': Icons.error,
      'color': Color(0xFFef4444),
    },
    {
      'id': '4',
      'user': 'Alice Williams',
      'action': 'Download',
      'details': 'Downloaded template MES02',
      'file': 'MES02_template.xlsx',
      'date': DateTime.now().subtract(Duration(days: 1)),
      'status': 'Success',
      'icon': Icons.download,
      'color': Color(0xFF1e3a8a),
    },
    {
      'id': '5',
      'user': 'John Doe',
      'action': 'Upload',
      'details': 'Uploaded sales data file',
      'file': 'sales_Q4_2024.xlsx',
      'date': DateTime.now().subtract(Duration(days: 1, hours: 3)),
      'status': 'Success',
      'icon': Icons.cloud_upload,
      'color': Color(0xFF10b981),
    },
    {
      'id': '6',
      'user': 'Sarah Davis',
      'action': 'Processing',
      'details': 'Successfully processed HR data',
      'file': 'hr_employee_data.xlsx',
      'date': DateTime.now().subtract(Duration(days: 2)),
      'status': 'Success',
      'icon': Icons.check_circle,
      'color': Color(0xFF10b981),
    },
    {
      'id': '7',
      'user': 'Mike Brown',
      'action': 'Download',
      'details': 'Downloaded template MES03',
      'file': 'MES03_template.xlsx',
      'date': DateTime.now().subtract(Duration(days: 2, hours: 5)),
      'status': 'Success',
      'icon': Icons.download,
      'color': Color(0xFF1e3a8a),
    },
    {
      'id': '8',
      'user': 'Emma Wilson',
      'action': 'Upload',
      'details': 'Uploaded customer feedback data',
      'file': 'customer_feedback.xlsx',
      'date': DateTime.now().subtract(Duration(days: 3)),
      'status': 'Pending',
      'icon': Icons.pending,
      'color': Color(0xFFf59e0b),
    },
    {
      'id': '9',
      'user': 'John Doe',
      'action': 'Processing',
      'details': 'Processing completed for monthly report',
      'file': 'monthly_report_jan.xlsx',
      'date': DateTime.now().subtract(Duration(days: 4)),
      'status': 'Success',
      'icon': Icons.check_circle,
      'color': Color(0xFF10b981),
    },
    {
      'id': '10',
      'user': 'Lisa Anderson',
      'action': 'Download',
      'details': 'Downloaded template MES01',
      'file': 'MES01_template.xlsx',
      'date': DateTime.now().subtract(Duration(days: 5)),
      'status': 'Success',
      'icon': Icons.download,
      'color': Color(0xFF1e3a8a),
    },
  ];

  List<Map<String, dynamic>> get _filteredHistory {
    List<Map<String, dynamic>> filtered = _historyItems;

    // Filter by action type
    if (_selectedFilter != 'All') {
      filtered = filtered.where((item) => item['action'] == _selectedFilter).toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((item) {
        return item['user'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
            item['details'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
            item['file'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Sort by date (most recent first)
    filtered.sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Activity History',
          style: TextStyle(
            color: colorScheme.onSurface,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: OutlinedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Export feature coming soon'),
                    backgroundColor: colorScheme.primary,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
              },
              icon: Icon(Icons.download, size: 18),
              label: Text('Export'),
              style: OutlinedButton.styleFrom(
                foregroundColor: colorScheme.primary,
                side: BorderSide(color: colorScheme.primary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Section
          Container(
            color: colorScheme.surface,
            padding: EdgeInsets.all(isDesktop ? 24 : 16),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  onChanged: (value) => setState(() => _searchQuery = value),
                  style: TextStyle(color: colorScheme.onSurface),
                  decoration: InputDecoration(
                    hintText: 'Search by user, action, or file name...',
                    hintStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.5)),
                    prefixIcon: Icon(Icons.search, color: colorScheme.onSurface.withOpacity(0.5)),
                    filled: true,
                    fillColor: theme.brightness == Brightness.light
                        ? Color(0xFFf8fafc)
                        : colorScheme.surface.withOpacity(0.5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
                SizedBox(height: 16),

                // Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All'),
                      SizedBox(width: 8),
                      _buildFilterChip('Download'),
                      SizedBox(width: 8),
                      _buildFilterChip('Upload'),
                      SizedBox(width: 8),
                      _buildFilterChip('Processing'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Stats Summary
          Container(
            padding: EdgeInsets.symmetric(horizontal: isDesktop ? 24 : 16, vertical: 16),
            child: Row(
              children: [
                _buildStatBadge('${_filteredHistory.length}', 'Total Actions', colorScheme.primary),
                SizedBox(width: 12),
                _buildStatBadge(
                  '${_filteredHistory.where((item) => item['status'] == 'Success').length}',
                  'Successful',
                  Color(0xFF10b981),
                ),
                SizedBox(width: 12),
                _buildStatBadge(
                  '${_filteredHistory.where((item) => item['status'] == 'Failed').length}',
                  'Failed',
                  colorScheme.error,
                ),
              ],
            ),
          ),

          // History List
          Expanded(
            child: _filteredHistory.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: isDesktop ? 24 : 16, vertical: 8),
              itemCount: _filteredHistory.length,
              itemBuilder: (context, index) {
                final item = _filteredHistory[index];
                return _buildHistoryCard(item, isDesktop);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSelected = _selectedFilter == label;

    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? colorScheme.primary : colorScheme.onSurface.withOpacity(0.6),
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _selectedFilter = selected ? label : 'All');
      },
      backgroundColor: colorScheme.surface,
      selectedColor: colorScheme.primary.withOpacity(0.1),
      checkmarkColor: colorScheme.primary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isSelected ? colorScheme.primary : theme.dividerColor,
        ),
      ),
    );
  }

  Widget _buildStatBadge(String value, String label, Color color) {
    final theme = Theme.of(context);

    return Expanded(
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: theme.brightness == Brightness.light
                    ? Color(0xFF64748b)
                    : Colors.white.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> item, bool isDesktop) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final date = item['date'] as DateTime;
    final timeAgo = _getTimeAgo(date);

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
        boxShadow: [
          BoxShadow(
            color: theme.brightness == Brightness.light
                ? Colors.black.withOpacity(0.02)
                : Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _showDetailsDialog(item),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (item['color'] as Color).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  item['icon'] as IconData,
                  color: item['color'] as Color,
                  size: 24,
                ),
              ),
              SizedBox(width: 16),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item['details'] as String,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                        _buildStatusBadge(item['status'] as String),
                      ],
                    ),
                    SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.person_outline, size: 14, color: colorScheme.onSurface.withOpacity(0.5)),
                        SizedBox(width: 4),
                        Text(
                          item['user'] as String,
                          style: TextStyle(fontSize: 13, color: colorScheme.onSurface.withOpacity(0.6)),
                        ),
                        SizedBox(width: 16),
                        Icon(Icons.insert_drive_file_outlined, size: 14, color: colorScheme.onSurface.withOpacity(0.5)),
                        SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            item['file'] as String,
                            style: TextStyle(fontSize: 13, color: colorScheme.onSurface.withOpacity(0.6)),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 14, color: colorScheme.onSurface.withOpacity(0.5)),
                        SizedBox(width: 4),
                        Text(
                          timeAgo,
                          style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withOpacity(0.5)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Arrow
              Icon(Icons.chevron_right, color: theme.dividerColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final theme = Theme.of(context);
    Color color;
    IconData icon;

    switch (status) {
      case 'Success':
        color = Color(0xFF10b981);
        icon = Icons.check_circle;
        break;
      case 'Failed':
        color = theme.colorScheme.error;
        icon = Icons.error;
        break;
      case 'Pending':
        color = Color(0xFFf59e0b);
        icon = Icons.pending;
        break;
      default:
        color = theme.colorScheme.onSurface.withOpacity(0.5);
        icon = Icons.info;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          SizedBox(width: 4),
          Text(
            status,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 80,
            color: theme.dividerColor,
          ),
          SizedBox(height: 16),
          Text(
            'No history found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty
                ? 'Try adjusting your search'
                : 'Activity history will appear here',
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  String _getTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 7) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  void _showDetailsDialog(Map<String, dynamic> item) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: colorScheme.surface,
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (item['color'] as Color).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(item['icon'] as IconData, color: item['color'] as Color, size: 24),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Action Details',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Action Type', item['action'] as String),
            SizedBox(height: 12),
            _buildDetailRow('User', item['user'] as String),
            SizedBox(height: 12),
            _buildDetailRow('File Name', item['file'] as String),
            SizedBox(height: 12),
            _buildDetailRow('Details', item['details'] as String),
            SizedBox(height: 12),
            _buildDetailRow('Status', item['status'] as String),
            SizedBox(height: 12),
            _buildDetailRow('Date & Time', _getTimeAgo(item['date'] as DateTime)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(color: colorScheme.primary)),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: colorScheme.onSurface.withOpacity(0.6),
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}