import 'package:flutter/material.dart';
import 'package:frontend_sage3/services/api_service.dart';
import 'package:frontend_sage3/services/auth_service.dart';

class AdminDashboardPage extends StatefulWidget {
  @override
  _AdminDashboardPageState createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // ── State ─────────────────────────────────────────────────────────────────
  List<Map<String, dynamic>> _users    = [];
  List<Map<String, dynamic>> _activity = [];
  Map<String, dynamic>       _stats    = {};

  bool   _loadingUsers    = true;
  bool   _loadingActivity = true;
  bool   _loadingStats    = true;
  String? _usersError;
  String? _activityError;

  // ── Admin info ────────────────────────────────────────────────────────────
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
    {'icon': Icons.people_outline,       'label': 'Users'},
    {'icon': Icons.history,              'label': 'Activity'},
    {'icon': Icons.description_outlined, 'label': 'Templates'},
    {'icon': Icons.settings_outlined,    'label': 'Settings'},
  ];

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    _loadUsers();
    _loadActivity();
    _loadStats();
  }

  // ── Data loaders ──────────────────────────────────────────────────────────
  Future<void> _loadUsers() async {
    setState(() { _loadingUsers = true; _usersError = null; });
    try {
      final data = await ApiService().getUsers();
      setState(() { _users = data; _loadingUsers = false; });
    } catch (e) {
      setState(() {
        _usersError   = e.toString().replaceFirst('Exception: ', '');
        _loadingUsers = false;
      });
    }
  }

  Future<void> _loadActivity() async {
    setState(() { _loadingActivity = true; _activityError = null; });
    try {
      // ✅ getAllHistory() — no userId filter, returns all imports for admin
      final data = await ApiService().getAllHistory();
      setState(() { _activity = data; _loadingActivity = false; });
    } catch (e) {
      setState(() {
        _activityError    = e.toString().replaceFirst('Exception: ', '');
        _loadingActivity  = false;
      });
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

  // ── Helpers ───────────────────────────────────────────────────────────────
  // ✅ Read isActive from backend
  String _userStatus(Map<String, dynamic> user) {
    final isActive = user['isActive'] ?? user['is_active'] ?? true;
    return isActive == true ? 'Active' : 'Suspended';
  }

  Color _statusColor(String s) {
    switch (s.toLowerCase()) {
      case 'active':    return Color(0xFF10b981);
      case 'suspended': return Color(0xFFef4444);
      default:          return Color(0xFF94a3b8);
    }
  }

  Color _roleColor(String r) =>
      r.toLowerCase() == 'admin' ? Color(0xFF8b5cf6) : Color(0xFF0ea5e9);

  String _userName(Map<String, dynamic> item) =>
      item['username'] ?? item['userName'] ?? item['user'] ?? '—';

  String _userEmail(Map<String, dynamic> item) =>
      item['email'] ?? '—';

  String _userRole(Map<String, dynamic> item) =>
      item['role'] ?? 'User';

  String _activityFileName(Map<String, dynamic> item) =>
      item['fileName'] ?? item['file'] ?? item['filename'] ?? '—';

  String _activityStatus(Map<String, dynamic> item) {
    final raw = item['status'] ?? 'Success';
    // normalize backend status values
    switch (raw.toString().toLowerCase()) {
      case 'converted': return 'Success';
      case 'error':     return 'Failed';
      case 'pending':   return 'Pending';
      default:          return raw[0].toUpperCase() + raw.substring(1);
    }
  }

  Color _activityStatusColor(Map<String, dynamic> item) {
    switch (_activityStatus(item)) {
      case 'Success': return Color(0xFF10b981);
      case 'Failed':  return Color(0xFFef4444);
      default:        return Color(0xFFf59e0b);
    }
  }

  String _timeAgo(Map<String, dynamic> item) {
    final raw = item['uploadDate'] ?? item['date'] ?? item['createdAt'];
    if (raw == null) return '—';
    try {
      final date = DateTime.parse(raw.toString()).toLocal();
      final diff = DateTime.now().difference(date);
      if (diff.inDays  > 7)  return '${date.day}/${date.month}/${date.year}';
      if (diff.inDays  > 0)  return '${diff.inDays}d ago';
      if (diff.inHours > 0)  return '${diff.inHours}h ago';
      if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
      return 'Just now';
    } catch (_) { return '—'; }
  }

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
          Expanded(child: SingleChildScrollView(
            padding: EdgeInsets.all(isDesktop ? 32 : 16),
            child:   _buildBody(isDesktop),
          )),
        ])),
      ]),
    );
  }

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
          padding: EdgeInsets.all(28),
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
        SizedBox(height: 12),
        ...List.generate(_menuItems.length, (i) {
          final sel = _selectedIndex == i;
          return Container(
            margin: EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            child: InkWell(
              onTap:        () => setState(() => _selectedIndex = i),
              borderRadius: BorderRadius.circular(12),
              child: Container(
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
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                          color: Color(0xFFef4444), borderRadius: BorderRadius.circular(10)),
                      child: Text('${_activity.length > 9 ? "9+" : _activity.length}',
                          style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                ]),
              ),
            ),
          );
        }),
        Spacer(),
        GestureDetector(
          onTap: _showLogoutDialog,
          child: Container(
            margin:  EdgeInsets.all(12),
            padding: EdgeInsets.all(14),
            decoration: BoxDecoration(
              color:        Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(14),
              border:       Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Row(children: [
              CircleAvatar(
                radius:          20,
                backgroundColor: Color(0xFF6366f1),
                child: Text(_adminInitials,
                    style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
              ),
              SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_adminUsername,
                    style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis),
                Text(_adminEmail,
                    style: TextStyle(color: Color(0xFF64748b), fontSize: 11),
                    overflow: TextOverflow.ellipsis),
              ])),
              Icon(Icons.logout, color: Color(0xFF64748b), size: 16),
            ]),
          ),
        ),
      ]),
    );
  }

  // ── Drawer (mobile) ───────────────────────────────────────────────────────
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
                gradient:     LinearGradient(colors: [Color(0xFF6366f1), Color(0xFF8b5cf6)]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.admin_panel_settings, color: Colors.white, size: 22),
            ),
            SizedBox(width: 10),
            Text('Admin Panel', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            Spacer(),
            IconButton(
                icon: Icon(Icons.close, color: Color(0xFF64748b)),
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
            onTap: () { Navigator.pop(context); setState(() => _selectedIndex = i); },
          );
        }),
      ])),
    );
  }

  // ── Top bar ───────────────────────────────────────────────────────────────
  Widget _buildTopBar(bool isDesktop) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color:     Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Row(children: [
        if (!isDesktop)
          IconButton(
            icon:      Icon(Icons.menu, color: Color(0xFF0f172a)),
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          ),
        Icon(Icons.admin_panel_settings, size: 18, color: Color(0xFF6366f1)),
        SizedBox(width: 8),
        Text('Admin', style: TextStyle(fontSize: 14, color: Color(0xFF64748b))),
        Icon(Icons.chevron_right, size: 16, color: Color(0xFF94a3b8)),
        Text(_menuItems[_selectedIndex]['label'],
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF0f172a))),
        Spacer(),
        IconButton(
          icon:      Icon(Icons.refresh, color: Color(0xFF64748b), size: 20),
          onPressed: _loadAll,
          tooltip:   'Refresh',
        ),
        SizedBox(width: 4),
        CircleAvatar(
          radius:          18,
          backgroundColor: Color(0xFF6366f1),
          child: Text(_adminInitials,
              style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
        ),
      ]),
    );
  }

  // ── Body ──────────────────────────────────────────────────────────────────
  Widget _buildBody(bool isDesktop) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Admin Dashboard',
              style: TextStyle(
                  fontSize: isDesktop ? 28 : 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0f172a))),
          SizedBox(height: 4),
          Text('Overview of all users, uploads and system activity',
              style: TextStyle(fontSize: 14, color: Color(0xFF64748b))),
        ])),
        ElevatedButton.icon(
          onPressed: _showAddUserDialog,
          icon:  Icon(Icons.person_add_outlined, size: 18),
          label: Text('Add User'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF6366f1),
            foregroundColor: Colors.white,
            padding:         EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
          ),
        ),
      ]),
      SizedBox(height: 28),
      _buildKpiRow(isDesktop),
      SizedBox(height: 28),
      isDesktop
          ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(flex: 3, child: _buildUsersTable()),
              SizedBox(width: 24),
              Expanded(flex: 2, child: _buildActivityFeed()),
            ])
          : Column(children: [
              _buildUsersTable(),
              SizedBox(height: 24),
              _buildActivityFeed(),
            ]),
      SizedBox(height: 28),
      _buildSystemStatus(isDesktop),
    ]);
  }

  // ── KPI row ───────────────────────────────────────────────────────────────
  // ✅ Uses real stats from /api/users/admin/stats
  Widget _buildKpiRow(bool isDesktop) {
    final totalUsers    = _stats['totalUsers']    ?? _users.length;
    final totalUploads  = _stats['totalUploads']  ?? _activity.length;
    final failedUploads = _stats['failedUploads'] ?? 0;

    final kpis = [
      {'label': 'Total Users',    'value': _loadingStats ? '…' : '$totalUsers',    'sub': 'Registered accounts', 'icon': Icons.people_outline,        'color': Color(0xFF6366f1), 'bg': Color(0xFFede9fe)},
      {'label': 'Total Uploads',  'value': _loadingStats ? '…' : '$totalUploads',  'sub': 'All time imports',    'icon': Icons.cloud_upload_outlined,  'color': Color(0xFF0ea5e9), 'bg': Color(0xFFe0f2fe)},
      {'label': 'Active Users',   'value': _loadingStats ? '…' : '${_stats['activeUsers'] ?? '—'}', 'sub': 'Currently active', 'icon': Icons.verified_user_outlined, 'color': Color(0xFF10b981), 'bg': Color(0xFFd1fae5)},
      {'label': 'Failed Uploads', 'value': _loadingStats ? '…' : '$failedUploads', 'sub': 'Needs attention',    'icon': Icons.error_outline,           'color': Color(0xFFef4444), 'bg': Color(0xFFfee2e2)},
    ];

    if (isDesktop) {
      return Row(
        children: kpis.asMap().entries.map((e) => Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: e.key < kpis.length - 1 ? 16 : 0),
            child:   _kpiCard(e.value),
          ),
        )).toList(),
      );
    }
    return Column(children: [
      Row(children: [Expanded(child: _kpiCard(kpis[0])), SizedBox(width: 12), Expanded(child: _kpiCard(kpis[1]))]),
      SizedBox(height: 12),
      Row(children: [Expanded(child: _kpiCard(kpis[2])), SizedBox(width: 12), Expanded(child: _kpiCard(kpis[3]))]),
    ]);
  }

  Widget _kpiCard(Map<String, dynamic> k) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(16),
        border:       Border.all(color: Color(0xFFe2e8f0)),
        boxShadow:    [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(color: k['bg'], borderRadius: BorderRadius.circular(10)),
            child: Icon(k['icon'], color: k['color'], size: 20),
          ),
          Icon(Icons.trending_up, size: 16, color: Color(0xFF10b981)),
        ]),
        SizedBox(height: 16),
        Text(k['value'],
            style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Color(0xFF0f172a))),
        SizedBox(height: 4),
        Text(k['label'],
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF0f172a))),
        SizedBox(height: 4),
        Text(k['sub'], style: TextStyle(fontSize: 12, color: Color(0xFF64748b))),
      ]),
    );
  }

  // ── Users table ───────────────────────────────────────────────────────────
  Widget _buildUsersTable() {
    return Container(
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(16),
        border:       Border.all(color: Color(0xFFe2e8f0)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: EdgeInsets.all(20),
          child: Row(children: [
            Text('Users', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF0f172a))),
            SizedBox(width: 10),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Color(0xFF6366f1).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Text('${_users.length}',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6366f1))),
            ),
            Spacer(),
            if (_loadingUsers)
              SizedBox(width: 18, height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF6366f1)))
            else
              IconButton(icon: Icon(Icons.refresh, size: 18, color: Color(0xFF64748b)),
                  onPressed: _loadUsers, tooltip: 'Refresh'),
          ]),
        ),
        Divider(height: 1, color: Color(0xFFf1f5f9)),
        if (_loadingUsers)
          Padding(padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator(color: Color(0xFF6366f1))))
        else if (_usersError != null)
          _errorWidget(_usersError!, _loadUsers)
        else if (_users.isEmpty)
          Padding(padding: EdgeInsets.all(32),
              child: Center(child: Text('No users found',
                  style: TextStyle(color: Color(0xFF94a3b8)))))
        else ...[
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            color: Color(0xFFf8fafc),
            child: Row(children: [
              Expanded(flex: 3, child: Text('USER',    style: _headerStyle())),
              Expanded(flex: 2, child: Text('ROLE',    style: _headerStyle())),
              Expanded(flex: 2, child: Text('STATUS',  style: _headerStyle())),
              Expanded(flex: 2, child: Text('EMAIL',   style: _headerStyle())),
              SizedBox(width: 40),
            ]),
          ),
          ..._users.map((u) => _userRow(u)),
        ],
      ]),
    );
  }

  TextStyle _headerStyle() => TextStyle(
      fontSize: 11, fontWeight: FontWeight.w700,
      color: Color(0xFF94a3b8), letterSpacing: 0.5);

  Widget _userRow(Map<String, dynamic> user) {
    final name   = _userName(user);
    final email  = _userEmail(user);
    final role   = _userRole(user);
    // ✅ Read real status from backend
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
                radius:          18,
                backgroundColor: _roleColor(role).withOpacity(0.15),
                child: Text(
                  name.length >= 2 ? name.substring(0, 2).toUpperCase() : name.toUpperCase(),
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _roleColor(role)),
                ),
              ),
              SizedBox(width: 10),
              Expanded(child: Text(name,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0f172a)),
                  overflow: TextOverflow.ellipsis)),
            ])),
            Expanded(flex: 2, child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _roleColor(role).withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
              child: Text(role,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _roleColor(role)),
                  textAlign: TextAlign.center),
            )),
            // ✅ Real status dot
            Expanded(flex: 2, child: Row(children: [
              Container(width: 7, height: 7,
                  decoration: BoxDecoration(color: _statusColor(status), shape: BoxShape.circle)),
              SizedBox(width: 6),
              Text(status,
                  style: TextStyle(fontSize: 12, color: _statusColor(status), fontWeight: FontWeight.w500)),
            ])),
            Expanded(flex: 2, child: Text(email,
                style: TextStyle(fontSize: 11, color: Color(0xFF94a3b8)),
                overflow: TextOverflow.ellipsis)),
            // ✅ Suspend/Activate added to menu
            PopupMenuButton<String>(
              icon:  Icon(Icons.more_vert, size: 18, color: Color(0xFF94a3b8)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              onSelected: (v) => _handleUserAction(v, user),
              itemBuilder: (_) => [
                PopupMenuItem(value: 'view',   child: _menuItem(Icons.visibility_outlined, 'View Details', Color(0xFF64748b))),
                PopupMenuItem(value: 'edit',   child: _menuItem(Icons.edit_outlined,       'Edit',         Color(0xFF0ea5e9))),
                if (status == 'Active')
                  PopupMenuItem(value: 'suspend',  child: _menuItem(Icons.block_outlined,       'Suspend',      Color(0xFFf59e0b)))
                else
                  PopupMenuItem(value: 'activate', child: _menuItem(Icons.check_circle_outline, 'Activate',     Color(0xFF10b981))),
                PopupMenuItem(value: 'delete', child: _menuItem(Icons.delete_outline,      'Delete',       Color(0xFFef4444))),
              ],
            ),
          ]),
        ),
      ),
    );
  }

  Widget _menuItem(IconData icon, String label, Color color) =>
      Row(children: [Icon(icon, size: 16, color: color), SizedBox(width: 8),
        Text(label, style: TextStyle(color: color))]);

  // ── Activity feed ─────────────────────────────────────────────────────────
  Widget _buildActivityFeed() {
    return Container(
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(16),
        border:       Border.all(color: Color(0xFFe2e8f0)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: EdgeInsets.all(20),
          child: Row(children: [
            Text('Recent Activity',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF0f172a))),
            Spacer(),
            if (_loadingActivity)
              SizedBox(width: 16, height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF6366f1))),
          ]),
        ),
        Divider(height: 1, color: Color(0xFFf1f5f9)),
        if (_loadingActivity)
          Padding(padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator(color: Color(0xFF6366f1))))
        else if (_activityError != null)
          _errorWidget(_activityError!, _loadActivity)
        else if (_activity.isEmpty)
          Padding(padding: EdgeInsets.all(32),
              child: Center(child: Text('No activity yet',
                  style: TextStyle(color: Color(0xFF94a3b8)))))
        else
          ..._activity.take(8).map((a) => _activityItem(a)),
        SizedBox(height: 8),
      ]),
    );
  }

  Widget _activityItem(Map<String, dynamic> a) {
    final status      = _activityStatus(a);
    final statusColor = _activityStatusColor(a);
    // ✅ Use 'username' from backend joined field
    final username    = a['username'] ?? a['userName'] ?? 'Unknown';

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(children: [
        Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
            color: Color(0xFF6366f1).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(Icons.cloud_upload_outlined, color: Color(0xFF6366f1), size: 18),
        ),
        SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          RichText(
            maxLines: 2, overflow: TextOverflow.ellipsis,
            text: TextSpan(
              style: TextStyle(fontSize: 13, color: Color(0xFF0f172a)),
              children: [
                TextSpan(text: username, style: TextStyle(fontWeight: FontWeight.w600)),
                TextSpan(text: ' uploaded '),
                TextSpan(text: _activityFileName(a),
                    style: TextStyle(color: Color(0xFF6366f1), fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          SizedBox(height: 3),
          Text(_timeAgo(a), style: TextStyle(fontSize: 11, color: Color(0xFF94a3b8))),
        ])),
        SizedBox(width: 8),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
          child: Text(status,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: statusColor)),
        ),
      ]),
    );
  }

  // ── System status ─────────────────────────────────────────────────────────
  Widget _buildSystemStatus(bool isDesktop) {
    final items = [
      {'label': 'API Server',       'status': 'Operational', 'uptime': '99.9%',  'color': Color(0xFF10b981)},
      {'label': 'Database',         'status': 'Operational', 'uptime': '99.99%', 'color': Color(0xFF10b981)},
      {'label': 'File Storage',     'status': 'Operational', 'uptime': '100%',   'color': Color(0xFF10b981)},
      {'label': 'Processing Queue', 'status': 'Degraded',    'uptime': '94.2%',  'color': Color(0xFFf59e0b)},
    ];
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(16),
        border:       Border.all(color: Color(0xFFe2e8f0)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 10, height: 10,
              decoration: BoxDecoration(color: Color(0xFF10b981), shape: BoxShape.circle)),
          SizedBox(width: 8),
          Text('System Status',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF0f172a))),
        ]),
        SizedBox(height: 16),
        Wrap(
          spacing: 12, runSpacing: 12,
          children: items.map((item) => Container(
            constraints: BoxConstraints(minWidth: 180),
            padding: EdgeInsets.all(14),
            decoration: BoxDecoration(
              color:        (item['color'] as Color).withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border:       Border.all(color: (item['color'] as Color).withOpacity(0.2)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 8, height: 8,
                  decoration: BoxDecoration(color: item['color'] as Color, shape: BoxShape.circle)),
              SizedBox(width: 10),
              Flexible(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(item['label'] as String,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0f172a))),
                SizedBox(height: 2),
                Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(item['status'] as String,
                      style: TextStyle(fontSize: 11, color: item['color'] as Color, fontWeight: FontWeight.w500)),
                  Text('  •  ${item['uptime']}',
                      style: TextStyle(fontSize: 11, color: Color(0xFF94a3b8))),
                ]),
              ])),
            ]),
          )).toList(),
        ),
      ]),
    );
  }

  // ── Error widget ──────────────────────────────────────────────────────────
  Widget _errorWidget(String msg, VoidCallback retry) {
    return Padding(
      padding: EdgeInsets.all(24),
      child: Column(children: [
        Icon(Icons.wifi_off_rounded, color: Color(0xFFef4444).withOpacity(0.5), size: 40),
        SizedBox(height: 8),
        Text(msg, textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Color(0xFF94a3b8))),
        SizedBox(height: 12),
        TextButton.icon(
          onPressed: retry,
          icon: Icon(Icons.refresh, size: 16),
          label: Text('Retry'),
          style: TextButton.styleFrom(foregroundColor: Color(0xFF6366f1)),
        ),
      ]),
    );
  }

  // ── Dialogs ───────────────────────────────────────────────────────────────
  void _showUserDetails(Map<String, dynamic> user) {
    final name   = _userName(user);
    final role   = _userRole(user);
    final status = _userStatus(user);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          CircleAvatar(
            radius:          22,
            backgroundColor: _roleColor(role).withOpacity(0.15),
            child: Text(
              name.length >= 2 ? name.substring(0, 2).toUpperCase() : name.toUpperCase(),
              style: TextStyle(fontWeight: FontWeight.bold, color: _roleColor(role)),
            ),
          ),
          SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            Text(_userEmail(user), style: TextStyle(fontSize: 12, color: Color(0xFF64748b))),
          ]),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          _dialogRow('User ID',    '#${user['id'] ?? '—'}'),
          _dialogRow('Username',   name),
          _dialogRow('Email',      _userEmail(user)),
          _dialogRow('Role',       role),
          _dialogRow('Status',     status),
          _dialogRow('Uploads',    '${user['uploadCount'] ?? 0}'),
          _dialogRow('Joined',     _formatDate(user['createdAt'])),
          _dialogRow('Last login', _formatDate(user['lastLoginAt'])),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Close')),
          ElevatedButton(
            onPressed: () { Navigator.pop(context); _showEditUserDialog(user); },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF6366f1), foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: Text('Edit User'),
          ),
        ],
      ),
    );
  }

  void _showAddUserDialog() {
    final usernameCtrl = TextEditingController();
    final emailCtrl    = TextEditingController();
    final passwordCtrl = TextEditingController();
    String role        = 'User';
    bool   isLoading   = false;
    String? errorMsg;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Add New User', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            if (errorMsg != null) ...[
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Color(0xFFef4444).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Text(errorMsg!, style: TextStyle(color: Color(0xFFef4444), fontSize: 13)),
              ),
              SizedBox(height: 12),
            ],
            _dialogField(usernameCtrl, 'Username',      Icons.person_outline),
            SizedBox(height: 12),
            _dialogField(emailCtrl,    'Email Address', Icons.email_outlined),
            SizedBox(height: 12),
            _dialogField(passwordCtrl, 'Password',      Icons.lock_outlined, obscure: true),
            SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: role,
              decoration: InputDecoration(
                labelText: 'Role',
                border:    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled:    true, fillColor: Color(0xFFf8fafc),
              ),
              items: ['User', 'Admin']
                  .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                  .toList(),
              onChanged: (v) => setDlg(() => role = v!),
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel')),
            ElevatedButton(
              onPressed: isLoading ? null : () async {
                setDlg(() => isLoading = true);
                try {
                  await ApiService().register(
                    usernameCtrl.text.trim(),
                    emailCtrl.text.trim(),
                    passwordCtrl.text,
                  );
                  Navigator.pop(ctx);
                  _loadUsers();
                  _loadStats();
                  _showSnack('User ${usernameCtrl.text} added!', Color(0xFF10b981));
                } catch (e) {
                  setDlg(() {
                    isLoading = false;
                    errorMsg  = e.toString().replaceFirst('Exception: ', '');
                  });
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF6366f1), foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              child: isLoading
                  ? SizedBox(width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text('Add User'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditUserDialog(Map<String, dynamic> user) {
    final usernameCtrl = TextEditingController(text: _userName(user));
    final emailCtrl    = TextEditingController(text: _userEmail(user));
    String role        = _userRole(user);
    bool   isLoading   = false;
    String? errorMsg;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Edit User', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            if (errorMsg != null) ...[
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Color(0xFFef4444).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Text(errorMsg!, style: TextStyle(color: Color(0xFFef4444), fontSize: 13)),
              ),
              SizedBox(height: 12),
            ],
            _dialogField(usernameCtrl, 'Username',      Icons.person_outline),
            SizedBox(height: 12),
            _dialogField(emailCtrl,    'Email Address', Icons.email_outlined),
            SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: role,
              decoration: InputDecoration(
                labelText: 'Role',
                border:    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled:    true, fillColor: Color(0xFFf8fafc),
              ),
              items: ['User', 'Admin']
                  .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                  .toList(),
              onChanged: (v) => setDlg(() => role = v!),
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel')),
            ElevatedButton(
              onPressed: isLoading ? null : () async {
                setDlg(() => isLoading = true);
                try {
                  await ApiService().updateUser(
                    user['id'] as int,
                    usernameCtrl.text.trim(),
                    emailCtrl.text.trim(),
                    role,
                  );
                  Navigator.pop(ctx);
                  _loadUsers();
                  _showSnack('User updated!', Color(0xFF10b981));
                } catch (e) {
                  setDlg(() {
                    isLoading = false;
                    errorMsg  = e.toString().replaceFirst('Exception: ', '');
                  });
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF6366f1), foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              child: isLoading
                  ? SizedBox(width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirm(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete User', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to delete ${_userName(user)}? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ApiService().deleteUser(user['id'] as int);
                _loadUsers();
                _loadStats();
                _showSnack('${_userName(user)} deleted.', Color(0xFFef4444));
              } catch (e) {
                _showSnack(e.toString().replaceFirst('Exception: ', ''), Color(0xFFef4444));
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFef4444), foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }

  // ✅ Handle suspend and activate
  void _handleUserAction(String action, Map<String, dynamic> user) {
    switch (action) {
      case 'view':     _showUserDetails(user);  break;
      case 'edit':     _showEditUserDialog(user); break;
      case 'delete':   _showDeleteConfirm(user); break;
      case 'suspend':  _confirmSuspend(user, suspend: true);  break;
      case 'activate': _confirmSuspend(user, suspend: false); break;
    }
  }

  void _confirmSuspend(Map<String, dynamic> user, {required bool suspend}) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(suspend ? 'Suspend User' : 'Activate User',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(suspend
            ? 'Suspend ${_userName(user)}? They will no longer be able to log in.'
            : 'Activate ${_userName(user)}? They will be able to log in again.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                if (suspend) {
                  await ApiService().suspendUser(user['id'] as int);
                  _showSnack('${_userName(user)} suspended.', Color(0xFFf59e0b));
                } else {
                  await ApiService().activateUser(user['id'] as int);
                  _showSnack('${_userName(user)} activated.', Color(0xFF10b981));
                }
                _loadUsers();
                _loadStats();
              } catch (e) {
                _showSnack(e.toString().replaceFirst('Exception: ', ''), Color(0xFFef4444));
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: suspend ? Color(0xFFf59e0b) : Color(0xFF10b981),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: Text(suspend ? 'Suspend' : 'Activate'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Logout', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to logout?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              AuthService.instance.logout();
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFef4444), foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: Text('Logout'),
          ),
        ],
      ),
    );
  }

  // ── Small helpers ─────────────────────────────────────────────────────────
  Widget _dialogField(TextEditingController ctrl, String label, IconData icon,
      {bool obscure = false}) {
    return TextField(
      controller:  ctrl,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText:  label,
        prefixIcon: Icon(icon),
        border:     OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled:     true, fillColor: Color(0xFFf8fafc),
      ),
    );
  }

  Widget _dialogRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        SizedBox(width: 100, child: Text(label,
            style: TextStyle(fontSize: 12, color: Color(0xFF64748b), fontWeight: FontWeight.w600))),
        Expanded(child: Text(value, style: TextStyle(fontSize: 14, color: Color(0xFF0f172a)))),
      ]),
    );
  }

  String _formatDate(dynamic raw) {
    if (raw == null) return '—';
    try {
      final d = DateTime.parse(raw.toString()).toLocal();
      return '${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year}';
    } catch (_) { return '—'; }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content:         Text(msg),
      backgroundColor: color,
      behavior:        SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }
}