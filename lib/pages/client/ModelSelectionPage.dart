import 'package:flutter/material.dart';

class ModelSelectionPage extends StatefulWidget {
  @override
  _ModelSelectionPageState createState() => _ModelSelectionPageState();
}

class _ModelSelectionPageState extends State<ModelSelectionPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';

  // Extended model data with more details
  final List<Map<String, dynamic>> models = [
    {
      'id': 'MES01',
      'name': 'Manufacturing Execution',
      'description': 'Template for manufacturing execution data',
      'category': 'Manufacturing',
      'fields': 25,
      'icon': Icons.precision_manufacturing,
      'color': Color(0xFF1e3a8a),
      'version': '2.1',
    },
    {
      'id': 'MES02',
      'name': 'Quality Control',
      'description': 'Quality assurance and control template',
      'category': 'Quality',
      'fields': 18,
      'icon': Icons.verified,
      'color': Color(0xFF10b981),
      'version': '1.8',
    },
    {
      'id': 'MES03',
      'name': 'Inventory Management',
      'description': 'Stock and inventory tracking template',
      'category': 'Inventory',
      'fields': 32,
      'icon': Icons.inventory_2,
      'color': Color(0xFF0ea5e9),
      'version': '3.0',
    },
    {
      'id': 'MES04',
      'name': 'Production Planning',
      'description': 'Plan and schedule production operations',
      'category': 'Manufacturing',
      'fields': 28,
      'icon': Icons.calendar_today,
      'color': Color(0xFF64748b),
      'version': '2.5',
    },
    {
      'id': 'MES05',
      'name': 'Supply Chain',
      'description': 'Supply chain management data',
      'category': 'Logistics',
      'fields': 22,
      'icon': Icons.local_shipping,
      'color': Color(0xFFf59e0b),
      'version': '1.9',
    },
    {
      'id': 'MES06',
      'name': 'Asset Management',
      'description': 'Track and manage company assets',
      'category': 'Assets',
      'fields': 20,
      'icon': Icons.business_center,
      'color': Color(0xFFef4444),
      'version': '2.2',
    },
  ];

  List<String> get categories {
    final cats = models.map((m) => m['category'] as String).toSet().toList();
    cats.insert(0, 'All');
    return cats;
  }

  List<Map<String, dynamic>> get filteredModels {
    return models.where((model) {
      final matchesSearch = _searchQuery.isEmpty ||
          model['id'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
          model['name'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
          model['description'].toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesCategory = _selectedCategory == 'All' ||
          model['category'] == _selectedCategory;

      return matchesSearch && matchesCategory;
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
              _buildSearchBar(),
              _buildCategoryFilter(),
              _buildModelCount(),
              Expanded(
                child: _buildModelList(),
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
                'Select Model',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              Text(
                'Choose a template to download',
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
          Spacer(),
          IconButton(
            icon: Icon(Icons.info_outline, color: colorScheme.primary),
            onPressed: () => _showInfoDialog(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.all(20),
      child: Container(
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
        child: TextField(
          controller: _searchController,
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
          style: TextStyle(color: colorScheme.onSurface),
          decoration: InputDecoration(
            hintText: 'Search models...',
            hintStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.5)),
            prefixIcon: Icon(Icons.search, color: colorScheme.primary),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
              icon: Icon(Icons.clear, color: colorScheme.onSurface.withOpacity(0.5)),
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                });
              },
            )
                : null,
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      height: 50,
      margin: EdgeInsets.only(bottom: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 20),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = _selectedCategory == category;

          return Padding(
            padding: EdgeInsets.only(right: 12),
            child: FilterChip(
              label: Text(
                category,
                style: TextStyle(
                  color: isSelected ? Colors.white : colorScheme.onSurface.withOpacity(0.6),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedCategory = category;
                });
              },
              backgroundColor: colorScheme.surface,
              selectedColor: colorScheme.primary,
              checkmarkColor: Colors.white,
              elevation: 2,
              shadowColor: Colors.black26,
            ),
          );
        },
      ),
    );
  }

  Widget _buildModelCount() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          Text(
            '${filteredModels.length} ${filteredModels.length == 1 ? 'Template' : 'Templates'} Available',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModelList() {
    if (filteredModels.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: filteredModels.length,
      itemBuilder: (context, index) {
        final model = filteredModels[index];
        return _buildModelCard(model, index);
      },
    );
  }

  Widget _buildModelCard(Map<String, dynamic> model, int index) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (model['color'] as Color).withOpacity(0.2),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _showModelDetails(model),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon Container
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: (model['color'] as Color).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    model['icon'] as IconData,
                    color: model['color'] as Color,
                    size: 30,
                  ),
                ),
                SizedBox(width: 16),

                // Model Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            model['id'],
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          SizedBox(width: 8),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: (model['color'] as Color).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'v${model['version']}',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: model['color'] as Color,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Text(
                        model['name'],
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        model['description'],
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurface.withOpacity(0.6),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.table_chart, size: 14, color: colorScheme.onSurface.withOpacity(0.5)),
                          SizedBox(width: 4),
                          Text(
                            '${model['fields']} fields',
                            style: TextStyle(
                              fontSize: 11,
                              color: colorScheme.onSurface.withOpacity(0.5),
                            ),
                          ),
                          SizedBox(width: 12),
                          Icon(Icons.category, size: 14, color: colorScheme.onSurface.withOpacity(0.5)),
                          SizedBox(width: 4),
                          Text(
                            model['category'],
                            style: TextStyle(
                              fontSize: 11,
                              color: colorScheme.onSurface.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Download Button
                Container(
                  decoration: BoxDecoration(
                    color: (model['color'] as Color).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: Icon(Icons.download_rounded, color: model['color'] as Color),
                    onPressed: () => _downloadTemplate(model),
                  ),
                ),
              ],
            ),
          ),
        ),
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
            Icons.search_off,
            size: 80,
            color: colorScheme.onSurface.withOpacity(0.3),
          ),
          SizedBox(height: 16),
          Text(
            'No templates found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Try adjusting your search or filters',
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              _searchController.clear();
              setState(() {
                _searchQuery = '';
                _selectedCategory = 'All';
              });
            },
            icon: Icon(Icons.refresh),
            label: Text('Reset Filters'),
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
      ),
    );
  }

  void _downloadTemplate(Map<String, dynamic> model) {
    final theme = Theme.of(context);

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: model['color'] as Color),
              SizedBox(height: 16),
              Text(
                'Downloading template...',
                style: TextStyle(color: theme.colorScheme.onSurface),
              ),
            ],
          ),
        ),
      ),
    );

    // Simulate download
    Future.delayed(Duration(seconds: 2), () {
      Navigator.pop(context);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text('Template ${model['id']} downloaded successfully!'),
              ),
            ],
          ),
          backgroundColor: Color(0xFF10b981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: EdgeInsets.all(16),
        ),
      );
    });
  }

  void _showModelDetails(Map<String, dynamic> model) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    (model['color'] as Color).withOpacity(0.1),
                    (model['color'] as Color).withOpacity(0.05),
                  ],
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: model['color'] as Color,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      model['icon'] as IconData,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          model['id'],
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          model['name'],
                          style: TextStyle(
                            fontSize: 16,
                            color: colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Details
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow('Description', model['description']),
                    _buildDetailRow('Category', model['category']),
                    _buildDetailRow('Version', model['version']),
                    _buildDetailRow('Fields', '${model['fields']} fields included'),
                    SizedBox(height: 16),
                    Text(
                      'What\'s Included:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    SizedBox(height: 8),
                    _buildBulletPoint('Pre-formatted Excel template'),
                    _buildBulletPoint('Sample data for reference'),
                    _buildBulletPoint('Field validation rules'),
                    _buildBulletPoint('Data import guidelines'),
                  ],
                ),
              ),
            ),

            // Download Button
            Padding(
              padding: EdgeInsets.all(24),
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _downloadTemplate(model);
                },
                icon: Icon(Icons.download_rounded),
                label: Text('Download Template'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: model['color'] as Color,
                  foregroundColor: Colors.white,
                  minimumSize: Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(Icons.check_circle, size: 16, color: Color(0xFF10b981)),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showInfoDialog(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: colorScheme.surface,
        title: Row(
          children: [
            Icon(Icons.info, color: colorScheme.primary),
            SizedBox(width: 8),
            Text(
              'About Templates',
              style: TextStyle(color: colorScheme.onSurface),
            ),
          ],
        ),
        content: Text(
          'Select a model template to download a pre-formatted Excel file. Fill in the template with your data and upload it back to the system for processing.',
          style: TextStyle(color: colorScheme.onSurface.withOpacity(0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Got it', style: TextStyle(color: colorScheme.primary)),
          ),
        ],
      ),
    );
  }
}