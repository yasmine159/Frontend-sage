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
      if (mounted) _snack('$title téléchargé avec succès', _green);
    } catch (e) {
      if (mounted) _snack('Échec du téléchargement: $e', _red);
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
              Text('Modèles d\'import', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700,
                  color: textCol, letterSpacing: -0.3)),
              Text('Sélectionnez un modèle Sage X3 pour télécharger son template Excel',
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
                child: Text('${_filtered.length} modèle${_filtered.length == 1 ? '' : 's'}',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _blue)),
              ),
              Spacer(),
              if (_query.isNotEmpty)
                GestureDetector(
                  onTap: () { _searchCtrl.clear(); _search(''); },
                  child: Text('Effacer', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: _blue)),
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
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ModelDetailSheet(
        code: code,
        title: title,
        objet: objet,
        texte: texte,
        accent: accent,
        dk: dk,
        card: card,
        bord: bord,
        txt: txt,
        sub: sub,
        api: _api,
        onDownload: () => _download(code, title),
      ),
    );
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
          hintText: 'Rechercher par code, nom ou objet...',
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
          Text('Échec du chargement', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: txt)),
          SizedBox(height: 6),
          Text(_error ?? '', style: TextStyle(fontSize: 12, color: sub), textAlign: TextAlign.center),
          SizedBox(height: 20),
          TextButton.icon(onPressed: _load, icon: Icon(Icons.refresh, size: 16),
              label: Text('Réessayer'), style: TextButton.styleFrom(foregroundColor: _blue)),
        ])));
  }

  Widget _emptyState(Color txt, Color sub) {
    return Center(child: Padding(padding: EdgeInsets.all(48),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.search_off_rounded, size: 48, color: sub.withOpacity(0.4)),
          SizedBox(height: 16),
          Text('Aucun modèle trouvé', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: txt)),
          SizedBox(height: 6),
          Text('Essayez d\'ajuster votre recherche', style: TextStyle(fontSize: 13, color: sub)),
        ])));
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  MODEL DETAIL SHEET — widget stateful séparé pour gérer le chargement async
// ═══════════════════════════════════════════════════════════════════════════════
class _ModelDetailSheet extends StatefulWidget {
  final String code, title, objet, texte;
  final Color accent, card, bord, txt, sub;
  final bool dk;
  final ApiService api;
  final VoidCallback onDownload;

  const _ModelDetailSheet({
    required this.code, required this.title, required this.objet,
    required this.texte, required this.accent, required this.card,
    required this.bord, required this.txt, required this.sub,
    required this.dk, required this.api, required this.onDownload,
  });

  @override
  _ModelDetailSheetState createState() => _ModelDetailSheetState();
}

class _ModelDetailSheetState extends State<_ModelDetailSheet> {
  Map<String, dynamic>? _details;
  bool _loading = true;
  String? _error;
  String _activeTab = 'tous'; // 'tous' | 'obligatoires' | 'optionnels'

  static const _green = Color(0xFF059669);
  static const _amber = Color(0xFFd97706);
  static const _blue  = Color(0xFF2563eb);

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    try {
      final data = await widget.api.getModelDetails(widget.code);
      if (mounted) setState(() { _details = data; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString().replaceFirst('Exception: ', ''); _loading = false; });
    }
  }

  List<Map<String, dynamic>> get _allFields {
    if (_details == null) return [];
    final champs = (_details!['champs'] as List? ?? []).cast<Map<String, dynamic>>();
    // Filtrer les séparateurs (indicateur == 'S' ou designation vide)
    return champs.where((f) {
      final ind = (f['indicateur'] ?? '').toString();
      final champ = (f['champ'] ?? '').toString();
      return ind != 'S' && champ.isNotEmpty;
    }).toList();
  }

  List<Map<String, dynamic>> get _filteredFields {
    final all = _allFields;
    if (_activeTab == 'obligatoires') return all.where((f) => f['obligatoire'] == true).toList();
    if (_activeTab == 'optionnels') return all.where((f) => f['obligatoire'] != true).toList();
    return all;
  }

  String _typeLabel(Map<String, dynamic> field) {
    // Priorité 1 : typeDonnee retourné par le backend (source de vérité)
    final td = (field['typeDonnee'] ?? '').toString().trim().toUpperCase();
    if (td == 'D')   return 'Date';
    if (td == 'DCB') return 'Décimal';
    if (td == 'L')   return 'Entier';
    if (td == 'A')   return 'Texte';

    // Priorité 2 : repli sur suffixe du code champ si typeDonnee vide
    final champ = (field['champ'] ?? '').toString().toUpperCase();
    if (champ.contains('DAT') || champ.contains('DATE')) return 'Date';
    if (champ.contains('QTY') || champ.contains('AMT') ||
        champ.contains('PRI') || champ.contains('NUM')) return 'Numérique';
    return 'Texte';
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'Date':    return Color(0xFF0891b2);
      case 'Numérique':
      case 'Entier':  return Color(0xFF7c3aed);
      case 'Décimal': return Color(0xFF7c3aed);
      case 'Montant': return Color(0xFFd97706);
      default:        return _blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;

    return Container(
      height: screenH * 0.88,
      decoration: BoxDecoration(
        color: widget.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(children: [
        // ── Handle ──────────────────────────────────────────────────────
        Padding(
          padding: EdgeInsets.only(top: 12, bottom: 4),
          child: Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: widget.sub.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),

        // ── Header fixe ─────────────────────────────────────────────────
        Padding(
          padding: EdgeInsets.fromLTRB(24, 16, 24, 0),
          child: Column(children: [
            // Icône + titre
            Row(children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [widget.accent, widget.accent.withOpacity(0.7)]),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: widget.accent.withOpacity(0.25), blurRadius: 12, offset: Offset(0, 4))],
                ),
                child: Icon(Icons.description_rounded, color: Colors.white, size: 22),
              ),
              SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(widget.title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: widget.txt),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                SizedBox(height: 4),
                Row(children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: widget.accent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(widget.code,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: widget.accent)),
                  ),
                  if (widget.objet.isNotEmpty) ...[
                    SizedBox(width: 8),
                    Flexible(child: Text(widget.objet,
                        style: TextStyle(fontSize: 11, color: widget.sub),
                        maxLines: 1, overflow: TextOverflow.ellipsis)),
                  ],
                ]),
              ])),
              // Bouton fermer
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 34, height: 34,
                  decoration: BoxDecoration(
                    color: widget.sub.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.close, size: 16, color: widget.sub),
                ),
              ),
            ]),

            SizedBox(height: 16),

            // Méta-infos (format date, séparateur)
            if (!_loading && _details != null)
              _metaRow(),

            SizedBox(height: 16),
          ]),
        ),

        // ── Contenu principal ────────────────────────────────────────────
        Expanded(
          child: _loading
              ? _loadingState()
              : _error != null
              ? _errorState()
              : _fieldsContent(),
        ),

        // ── Bouton download fixe en bas ──────────────────────────────────
        Padding(
          padding: EdgeInsets.fromLTRB(24, 12, 24, 28),
          child: SizedBox(
            width: double.infinity, height: 50,
            child: ElevatedButton.icon(
              onPressed: () { Navigator.pop(context); widget.onDownload(); },
              icon: Icon(Icons.download_rounded, size: 18),
              label: Text('Télécharger le template Excel',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.accent, foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  // ── Meta row (format date, séparateur, nb champs) ────────────────────
  Widget _metaRow() {
    final formatDate = (_details!['formatDate'] ?? 'DDMMYYYY').toString();
    final sep        = (_details!['separateur'] ?? ';').toString();
    final total      = _allFields.length;
    final reqCount   = _allFields.where((f) => f['obligatoire'] == true).length;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: widget.dk ? Color(0xFF1a1d24) : Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: widget.bord),
      ),
      child: Row(children: [
        _metaChip(Icons.calendar_today_outlined, formatDate, Color(0xFF0891b2)),
        _metaDivider(),
        _metaChip(Icons.device_hub_rounded, 'Sep: "$sep"', widget.sub),
        _metaDivider(),
        _metaChip(Icons.list_alt_rounded, '$total champs', _blue),
        _metaDivider(),
        _metaChip(Icons.star_rounded, '$reqCount obligatoires', _amber),
      ]),
    );
  }

  Widget _metaChip(IconData icon, String label, Color color) {
    return Expanded(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(icon, size: 12, color: color),
      SizedBox(width: 5),
      Flexible(child: Text(label,
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color),
          maxLines: 1, overflow: TextOverflow.ellipsis)),
    ]));
  }

  Widget _metaDivider() => Container(width: 1, height: 20, color: widget.bord);

  // ── Loading ──────────────────────────────────────────────────────────
  Widget _loadingState() {
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      CircularProgressIndicator(color: widget.accent, strokeWidth: 2.5),
      SizedBox(height: 16),
      Text('Chargement des champs...', style: TextStyle(fontSize: 13, color: widget.sub)),
    ]);
  }

  // ── Error ────────────────────────────────────────────────────────────
  Widget _errorState() {
    return Center(child: Padding(padding: EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.error_outline_rounded, size: 40, color: Colors.red.withOpacity(0.4)),
        SizedBox(height: 12),
        Text('Impossible de charger les champs', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: widget.txt)),
        SizedBox(height: 6),
        Text(_error ?? '', style: TextStyle(fontSize: 12, color: widget.sub), textAlign: TextAlign.center),
        SizedBox(height: 16),
        TextButton.icon(
          onPressed: () { setState(() { _loading = true; _error = null; }); _loadDetails(); },
          icon: Icon(Icons.refresh, size: 16),
          label: Text('Réessayer'),
          style: TextButton.styleFrom(foregroundColor: widget.accent),
        ),
      ]),
    ));
  }

  // ── Fields content ───────────────────────────────────────────────────
  Widget _fieldsContent() {
    final fields = _filteredFields;
    final total    = _allFields.length;
    final reqCount = _allFields.where((f) => f['obligatoire'] == true).length;
    final optCount = total - reqCount;

    return Column(children: [
      // Tabs filtre
      Padding(
        padding: EdgeInsets.fromLTRB(24, 0, 24, 12),
        child: Row(children: [
          _tabBtn('tous', 'Tous ($total)'),
          SizedBox(width: 8),
          _tabBtn('obligatoires', 'Obligatoires ($reqCount)'),
          SizedBox(width: 8),
          _tabBtn('optionnels', 'Optionnels ($optCount)'),
        ]),
      ),

      // En-tête tableau
      Padding(
        padding: EdgeInsets.fromLTRB(24, 0, 24, 8),
        child: Row(children: [
          Expanded(flex: 3, child: Text('Désignation', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: widget.sub))),
          Expanded(flex: 2, child: Text('Champ', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: widget.sub))),
          SizedBox(width: 60, child: Text('Type', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: widget.sub))),
          SizedBox(width: 72, child: Center(child: Text('Statut', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: widget.sub)))),
        ]),
      ),

      Divider(height: 1, color: widget.bord),

      // Liste des champs
      Expanded(
        child: fields.isEmpty
            ? Center(child: Text('Aucun champ dans cette catégorie',
            style: TextStyle(fontSize: 13, color: widget.sub)))
            : ListView.separated(
          padding: EdgeInsets.fromLTRB(24, 0, 24, 12),
          itemCount: fields.length,
          separatorBuilder: (_, __) => Divider(height: 1, color: widget.bord.withOpacity(0.5)),
          itemBuilder: (_, i) => _fieldRow(fields[i]),
        ),
      ),
    ]);
  }

  Widget _tabBtn(String key, String label) {
    final active = _activeTab == key;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeTab = key),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: active ? widget.accent : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: active ? widget.accent : widget.bord),
          ),
          child: Text(label, textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: active ? Colors.white : widget.sub,
              )),
        ),
      ),
    );
  }

  Widget _fieldRow(Map<String, dynamic> field) {
    final designation = (field['designation'] ?? '').toString();
    final champ       = (field['champ']       ?? '').toString();
    final obligatoire = field['obligatoire'] == true;
    final type        = _typeLabel(field);
    final typeColor   = _typeColor(type);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        // Désignation
        Expanded(flex: 3, child: Text(
          designation.isNotEmpty ? designation : '—',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: widget.txt),
          maxLines: 2, overflow: TextOverflow.ellipsis,
        )),

        // Code champ
        Expanded(flex: 2, child: Text(
          champ,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
              color: widget.accent, fontFamily: 'monospace'),
          maxLines: 1, overflow: TextOverflow.ellipsis,
        )),

        // Type badge
        SizedBox(width: 60, child: Container(
          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: typeColor.withOpacity(widget.dk ? 0.15 : 0.08),
            borderRadius: BorderRadius.circular(5),
          ),
          child: Text(type, textAlign: TextAlign.center,
              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: typeColor),
              maxLines: 1, overflow: TextOverflow.ellipsis),
        )),

        // Obligatoire badge
        SizedBox(width: 72, child: Center(child: Container(
          padding: EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: (obligatoire ? _amber : _green).withOpacity(widget.dk ? 0.15 : 0.08),
            borderRadius: BorderRadius.circular(5),
          ),
          child: Text(
            obligatoire ? 'Requis' : 'Optionnel',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 9, fontWeight: FontWeight.w600,
              color: obligatoire ? _amber : _green,
            ),
          ),
        ))),
      ]),
    );
  }
}