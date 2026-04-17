import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:frontend_sage3/services/api_service.dart';
import 'package:frontend_sage3/services/auth_service.dart';
import 'package:frontend_sage3/services/api_service_web.dart'
    if (dart.library.io) 'package:frontend_sage3/services/api_service_stub.dart';

class HistoryPage extends StatefulWidget {
  @override
  _HistoryPageState createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  String _selectedFilter = 'Tous';
  String _searchQuery    = '';

  List<Map<String, dynamic>> _historyItems = [];
  bool    _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final userId = AuthService.instance.currentUser?.id;
      final data   = await ApiService().getHistory(userId: userId);
      setState(() { _historyItems = data; _isLoading = false; });
    } catch (e) {
      setState(() {
        _error     = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  // ✅ Lit uploadDate (vrai champ retourné par l'API)
  DateTime? _parseDate(Map<String, dynamic> item) {
    final raw = item['uploadDate'] ?? item['date'] ?? item['createdAt'];
    if (raw == null) return null;
    try { return DateTime.parse(raw.toString()).toLocal(); }
    catch (_) { return null; }
  }

  // ✅ Status réel : Converted → Succès, Error → Échec
  String _statusLabel(Map<String, dynamic> item) {
    final raw = (item['status'] ?? '').toString().toLowerCase();
    return switch (raw) {
      'converted' => 'Succès',
      'error'     => 'Échec',
      'pending'   => 'En attente',
      _           => raw.isEmpty ? '—' : raw,
    };
  }

  Color _statusColor(Map<String, dynamic> item) =>
      switch (_statusLabel(item)) {
        'Succès'     => Color(0xFF10b981),
        'Échec'      => Color(0xFFef4444),
        'En attente' => Color(0xFFf59e0b),
        _            => Color(0xFF94a3b8),
      };

  IconData _statusIcon(Map<String, dynamic> item) =>
      switch (_statusLabel(item)) {
        'Succès'     => Icons.check_circle_outline,
        'Échec'      => Icons.error_outline,
        'En attente' => Icons.hourglass_empty,
        _            => Icons.upload_file_outlined,
      };

  // ✅ Vrais champs retournés par l'API
  String _fileName(Map<String, dynamic> item) =>
      item['fileName'] ?? item['file'] ?? '—';

  String _modelCode(Map<String, dynamic> item) =>
      item['modelCode'] ?? '—';

  int _rowCount(Map<String, dynamic> item) =>
      item['rowCount'] ?? 0;

  String _message(Map<String, dynamic> item) =>
      item['message'] ?? '—';

  bool _hasCsv(Map<String, dynamic> item) =>
      item['csvContent'] != null &&
      item['csvContent'].toString().isNotEmpty;

  // ✅ Filtres adaptés aux vrais statuts
  List<Map<String, dynamic>> get _filtered {
    var list = _historyItems.toList();

    if (_selectedFilter != 'Tous') {
      list = list.where((i) =>
          _statusLabel(i) == _selectedFilter).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((i) =>
          _fileName(i).toLowerCase().contains(q) ||
          _modelCode(i).toLowerCase().contains(q) ||
          _statusLabel(i).toLowerCase().contains(q)).toList();
    }

    list.sort((a, b) {
      final da = _parseDate(a) ?? DateTime(2000);
      final db = _parseDate(b) ?? DateTime(2000);
      return db.compareTo(da);
    });

    return list;
  }

  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final theme       = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDesktop   = MediaQuery.of(context).size.width >= 1024;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        title: Text('Historique des imports',
            style: TextStyle(
              color:      colorScheme.onSurface,
              fontSize:   20,
              fontWeight: FontWeight.bold,
            )),
        actions: [
          IconButton(
            icon:      Icon(Icons.refresh_rounded, color: colorScheme.onSurface),
            onPressed: _loadHistory,
            tooltip:   'Rafraîchir',
          ),
          SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? _buildLoading()
          : _error != null
              ? _buildError()
              : Column(children: [
                  _buildSearchBar(isDesktop),
                  _buildStats(isDesktop),
                  Expanded(child: _buildList(isDesktop)),
                ]),
    );
  }

  Widget _buildLoading() => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      CircularProgressIndicator(),
      SizedBox(height: 16),
      Text('Chargement…',
          style: TextStyle(
              color: Theme.of(context)
                  .colorScheme.onSurface.withOpacity(0.5))),
    ]),
  );

  Widget _buildError() {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.wifi_off_rounded,
              size: 64, color: colorScheme.error.withOpacity(0.5)),
          SizedBox(height: 16),
          Text('Impossible de charger l\'historique',
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface)),
          SizedBox(height: 8),
          Text(_error!,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13,
                  color: colorScheme.onSurface.withOpacity(0.5))),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadHistory,
            icon:  Icon(Icons.refresh),
            label: Text('Réessayer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ]),
      ),
    );
  }

  // ── Search + filtres ──────────────────────────────────────────────────────
  Widget _buildSearchBar(bool isDesktop) {
    final theme       = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      color:   colorScheme.surface,
      padding: EdgeInsets.fromLTRB(
          isDesktop ? 24 : 16, 16, isDesktop ? 24 : 16, 12),
      child: Column(children: [
        TextField(
          onChanged: (v) => setState(() => _searchQuery = v),
          style: TextStyle(color: colorScheme.onSurface),
          decoration: InputDecoration(
            hintText:  'Rechercher par fichier ou modèle…',
            hintStyle: TextStyle(
                color: colorScheme.onSurface.withOpacity(0.45)),
            prefixIcon: Icon(Icons.search,
                color: colorScheme.onSurface.withOpacity(0.45), size: 20),
            filled:    true,
            fillColor: theme.brightness == Brightness.light
                ? Color(0xFFf8fafc) : colorScheme.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:   BorderSide(color: theme.dividerColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:   BorderSide(color: theme.dividerColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
            ),
            contentPadding:
                EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          ),
        ),
        SizedBox(height: 12),
        // ✅ Filtres avec les vrais statuts de l'API
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: ['Tous', 'Succès', 'Échec', 'En attente']
                .map((f) => Padding(
                      padding: EdgeInsets.only(right: 8),
                      child:   _filterChip(f),
                    ))
                .toList(),
          ),
        ),
      ]),
    );
  }

  Widget _filterChip(String label) {
    final theme       = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSelected  = _selectedFilter == label;

    Color chipColor = switch (label) {
      'Succès'     => Color(0xFF10b981),
      'Échec'      => Color(0xFFef4444),
      'En attente' => Color(0xFFf59e0b),
      _            => colorScheme.primary,
    };

    return FilterChip(
      label: Text(label,
          style: TextStyle(
              fontSize: 13,
              color:    isSelected ? chipColor
                  : colorScheme.onSurface.withOpacity(0.6))),
      selected:        isSelected,
      onSelected:      (_) => setState(
          () => _selectedFilter = isSelected ? 'Tous' : label),
      backgroundColor: colorScheme.surface,
      selectedColor:   chipColor.withOpacity(0.1),
      checkmarkColor:  chipColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
            color: isSelected ? chipColor : theme.dividerColor),
      ),
    );
  }

  // ── Stats ─────────────────────────────────────────────────────────────────
  Widget _buildStats(bool isDesktop) {
    final items   = _historyItems; // stats sur tout, pas sur filtered
    final total   = items.length;
    final success = items.where((i) => _statusLabel(i) == 'Succès').length;
    final failed  = items.where((i) => _statusLabel(i) == 'Échec').length;
    final pending = items.where((i) => _statusLabel(i) == 'En attente').length;

    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 24 : 16, vertical: 14),
      child: Row(children: [
        _statBadge('$total',   'Total',      Color(0xFF6366f1)),
        SizedBox(width: 10),
        _statBadge('$success', 'Succès',     Color(0xFF10b981)),
        SizedBox(width: 10),
        _statBadge('$failed',  'Échecs',     Color(0xFFef4444)),
        SizedBox(width: 10),
        _statBadge('$pending', 'En attente', Color(0xFFf59e0b)),
      ]),
    );
  }

  Widget _statBadge(String value, String label, Color color) {
    return Expanded(child: Container(
      padding: EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color:        color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border:       Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(children: [
        Text(value,
            style: TextStyle(
                fontSize:   18,
                fontWeight: FontWeight.bold,
                color:      color)),
        SizedBox(height: 2),
        Text(label,
            style: TextStyle(fontSize: 10, color: color.withOpacity(0.8)),
            textAlign: TextAlign.center),
      ]),
    ));
  }

  // ── Liste ─────────────────────────────────────────────────────────────────
  Widget _buildList(bool isDesktop) {
    final items = _filtered;
    if (items.isEmpty) return _buildEmpty();
    return RefreshIndicator(
      onRefresh: _loadHistory,
      child: ListView.builder(
        padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 24 : 16, vertical: 8),
        itemCount:   items.length,
        itemBuilder: (_, i) => _historyCard(items[i], isDesktop),
      ),
    );
  }

  Widget _buildEmpty() {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.inbox_outlined, size: 72,
            color: Theme.of(context).dividerColor),
        SizedBox(height: 16),
        Text('Aucun import trouvé',
            style: TextStyle(
                fontSize:   18,
                fontWeight: FontWeight.w600,
                color:      colorScheme.onSurface.withOpacity(0.6))),
        SizedBox(height: 8),
        Text(
          _searchQuery.isNotEmpty
              ? 'Essayez d\'autres mots clés'
              : 'Vos imports apparaîtront ici',
          style: TextStyle(
              fontSize: 14,
              color:    colorScheme.onSurface.withOpacity(0.4)),
        ),
      ]),
    );
  }

  // ── Card ──────────────────────────────────────────────────────────────────
  Widget _historyCard(Map<String, dynamic> item, bool isDesktop) {
    final theme       = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final date        = _parseDate(item);
    final timeAgo     = date != null ? _timeAgo(date) : '—';
    final color       = _statusColor(item);
    final icon        = _statusIcon(item);
    final status      = _statusLabel(item);
    final hasCsv      = _hasCsv(item);

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color:        colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border:       Border.all(color: theme.dividerColor),
        boxShadow: [BoxShadow(
          color:      Colors.black.withOpacity(
              theme.brightness == Brightness.light ? 0.03 : 0.12),
          blurRadius: 8, offset: Offset(0, 2),
        )],
      ),
      child: InkWell(
        onTap:        () => _showDetails(item),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Ligne 1 : icône + nom fichier + badge statut ──────────────
              Row(children: [
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color:        color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                SizedBox(width: 12),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_fileName(item),
                        style: TextStyle(
                            fontSize:   14,
                            fontWeight: FontWeight.w600,
                            color:      colorScheme.onSurface),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    SizedBox(height: 3),
                    Row(children: [
                      // Modèle badge
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color:        Color(0xFF0ea5e9).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(_modelCode(item),
                            style: TextStyle(
                                fontSize:   11,
                                fontWeight: FontWeight.w600,
                                color:      Color(0xFF0ea5e9))),
                      ),
                      SizedBox(width: 8),
                      Text(timeAgo,
                          style: TextStyle(
                              fontSize: 11,
                              color: colorScheme.onSurface.withOpacity(0.45))),
                    ]),
                  ],
                )),
                // ✅ Badge statut
                _statusBadge(status, color),
              ]),

              SizedBox(height: 12),
              Divider(height: 1, color: theme.dividerColor),
              SizedBox(height: 10),

              // ── Ligne 2 : lignes converties + message + CSV ───────────────
              Row(children: [
                // Lignes
                Icon(Icons.table_rows_outlined, size: 14,
                    color: colorScheme.onSurface.withOpacity(0.45)),
                SizedBox(width: 4),
                Text('${_rowCount(item)} lignes',
                    style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurface.withOpacity(0.6))),
                SizedBox(width: 16),
                // Message
                Expanded(child: Text(_message(item),
                    style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurface.withOpacity(0.5)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis)),
                // ✅ Bouton download CSV si disponible
                if (hasCsv)
                  GestureDetector(
                    onTap: () => _downloadCsv(item),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color:        Color(0xFF10b981).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: Color(0xFF10b981).withOpacity(0.3)),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.download_rounded,
                            size: 14, color: Color(0xFF10b981)),
                        SizedBox(width: 4),
                        Text('CSV',
                            style: TextStyle(
                                fontSize:   11,
                                fontWeight: FontWeight.w600,
                                color:      Color(0xFF10b981))),
                      ]),
                    ),
                  ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusBadge(String status, Color color) => Container(
    padding: EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(
      color:        color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
      border:       Border.all(color: color.withOpacity(0.3)),
    ),
    child: Text(status,
        style: TextStyle(
            fontSize:   11,
            fontWeight: FontWeight.w700,
            color:      color)),
  );

  // ── Download CSV ──────────────────────────────────────────────────────────
  void _downloadCsv(Map<String, dynamic> item) {
    try {
      final csv      = item['csvContent'] as String;
      final model    = _modelCode(item);
      final id       = item['id'] ?? '';
      final fileName = '${model}_$id.csv';
      final bytes    = Uint8List.fromList(utf8.encode(csv));
      if (kIsWeb) {
        triggerWebDownload(bytes, fileName);
      } else {
        saveMobileFile(bytes, fileName);
      }
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content:          Text('Erreur lors du téléchargement'),
        backgroundColor:  Color(0xFFef4444),
        behavior:         SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }
  }

  // ── Détail dialog ─────────────────────────────────────────────────────────
  void _showDetails(Map<String, dynamic> item) {
    final colorScheme = Theme.of(context).colorScheme;
    final date        = _parseDate(item);
    final color       = _statusColor(item);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: colorScheme.surface,
        title: Row(children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(_statusIcon(item), color: color, size: 22),
          ),
          SizedBox(width: 12),
          Expanded(child: Text('Détails de l\'import',
              style: TextStyle(
                  fontSize:   18,
                  fontWeight: FontWeight.bold,
                  color:      colorScheme.onSurface))),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          _detailRow('Fichier',   _fileName(item)),
          _detailRow('Modèle',    _modelCode(item)),
          _detailRow('Statut',    _statusLabel(item)),
          _detailRow('Lignes',    '${_rowCount(item)}'),
          _detailRow('Message',   _message(item)),
          _detailRow('Date',      date != null
              ? '${date.day.toString().padLeft(2,'0')}/${date.month.toString().padLeft(2,'0')}/${date.year}  ${date.hour.toString().padLeft(2,'0')}:${date.minute.toString().padLeft(2,'0')}'
              : '—'),
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Fermer',
                style: TextStyle(color: colorScheme.primary)),
          ),
          if (_hasCsv(item))
            ElevatedButton.icon(
              onPressed: () { Navigator.pop(context); _downloadCsv(item); },
              icon:  Icon(Icons.download_rounded, size: 16),
              label: Text('Télécharger CSV'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF10b981),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
            ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 80,
            child: Text(label,
                style: TextStyle(
                    fontSize:   12,
                    fontWeight: FontWeight.w600,
                    color:      colorScheme.onSurface.withOpacity(0.55)))),
        Expanded(child: Text(value,
            style: TextStyle(
                fontSize: 13, color: colorScheme.onSurface))),
      ]),
    );
  }

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 7)    return '${date.day}/${date.month}/${date.year}';
    if (diff.inDays > 0)    return 'Il y a ${diff.inDays}j';
    if (diff.inHours > 0)   return 'Il y a ${diff.inHours}h';
    if (diff.inMinutes > 0) return 'Il y a ${diff.inMinutes}min';
    return 'À l\'instant';
  }
}