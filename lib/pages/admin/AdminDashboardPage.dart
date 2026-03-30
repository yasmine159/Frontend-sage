import 'dart:math';
import 'package:flutter/material.dart';
import 'package:frontend_sage3/services/api_service.dart';
import 'package:frontend_sage3/services/auth_service.dart';

class AdminDashboardPage extends StatefulWidget {
  @override
  _AdminDashboardPageState createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  List<Map<String, dynamic>> _users    = [];
  List<Map<String, dynamic>> _activity = [];
  List<Map<String, dynamic>> _models   = [];
  Map<String, dynamic>       _stats    = {};

  bool    _loadingUsers    = true;
  bool    _loadingActivity = true;
  bool    _loadingStats    = true;
  bool    _loadingModels   = true;
  String? _usersError;
  String? _activityError;
  String? _modelsError;

  String _userSearch     = '';
  String _activitySearch = '';
  String _modelSearch    = '';

  late AnimationController _animCtrl;
  late Animation<double>   _fadeAnim;

  String get _adminUsername => AuthService.instance.currentUser?.username ?? 'Admin';
  String get _adminEmail    => AuthService.instance.currentUser?.email    ?? '';
  String get _adminInitials {
    final parts = _adminUsername.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return _adminUsername.length >= 2
        ? _adminUsername.substring(0, 2).toUpperCase()
        : _adminUsername.toUpperCase();
  }

  final List<Map<String, dynamic>> _menuItems = [
    {'icon': Icons.dashboard_outlined,   'label': 'Dashboard'},
    {'icon': Icons.people_outline,       'label': 'Utilisateurs'},
    {'icon': Icons.history,              'label': 'Activité'},
    {'icon': Icons.description_outlined, 'label': 'Templates'},
    {'icon': Icons.settings_outlined,    'label': 'Paramètres'},
  ];

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: Duration(milliseconds: 500));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
    _loadAll();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    _animCtrl.reset();
    _animCtrl.forward();
    await Future.wait([_loadUsers(), _loadActivity(), _loadStats(), _loadModels()]);
  }

  Future<void> _loadUsers() async {
    setState(() { _loadingUsers = true; _usersError = null; });
    try {
      final data = await ApiService().getUsers();
      setState(() { _users = data; _loadingUsers = false; });
    } catch (e) {
      setState(() { _usersError = e.toString().replaceFirst('Exception: ', ''); _loadingUsers = false; });
    }
  }

  Future<void> _loadActivity() async {
    setState(() { _loadingActivity = true; _activityError = null; });
    try {
      final data = await ApiService().getAllHistory();
      setState(() { _activity = data; _loadingActivity = false; });
    } catch (e) {
      setState(() { _activityError = e.toString().replaceFirst('Exception: ', ''); _loadingActivity = false; });
    }
  }

  Future<void> _loadStats() async {
    setState(() => _loadingStats = true);
    try {
      final data = await ApiService().getAdminStats();
      setState(() { _stats = data; _loadingStats = false; });
    } catch (_) {
      setState(() => _loadingStats = false);
    }
  }

  Future<void> _loadModels() async {
    setState(() { _loadingModels = true; _modelsError = null; });
    try {
      final data = await ApiService().getModels();
      setState(() { _models = data; _loadingModels = false; });
    } catch (e) {
      setState(() { _modelsError = e.toString().replaceFirst('Exception: ', ''); _loadingModels = false; });
    }
  }

  void _navigate(int index) {
    setState(() => _selectedIndex = index);
    _animCtrl.reset();
    _animCtrl.forward();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  String _userStatus(Map<String, dynamic> user) {
    final v = user['isActive'] ?? user['is_active'] ?? true;
    return v == true ? 'Actif' : 'Suspendu';
  }

  Color _statusColor(String s) => switch (s.toLowerCase()) {
    'actif'    => Color(0xFF10b981),
    'suspendu' => Color(0xFFef4444),
    _          => Color(0xFF94a3b8),
  };

  Color _roleColor(String r) =>
      r.toLowerCase() == 'admin' ? Color(0xFF8b5cf6) : Color(0xFF0ea5e9);

  String _userName(Map<String, dynamic> i)  => i['username'] ?? i['userName'] ?? i['user'] ?? '—';
  String _userEmail(Map<String, dynamic> i) => i['email'] ?? '—';
  String _userRole(Map<String, dynamic> i)  => i['role'] ?? 'User';

  String _activityFileName(Map<String, dynamic> i) =>
      i['fileName'] ?? i['file'] ?? i['filename'] ?? '—';

  String _activityStatus(Map<String, dynamic> item) {
    final raw = item['status'] ?? '';
    return switch (raw.toString().toLowerCase()) {
      'converted' => 'Succès',
      'error'     => 'Échec',
      'pending'   => 'En attente',
      _           => raw.isEmpty ? '—' : raw,
    };
  }

  Color _activityStatusColor(Map<String, dynamic> item) => switch (_activityStatus(item)) {
    'Succès'     => Color(0xFF10b981),
    'Échec'      => Color(0xFFef4444),
    'En attente' => Color(0xFFf59e0b),
    _            => Color(0xFF94a3b8),
  };

  String _timeAgo(Map<String, dynamic> item) {
    final raw = item['uploadDate'] ?? item['date'] ?? item['createdAt'];
    if (raw == null) return '—';
    try {
      final date = DateTime.parse(raw.toString()).toLocal();
      final diff = DateTime.now().difference(date);
      if (diff.inDays > 7)    return '${date.day}/${date.month}/${date.year}';
      if (diff.inDays > 0)    return 'Il y a ${diff.inDays}j';
      if (diff.inHours > 0)   return 'Il y a ${diff.inHours}h';
      if (diff.inMinutes > 0) return 'Il y a ${diff.inMinutes}min';
      return 'À l\'instant';
    } catch (_) { return '—'; }
  }

  String _formatDate(dynamic raw) {
    if (raw == null) return '—';
    try {
      final d = DateTime.parse(raw.toString()).toLocal();
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    } catch (_) { return '—'; }
  }

  // ── Chart data ────────────────────────────────────────────────────────────
  List<_ChartBar> _buildChartData() {
    final now  = DateTime.now();
    final bars = <_ChartBar>[];
    for (int i = 6; i >= 0; i--) {
      final day   = now.subtract(Duration(days: i));
      final count = _activity.where((a) {
        final raw = a['uploadDate'] ?? a['date'] ?? '';
        try {
          final d = DateTime.parse(raw.toString()).toLocal();
          return d.year == day.year && d.month == day.month && d.day == day.day;
        } catch (_) { return false; }
      }).length;
      bars.add(_ChartBar(label: _dayLabel(day.weekday), count: count, isToday: i == 0));
    }
    return bars;
  }

  String _dayLabel(int weekday) => switch (weekday) {
    1 => 'Lun', 2 => 'Mar', 3 => 'Mer',
    4 => 'Jeu', 5 => 'Ven', 6 => 'Sam', 7 => 'Dim', _ => '',
  };

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 1024;
    return Scaffold(
      key:             _scaffoldKey,
      backgroundColor: Color(0xFFf1f5f9),
      drawer:          isDesktop ? null : _buildDrawer(),
      body: Row(children: [
        if (isDesktop) _buildSidebar(),
        Expanded(child: Column(children: [
          _buildTopBar(isDesktop),
          Expanded(child: FadeTransition(
            opacity: _fadeAnim,
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isDesktop ? 32 : 16),
              child:   _buildCurrentSection(isDesktop),
            ),
          )),
        ])),
      ]),
    );
  }

  Widget _buildCurrentSection(bool isDesktop) => switch (_selectedIndex) {
    0 => _buildDashboard(isDesktop),
    1 => _buildUsersSection(isDesktop),
    2 => _buildActivitySection(isDesktop),
    3 => _buildTemplatesSection(isDesktop),
    4 => _buildSettingsSection(isDesktop),
    _ => _buildDashboard(isDesktop),
  };

  // ── Sidebar ───────────────────────────────────────────────────────────────
  Widget _buildSidebar() {
    return Container(
      width: 260,
      decoration: BoxDecoration(
        color:     Color(0xFF0f172a),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20)],
      ),
      child: Column(children: [
        Container(
          padding: EdgeInsets.fromLTRB(24, 28, 24, 20),
          child: Row(children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                gradient:     LinearGradient(colors: [Color(0xFF6366f1), Color(0xFF8b5cf6)]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.admin_panel_settings, color: Colors.white, size: 24),
            ),
            SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('SageX3', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              Text('Admin Panel', style: TextStyle(fontSize: 11, color: Color(0xFF6366f1), fontWeight: FontWeight.w500)),
            ]),
          ]),
        ),
        Divider(height: 1, color: Colors.white.withOpacity(0.08)),
        SizedBox(height: 10),
        ...List.generate(_menuItems.length, (i) {
          final sel = _selectedIndex == i;
          return Container(
            margin: EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            child: InkWell(
              onTap: () => _navigate(i),
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                decoration: BoxDecoration(
                  color:        sel ? Color(0xFF6366f1).withOpacity(0.15) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border:       sel ? Border.all(color: Color(0xFF6366f1).withOpacity(0.3)) : null,
                ),
                child: Row(children: [
                  Icon(_menuItems[i]['icon'],
                      color: sel ? Color(0xFF818cf8) : Color(0xFF64748b), size: 20),
                  SizedBox(width: 12),
                  Expanded(child: Text(_menuItems[i]['label'],
                      style: TextStyle(
                        fontSize:   14,
                        fontWeight: sel ? FontWeight.w600 : FontWeight.normal,
                        color:      sel ? Colors.white : Color(0xFF94a3b8),
                      ))),
                  if (i == 2 && _activity.isNotEmpty)
                    _sideBadge('${_activity.length > 9 ? "9+" : _activity.length}', Color(0xFFef4444)),
                  if (i == 1 && _users.isNotEmpty)
                    _sideBadge('${_users.length}', Color(0xFF6366f1)),
                ]),
              ),
            ),
          );
        }),
        Spacer(),
        Container(
          margin:  EdgeInsets.fromLTRB(12, 0, 12, 16),
          padding: EdgeInsets.all(14),
          decoration: BoxDecoration(
            color:        Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(14),
            border:       Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Row(children: [
            CircleAvatar(
              radius: 18, backgroundColor: Color(0xFF6366f1),
              child: Text(_adminInitials,
                  style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
            SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_adminUsername,
                  style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis),
              Text(_adminEmail,
                  style: TextStyle(color: Color(0xFF64748b), fontSize: 10),
                  overflow: TextOverflow.ellipsis),
            ])),
          ]),
        ),
      ]),
    );
  }

  Widget _sideBadge(String val, Color color) => Container(
    padding: EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
    child: Text(val, style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
  );

  // ── Drawer mobile ─────────────────────────────────────────────────────────
  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: Color(0xFF0f172a),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.only(
          topRight: Radius.circular(24), bottomRight: Radius.circular(24))),
      child: SafeArea(child: Column(children: [
        Container(
          padding: EdgeInsets.all(20),
          child: Row(children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Color(0xFF6366f1), Color(0xFF8b5cf6)]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.admin_panel_settings, color: Colors.white, size: 22),
            ),
            SizedBox(width: 10),
            Text('Admin Panel', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            Spacer(),
            IconButton(icon: Icon(Icons.close, color: Color(0xFF64748b)),
                onPressed: () => Navigator.pop(context)),
          ]),
        ),
        Divider(color: Colors.white.withOpacity(0.08)),
        ...List.generate(_menuItems.length, (i) {
          final sel = _selectedIndex == i;
          return ListTile(
            leading: Icon(_menuItems[i]['icon'],
                color: sel ? Color(0xFF818cf8) : Color(0xFF64748b), size: 20),
            title: Text(_menuItems[i]['label'],
                style: TextStyle(color: sel ? Colors.white : Color(0xFF94a3b8), fontSize: 14)),
            tileColor: sel ? Color(0xFF6366f1).withOpacity(0.15) : Colors.transparent,
            onTap: () { Navigator.pop(context); _navigate(i); },
          );
        }),
      ])),
    );
  }

  // ── Top bar ───────────────────────────────────────────────────────────────
  Widget _buildTopBar(bool isDesktop) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color:     Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Row(children: [
        if (!isDesktop)
          IconButton(icon: Icon(Icons.menu, color: Color(0xFF0f172a)),
              onPressed: () => _scaffoldKey.currentState?.openDrawer()),
        Icon(Icons.admin_panel_settings, size: 16, color: Color(0xFF6366f1)),
        SizedBox(width: 6),
        Text('Admin', style: TextStyle(fontSize: 13, color: Color(0xFF64748b))),
        Icon(Icons.chevron_right, size: 14, color: Color(0xFF94a3b8)),
        Text(_menuItems[_selectedIndex]['label'],
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0f172a))),
        Spacer(),
        IconButton(
          icon: Icon(Icons.refresh_rounded, color: Color(0xFF64748b), size: 20),
          onPressed: _loadAll, tooltip: 'Rafraîchir',
        ),
        SizedBox(width: 4),
        CircleAvatar(
          radius: 17, backgroundColor: Color(0xFF6366f1),
          child: Text(_adminInitials,
              style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
        ),
        SizedBox(width: 10),
        ElevatedButton.icon(
          onPressed: _showLogoutDialog,
          icon:  Icon(Icons.logout_rounded, size: 16),
          label: Text('Logout', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFFef4444), foregroundColor: Colors.white,
            padding:   EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 0,
          ),
        ),
      ]),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  SECTION 0 — DASHBOARD
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildDashboard(bool isDesktop) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Tableau de bord',
              style: TextStyle(fontSize: isDesktop ? 26 : 20,
                  fontWeight: FontWeight.bold, color: Color(0xFF0f172a))),
          SizedBox(height: 4),
          Text('Vue d\'ensemble — utilisateurs, imports et activité',
              style: TextStyle(fontSize: 13, color: Color(0xFF64748b))),
        ])),
        ElevatedButton.icon(
          onPressed: _showAddUserDialog,
          icon: Icon(Icons.person_add_outlined, size: 16), label: Text('Ajouter'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF6366f1), foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0,
          ),
        ),
      ]),
      SizedBox(height: 24),
      _buildKpiRow(isDesktop),
      SizedBox(height: 24),
      _buildChart(isDesktop),   // ← fixed chart
      SizedBox(height: 24),
      isDesktop
          ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(flex: 3, child: _buildUsersTableWidget(limit: 5)),
              SizedBox(width: 20),
              Expanded(flex: 2, child: _buildActivityFeedWidget(limit: 6)),
            ])
          : Column(children: [
              _buildUsersTableWidget(limit: 5),
              SizedBox(height: 20),
              _buildActivityFeedWidget(limit: 6),
            ]),
    ]);
  }

  // ── Chart (FIXED — no overflow) ───────────────────────────────────────────
  Widget _buildChart(bool isDesktop) {
    final bars   = _buildChartData();
    final maxVal = bars.map((b) => b.count).reduce(max).clamp(1, 9999);

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color(0xFFe2e8f0)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Color(0xFF6366f1).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(Icons.bar_chart_rounded, color: Color(0xFF6366f1), size: 18),
          ),
          SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Imports des 7 derniers jours',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0f172a))),
            Text('Nombre d\'imports par jour',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748b))),
          ]),
          Spacer(),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Color(0xFF6366f1).withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
            child: Text('Total : ${bars.fold(0, (s, b) => s + b.count)}',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6366f1))),
          ),
        ]),
        SizedBox(height: 24),

        if (_loadingActivity)
          Center(child: Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: CircularProgressIndicator(color: Color(0xFF6366f1)),
          ))
        else
          SizedBox(
            height: 180,  // ← increased from 160 to give labels room
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: bars.asMap().entries.map((e) {
                final bar      = e.value;
                final maxBarH  = 120.0;
                final barH     = bar.count == 0 ? 4.0 : (bar.count / maxVal) * maxBarH;
                final barColor = bar.isToday
                    ? Color(0xFF6366f1)
                    : bar.count > 0
                        ? Color(0xFF6366f1).withOpacity(0.4)
                        : Color(0xFFe2e8f0);

                return Expanded(child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,  // ← KEY FIX: prevents overflow
                  children: [
                    // Count label — fixed height slot
                    SizedBox(
                      height: 18,
                      child: Text(
                        bar.count > 0 ? '${bar.count}' : '',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11, fontWeight: FontWeight.bold,
                          color: bar.isToday ? Color(0xFF6366f1) : Color(0xFF94a3b8),
                        ),
                      ),
                    ),
                    SizedBox(height: 4),
                    // Bar
                    AnimatedContainer(
                      duration: Duration(milliseconds: 600 + e.key * 80),
                      curve:    Curves.easeOutCubic,
                      height:   barH,
                      margin:   EdgeInsets.symmetric(horizontal: 5),
                      decoration: BoxDecoration(
                        color:        barColor,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(6)),
                      ),
                    ),
                    SizedBox(height: 6),
                    // Day label — fixed height slot
                    SizedBox(
                      height: 14,
                      child: Text(bar.label,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: bar.isToday ? FontWeight.bold : FontWeight.normal,
                          color:     bar.isToday ? Color(0xFF6366f1) : Color(0xFF94a3b8),
                        ),
                      ),
                    ),
                    // Today dot — always same height slot to avoid layout shift
                    SizedBox(
                      height: 10,
                      child: bar.isToday
                          ? Center(child: Container(
                              width: 5, height: 5,
                              decoration: BoxDecoration(color: Color(0xFF6366f1), shape: BoxShape.circle)))
                          : SizedBox.shrink(),
                    ),
                  ],
                ));
              }).toList(),
            ),
          ),
      ]),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  SECTION 1 — USERS
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildUsersSection(bool isDesktop) {
    final filtered = _users.where((u) {
      final q = _userSearch.toLowerCase();
      return q.isEmpty
          || _userName(u).toLowerCase().contains(q)
          || _userEmail(u).toLowerCase().contains(q)
          || _userRole(u).toLowerCase().contains(q);
    }).toList();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Gestion des utilisateurs',
              style: TextStyle(fontSize: isDesktop ? 24 : 20,
                  fontWeight: FontWeight.bold, color: Color(0xFF0f172a))),
          SizedBox(height: 4),
          Text('${_users.length} utilisateur(s) enregistré(s)',
              style: TextStyle(fontSize: 13, color: Color(0xFF64748b))),
        ])),
        ElevatedButton.icon(
          onPressed: _showAddUserDialog,
          icon: Icon(Icons.person_add_outlined, size: 16), label: Text('Ajouter'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF6366f1), foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0,
          ),
        ),
      ]),
      SizedBox(height: 20),
      Row(children: [
        _miniStatCard('Total',      '${_users.length}',
            Icons.people_outline,               Color(0xFF6366f1)),
        SizedBox(width: 12),
        _miniStatCard('Actifs',
            '${_users.where((u) => _userStatus(u) == "Actif").length}',
            Icons.check_circle_outline,         Color(0xFF10b981)),
        SizedBox(width: 12),
        _miniStatCard('Suspendus',
            '${_users.where((u) => _userStatus(u) == "Suspendu").length}',
            Icons.block_outlined,               Color(0xFFef4444)),
        SizedBox(width: 12),
        _miniStatCard('Admins',
            '${_users.where((u) => _userRole(u).toLowerCase() == "admin").length}',
            Icons.admin_panel_settings_outlined, Color(0xFF8b5cf6)),
      ]),
      SizedBox(height: 20),
      _searchBar('Rechercher par nom, email ou rôle...', (v) => setState(() => _userSearch = v)),
      SizedBox(height: 16),
      _buildUsersTableWidget(data: filtered, showAll: true),
    ]);
  }

  Widget _miniStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(child: Container(
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFFe2e8f0)),
      ),
      child: Row(children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: color, size: 16),
        ),
        SizedBox(width: 10),
        Flexible(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0f172a))),
          Text(label, style: TextStyle(fontSize: 11, color: Color(0xFF64748b)),
              overflow: TextOverflow.ellipsis),
        ])),
      ]),
    ));
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  SECTION 2 — ACTIVITY
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildActivitySection(bool isDesktop) {
    final filtered = _activity.where((a) {
      final q = _activitySearch.toLowerCase();
      return q.isEmpty
          || _activityFileName(a).toLowerCase().contains(q)
          || (a['username'] ?? '').toString().toLowerCase().contains(q)
          || (a['modelCode'] ?? '').toString().toLowerCase().contains(q);
    }).toList();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Historique des imports',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0f172a))),
      SizedBox(height: 4),
      Text('${_activity.length} import(s) au total',
          style: TextStyle(fontSize: 13, color: Color(0xFF64748b))),
      SizedBox(height: 20),
      Row(children: [
        _miniStatCard('Total',       '${_activity.length}',
            Icons.upload_file,              Color(0xFF0ea5e9)),
        SizedBox(width: 12),
        _miniStatCard('Succès',
            '${_activity.where((a) => _activityStatus(a) == "Succès").length}',
            Icons.check_circle_outline,     Color(0xFF10b981)),
        SizedBox(width: 12),
        _miniStatCard('Échecs',
            '${_activity.where((a) => _activityStatus(a) == "Échec").length}',
            Icons.error_outline,            Color(0xFFef4444)),
        SizedBox(width: 12),
        _miniStatCard('En attente',
            '${_activity.where((a) => _activityStatus(a) == "En attente").length}',
            Icons.hourglass_empty,          Color(0xFFf59e0b)),
      ]),
      SizedBox(height: 20),
      _searchBar('Rechercher par fichier, utilisateur ou modèle...',
          (v) => setState(() => _activitySearch = v)),
      SizedBox(height: 16),
      Container(
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Color(0xFFe2e8f0)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: EdgeInsets.all(20),
            child: Row(children: [
              Text('Tous les imports',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0f172a))),
              SizedBox(width: 10),
              _countBadge('${filtered.length}', Color(0xFF0ea5e9)),
              Spacer(),
              if (_loadingActivity)
                SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF6366f1)))
              else
                IconButton(icon: Icon(Icons.refresh, size: 18, color: Color(0xFF64748b)),
                    onPressed: _loadActivity),
            ]),
          ),
          Divider(height: 1, color: Color(0xFFf1f5f9)),
          if (_loadingActivity)
            Padding(padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator(color: Color(0xFF6366f1))))
          else if (_activityError != null)
            _errorWidget(_activityError!, _loadActivity)
          else if (filtered.isEmpty)
            Padding(padding: EdgeInsets.all(32),
                child: Center(child: Text('Aucun import trouvé',
                    style: TextStyle(color: Color(0xFF94a3b8)))))
          else ...[
            Container(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              color: Color(0xFFf8fafc),
              child: Row(children: [
                Expanded(flex: 3, child: Text('FICHIER',     style: _headerStyle())),
                Expanded(flex: 2, child: Text('UTILISATEUR', style: _headerStyle())),
                Expanded(flex: 2, child: Text('MODÈLE',      style: _headerStyle())),
                Expanded(flex: 2, child: Text('DATE',        style: _headerStyle())),
                Expanded(flex: 1, child: Text('LIGNES',      style: _headerStyle())),
                Expanded(flex: 2, child: Text('STATUT',      style: _headerStyle())),
                SizedBox(width: 40),
              ]),
            ),
            ...filtered.map((a) => _activityTableRow(a)),
          ],
        ]),
      ),
    ]);
  }

  Widget _activityTableRow(Map<String, dynamic> a) {
    final status      = _activityStatus(a);
    final statusColor = _activityStatusColor(a);
    final username    = a['username'] ?? a['userName'] ?? 'Inconnu';
    return Container(
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFf1f5f9)))),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(children: [
          Expanded(flex: 3, child: Row(children: [
            Container(
              width: 30, height: 30,
              decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Icon(Icons.insert_drive_file_outlined, color: statusColor, size: 14),
            ),
            SizedBox(width: 10),
            Expanded(child: Text(_activityFileName(a),
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0f172a)),
                overflow: TextOverflow.ellipsis)),
          ])),
          Expanded(flex: 2, child: Text(username,
              style: TextStyle(fontSize: 12, color: Color(0xFF64748b)),
              overflow: TextOverflow.ellipsis)),
          Expanded(flex: 2, child: Container(
            padding: EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(color: Color(0xFFe0f2fe), borderRadius: BorderRadius.circular(6)),
            child: Text(a['modelCode'] ?? '—',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF0ea5e9)),
                overflow: TextOverflow.ellipsis),
          )),
          Expanded(flex: 2, child: Text(_timeAgo(a),
              style: TextStyle(fontSize: 11, color: Color(0xFF94a3b8)))),
          Expanded(flex: 1, child: Text('${a['rowCount'] ?? 0}',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0f172a)),
              textAlign: TextAlign.center)),
          Expanded(flex: 2, child: Row(children: [
            Container(width: 6, height: 6,
                decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
            SizedBox(width: 5),
            Text(status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor)),
          ])),
          SizedBox(width: 40, child: IconButton(
            icon: Icon(Icons.download_outlined, size: 15, color: Color(0xFF64748b)),
            onPressed: a['status']?.toString().toLowerCase() == 'converted'
                ? () => _downloadCsv(a) : null,
            tooltip: 'Télécharger CSV',
          )),
        ]),
      ),
    );
  }

  Future<void> _downloadCsv(Map<String, dynamic> item) async {
    try {
      await ApiService().downloadCsv(item['id'] as int);
      _showSnack('CSV téléchargé !', Color(0xFF10b981));
    } catch (e) {
      _showSnack(e.toString().replaceFirst('Exception: ', ''), Color(0xFFef4444));
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  SECTION 3 — TEMPLATES
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildTemplatesSection(bool isDesktop) {
    final filtered = _models.where((m) {
      final q = _modelSearch.toLowerCase();
      return q.isEmpty
          || (m['codeModele'] ?? '').toString().toLowerCase().contains(q)
          || (m['objet']      ?? '').toString().toLowerCase().contains(q)
          || (m['texte']      ?? '').toString().toLowerCase().contains(q);
    }).toList();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Modèles d\'import Sage X3',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0f172a))),
      SizedBox(height: 4),
      Text('${_models.length} modèle(s) disponible(s)',
          style: TextStyle(fontSize: 13, color: Color(0xFF64748b))),
      SizedBox(height: 20),
      _searchBar('Rechercher par code, objet ou description...',
          (v) => setState(() => _modelSearch = v)),
      SizedBox(height: 16),
      if (_loadingModels)
        Center(child: Padding(padding: EdgeInsets.all(48),
            child: CircularProgressIndicator(color: Color(0xFF6366f1))))
      else if (_modelsError != null)
        _errorWidget(_modelsError!, _loadModels)
      else if (filtered.isEmpty)
        Center(child: Padding(padding: EdgeInsets.all(48),
            child: Text('Aucun modèle trouvé', style: TextStyle(color: Color(0xFF94a3b8)))))
      else
        GridView.builder(
          shrinkWrap: true,
          physics:    NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount:   isDesktop ? 3 : 2,
            crossAxisSpacing: 16, mainAxisSpacing: 16,
            childAspectRatio: 2.2,
          ),
          itemCount:   filtered.length,
          itemBuilder: (_, i) => _modelCard(filtered[i]),
        ),
    ]);
  }

  Widget _modelCard(Map<String, dynamic> m) {
    final code  = m['codeModele'] ?? '—';
    final objet = m['objet']     ?? '—';
    final texte = m['texte']     ?? '';
    return Container(
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Color(0xFFe2e8f0)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Row(children: [
          Container(
            padding: EdgeInsets.all(7),
            decoration: BoxDecoration(color: Color(0xFFe0f2fe), borderRadius: BorderRadius.circular(8)),
            child: Icon(Icons.description_outlined, color: Color(0xFF0ea5e9), size: 16),
          ),
          SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(code, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0f172a)),
                overflow: TextOverflow.ellipsis),
            Text(objet, style: TextStyle(fontSize: 10, color: Color(0xFF64748b)),
                overflow: TextOverflow.ellipsis),
          ])),
        ]),
        if (texte.isNotEmpty)
          Text(texte, style: TextStyle(fontSize: 9, color: Color(0xFF94a3b8)),
              overflow: TextOverflow.ellipsis),
        Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          TextButton.icon(
            onPressed: () async {
              try {
                await ApiService().downloadTemplate(code);
                _showSnack('Template $code téléchargé !', Color(0xFF10b981));
              } catch (e) {
                _showSnack(e.toString().replaceFirst('Exception: ', ''), Color(0xFFef4444));
              }
            },
            icon:  Icon(Icons.download_outlined, size: 12),
            label: Text('Template', style: TextStyle(fontSize: 10)),
            style: TextButton.styleFrom(
              foregroundColor: Color(0xFF0ea5e9),
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            ),
          ),
        ]),
      ]),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  SECTION 4 — SETTINGS
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildSettingsSection(bool isDesktop) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Paramètres',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0f172a))),
      SizedBox(height: 4),
      Text('Configuration du compte administrateur',
          style: TextStyle(fontSize: 13, color: Color(0xFF64748b))),
      SizedBox(height: 24),
      _settingsCard(
        title: 'Profil administrateur',
        icon: Icons.person_outline, color: Color(0xFF6366f1),
        child: Column(children: [
          _settingsRow('Nom d\'utilisateur', _adminUsername, Icons.person_outline),
          Divider(height: 1, color: Color(0xFFf1f5f9)),
          _settingsRow('Email',              _adminEmail,    Icons.email_outlined),
          Divider(height: 1, color: Color(0xFFf1f5f9)),
          _settingsRow('Rôle',               'Administrateur', Icons.shield_outlined),
        ]),
      ),
      SizedBox(height: 16),
      _settingsCard(
        title: 'Sécurité', icon: Icons.lock_outline, color: Color(0xFF10b981),
        child: _changePasswordWidget(),
      ),
      SizedBox(height: 16),
      _settingsCard(
        title: 'Déconnexion', icon: Icons.warning_amber_outlined, color: Color(0xFFef4444),
        child: Row(children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Color(0xFFef4444).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(Icons.logout_rounded, color: Color(0xFFef4444), size: 20),
          ),
          SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Se déconnecter',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF0f172a))),
            Text('Termine la session et retourne à la connexion',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748b))),
          ])),
          SizedBox(width: 16),
          ElevatedButton.icon(
            onPressed: _showLogoutDialog,
            icon: Icon(Icons.logout_rounded, size: 16), label: Text('Déconnecter'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFef4444), foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), elevation: 0,
            ),
          ),
        ]),
      ),
    ]);
  }

  Widget _settingsCard({required String title, required IconData icon,
      required Color color, required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color(0xFFe2e8f0)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: EdgeInsets.all(18),
          child: Row(children: [
            Container(padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: color, size: 16)),
            SizedBox(width: 12),
            Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0f172a))),
          ]),
        ),
        Divider(height: 1, color: Color(0xFFf1f5f9)),
        Padding(padding: EdgeInsets.all(18), child: child),
      ]),
    );
  }

  Widget _settingsRow(String label, String value, IconData icon) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10),
      child: Row(children: [
        Icon(icon, size: 16, color: Color(0xFF94a3b8)),
        SizedBox(width: 12),
        SizedBox(width: 140, child: Text(label, style: TextStyle(fontSize: 13, color: Color(0xFF64748b)))),
        Expanded(child: Text(value,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0f172a)),
            overflow: TextOverflow.ellipsis)),
      ]),
    );
  }

  Widget _changePasswordWidget() {
    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final cnfCtrl = TextEditingController();
    return StatefulBuilder(builder: (ctx, setLocal) {
      bool    loading    = false;
      String? errorMsg;
      String? successMsg;
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (errorMsg != null)   _alertBox(errorMsg!,   Color(0xFFef4444)),
        if (successMsg != null) _alertBox(successMsg!, Color(0xFF10b981)),
        _dialogField(oldCtrl, 'Ancien mot de passe',    Icons.lock_outline,  obscure: true),
        SizedBox(height: 12),
        _dialogField(newCtrl, 'Nouveau mot de passe',   Icons.lock_open,     obscure: true),
        SizedBox(height: 12),
        _dialogField(cnfCtrl, 'Confirmer mot de passe', Icons.lock_outline,  obscure: true),
        SizedBox(height: 16),
        ElevatedButton(
          onPressed: loading ? null : () async {
            if (newCtrl.text != cnfCtrl.text) {
              setLocal(() => errorMsg = 'Les mots de passe ne correspondent pas.');
              return;
            }
            setLocal(() { loading = true; errorMsg = null; });
            try {
              await ApiService().changePassword(
                  AuthService.instance.currentUser!.id, oldCtrl.text, newCtrl.text);
              setLocal(() { loading = false; successMsg = 'Mot de passe modifié !'; });
              oldCtrl.clear(); newCtrl.clear(); cnfCtrl.clear();
            } catch (e) {
              setLocal(() {
                loading  = false;
                errorMsg = e.toString().replaceFirst('Exception: ', '');
              });
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF10b981), foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 0, minimumSize: Size(double.infinity, 44),
          ),
          child: loading
              ? SizedBox(width: 16, height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text('Changer le mot de passe'),
        ),
      ]);
    });
  }

  Widget _alertBox(String msg, Color color) => Container(
    margin: EdgeInsets.only(bottom: 12),
    padding: EdgeInsets.all(10),
    decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
    child: Text(msg, style: TextStyle(color: color, fontSize: 13)),
  );

  // ══════════════════════════════════════════════════════════════════════════
  //  SHARED WIDGETS
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildKpiRow(bool isDesktop) {
    final totalUsers    = _stats['totalUsers']    ?? _users.length;
    final totalUploads  = _stats['totalUploads']  ?? _activity.length;
    final activeUsers   = _stats['activeUsers']   ??
        _users.where((u) => _userStatus(u) == 'Actif').length;
    final failedUploads = _stats['failedUploads'] ??
        _activity.where((a) => _activityStatus(a) == 'Échec').length;

    final kpis = [
      {'label': 'Utilisateurs', 'value': _loadingStats ? '…' : '$totalUsers',
       'sub': 'Comptes enregistrés', 'icon': Icons.people_outline,
       'color': Color(0xFF6366f1), 'bg': Color(0xFFede9fe)},
      {'label': 'Total Imports', 'value': _loadingStats ? '…' : '$totalUploads',
       'sub': 'Imports au total', 'icon': Icons.cloud_upload_outlined,
       'color': Color(0xFF0ea5e9), 'bg': Color(0xFFe0f2fe)},
      {'label': 'Actifs', 'value': _loadingStats ? '…' : '$activeUsers',
       'sub': 'Comptes actifs', 'icon': Icons.verified_user_outlined,
       'color': Color(0xFF10b981), 'bg': Color(0xFFd1fae5)},
      {'label': 'Échecs', 'value': _loadingStats ? '…' : '$failedUploads',
       'sub': 'À vérifier', 'icon': Icons.error_outline,
       'color': Color(0xFFef4444), 'bg': Color(0xFFfee2e2)},
    ];

    if (isDesktop) {
      return Row(children: kpis.asMap().entries.map((e) => Expanded(
        child: Padding(
          padding: EdgeInsets.only(right: e.key < kpis.length - 1 ? 16 : 0),
          child:   _kpiCard(e.value),
        ),
      )).toList());
    }
    return Column(children: [
      Row(children: [Expanded(child: _kpiCard(kpis[0])), SizedBox(width: 12), Expanded(child: _kpiCard(kpis[1]))]),
      SizedBox(height: 12),
      Row(children: [Expanded(child: _kpiCard(kpis[2])), SizedBox(width: 12), Expanded(child: _kpiCard(kpis[3]))]),
    ]);
  }

  Widget _kpiCard(Map<String, dynamic> k) {
    return Container(
      padding: EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color(0xFFe2e8f0)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(color: k['bg'], borderRadius: BorderRadius.circular(10)),
            child: Icon(k['icon'], color: k['color'], size: 20),
          ),
          Icon(Icons.trending_up, size: 14, color: Color(0xFF10b981)),
        ]),
        SizedBox(height: 14),
        Text(k['value'],
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF0f172a))),
        SizedBox(height: 4),
        Text(k['label'],
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0f172a))),
        SizedBox(height: 2),
        Text(k['sub'], style: TextStyle(fontSize: 11, color: Color(0xFF64748b))),
      ]),
    );
  }

  Widget _buildUsersTableWidget({List<Map<String, dynamic>>? data,
      int? limit, bool showAll = false}) {
    final list = (data ?? _users).take(limit ?? 9999).toList();
    return Container(
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color(0xFFe2e8f0)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: EdgeInsets.all(18),
          child: Row(children: [
            Text('Utilisateurs',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0f172a))),
            SizedBox(width: 10),
            _countBadge('${list.length}', Color(0xFF6366f1)),
            Spacer(),
            if (_loadingUsers)
              SizedBox(width: 18, height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF6366f1)))
            else
              IconButton(icon: Icon(Icons.refresh, size: 18, color: Color(0xFF64748b)),
                  onPressed: _loadUsers),
            if (!showAll)
              TextButton(onPressed: () => _navigate(1),
                  child: Text('Voir tout', style: TextStyle(color: Color(0xFF6366f1), fontSize: 12))),
          ]),
        ),
        Divider(height: 1, color: Color(0xFFf1f5f9)),
        if (_loadingUsers)
          Padding(padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator(color: Color(0xFF6366f1))))
        else if (_usersError != null)
          _errorWidget(_usersError!, _loadUsers)
        else if (list.isEmpty)
          Padding(padding: EdgeInsets.all(32),
              child: Center(child: Text('Aucun utilisateur', style: TextStyle(color: Color(0xFF94a3b8)))))
        else ...[
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            color: Color(0xFFf8fafc),
            child: Row(children: [
              Expanded(flex: 3, child: Text('UTILISATEUR', style: _headerStyle())),
              Expanded(flex: 2, child: Text('RÔLE',        style: _headerStyle())),
              Expanded(flex: 2, child: Text('STATUT',      style: _headerStyle())),
              Expanded(flex: 2, child: Text('EMAIL',       style: _headerStyle())),
              SizedBox(width: 40),
            ]),
          ),
          ...list.map((u) => _userRow(u)),
        ],
      ]),
    );
  }

  Widget _buildActivityFeedWidget({int limit = 8}) {
    final list = _activity.take(limit).toList();
    return Container(
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color(0xFFe2e8f0)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: EdgeInsets.all(18),
          child: Row(children: [
            Text('Activité récente',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0f172a))),
            Spacer(),
            if (_loadingActivity)
              SizedBox(width: 16, height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF6366f1))),
            TextButton(onPressed: () => _navigate(2),
                child: Text('Voir tout', style: TextStyle(color: Color(0xFF6366f1), fontSize: 12))),
          ]),
        ),
        Divider(height: 1, color: Color(0xFFf1f5f9)),
        if (_loadingActivity)
          Padding(padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator(color: Color(0xFF6366f1))))
        else if (_activityError != null)
          _errorWidget(_activityError!, _loadActivity)
        else if (list.isEmpty)
          Padding(padding: EdgeInsets.all(32),
              child: Center(child: Text('Aucune activité', style: TextStyle(color: Color(0xFF94a3b8)))))
        else
          ...list.map((a) => _activityItem(a)),
        SizedBox(height: 8),
      ]),
    );
  }

  Widget _activityItem(Map<String, dynamic> a) {
    final status      = _activityStatus(a);
    final statusColor = _activityStatusColor(a);
    final username    = a['username'] ?? a['userName'] ?? 'Inconnu';
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(Icons.cloud_upload_outlined, color: statusColor, size: 16),
        ),
        SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          RichText(
            maxLines: 2, overflow: TextOverflow.ellipsis,
            text: TextSpan(style: TextStyle(fontSize: 12, color: Color(0xFF0f172a)), children: [
              TextSpan(text: username, style: TextStyle(fontWeight: FontWeight.w600)),
              TextSpan(text: ' — '),
              TextSpan(text: _activityFileName(a),
                  style: TextStyle(color: Color(0xFF6366f1), fontWeight: FontWeight.w500)),
            ]),
          ),
          SizedBox(height: 2),
          Text(_timeAgo(a), style: TextStyle(fontSize: 10, color: Color(0xFF94a3b8))),
        ])),
        SizedBox(width: 8),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
          child: Text(status, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: statusColor)),
        ),
      ]),
    );
  }

  Widget _userRow(Map<String, dynamic> user) {
    final name   = _userName(user);
    final email  = _userEmail(user);
    final role   = _userRole(user);
    final status = _userStatus(user);
    return Container(
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFf1f5f9)))),
      child: InkWell(
        onTap: () => _showUserDetails(user),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(children: [
            Expanded(flex: 3, child: Row(children: [
              CircleAvatar(
                radius: 17, backgroundColor: _roleColor(role).withOpacity(0.15),
                child: Text(name.length >= 2 ? name.substring(0, 2).toUpperCase() : name.toUpperCase(),
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _roleColor(role))),
              ),
              SizedBox(width: 10),
              Expanded(child: Text(name,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0f172a)),
                  overflow: TextOverflow.ellipsis)),
            ])),
            Expanded(flex: 2, child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                  color: _roleColor(role).withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
              child: Text(role,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _roleColor(role)),
                  textAlign: TextAlign.center),
            )),
            Expanded(flex: 2, child: Row(children: [
              Container(width: 6, height: 6,
                  decoration: BoxDecoration(color: _statusColor(status), shape: BoxShape.circle)),
              SizedBox(width: 6),
              Text(status, style: TextStyle(fontSize: 11, color: _statusColor(status), fontWeight: FontWeight.w500)),
            ])),
            Expanded(flex: 2, child: Text(email,
                style: TextStyle(fontSize: 11, color: Color(0xFF94a3b8)), overflow: TextOverflow.ellipsis)),
            PopupMenuButton<String>(
              icon:  Icon(Icons.more_vert, size: 17, color: Color(0xFF94a3b8)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              onSelected: (v) => _handleUserAction(v, user),
              itemBuilder: (_) => [
                PopupMenuItem(value: 'view',   child: _menuItem(Icons.visibility_outlined, 'Voir',      Color(0xFF64748b))),
                PopupMenuItem(value: 'edit',   child: _menuItem(Icons.edit_outlined,       'Modifier',  Color(0xFF0ea5e9))),
                if (status == 'Actif')
                  PopupMenuItem(value: 'suspend',
                      child: _menuItem(Icons.block_outlined,         'Suspendre', Color(0xFFf59e0b)))
                else
                  PopupMenuItem(value: 'activate',
                      child: _menuItem(Icons.check_circle_outline,   'Activer',   Color(0xFF10b981))),
                PopupMenuItem(value: 'delete',
                    child: _menuItem(Icons.delete_outline,            'Supprimer', Color(0xFFef4444))),
              ],
            ),
          ]),
        ),
      ),
    );
  }

  Widget _menuItem(IconData icon, String label, Color color) =>
      Row(children: [Icon(icon, size: 15, color: color), SizedBox(width: 8),
        Text(label, style: TextStyle(color: color, fontSize: 13))]);

  // ── Dialogs ───────────────────────────────────────────────────────────────
  void _showUserDetails(Map<String, dynamic> user) {
    final name = _userName(user); final role = _userRole(user);
    showDialog(context: context, builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(children: [
        CircleAvatar(radius: 22, backgroundColor: _roleColor(role).withOpacity(0.15),
            child: Text(name.length >= 2 ? name.substring(0, 2).toUpperCase() : name.toUpperCase(),
                style: TextStyle(fontWeight: FontWeight.bold, color: _roleColor(role)))),
        SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis),
          Text(_userEmail(user), style: TextStyle(fontSize: 12, color: Color(0xFF64748b)),
              overflow: TextOverflow.ellipsis),
        ])),
      ]),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        _dialogRow('ID',     '#${user['id'] ?? '—'}'),
        _dialogRow('Rôle',   role),
        _dialogRow('Statut', _userStatus(user)),
        _dialogRow('Inscrit', _formatDate(user['createdAt'])),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text('Fermer')),
        ElevatedButton(
          onPressed: () { Navigator.pop(context); _showEditUserDialog(user); },
          style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF6366f1),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          child: Text('Modifier'),
        ),
      ],
    ));
  }

  void _showAddUserDialog() {
    final uCtrl = TextEditingController();
    final eCtrl = TextEditingController();
    final pCtrl = TextEditingController();
    String role = 'User'; bool loading = false; String? err;
    showDialog(context: context, builder: (_) => StatefulBuilder(
      builder: (ctx, setDlg) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Ajouter un utilisateur', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          if (err != null) _alertBox(err!, Color(0xFFef4444)),
          _dialogField(uCtrl, 'Nom d\'utilisateur', Icons.person_outline),
          SizedBox(height: 12),
          _dialogField(eCtrl, 'Email',              Icons.email_outlined),
          SizedBox(height: 12),
          _dialogField(pCtrl, 'Mot de passe',       Icons.lock_outlined, obscure: true),
          SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: role,
            decoration: InputDecoration(labelText: 'Rôle',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true, fillColor: Color(0xFFf8fafc)),
            items: ['User', 'Admin'].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
            onChanged: (v) => setDlg(() => role = v!),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Annuler')),
          ElevatedButton(
            onPressed: loading ? null : () async {
              setDlg(() => loading = true);
              try {
                await ApiService().register(uCtrl.text.trim(), eCtrl.text.trim(), pCtrl.text);
                Navigator.pop(ctx); _loadUsers(); _loadStats();
                _showSnack('Utilisateur ajouté !', Color(0xFF10b981));
              } catch (e) {
                setDlg(() { loading = false; err = e.toString().replaceFirst('Exception: ', ''); });
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF6366f1),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: loading
                ? SizedBox(width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text('Ajouter'),
          ),
        ],
      ),
    ));
  }

  void _showEditUserDialog(Map<String, dynamic> user) {
    final uCtrl = TextEditingController(text: _userName(user));
    final eCtrl = TextEditingController(text: _userEmail(user));
    String role = _userRole(user); bool loading = false; String? err;
    showDialog(context: context, builder: (_) => StatefulBuilder(
      builder: (ctx, setDlg) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Modifier l\'utilisateur', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          if (err != null) _alertBox(err!, Color(0xFFef4444)),
          _dialogField(uCtrl, 'Nom d\'utilisateur', Icons.person_outline),
          SizedBox(height: 12),
          _dialogField(eCtrl, 'Email',              Icons.email_outlined),
          SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: role,
            decoration: InputDecoration(labelText: 'Rôle',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true, fillColor: Color(0xFFf8fafc)),
            items: ['User', 'Admin'].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
            onChanged: (v) => setDlg(() => role = v!),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Annuler')),
          ElevatedButton(
            onPressed: loading ? null : () async {
              setDlg(() => loading = true);
              try {
                await ApiService().updateUser(user['id'] as int,
                    uCtrl.text.trim(), eCtrl.text.trim(), role);
                Navigator.pop(ctx); _loadUsers();
                _showSnack('Utilisateur modifié !', Color(0xFF10b981));
              } catch (e) {
                setDlg(() { loading = false; err = e.toString().replaceFirst('Exception: ', ''); });
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF6366f1),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: loading
                ? SizedBox(width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text('Enregistrer'),
          ),
        ],
      ),
    ));
  }

  void _showDeleteConfirm(Map<String, dynamic> user) {
    showDialog(context: context, builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('Supprimer', style: TextStyle(fontWeight: FontWeight.bold)),
      content: Text('Supprimer ${_userName(user)} ? Cette action est irréversible.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text('Annuler')),
        ElevatedButton(
          onPressed: () async {
            Navigator.pop(context);
            try {
              await ApiService().deleteUser(user['id'] as int);
              _loadUsers(); _loadStats();
              _showSnack('${_userName(user)} supprimé.', Color(0xFFef4444));
            } catch (e) {
              _showSnack(e.toString().replaceFirst('Exception: ', ''), Color(0xFFef4444));
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: Color(0xFFef4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          child: Text('Supprimer'),
        ),
      ],
    ));
  }

  void _handleUserAction(String action, Map<String, dynamic> user) {
    switch (action) {
      case 'view':     _showUserDetails(user);               break;
      case 'edit':     _showEditUserDialog(user);            break;
      case 'delete':   _showDeleteConfirm(user);             break;
      case 'suspend':  _confirmSuspend(user, suspend: true); break;
      case 'activate': _confirmSuspend(user, suspend: false);break;
    }
  }

  void _confirmSuspend(Map<String, dynamic> user, {required bool suspend}) {
    showDialog(context: context, builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(suspend ? 'Suspendre' : 'Activer',
          style: TextStyle(fontWeight: FontWeight.bold)),
      content: Text(suspend
          ? 'Suspendre ${_userName(user)} ? Il ne pourra plus se connecter.'
          : 'Activer ${_userName(user)} ? Il pourra se connecter à nouveau.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text('Annuler')),
        ElevatedButton(
          onPressed: () async {
            Navigator.pop(context);
            try {
              if (suspend) {
                await ApiService().suspendUser(user['id'] as int);
                _showSnack('${_userName(user)} suspendu.', Color(0xFFf59e0b));
              } else {
                await ApiService().activateUser(user['id'] as int);
                _showSnack('${_userName(user)} activé.', Color(0xFF10b981));
              }
              _loadUsers(); _loadStats();
            } catch (e) {
              _showSnack(e.toString().replaceFirst('Exception: ', ''), Color(0xFFef4444));
            }
          },
          style: ElevatedButton.styleFrom(
              backgroundColor: suspend ? Color(0xFFf59e0b) : Color(0xFF10b981),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          child: Text(suspend ? 'Suspendre' : 'Activer'),
        ),
      ],
    ));
  }

  void _showLogoutDialog() {
    showDialog(context: context, builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('Déconnexion', style: TextStyle(fontWeight: FontWeight.bold)),
      content: Text('Voulez-vous vraiment vous déconnecter ?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text('Annuler')),
        ElevatedButton(
          onPressed: () {
            AuthService.instance.logout();
            Navigator.pop(context);
            Navigator.pushReplacementNamed(context, '/login');
          },
          style: ElevatedButton.styleFrom(backgroundColor: Color(0xFFef4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          child: Text('Déconnecter'),
        ),
      ],
    ));
  }

  // ── Micro helpers ─────────────────────────────────────────────────────────
  TextStyle _headerStyle() => TextStyle(
      fontSize: 10, fontWeight: FontWeight.w700,
      color: Color(0xFF94a3b8), letterSpacing: 0.5);

  Widget _countBadge(String val, Color color) => Container(
    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
    child: Text(val, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
  );

  Widget _searchBar(String hint, ValueChanged<String> onChanged) => Container(
    decoration: BoxDecoration(
      color: Colors.white, borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Color(0xFFe2e8f0)),
    ),
    child: TextField(
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText:   hint,
        hintStyle:  TextStyle(color: Color(0xFF94a3b8), fontSize: 13),
        prefixIcon: Icon(Icons.search, color: Color(0xFF94a3b8), size: 18),
        border:     InputBorder.none,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      ),
    ),
  );

  Widget _dialogField(TextEditingController ctrl, String label, IconData icon,
      {bool obscure = false}) => TextField(
    controller: ctrl, obscureText: obscure,
    decoration: InputDecoration(
      labelText: label, prefixIcon: Icon(icon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true, fillColor: Color(0xFFf8fafc),
    ),
  );

  Widget _dialogRow(String label, String value) => Padding(
    padding: EdgeInsets.symmetric(vertical: 6),
    child: Row(children: [
      SizedBox(width: 100, child: Text(label,
          style: TextStyle(fontSize: 12, color: Color(0xFF64748b), fontWeight: FontWeight.w600))),
      Expanded(child: Text(value, style: TextStyle(fontSize: 13, color: Color(0xFF0f172a)))),
    ]),
  );

  Widget _errorWidget(String msg, VoidCallback retry) => Padding(
    padding: EdgeInsets.all(24),
    child: Column(children: [
      Icon(Icons.wifi_off_rounded, color: Color(0xFFef4444).withOpacity(0.5), size: 36),
      SizedBox(height: 8),
      Text(msg, textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: Color(0xFF94a3b8))),
      SizedBox(height: 10),
      TextButton.icon(onPressed: retry, icon: Icon(Icons.refresh, size: 14),
          label: Text('Réessayer'),
          style: TextButton.styleFrom(foregroundColor: Color(0xFF6366f1))),
    ]),
  );

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg), backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }
}

class _ChartBar {
  final String label;
  final int    count;
  final bool   isToday;
  const _ChartBar({required this.label, required this.count, required this.isToday});
}