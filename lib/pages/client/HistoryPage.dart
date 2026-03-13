import 'package:flutter/material.dart';
import 'package:frontend_sage3/services/api_service.dart';
import 'package:frontend_sage3/services/auth_service.dart';

class HistoryPage extends StatefulWidget {
  @override
  _HistoryPageState createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  String _selectedFilter = 'All';
  String _searchQuery    = '';

  List<Map<String, dynamic>> _historyItems = [];
  bool   _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  // ── Load from real API ────────────────────────────────────────────────────
  Future<void> _loadHistory() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final userId = AuthService.instance.currentUser?.id;
      final data   = await ApiService().getHistory(userId: userId);
      setState(() {
        _historyItems = data;
        _isLoading    = false;
      });
    } catch (e) {
      setState(() {
        _error     = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  // ── Map backend status/action to icon & color ─────────────────────────────
  IconData _iconFor(Map<String, dynamic> item) {
    final status = (item['status'] ?? '').toString().toLowerCase();
    final action = (item['action'] ?? item['type'] ?? '').toString().toLowerCase();
    if (status == 'failed')    return Icons.error;
    if (status == 'pending')   return Icons.pending;
    if (action.contains('download')) return Icons.download;
    if (action.contains('upload'))   return Icons.cloud_upload;
    return Icons.check_circle;
  }

  Color _colorFor(Map<String, dynamic> item) {
    final status = (item['status'] ?? '').toString().toLowerCase();
    final action = (item['action'] ?? item['type'] ?? '').toString().toLowerCase();
    if (status == 'failed')          return Color(0xFFef4444);
    if (status == 'pending')         return Color(0xFFf59e0b);
    if (action.contains('download')) return Color(0xFF1e3a8a);
    return Color(0xFF10b981);
  }

  String _actionLabel(Map<String, dynamic> item) {
    final raw = (item['action'] ?? item['type'] ?? 'Upload').toString();
    return raw[0].toUpperCase() + raw.substring(1);
  }

  String _statusLabel(Map<String, dynamic> item) {
    final raw = (item['status'] ?? 'Success').toString();
    return raw[0].toUpperCase() + raw.substring(1);
  }

  DateTime? _parseDate(Map<String, dynamic> item) {
    final raw = item['date'] ?? item['createdAt'] ?? item['timestamp'];
    if (raw == null) return null;
    try { return DateTime.parse(raw.toString()); } catch (_) { return null; }
  }

  String _userName(Map<String, dynamic> item) =>
      item['username'] ??
      item['userName'] ??
      item['user'] ??
      AuthService.instance.currentUser?.username ??
      '—';

  String _fileName(Map<String, dynamic> item) =>
      item['fileName'] ?? item['file'] ?? item['filename'] ?? '—';

  String _details(Map<String, dynamic> item) =>
      item['details'] ?? item['description'] ??
      '${_actionLabel(item)} — ${_fileName(item)}';

  // ── Filter ────────────────────────────────────────────────────────────────
  List<Map<String, dynamic>> get _filtered {
    var list = _historyItems.toList();

    if (_selectedFilter != 'All') {
      list = list.where((i) =>
          _actionLabel(i).toLowerCase() ==
          _selectedFilter.toLowerCase()).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((i) =>
          _userName(i).toLowerCase().contains(q) ||
          _details(i).toLowerCase().contains(q) ||
          _fileName(i).toLowerCase().contains(q)).toList();
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
        title: Text('Activity History',
            style: TextStyle(
              color:      colorScheme.onSurface,
              fontSize:   20,
              fontWeight: FontWeight.bold,
            )),
        actions: [
          // Refresh
          IconButton(
            icon:      Icon(Icons.refresh, color: colorScheme.onSurface),
            onPressed: _loadHistory,
            tooltip:   'Refresh',
          ),
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: OutlinedButton.icon(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content:   Text('Export feature coming soon'),
                  behavior:  SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              icon:  Icon(Icons.download, size: 18),
              label: Text('Export'),
              style: OutlinedButton.styleFrom(
                foregroundColor: colorScheme.primary,
                side:  BorderSide(color: colorScheme.primary),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? _buildLoading()
          : _error != null
              ? _buildError()
              : Column(children: [
                  // Search + filters
                  _buildSearchBar(context, isDesktop),
                  // Stats row
                  _buildStats(context, isDesktop),
                  // List
                  Expanded(child: _buildList(context, isDesktop)),
                ]),
    );
  }

  // ── Loading ───────────────────────────────────────────────────────────────
  Widget _buildLoading() => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      CircularProgressIndicator(),
      SizedBox(height: 16),
      Text('Loading history…',
          style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
    ]),
  );

  // ── Error ─────────────────────────────────────────────────────────────────
  Widget _buildError() {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.wifi_off_rounded,
              size: 64, color: colorScheme.error.withOpacity(0.5)),
          SizedBox(height: 16),
          Text('Could not load history',
              style: TextStyle(
                  fontSize:   18,
                  fontWeight: FontWeight.w600,
                  color:      colorScheme.onSurface)),
          SizedBox(height: 8),
          Text(_error!,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13,
                  color:    colorScheme.onSurface.withOpacity(0.5))),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadHistory,
            icon:  Icon(Icons.refresh),
            label: Text('Try again'),
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

  // ── Search + filter bar ───────────────────────────────────────────────────
  Widget _buildSearchBar(BuildContext context, bool isDesktop) {
    final theme       = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      color:   colorScheme.surface,
      padding: EdgeInsets.all(isDesktop ? 24 : 16),
      child: Column(children: [
        TextField(
          onChanged: (v) => setState(() => _searchQuery = v),
          style: TextStyle(color: colorScheme.onSurface),
          decoration: InputDecoration(
            hintText:  'Search by user, action, or file name…',
            hintStyle: TextStyle(
                color: colorScheme.onSurface.withOpacity(0.5)),
            prefixIcon: Icon(Icons.search,
                color: colorScheme.onSurface.withOpacity(0.5)),
            filled:    true,
            fillColor: theme.brightness == Brightness.light
                ? Color(0xFFf8fafc)
                : colorScheme.surface.withOpacity(0.5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding:
                EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
        SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: ['All', 'Download', 'Upload', 'Processing']
                .map((f) => Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: _filterChip(f),
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
    return FilterChip(
      label: Text(label,
          style: TextStyle(
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.onSurface.withOpacity(0.6))),
      selected:        isSelected,
      onSelected:      (_) =>
          setState(() => _selectedFilter = isSelected ? 'All' : label),
      backgroundColor: colorScheme.surface,
      selectedColor:   colorScheme.primary.withOpacity(0.1),
      checkmarkColor:  colorScheme.primary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
            color: isSelected ? colorScheme.primary : theme.dividerColor),
      ),
    );
  }

  // ── Stats row ─────────────────────────────────────────────────────────────
  Widget _buildStats(BuildContext context, bool isDesktop) {
    final items = _filtered;
    final total   = items.length;
    final success = items.where((i) => _statusLabel(i) == 'Success').length;
    final failed  = items.where((i) => _statusLabel(i) == 'Failed').length;
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 24 : 16, vertical: 16),
      child: Row(children: [
        _statBadge('$total',   'Total Actions', colorScheme.primary),
        SizedBox(width: 12),
        _statBadge('$success', 'Successful',    Color(0xFF10b981)),
        SizedBox(width: 12),
        _statBadge('$failed',  'Failed',        colorScheme.error),
      ]),
    );
  }

  Widget _statBadge(String value, String label, Color color) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color:        color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border:       Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(children: [
          Text(value,
              style: TextStyle(
                  fontSize:   20,
                  fontWeight: FontWeight.bold,
                  color:      color)),
          SizedBox(height: 4),
          Text(label,
              style: TextStyle(
                  fontSize:  11,
                  color: theme.brightness == Brightness.light
                      ? Color(0xFF64748b)
                      : Colors.white.withOpacity(0.7)),
              textAlign: TextAlign.center),
        ]),
      ),
    );
  }

  // ── List ──────────────────────────────────────────────────────────────────
  Widget _buildList(BuildContext context, bool isDesktop) {
    final items = _filtered;
    if (items.isEmpty) return _buildEmpty();
    return RefreshIndicator(
      onRefresh: _loadHistory,
      child: ListView.builder(
        padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 24 : 16, vertical: 8),
        itemCount: items.length,
        itemBuilder: (ctx, i) => _historyCard(items[i], isDesktop),
      ),
    );
  }

  Widget _buildEmpty() {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.history, size: 80,
            color: Theme.of(context).dividerColor),
        SizedBox(height: 16),
        Text('No history found',
            style: TextStyle(
                fontSize:   18,
                fontWeight: FontWeight.w600,
                color:      colorScheme.onSurface.withOpacity(0.6))),
        SizedBox(height: 8),
        Text(
          _searchQuery.isNotEmpty
              ? 'Try adjusting your search'
              : 'Your activity will appear here',
          style: TextStyle(
              fontSize: 14,
              color:    colorScheme.onSurface.withOpacity(0.5)),
        ),
      ]),
    );
  }

  // ── History card ──────────────────────────────────────────────────────────
  Widget _historyCard(Map<String, dynamic> item, bool isDesktop) {
    final theme       = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final date        = _parseDate(item);
    final timeAgo     = date != null ? _timeAgo(date) : '—';
    final icon        = _iconFor(item);
    final color       = _colorFor(item);

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color:        colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border:       Border.all(color: theme.dividerColor),
        boxShadow: [BoxShadow(
          color:      theme.brightness == Brightness.light
              ? Colors.black.withOpacity(0.02)
              : Colors.black.withOpacity(0.1),
          blurRadius: 8, offset: Offset(0, 2),
        )],
      ),
      child: InkWell(
        onTap:         () => _showDetails(item),
        borderRadius:  BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(children: [
            // Icon
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color:        color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            SizedBox(width: 16),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(
                      child: Text(_details(item),
                          style: TextStyle(
                              fontSize:   15,
                              fontWeight: FontWeight.w600,
                              color:      colorScheme.onSurface)),
                    ),
                    _statusBadge(_statusLabel(item)),
                  ]),
                  SizedBox(height: 6),
                  Row(children: [
                    Icon(Icons.person_outline, size: 14,
                        color: colorScheme.onSurface.withOpacity(0.5)),
                    SizedBox(width: 4),
                    Text(_userName(item),
                        style: TextStyle(
                            fontSize: 13,
                            color:    colorScheme.onSurface.withOpacity(0.6))),
                    SizedBox(width: 16),
                    Icon(Icons.insert_drive_file_outlined, size: 14,
                        color: colorScheme.onSurface.withOpacity(0.5)),
                    SizedBox(width: 4),
                    Expanded(
                      child: Text(_fileName(item),
                          style: TextStyle(
                              fontSize: 13,
                              color:    colorScheme.onSurface.withOpacity(0.6)),
                          overflow: TextOverflow.ellipsis),
                    ),
                  ]),
                  SizedBox(height: 6),
                  Row(children: [
                    Icon(Icons.access_time, size: 14,
                        color: colorScheme.onSurface.withOpacity(0.5)),
                    SizedBox(width: 4),
                    Text(timeAgo,
                        style: TextStyle(
                            fontSize: 12,
                            color:    colorScheme.onSurface.withOpacity(0.5))),
                  ]),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: theme.dividerColor),
          ]),
        ),
      ),
    );
  }

  Widget _statusBadge(String status) {
    final theme = Theme.of(context);
    Color    color;
    IconData icon;
    switch (status) {
      case 'Success':
        color = Color(0xFF10b981); icon = Icons.check_circle; break;
      case 'Failed':
        color = theme.colorScheme.error; icon = Icons.error; break;
      case 'Pending':
        color = Color(0xFFf59e0b); icon = Icons.pending; break;
      default:
        color = theme.colorScheme.onSurface.withOpacity(0.5);
        icon  = Icons.info;
    }
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color:        color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: color),
        SizedBox(width: 4),
        Text(status,
            style: TextStyle(
                fontSize:   11,
                fontWeight: FontWeight.w600,
                color:      color)),
      ]),
    );
  }

  // ── Detail dialog ─────────────────────────────────────────────────────────
  void _showDetails(Map<String, dynamic> item) {
    final colorScheme = Theme.of(context).colorScheme;
    final date        = _parseDate(item);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: colorScheme.surface,
        title: Row(children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color:        _colorFor(item).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_iconFor(item),
                color: _colorFor(item), size: 24),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text('Action Details',
                style: TextStyle(
                    fontSize:   20,
                    fontWeight: FontWeight.bold,
                    color:      colorScheme.onSurface)),
          ),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailRow('Action Type', _actionLabel(item)),
            SizedBox(height: 12),
            _detailRow('User',        _userName(item)),
            SizedBox(height: 12),
            _detailRow('File Name',   _fileName(item)),
            SizedBox(height: 12),
            _detailRow('Details',     _details(item)),
            SizedBox(height: 12),
            _detailRow('Status',      _statusLabel(item)),
            SizedBox(height: 12),
            _detailRow('Date & Time', date != null ? _timeAgo(date) : '—'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Close',
                style: TextStyle(color: colorScheme.primary)),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: TextStyle(
              fontSize:   12,
              fontWeight: FontWeight.w600,
              color:      colorScheme.onSurface.withOpacity(0.6))),
      SizedBox(height: 4),
      Text(value,
          style: TextStyle(fontSize: 14, color: colorScheme.onSurface)),
    ]);
  }

  // ── Time ago helper ───────────────────────────────────────────────────────
  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 7)      return '${date.day}/${date.month}/${date.year}';
    if (diff.inDays  > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }
}