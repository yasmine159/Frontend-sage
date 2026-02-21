import 'package:flutter/material.dart';

class AdminDashboardPage extends StatefulWidget {
  @override
  _AdminDashboardPageState createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // ─── Fake Data ───────────────────────────────────────────────
  final List<Map<String, dynamic>> _users = [
    {'id': '001', 'name': 'John Doe',      'email': 'john@sagex3.com',  'role': 'Admin',    'status': 'Active',   'uploads': 23, 'lastSeen': '2 min ago'},
    {'id': '002', 'name': 'Jane Smith',    'email': 'jane@sagex3.com',  'role': 'Client',   'status': 'Active',   'uploads': 12, 'lastSeen': '1 hour ago'},
    {'id': '003', 'name': 'Bob Johnson',   'email': 'bob@sagex3.com',   'role': 'Client',   'status': 'Inactive', 'uploads': 5,  'lastSeen': '3 days ago'},
    {'id': '004', 'name': 'Alice Williams','email': 'alice@sagex3.com', 'role': 'Client',   'status': 'Active',   'uploads': 31, 'lastSeen': '30 min ago'},
    {'id': '005', 'name': 'Sarah Davis',   'email': 'sarah@sagex3.com', 'role': 'Client',   'status': 'Active',   'uploads': 8,  'lastSeen': '2 hours ago'},
    {'id': '006', 'name': 'Mike Brown',    'email': 'mike@sagex3.com',  'role': 'Client',   'status': 'Suspended','uploads': 0,  'lastSeen': '1 week ago'},
  ];

  final List<Map<String, dynamic>> _recentActivity = [
    {'user': 'Alice Williams', 'action': 'Uploaded',   'file': 'inventory_Q1.xlsx',        'time': '5 min ago',   'status': 'Success', 'color': Color(0xFF10b981)},
    {'user': 'Jane Smith',     'action': 'Downloaded', 'file': 'MES01_template.xlsx',       'time': '18 min ago',  'status': 'Success', 'color': Color(0xFF1e3a8a)},
    {'user': 'John Doe',       'action': 'Uploaded',   'file': 'production_report.xlsx',    'time': '1 hour ago',  'status': 'Failed',  'color': Color(0xFFef4444)},
    {'user': 'Sarah Davis',    'action': 'Downloaded', 'file': 'MES03_template.xlsx',       'time': '2 hours ago', 'status': 'Success', 'color': Color(0xFF1e3a8a)},
    {'user': 'Alice Williams', 'action': 'Uploaded',   'file': 'sales_data_feb.xlsx',       'time': '3 hours ago', 'status': 'Pending', 'color': Color(0xFFf59e0b)},
  ];

  final List<Map<String, dynamic>> _menuItems = [
    {'icon': Icons.dashboard_outlined,    'label': 'Dashboard'},
    {'icon': Icons.people_outline,        'label': 'Users'},
    {'icon': Icons.history,               'label': 'Activity'},
    {'icon': Icons.description_outlined,  'label': 'Templates'},
    {'icon': Icons.settings_outlined,     'label': 'Settings'},
  ];

  // ─── Helpers ─────────────────────────────────────────────────
  Color _statusColor(String s) {
    switch (s) {
      case 'Active':    return Color(0xFF10b981);
      case 'Inactive':  return Color(0xFF94a3b8);
      case 'Suspended': return Color(0xFFef4444);
      default:          return Color(0xFF64748b);
    }
  }

  Color _roleColor(String r) =>
      r == 'Admin' ? Color(0xFF8b5cf6) : Color(0xFF0ea5e9);

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final isDesktop = sw >= 1024;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Color(0xFFf1f5f9),
      drawer: isDesktop ? null : _buildDrawer(),
      body: Row(
        children: [
          if (isDesktop) _buildSidebar(),
          Expanded(
            child: Column(
              children: [
                _buildTopBar(isDesktop),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(isDesktop ? 32 : 16),
                    child: _buildBody(isDesktop),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Sidebar ─────────────────────────────────────────────────
  Widget _buildSidebar() {
    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: Color(0xFF0f172a),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20)],
      ),
      child: Column(
        children: [
          // Logo
          Container(
            padding: EdgeInsets.all(28),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [Color(0xFF6366f1), Color(0xFF8b5cf6)]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.admin_panel_settings, color: Colors.white, size: 24),
                ),
                SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('SageX3', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                    Text('Admin Panel', style: TextStyle(fontSize: 11, color: Color(0xFF6366f1), fontWeight: FontWeight.w500)),
                  ],
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.white.withOpacity(0.08)),
          SizedBox(height: 12),

          // Menu items
          ...List.generate(_menuItems.length, (i) {
            final item = _menuItems[i];
            final sel = _selectedIndex == i;
            return Container(
              margin: EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              child: InkWell(
                onTap: () => setState(() => _selectedIndex = i),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                  decoration: BoxDecoration(
                    color: sel ? Color(0xFF6366f1).withOpacity(0.15) : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: sel ? Border.all(color: Color(0xFF6366f1).withOpacity(0.3)) : null,
                  ),
                  child: Row(
                    children: [
                      Icon(item['icon'], color: sel ? Color(0xFF818cf8) : Color(0xFF64748b), size: 20),
                      SizedBox(width: 12),
                      Text(item['label'],
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: sel ? FontWeight.w600 : FontWeight.normal,
                            color: sel ? Colors.white : Color(0xFF94a3b8),
                          )),
                      if (i == 2) ...[
                        Spacer(),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: Color(0xFFef4444),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text('3', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }),

          Spacer(),

          // Admin profile
          Container(
            margin: EdgeInsets.all(12),
            padding: EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Color(0xFF6366f1),
                  child: Text('AD', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Super Admin', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                      Text('admin@sagex3.com', style: TextStyle(color: Color(0xFF64748b), fontSize: 11), overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                Icon(Icons.logout, color: Color(0xFF64748b), size: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Drawer (mobile) ─────────────────────────────────────────
  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: Color(0xFF0f172a),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(topRight: Radius.circular(24), bottomRight: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [Color(0xFF6366f1), Color(0xFF8b5cf6)]),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.admin_panel_settings, color: Colors.white, size: 22),
                  ),
                  SizedBox(width: 10),
                  Text('Admin Panel', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  Spacer(),
                  IconButton(icon: Icon(Icons.close, color: Color(0xFF64748b)), onPressed: () => Navigator.pop(context)),
                ],
              ),
            ),
            Divider(color: Colors.white.withOpacity(0.08)),
            ...List.generate(_menuItems.length, (i) {
              final item = _menuItems[i];
              final sel = _selectedIndex == i;
              return ListTile(
                leading: Icon(item['icon'], color: sel ? Color(0xFF818cf8) : Color(0xFF64748b), size: 20),
                title: Text(item['label'], style: TextStyle(color: sel ? Colors.white : Color(0xFF94a3b8), fontSize: 14)),
                tileColor: sel ? Color(0xFF6366f1).withOpacity(0.15) : Colors.transparent,
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _selectedIndex = i);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  // ─── Top Bar ─────────────────────────────────────────────────
  Widget _buildTopBar(bool isDesktop) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Row(
        children: [
          if (!isDesktop)
            IconButton(
              icon: Icon(Icons.menu, color: Color(0xFF0f172a)),
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            ),
          // Breadcrumb
          Icon(Icons.admin_panel_settings, size: 18, color: Color(0xFF6366f1)),
          SizedBox(width: 8),
          Text('Admin', style: TextStyle(fontSize: 14, color: Color(0xFF64748b))),
          Icon(Icons.chevron_right, size: 16, color: Color(0xFF94a3b8)),
          Text(
            _menuItems[_selectedIndex]['label'],
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF0f172a)),
          ),
          Spacer(),
          // Search
          if (isDesktop)
            Container(
              width: 220,
              height: 38,
              decoration: BoxDecoration(
                color: Color(0xFFf8fafc),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Color(0xFFe2e8f0)),
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search...',
                  hintStyle: TextStyle(fontSize: 13, color: Color(0xFF94a3b8)),
                  prefixIcon: Icon(Icons.search, size: 16, color: Color(0xFF94a3b8)),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          SizedBox(width: 12),
          // Notification bell
          Stack(
            children: [
              IconButton(
                icon: Icon(Icons.notifications_outlined, color: Color(0xFF64748b)),
                onPressed: () {},
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: Color(0xFFef4444), shape: BoxShape.circle),
                ),
              ),
            ],
          ),
          SizedBox(width: 4),
          CircleAvatar(
            radius: 18,
            backgroundColor: Color(0xFF6366f1),
            child: Text('AD', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ─── Body ─────────────────────────────────────────────────────
  Widget _buildBody(bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Page title
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Admin Dashboard', style: TextStyle(fontSize: isDesktop ? 28 : 22, fontWeight: FontWeight.bold, color: Color(0xFF0f172a))),
                  SizedBox(height: 4),
                  Text('Overview of all users, uploads and system activity', style: TextStyle(fontSize: 14, color: Color(0xFF64748b))),
                ],
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => _showAddUserDialog(),
              icon: Icon(Icons.person_add_outlined, size: 18),
              label: Text('Add User'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF6366f1),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          ],
        ),
        SizedBox(height: 28),

        // KPI Cards
        _buildKpiRow(isDesktop),
        SizedBox(height: 28),

        // Users Table + Activity side by side on desktop
        isDesktop
            ? Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 3, child: _buildUsersTable()),
            SizedBox(width: 24),
            Expanded(flex: 2, child: _buildActivityFeed()),
          ],
        )
            : Column(
          children: [
            _buildUsersTable(),
            SizedBox(height: 24),
            _buildActivityFeed(),
          ],
        ),

        SizedBox(height: 28),
        _buildSystemStatus(isDesktop),
      ],
    );
  }

  // ─── KPI Row ────────────────────────────────────────────────
  Widget _buildKpiRow(bool isDesktop) {
    final kpis = [
      {'label': 'Total Users',     'value': '6',    'sub': '+1 this week',   'icon': Icons.people_outline,       'color': Color(0xFF6366f1), 'bg': Color(0xFFede9fe)},
      {'label': 'Total Uploads',   'value': '45',   'sub': '+8 today',       'icon': Icons.cloud_upload_outlined, 'color': Color(0xFF0ea5e9), 'bg': Color(0xFFe0f2fe)},
      {'label': 'Templates',       'value': '12',   'sub': '3 models active','icon': Icons.description_outlined,  'color': Color(0xFF1e3a8a), 'bg': Color(0xFFdbeafe)},
      {'label': 'Failed Uploads',  'value': '3',    'sub': 'Needs attention', 'icon': Icons.error_outline,         'color': Color(0xFFef4444), 'bg': Color(0xFFfee2e2)},
    ];

    if (isDesktop) {
      return Row(
        children: kpis.map((k) => Expanded(child: Padding(
          padding: EdgeInsets.only(right: kpis.indexOf(k) < kpis.length - 1 ? 16 : 0),
          child: _buildKpiCard(k),
        ))).toList(),
      );
    }

    return Column(
      children: [
        Row(children: [
          Expanded(child: _buildKpiCard(kpis[0])),
          SizedBox(width: 12),
          Expanded(child: _buildKpiCard(kpis[1])),
        ]),
        SizedBox(height: 12),
        Row(children: [
          Expanded(child: _buildKpiCard(kpis[2])),
          SizedBox(width: 12),
          Expanded(child: _buildKpiCard(kpis[3])),
        ]),
      ],
    );
  }

  Widget _buildKpiCard(Map<String, dynamic> k) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color(0xFFe2e8f0)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(color: k['bg'], borderRadius: BorderRadius.circular(10)),
                child: Icon(k['icon'], color: k['color'], size: 20),
              ),
              Icon(Icons.trending_up, size: 16, color: Color(0xFF10b981)),
            ],
          ),
          SizedBox(height: 16),
          Text(k['value'], style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Color(0xFF0f172a))),
          SizedBox(height: 4),
          Text(k['label'], style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF0f172a))),
          SizedBox(height: 4),
          Text(k['sub'], style: TextStyle(fontSize: 12, color: Color(0xFF64748b))),
        ],
      ),
    );
  }

  // ─── Users Table ─────────────────────────────────────────────
  Widget _buildUsersTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color(0xFFe2e8f0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(20),
            child: Row(
              children: [
                Text('Users', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF0f172a))),
                SizedBox(width: 10),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: Color(0xFF6366f1).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('${_users.length}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6366f1))),
                ),
                Spacer(),
                TextButton.icon(
                  onPressed: () {},
                  icon: Icon(Icons.filter_list, size: 16),
                  label: Text('Filter'),
                  style: TextButton.styleFrom(foregroundColor: Color(0xFF64748b)),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Color(0xFFf1f5f9)),
          // Header row
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            color: Color(0xFFf8fafc),
            child: Row(
              children: [
                Expanded(flex: 3, child: Text('USER', style: _headerStyle())),
                Expanded(flex: 2, child: Text('ROLE', style: _headerStyle())),
                Expanded(flex: 2, child: Text('STATUS', style: _headerStyle())),
                Expanded(flex: 1, child: Text('UPLOADS', style: _headerStyle())),
                Expanded(flex: 2, child: Text('LAST SEEN', style: _headerStyle())),
                SizedBox(width: 40),
              ],
            ),
          ),
          // User rows
          ..._users.map((user) => _buildUserRow(user)),
        ],
      ),
    );
  }

  TextStyle _headerStyle() => TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF94a3b8), letterSpacing: 0.5);

  Widget _buildUserRow(Map<String, dynamic> user) {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFf1f5f9))),
      ),
      child: InkWell(
        onTap: () => _showUserDetails(user),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              // Avatar + name
              Expanded(
                flex: 3,
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: _roleColor(user['role']).withOpacity(0.15),
                      child: Text(
                        user['name'].toString().substring(0, 2).toUpperCase(),
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _roleColor(user['role'])),
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user['name'], style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0f172a)), overflow: TextOverflow.ellipsis),
                          Text(user['email'], style: TextStyle(fontSize: 11, color: Color(0xFF94a3b8)), overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Role
              Expanded(
                flex: 2,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _roleColor(user['role']).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(user['role'],
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _roleColor(user['role'])),
                      textAlign: TextAlign.center),
                ),
              ),
              // Status
              Expanded(
                flex: 2,
                child: Row(
                  children: [
                    Container(width: 7, height: 7,
                        decoration: BoxDecoration(color: _statusColor(user['status']), shape: BoxShape.circle)),
                    SizedBox(width: 6),
                    Text(user['status'], style: TextStyle(fontSize: 12, color: _statusColor(user['status']), fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              // Uploads
              Expanded(
                flex: 1,
                child: Text(user['uploads'].toString(),
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0f172a)),
                    textAlign: TextAlign.center),
              ),
              // Last seen
              Expanded(
                flex: 2,
                child: Text(user['lastSeen'], style: TextStyle(fontSize: 12, color: Color(0xFF94a3b8))),
              ),
              // Actions
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, size: 18, color: Color(0xFF94a3b8)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onSelected: (value) => _handleUserAction(value, user),
                itemBuilder: (_) => [
                  PopupMenuItem(value: 'view',    child: Row(children: [Icon(Icons.visibility_outlined, size: 16, color: Color(0xFF64748b)), SizedBox(width: 8), Text('View Details')])),
                  PopupMenuItem(value: 'edit',    child: Row(children: [Icon(Icons.edit_outlined, size: 16, color: Color(0xFF0ea5e9)),    SizedBox(width: 8), Text('Edit')])),
                  PopupMenuItem(value: 'suspend', child: Row(children: [Icon(Icons.block_outlined, size: 16, color: Color(0xFFf59e0b)),   SizedBox(width: 8), Text('Suspend')])),
                  PopupMenuItem(value: 'delete',  child: Row(children: [Icon(Icons.delete_outline, size: 16, color: Color(0xFFef4444)),   SizedBox(width: 8), Text('Delete', style: TextStyle(color: Color(0xFFef4444)))])),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Activity Feed ───────────────────────────────────────────
  Widget _buildActivityFeed() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color(0xFFe2e8f0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(20),
            child: Row(
              children: [
                Text('Recent Activity', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF0f172a))),
                Spacer(),
                TextButton(onPressed: () {}, child: Text('View all', style: TextStyle(fontSize: 13, color: Color(0xFF6366f1)))),
              ],
            ),
          ),
          Divider(height: 1, color: Color(0xFFf1f5f9)),
          ..._recentActivity.map((a) => _buildActivityItem(a)),
          SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildActivityItem(Map<String, dynamic> a) {
    final statusColor = a['status'] == 'Success'
        ? Color(0xFF10b981)
        : a['status'] == 'Failed'
        ? Color(0xFFef4444)
        : Color(0xFFf59e0b);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: (a['color'] as Color).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              a['action'] == 'Uploaded' ? Icons.cloud_upload_outlined : Icons.download_outlined,
              color: a['color'] as Color,
              size: 18,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: TextStyle(fontSize: 13, color: Color(0xFF0f172a)),
                    children: [
                      TextSpan(text: a['user'], style: TextStyle(fontWeight: FontWeight.w600)),
                      TextSpan(text: ' ${a['action'].toString().toLowerCase()} '),
                      TextSpan(text: a['file'], style: TextStyle(color: Color(0xFF6366f1), fontWeight: FontWeight.w500)),
                    ],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 3),
                Text(a['time'], style: TextStyle(fontSize: 11, color: Color(0xFF94a3b8))),
              ],
            ),
          ),
          SizedBox(width: 8),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(a['status'], style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: statusColor)),
          ),
        ],
      ),
    );
  }

  // ─── System Status ───────────────────────────────────────────
  Widget _buildSystemStatus(bool isDesktop) {
    final items = [
      {'label': 'API Server',      'status': 'Operational', 'uptime': '99.9%',  'color': Color(0xFF10b981)},
      {'label': 'File Storage',    'status': 'Operational', 'uptime': '100%',   'color': Color(0xFF10b981)},
      {'label': 'Processing Queue','status': 'Degraded',    'uptime': '94.2%',  'color': Color(0xFFf59e0b)},
      {'label': 'Database',        'status': 'Operational', 'uptime': '99.99%', 'color': Color(0xFF10b981)},
    ];

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color(0xFFe2e8f0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 10, height: 10,
                  decoration: BoxDecoration(color: Color(0xFF10b981), shape: BoxShape.circle)),
              SizedBox(width: 8),
              Text('System Status', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF0f172a))),
            ],
          ),
          SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: items.map((item) => Container(
              constraints: BoxConstraints(minWidth: 180),
              padding: EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: (item['color'] as Color).withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: (item['color'] as Color).withOpacity(0.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 8, height: 8,
                      decoration: BoxDecoration(color: item['color'] as Color, shape: BoxShape.circle)),
                  SizedBox(width: 10),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item['label'] as String, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0f172a))),
                        SizedBox(height: 2),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(item['status'] as String, style: TextStyle(fontSize: 11, color: item['color'] as Color, fontWeight: FontWeight.w500)),
                            Text('  •  ${item['uptime']}', style: TextStyle(fontSize: 11, color: Color(0xFF94a3b8))),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }

  // ─── Dialogs ─────────────────────────────────────────────────
  void _showUserDetails(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: _roleColor(user['role']).withOpacity(0.15),
              child: Text(user['name'].toString().substring(0, 2).toUpperCase(),
                  style: TextStyle(fontWeight: FontWeight.bold, color: _roleColor(user['role']))),
            ),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user['name'], style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                Text(user['email'], style: TextStyle(fontSize: 12, color: Color(0xFF64748b))),
              ],
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _dialogRow('User ID', '#${user['id']}'),
            _dialogRow('Role', user['role']),
            _dialogRow('Status', user['status']),
            _dialogRow('Total Uploads', user['uploads'].toString()),
            _dialogRow('Last Seen', user['lastSeen']),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Close')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF6366f1), foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: Text('Edit User'),
          ),
        ],
      ),
    );
  }

  void _showAddUserDialog() {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    String role = 'Client';

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Add New User', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true, fillColor: Color(0xFFf8fafc),
                ),
              ),
              SizedBox(height: 14),
              TextField(
                controller: emailCtrl,
                decoration: InputDecoration(
                  labelText: 'Email Address',
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true, fillColor: Color(0xFFf8fafc),
                ),
              ),
              SizedBox(height: 14),
              DropdownButtonFormField<String>(
                value: role,
                decoration: InputDecoration(
                  labelText: 'Role',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true, fillColor: Color(0xFFf8fafc),
                ),
                items: ['Admin', 'Client']
                    .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                    .toList(),
                onChanged: (v) => setDialogState(() => role = v!),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('User ${nameCtrl.text} added successfully!'),
                    backgroundColor: Color(0xFF10b981),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF6366f1),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              child: Text('Add User'),
            ),
          ],
        ),
      ),
    );
  }

  void _handleUserAction(String action, Map<String, dynamic> user) {
    if (action == 'view') {
      _showUserDetails(user);
    } else {
      final messages = {
        'edit': 'Editing ${user['name']}...',
        'suspend': '${user['name']} has been suspended.',
        'delete': '${user['name']} has been deleted.',
      };
      final colors = {
        'edit': Color(0xFF0ea5e9),
        'suspend': Color(0xFFf59e0b),
        'delete': Color(0xFFef4444),
      };
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(messages[action]!),
        backgroundColor: colors[action],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }
  }

  Widget _dialogRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(width: 110, child: Text(label, style: TextStyle(fontSize: 12, color: Color(0xFF64748b), fontWeight: FontWeight.w600))),
          Expanded(child: Text(value, style: TextStyle(fontSize: 14, color: Color(0xFF0f172a)))),
        ],
      ),
    );
  }
}