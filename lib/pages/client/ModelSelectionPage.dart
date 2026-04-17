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
  bool    _loading = true;
  String? _error;
  String  _query   = '';
  Set<String> _downloading = {};

  // Design tokens — matching HomePage
  static const _blue   = Color(0xFF2563eb);
  static const _violet = Color(0xFF7c3aed);
  static const _green  = Color(0xFF059669);
  static const _red    = Color(0xFFdc2626);

  @override
  void initState() { super.initState(); _load(); }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await _api.getModels();
      setState(() { _models = data; _filtered = data; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString().replaceFirst('Exception: ', ''); _loading = false; });
    }
  }

  void _search(String q) {
    setState(() {
      _query = q;
      _filtered = _models.where((m) {
        final code  = (m['codeModele'] ?? '').toString().toLowerCase();
        final texte = (m['texte']      ?? '').toString().toLowerCase();
        final objet = (m['objet']      ?? '').toString().toLowerCase();
        return code.contains(q.toLowerCase()) ||
               texte.contains(q.toLowerCase()) ||
               objet.contains(q.toLowerCase());
      }).toList();
    });
  }

  Future<void> _download(String code, String title) async {
    setState(() => _downloading.add(code));
    try {
      await _api.downloadTemplate(code);
      if (mounted) _snack('$title downloaded successfully', _green);
    } catch (e) {
      if (mounted) _snack('Download failed: $e', _red);
    } finally {
      if (mounted) setState(() => _downloading.remove(code));
    }
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: TextStyle(fontSize: 13)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: EdgeInsets.all(16),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isDark    = Theme.of(context).brightness == Brightness.dark;
    final bg        = isDark ? Color(0xFF0b0e13) : Color(0xFFF7F8FA);
    final cardBg    = isDark ? Color(0xFF151921) : Colors.white;
    final borderCol = isDark ? Color(0xFF1e2028) : Color(0xFFf0f0f5);
    final textCol   = isDark ? Colors.white : Color(0xFF111827);
    final subCol    = isDark ? Color(0xFF6b7280) : Color(0xFF9ca3af);
    final isDesktop = MediaQuery.of(context).size.width >= 1024;

    return Scaffold(
      backgroundColor: bg,
      body: Column(children: [
        // ── Header ──────────────────────────────────────────────────────
        Container(
          padding: EdgeInsets.symmetric(horizontal: isDesktop ? 32 : 20, vertical: 16),
          decoration: BoxDecoration(
            color: cardBg,
            border: Border(bottom: BorderSide(color: borderCol)),
          ),
          child: Row(children: [
            _backButton(context, isDark, subCol),
            SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Import Models', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700,
                  color: textCol, letterSpacing: -0.3)),
              Text('Choose a Sage X3 model and download its Excel template',
                  style: TextStyle(fontSize: 12, color: subCol)),
            ])),
            _refreshButton(_load, subCol, isDark),
          ]),
        ),

        // ── Search + count ──────────────────────────────────────────────
        Container(
          padding: EdgeInsets.fromLTRB(isDesktop ? 32 : 20, 20, isDesktop ? 32 : 20, 16),
          child: Column(children: [
            _searchField(isDark, cardBg, borderCol, textCol, subCol),
            SizedBox(height: 14),
            Row(children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: _blue.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
                child: Text('${_filtered.length} model${_filtered.length == 1 ? '' : 's'}',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _blue)),
              ),
              Spacer(),
              if (_query.isNotEmpty)
                GestureDetector(
                  onTap: () { _searchCtrl.clear(); _search(''); },
                  child: Text('Clear', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: _blue)),
                ),
            ]),
          ]),
        ),

        // ── Body ────────────────────────────────────────────────────────
        Expanded(child: _buildBody(isDesktop, isDark, cardBg, borderCol, textCol, subCol)),
      ]),
    );
  }

  Widget _buildBody(bool desk, bool dk, Color card, Color bord, Color txt, Color sub) {
    if (_loading) return Center(child: CircularProgressIndicator(color: _blue, strokeWidth: 2.5));
    if (_error != null) return _errorState(txt, sub);
    if (_filtered.isEmpty) return _emptyState(txt, sub);

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(desk ? 32 : 20, 0, desk ? 32 : 20, 24),
      itemCount: _filtered.length,
      itemBuilder: (_, i) => _modelCard(_filtered[i], dk, card, bord, txt, sub),
    );
  }

  // ── Model card ────────────────────────────────────────────────────────
  Widget _modelCard(Map<String, dynamic> m, bool dk, Color card, Color bord, Color txt, Color sub) {
    final code  = (m['codeModele'] ?? '').toString();
    final texte = (m['texte']      ?? '').toString();
    final objet = (m['objet']      ?? '').toString().trim();
    final title = texte.isNotEmpty ? texte : code;
    final isDown = _downloading.contains(code);
    final letter = title.isNotEmpty ? title[0].toUpperCase() : '?';

    // Rotating colors for visual variety
    final colorIndex = code.hashCode.abs() % 5;
    final colors = [_blue, _violet, _green, Color(0xFF0891b2), Color(0xFFd97706)];
    final accentColor = colors[colorIndex];

    return Container(
      margin: EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: bord),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _showModelDetail(m, dk, card, bord, txt, sub, accentColor),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(children: [
              // Avatar
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(dk ? 0.15 : 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(child: Text(letter,
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: accentColor))),
              ),
              SizedBox(width: 14),

              // Info
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: txt),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                SizedBox(height: 5),
                Row(children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(dk ? 0.15 : 0.06),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(code, style: TextStyle(fontSize: 10,
                        fontWeight: FontWeight.w600, color: accentColor)),
                  ),
                  if (objet.isNotEmpty) ...[
                    SizedBox(width: 8),
                    Flexible(child: Text(objet, style: TextStyle(fontSize: 11, color: sub),
                        maxLines: 1, overflow: TextOverflow.ellipsis)),
                  ],
                ]),
              ])),
              SizedBox(width: 12),

              // Download button
              isDown
                  ? SizedBox(width: 22, height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, color: accentColor))
                  : Container(
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(dk ? 0.15 : 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        child: InkWell(
                          onTap: () => _download(code, title),
                          borderRadius: BorderRadius.circular(10),
                          child: Padding(
                            padding: EdgeInsets.all(9),
                            child: Icon(Icons.download_rounded, color: accentColor, size: 18),
                          ),
                        ),
                      ),
                    ),
            ]),
          ),
        ),
      ),
    );
  }

  // ── Model detail bottom sheet ─────────────────────────────────────────
  void _showModelDetail(Map<String, dynamic> m, bool dk, Color card, Color bord,
      Color txt, Color sub, Color accent) {
    final code  = (m['codeModele'] ?? '').toString();
    final texte = (m['texte']      ?? '').toString();
    final objet = (m['objet']      ?? '').toString().trim();
    final title = texte.isNotEmpty ? texte : code;

    showModalBottomSheet(
      context: context,
      backgroundColor: card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(28, 8, 28, 32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Handle
          Container(width: 40, height: 4, margin: EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(color: sub.withOpacity(0.3), borderRadius: BorderRadius.circular(2))),
          // Icon
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [accent, accent.withOpacity(0.7)]),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: accent.withOpacity(0.25), blurRadius: 16, offset: Offset(0, 6))],
            ),
            child: Icon(Icons.description_rounded, color: Colors.white, size: 26),
          ),
          SizedBox(height: 18),
          Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: txt), textAlign: TextAlign.center),
          SizedBox(height: 6),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: accent.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
              child: Text(code, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: accent)),
            ),
            if (objet.isNotEmpty) ...[
              SizedBox(width: 8),
              Text(objet, style: TextStyle(fontSize: 12, color: sub)),
            ],
          ]),
          SizedBox(height: 24),
          // Info rows
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: dk ? Color(0xFF1a1d24) : Color(0xFFF7F8FA),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(children: [
              _detailRow(Icons.code_rounded, 'Model Code', code, txt, sub),
              Divider(height: 20, color: bord),
              _detailRow(Icons.category_outlined, 'Object', objet.isEmpty ? '—' : objet, txt, sub),
              Divider(height: 20, color: bord),
              _detailRow(Icons.description_outlined, 'Description', texte.isEmpty ? '—' : texte, txt, sub),
            ]),
          ),
          SizedBox(height: 24),
          // Download button
          SizedBox(
            width: double.infinity, height: 50,
            child: ElevatedButton.icon(
              onPressed: () { Navigator.pop(context); _download(code, title); },
              icon: Icon(Icons.download_rounded, size: 18),
              label: Text('Download Template', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: accent, foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value, Color txt, Color sub) {
    return Row(children: [
      Icon(icon, size: 16, color: sub),
      SizedBox(width: 10),
      SizedBox(width: 90, child: Text(label, style: TextStyle(fontSize: 12, color: sub))),
      Expanded(child: Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: txt),
          maxLines: 2, overflow: TextOverflow.ellipsis)),
    ]);
  }

  // ── Shared widgets ────────────────────────────────────────────────────
  Widget _backButton(BuildContext ctx, bool dk, Color sub) {
    return Container(
      width: 38, height: 38,
      decoration: BoxDecoration(
        color: dk ? Color(0xFF1a1d24) : Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: () => Navigator.pop(ctx),
          borderRadius: BorderRadius.circular(10),
          child: Icon(Icons.arrow_back, size: 18, color: sub),
        ),
      ),
    );
  }

  Widget _refreshButton(VoidCallback onTap, Color sub, bool dk) {
    return Container(
      width: 38, height: 38,
      decoration: BoxDecoration(
        color: dk ? Color(0xFF1a1d24) : Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(10),
            child: Icon(Icons.refresh, size: 18, color: sub)),
      ),
    );
  }

  Widget _searchField(bool dk, Color card, Color bord, Color txt, Color sub) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: dk ? Color(0xFF1a1d24) : card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: bord),
      ),
      child: TextField(
        controller: _searchCtrl,
        onChanged: _search,
        style: TextStyle(fontSize: 14, color: txt),
        decoration: InputDecoration(
          hintText: 'Search by code, name or object...',
          hintStyle: TextStyle(fontSize: 13, color: sub),
          prefixIcon: Icon(Icons.search, size: 18, color: sub),
          suffixIcon: _query.isNotEmpty
              ? IconButton(icon: Icon(Icons.close, size: 16, color: sub),
                  onPressed: () { _searchCtrl.clear(); _search(''); })
              : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _errorState(Color txt, Color sub) {
    return Center(child: Padding(padding: EdgeInsets.all(48),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.cloud_off_outlined, size: 48, color: _red.withOpacity(0.4)),
          SizedBox(height: 16),
          Text('Failed to load models', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: txt)),
          SizedBox(height: 6),
          Text(_error ?? '', style: TextStyle(fontSize: 12, color: sub), textAlign: TextAlign.center),
          SizedBox(height: 20),
          TextButton.icon(onPressed: _load, icon: Icon(Icons.refresh, size: 16),
              label: Text('Try again'), style: TextButton.styleFrom(foregroundColor: _blue)),
        ])));
  }

  Widget _emptyState(Color txt, Color sub) {
    return Center(child: Padding(padding: EdgeInsets.all(48),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.search_off_rounded, size: 48, color: sub.withOpacity(0.4)),
          SizedBox(height: 16),
          Text('No models found', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: txt)),
          SizedBox(height: 6),
          Text('Try adjusting your search', style: TextStyle(fontSize: 13, color: sub)),
        ])));
  }
}