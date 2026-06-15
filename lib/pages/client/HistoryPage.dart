import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:frontend_sage3/services/api_service.dart';
import 'package:frontend_sage3/services/auth_service.dart';
import 'package:frontend_sage3/services/api_service_web.dart'
if (dart.library.io) 'package:frontend_sage3/services/api_service_stub.dart';
import 'package:frontend_sage3/main.dart';
import 'package:frontend_sage3/app_strings.dart';

class HistoryPage extends StatefulWidget {
  @override
  _HistoryPageState createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  // ✅ FIX: code neutre indépendant de la langue
  String _filterCode  = 'all'; // 'all' | 'success' | 'failed'
  String _searchQuery = '';

  List<Map<String, dynamic>> _historyItems = [];
  bool    _isLoading = true;
  String? _error;

  AppStrings get _s => SageX3App.of(context)?.strings ?? AppStrings('fr');

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
      if (!mounted) return;
      setState(() { _historyItems = data; _isLoading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error     = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  DateTime? _parseDate(Map<String, dynamic> item) {
    final raw = item['uploadDate'] ?? item['date'] ?? item['createdAt'];
    if (raw == null) return null;
    try { return DateTime.parse(raw.toString()).toLocal(); }
    catch (_) { return null; }
  }

  // ✅ FIX: _statusLabel garde le label traduit UNIQUEMENT pour l'affichage
  String _statusLabel(Map<String, dynamic> item) {
    final s   = _s;
    final raw = (item['status'] ?? '').toString().toLowerCase();
    return switch (raw) {
      'converted' => s.filterSuccess,
      'error'     => s.filterFailed,
      _           => raw.isEmpty ? '—' : raw,
    };
  }

  // ✅ FIX: _statusCode retourne le code neutre pour le filtrage
  String _statusCode(Map<String, dynamic> item) {
    final raw = (item['status'] ?? '').toString().toLowerCase();
    return switch (raw) {
      'converted' => 'success',
      'error'     => 'failed',
      _           => 'other',
    };
  }

  Color _statusColor(Map<String, dynamic> item) {
    final raw = (item['status'] ?? '').toString().toLowerCase();
    return switch (raw) {
      'converted' => const Color(0xFF10b981),
      'error'     => const Color(0xFFef4444),
      _           => const Color(0xFF94a3b8),
    };
  }

  IconData _statusIcon(Map<String, dynamic> item) {
    final raw = (item['status'] ?? '').toString().toLowerCase();
    return switch (raw) {
      'converted' => Icons.check_circle_outline,
      'error'     => Icons.error_outline,
      _           => Icons.upload_file_outlined,
    };
  }

  String _fileName(Map<String, dynamic> item)  => item['fileName'] ?? item['file'] ?? '—';
  String _modelCode(Map<String, dynamic> item)  => item['modelCode'] ?? '—';
  int    _rowCount(Map<String, dynamic> item)   => item['rowCount'] ?? 0;
  String _message(Map<String, dynamic> item)    => item['message'] ?? '—';
  bool   _hasCsv(Map<String, dynamic> item)     =>
      item['csvContent'] != null && item['csvContent'].toString().isNotEmpty;

  // ✅ FIX: filtre par code neutre, pas par label traduit
  List<Map<String, dynamic>> get _filtered {
    var list = _historyItems.toList();

    if (_filterCode == 'success') {
      list = list.where((i) => _statusCode(i) == 'success').toList();
    } else if (_filterCode == 'failed') {
      list = list.where((i) => _statusCode(i) == 'failed').toList();
    }
    // 'all' → pas de filtre

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

  @override
  Widget build(BuildContext context) {
    final s           = _s;
    final theme       = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDesktop   = MediaQuery.of(context).size.width >= 1024;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        title: Text(s.historyTitle,
            style: TextStyle(color: colorScheme.onSurface, fontSize: 20, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon:      Icon(Icons.refresh_rounded, color: colorScheme.onSurface),
            onPressed: _loadHistory,
            tooltip:   s.refresh,
          ),
          const SizedBox(width: 8),
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
      const CircularProgressIndicator(),
      const SizedBox(height: 16),
      Text(_s.loading, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
    ]),
  );

  Widget _buildError() {
    final s           = _s;
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.wifi_off_rounded, size: 64, color: colorScheme.error.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(s.historyLoadError, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: colorScheme.onSurface)),
          const SizedBox(height: 8),
          Text(_error!, textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: colorScheme.onSurface.withOpacity(0.5))),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadHistory,
            icon:  const Icon(Icons.refresh),
            label: Text(s.retry),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary, foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildSearchBar(bool isDesktop) {
    final s           = _s;
    final theme       = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // ✅ FIX: liste de {code, label} — le code est stable, le label est traduit
    final filters = [
      {'code': 'all',     'label': s.filterAll},
      {'code': 'success', 'label': s.filterSuccess},
      {'code': 'failed',  'label': s.filterFailed},
    ];

    return Container(
      color:   colorScheme.surface,
      padding: EdgeInsets.fromLTRB(isDesktop ? 24 : 16, 16, isDesktop ? 24 : 16, 12),
      child: Column(children: [
        TextField(
          onChanged: (v) => setState(() => _searchQuery = v),
          style: TextStyle(color: colorScheme.onSurface),
          decoration: InputDecoration(
            hintText:  s.historySearch,
            hintStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.45)),
            prefixIcon: Icon(Icons.search, color: colorScheme.onSurface.withOpacity(0.45), size: 20),
            filled:    true,
            fillColor: theme.brightness == Brightness.light ? const Color(0xFFf8fafc) : colorScheme.surface,
            border:         OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: theme.dividerColor)),
            enabledBorder:  OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: theme.dividerColor)),
            focusedBorder:  OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colorScheme.primary, width: 1.5)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: filters.map((f) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _filterChip(f['code']!, f['label']!),
            )).toList(),
          ),
        ),
      ]),
    );
  }

  // ✅ FIX: prend code + label séparément
  Widget _filterChip(String code, String label) {
    final theme       = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSelected  = _filterCode == code;

    Color chipColor = code == 'success'
        ? const Color(0xFF10b981)
        : code == 'failed'
        ? const Color(0xFFef4444)
        : colorScheme.primary;

    return FilterChip(
      label: Text(label, style: TextStyle(fontSize: 13, color: isSelected ? chipColor : colorScheme.onSurface.withOpacity(0.6))),
      selected:        isSelected,
      onSelected:      (_) => setState(() => _filterCode = isSelected ? 'all' : code),
      backgroundColor: colorScheme.surface,
      selectedColor:   chipColor.withOpacity(0.1),
      checkmarkColor:  chipColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: isSelected ? chipColor : theme.dividerColor),
      ),
    );
  }

  Widget _buildStats(bool isDesktop) {
    final s       = _s;
    final items   = _historyItems;
    final total   = items.length;
    final success = items.where((i) => _statusCode(i) == 'success').length;
    final failed  = items.where((i) => _statusCode(i) == 'failed').length;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 24 : 16, vertical: 14),
      child: Row(children: [
        _statBadge('$total',   s.statTotal,     const Color(0xFF6366f1)),
        const SizedBox(width: 10),
        _statBadge('$success', s.filterSuccess, const Color(0xFF10b981)),
        const SizedBox(width: 10),
        _statBadge('$failed',  s.statFailed,    const Color(0xFFef4444)),
        const SizedBox(width: 10),
      ]),
    );
  }

  Widget _statBadge(String value, String label, Color color) {
    return Expanded(child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.2))),
      child: Column(children: [
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 10, color: color.withOpacity(0.8)), textAlign: TextAlign.center),
      ]),
    ));
  }

  Widget _buildList(bool isDesktop) {
    final items = _filtered;
    if (items.isEmpty) return _buildEmpty();
    return RefreshIndicator(
      onRefresh: _loadHistory,
      child: ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: isDesktop ? 24 : 16, vertical: 8),
        itemCount:   items.length,
        itemBuilder: (_, i) => _historyCard(items[i], isDesktop),
      ),
    );
  }

  Widget _buildEmpty() {
    final s           = _s;
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.inbox_outlined, size: 72, color: Theme.of(context).dividerColor),
        const SizedBox(height: 16),
        Text(s.noImportFound, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: colorScheme.onSurface.withOpacity(0.6))),
        const SizedBox(height: 8),
        Text(
          _searchQuery.isNotEmpty ? s.tryOtherKeywords : s.importsWillAppear,
          style: TextStyle(fontSize: 14, color: colorScheme.onSurface.withOpacity(0.4)),
        ),
      ]),
    );
  }

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
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(theme.brightness == Brightness.light ? 0.03 : 0.12), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: InkWell(
        onTap: () => _showDetails(item),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: Icon(icon, color: color, size: 22)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_fileName(item), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colorScheme.onSurface), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                Row(children: [
                  Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(color: const Color(0xFF0ea5e9).withOpacity(0.1), borderRadius: BorderRadius.circular(5)),
                      child: Text(_modelCode(item), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF0ea5e9)))),
                  const SizedBox(width: 8),
                  Text(timeAgo, style: TextStyle(fontSize: 11, color: colorScheme.onSurface.withOpacity(0.45))),
                ]),
              ])),
              _statusBadge(status, color),
            ]),
            const SizedBox(height: 12),
            Divider(height: 1, color: theme.dividerColor),
            const SizedBox(height: 10),
            Row(children: [
              Icon(Icons.table_rows_outlined, size: 14, color: colorScheme.onSurface.withOpacity(0.45)),
              const SizedBox(width: 4),
              Text('${_rowCount(item)} ${_s.lines}', style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withOpacity(0.6))),
              const SizedBox(width: 16),
              Expanded(child: Text(_message(item), style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withOpacity(0.5)), maxLines: 1, overflow: TextOverflow.ellipsis)),
              if (hasCsv)
                GestureDetector(
                  onTap: () => _downloadCsv(item),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: const Color(0xFF10b981).withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFF10b981).withOpacity(0.3))),
                    child: const Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.download_rounded, size: 14, color: Color(0xFF10b981)),
                      SizedBox(width: 4),
                      Text('CSV', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF10b981))),
                    ]),
                  ),
                ),
            ]),
          ]),
        ),
      ),
    );
  }

  Widget _statusBadge(String status, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: color.withOpacity(0.3))),
    child: Text(status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
  );

  void _downloadCsv(Map<String, dynamic> item) {
    try {
      final csv      = item['csvContent'] as String;
      final model    = _modelCode(item);
      final id       = item['id'] ?? '';
      final fileName = '${model}_$id.csv';
      final bytes    = Uint8List.fromList(utf8.encode(csv));
      if (kIsWeb) { triggerWebDownload(bytes, fileName); }
      else { saveMobileFile(bytes, fileName); }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content:         Text(_s.downloadError),
        backgroundColor: const Color(0xFFef4444),
        behavior:        SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }
  }

  void _showDetails(Map<String, dynamic> item) {
    if (!mounted) return;
    final s           = _s;
    final colorScheme = Theme.of(context).colorScheme;
    final date        = _parseDate(item);
    final color       = _statusColor(item);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: colorScheme.surface,
        title: Row(children: [
          Container(padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(_statusIcon(item), color: color, size: 22)),
          const SizedBox(width: 12),
          Expanded(child: Text(s.importDetails, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorScheme.onSurface))),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          _detailRow(s.detailFile,    _fileName(item), colorScheme),
          _detailRow(s.detailModel,   _modelCode(item), colorScheme),
          _detailRow(s.detailStatus,  _statusLabel(item), colorScheme),
          _detailRow(s.detailRows,    '${_rowCount(item)}', colorScheme),
          _detailRow(s.detailMessage, _message(item), colorScheme),
          _detailRow(s.detailDate,    date != null
              ? '${date.day.toString().padLeft(2,'0')}/${date.month.toString().padLeft(2,'0')}/${date.year}  ${date.hour.toString().padLeft(2,'0')}:${date.minute.toString().padLeft(2,'0')}'
              : '—', colorScheme),
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(s.close, style: TextStyle(color: colorScheme.primary)),
          ),
          if (_hasCsv(item))
            ElevatedButton.icon(
              onPressed: () { Navigator.pop(dialogContext); _downloadCsv(item); },
              icon:  const Icon(Icons.download_rounded, size: 16),
              label: Text(s.downloadCsv),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10b981), foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), elevation: 0,
              ),
            ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 80, child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colorScheme.onSurface.withOpacity(0.55)))),
        Expanded(child: Text(value, style: TextStyle(fontSize: 13, color: colorScheme.onSurface))),
      ]),
    );
  }

  String _timeAgo(DateTime date) {
    final s    = _s;
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 7)    return '${date.day}/${date.month}/${date.year}';
    if (diff.inDays > 0)    return s.daysAgo(diff.inDays);
    if (diff.inHours > 0)   return s.hoursAgo(diff.inHours);
    if (diff.inMinutes > 0) return s.minutesAgo(diff.inMinutes);
    return s.justNow;
  }
}