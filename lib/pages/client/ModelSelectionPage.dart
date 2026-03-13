import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class ModelSelectionPage extends StatefulWidget {
  @override
  _ModelSelectionPageState createState() => _ModelSelectionPageState();
}

class _ModelSelectionPageState extends State<ModelSelectionPage> {
  final ApiService _api = ApiService();
  final TextEditingController _searchCtrl = TextEditingController();

  List<Map<String, dynamic>> _models   = [];
  List<Map<String, dynamic>> _filtered = [];
  bool    _loading     = true;
  String? _error;
  String  _searchQuery = '';
  Set<String> _downloading = {};

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
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  void _onSearch(String query) {
    setState(() {
      _searchQuery = query;
      _filtered = _models.where((m) {
        final code  = (m['codeModele'] ?? '').toLowerCase();
        final texte = (m['texte']      ?? '').toLowerCase();
        return code.contains(query.toLowerCase()) ||
               texte.contains(query.toLowerCase());
      }).toList();
    });
  }

  Future<void> _downloadTemplate(String modelCode, String displayTitle) async {
    setState(() => _downloading.add(modelCode));
    try {
      await _api.downloadTemplate(modelCode);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Row(children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 10),
            Expanded(child: Text('$displayTitle downloaded!')),
          ]),
          backgroundColor: Color(0xFF10b981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: EdgeInsets.all(16),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Download failed: $e'),
          backgroundColor: Color(0xFFef4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: EdgeInsets.all(16),
        ));
      }
    } finally {
      if (mounted) setState(() => _downloading.remove(modelCode));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme       = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark      = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end:   Alignment.bottomRight,
            colors: [
              theme.scaffoldBackgroundColor,
              isDark ? Color(0xFF0F172A) : Color(0xFFe2e8f0),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(children: [
            _buildAppBar(context),
            _buildSearchBar(colorScheme, theme, isDark),
            _buildCountBar(colorScheme),
            Expanded(child: _buildBody(colorScheme, theme)),
          ]),
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
          blurRadius: 10, offset: Offset(0, 2),
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

  Widget _buildSearchBar(ColorScheme colorScheme, ThemeData theme, bool isDark) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Container(
        decoration: BoxDecoration(
          color:        colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(
            color:      isDark ? Colors.black54 : Colors.black12,
            blurRadius: 8, offset: Offset(0, 4),
          )],
        ),
        child: TextField(
          controller: _searchCtrl,
          onChanged:  _onSearch,
          style:      TextStyle(color: colorScheme.onSurface),
          decoration: InputDecoration(
            hintText:   'Search by name or code...',
            hintStyle:  TextStyle(color: colorScheme.onSurface.withOpacity(0.5)),
            prefixIcon: Icon(Icons.search, color: colorScheme.primary),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear,
                        color: colorScheme.onSurface.withOpacity(0.5)),
                    onPressed: () { _searchCtrl.clear(); _onSearch(''); },
                  )
                : null,
            border:         InputBorder.none,
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildCountBar(ColorScheme colorScheme) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(children: [
        Text(
          '${_filtered.length} ${_filtered.length == 1 ? 'template' : 'templates'} available',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
              color: colorScheme.onSurface.withOpacity(0.55)),
        ),
      ]),
    );
  }

  Widget _buildBody(ColorScheme colorScheme, ThemeData theme) {
    if (_loading) {
      return Center(child: CircularProgressIndicator(color: colorScheme.primary));
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
            icon: Icon(Icons.refresh), label: Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: Colors.white,
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
      padding:     EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      itemCount:   _filtered.length,
      itemBuilder: (context, index) =>
          _buildModelCard(_filtered[index], colorScheme, theme),
    );
  }

  Widget _buildModelCard(
      Map<String, dynamic> model,
      ColorScheme colorScheme,
      ThemeData theme) {

    final code          = model['codeModele'] ?? '';
    final texte         = model['texte']      ?? '';
    final objet         = (model['objet']     ?? '').toString().trim();
    final displayTitle  = texte.isNotEmpty ? texte : code;
    final isDownloading = _downloading.contains(code);
    final color         = colorScheme.primary;

    final avatarLetter = displayTitle.isNotEmpty
        ? displayTitle[0].toUpperCase()
        : '?';

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color:        colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withOpacity(0.6)),
        boxShadow: [BoxShadow(
          color:      Colors.black.withOpacity(
              theme.brightness == Brightness.light ? 0.04 : 0.15),
          blurRadius: 8, offset: Offset(0, 3),
        )],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {},
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(children: [

              // ── Circle avatar — single primary color ─────────────────────
              Container(
                width: 46, height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withOpacity(0.1),
                  border: Border.all(
                    color: color.withOpacity(0.25),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Text(avatarLetter,
                      style: TextStyle(
                        fontSize:   18,
                        fontWeight: FontWeight.w700,
                        color:      color,
                      )),
                ),
              ),

              SizedBox(width: 14),

              // ── Text ─────────────────────────────────────────────────────
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(displayTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize:   15,
                        fontWeight: FontWeight.w600,
                        color:      colorScheme.onSurface,
                      )),
                  SizedBox(height: 5),
                  Row(children: [
                    // Code badge
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color:        color.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(code,
                          style: TextStyle(
                            fontSize:   11,
                            fontWeight: FontWeight.w600,
                            color:      color.withOpacity(0.85),
                          )),
                    ),
                    if (objet.isNotEmpty) ...[
                      SizedBox(width: 6),
                      Text(objet,
                          style: TextStyle(
                            fontSize: 11,
                            color:    colorScheme.onSurface.withOpacity(0.35),
                          )),
                    ],
                  ]),
                ],
              )),

              SizedBox(width: 8),

              // ── Download button ───────────────────────────────────────────
              isDownloading
                  ? SizedBox(
                      width: 24, height: 24,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: color),
                    )
                  : IconButton(
                      icon: Icon(Icons.download_rounded, color: color, size: 22),
                      onPressed: () => _downloadTemplate(code, displayTitle),
                      tooltip: 'Download $displayTitle',
                    ),
            ]),
          ),
        ),
      ),
    );
  }
}