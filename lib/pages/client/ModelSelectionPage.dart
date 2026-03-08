import 'dart:io';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import '../../services/api_service.dart';

class ModelSelectionPage extends StatefulWidget {
  @override
  _ModelSelectionPageState createState() => _ModelSelectionPageState();
}

class _ModelSelectionPageState extends State<ModelSelectionPage> {
  final ApiService          _api            = ApiService();
  final TextEditingController _searchCtrl   = TextEditingController();

  List<Map<String, dynamic>> _models        = [];
  List<Map<String, dynamic>> _filtered      = [];
  bool                       _loading       = true;
  String?                    _error;
  String                     _searchQuery   = '';
  Set<String>                _downloading   = {};

  @override
  void initState() {
    super.initState();
    _loadModels();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Load models from API ─────────────────────────────────────────────────
  Future<void> _loadModels() async {
    setState(() { _loading = true; _error = null; });
    try {
      final models = await _api.getModels();
      setState(() {
        _models   = models;
        _filtered = models;
        _loading  = false;
      });
    } catch (e) {
      setState(() {
        _error   = e.toString();
        _loading = false;
      });
    }
  }

  void _onSearch(String query) {
    setState(() {
      _searchQuery = query;
      _filtered    = _models.where((m) {
        final code = (m['codeModele'] ?? '').toLowerCase();
        final obj  = (m['objet']     ?? '').toLowerCase();
        final q    = query.toLowerCase();
        return code.contains(q) || obj.contains(q);
      }).toList();
    });
  }

  // ── Download template ────────────────────────────────────────────────────
  // ── Replace _downloadTemplate method in ModelSelectionPage.dart ──────────
// OLD signature: Future<void> _downloadTemplate(String modelCode) 
// The only change needed is removing the "open_filex" call and 
// calling _api.downloadTemplate which now handles web/mobile internally.

  Future<void> _downloadTemplate(String modelCode) async {
    setState(() => _downloading.add(modelCode));
    try {
      await _api.downloadTemplate(modelCode); // handles web + mobile

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Expanded(child: Text('Template $modelCode downloaded!')),
            ]),
            backgroundColor: Color(0xFF10b981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download failed: $e'),
            backgroundColor: Color(0xFFef4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: EdgeInsets.all(16),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _downloading.remove(modelCode));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme       = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end:   Alignment.bottomRight,
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
              _buildAppBar(context),
              _buildSearchBar(colorScheme, theme),
              _buildModelCount(colorScheme),
              Expanded(child: _buildBody(colorScheme, theme)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    final theme       = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [BoxShadow(
          color:      theme.brightness == Brightness.light
              ? Colors.black12 : Colors.black54,
          blurRadius: 10,
          offset:     Offset(0, 2),
        )],
      ),
      child: Row(children: [
        IconButton(
          icon:      Icon(Icons.arrow_back, color: colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        SizedBox(width: 8),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Select Model',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface)),
          Text('Choose a template to download',
              style: TextStyle(fontSize: 12,
                  color: colorScheme.onSurface.withOpacity(0.6))),
        ]),
        Spacer(),
        IconButton(
          icon:      Icon(Icons.refresh, color: colorScheme.primary),
          onPressed: _loadModels,
        ),
      ]),
    );
  }

  Widget _buildSearchBar(ColorScheme colorScheme, ThemeData theme) {
    return Padding(
      padding: EdgeInsets.all(20),
      child: Container(
        decoration: BoxDecoration(
          color:        colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(
            color:      theme.brightness == Brightness.light
                ? Colors.black12 : Colors.black54,
            blurRadius: 8,
            offset:     Offset(0, 4),
          )],
        ),
        child: TextField(
          controller: _searchCtrl,
          onChanged:  _onSearch,
          style:      TextStyle(color: colorScheme.onSurface),
          decoration: InputDecoration(
            hintText:        'Search models...',
            hintStyle:       TextStyle(
                color: colorScheme.onSurface.withOpacity(0.5)),
            prefixIcon:      Icon(Icons.search, color: colorScheme.primary),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
              icon: Icon(Icons.clear,
                  color: colorScheme.onSurface.withOpacity(0.5)),
              onPressed: () {
                _searchCtrl.clear();
                _onSearch('');
              },
            ) : null,
            border:          InputBorder.none,
            contentPadding:  EdgeInsets.symmetric(
                horizontal: 16, vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildModelCount(ColorScheme colorScheme) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Row(children: [
        Text(
          '${_filtered.length} '
              '${_filtered.length == 1 ? 'Template' : 'Templates'} Available',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
              color: colorScheme.onSurface.withOpacity(0.7)),
        ),
      ]),
    );
  }

  Widget _buildBody(ColorScheme colorScheme, ThemeData theme) {
    if (_loading) {
      return Center(child: CircularProgressIndicator(
          color: colorScheme.primary));
    }

    if (_error != null) {
      return Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64,
              color: colorScheme.error.withOpacity(0.5)),
          SizedBox(height: 16),
          Text('Failed to load models',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface)),
          SizedBox(height: 8),
          Text(_error!, style: TextStyle(fontSize: 12,
              color: colorScheme.onSurface.withOpacity(0.5)),
              textAlign: TextAlign.center),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadModels,
            icon:  Icon(Icons.refresh),
            label: Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor:  colorScheme.primary,
              foregroundColor:  Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ));
    }

    if (_filtered.isEmpty) {
      return Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64,
              color: colorScheme.onSurface.withOpacity(0.3)),
          SizedBox(height: 16),
          Text('No templates found',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface.withOpacity(0.7))),
          SizedBox(height: 8),
          Text('Try adjusting your search',
              style: TextStyle(fontSize: 14,
                  color: colorScheme.onSurface.withOpacity(0.5))),
        ],
      ));
    }

    return ListView.builder(
      padding:     EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount:   _filtered.length,
      itemBuilder: (context, index) =>
          _buildModelCard(_filtered[index], colorScheme, theme),
    );
  }

  Widget _buildModelCard(
      Map<String, dynamic> model,
      ColorScheme colorScheme,
      ThemeData theme) {

    final code         = model['codeModele'] ?? '';
    final objet        = model['objet']      ?? '';
    final isDownloading = _downloading.contains(code);
    final Color color  = colorScheme.primary;

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color:        colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(
          color:      color.withOpacity(0.1),
          blurRadius: 12,
          offset:     Offset(0, 6),
        )],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(children: [
              // Icon
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  color:        color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(code.length >= 2 ? code.substring(0, 2) : code,
                      style: TextStyle(fontSize: 18,
                          fontWeight: FontWeight.bold, color: color)),
                ),
              ),
              SizedBox(width: 16),

              // Info
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(code,
                      style: TextStyle(fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface)),
                  if (objet.isNotEmpty) ...[
                    SizedBox(height: 4),
                    Text(objet,
                        style: TextStyle(fontSize: 13,
                            color: colorScheme.onSurface.withOpacity(0.6))),
                  ],
                ],
              )),

              // Download button
              Container(
                decoration: BoxDecoration(
                  color:        color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: isDownloading
                    ? Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 24, height: 24,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: color),
                  ),
                )
                    : IconButton(
                  icon:      Icon(Icons.download_rounded, color: color),
                  onPressed: () => _downloadTemplate(code),
                  tooltip:   'Download template',
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}