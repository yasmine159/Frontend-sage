import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend_sage3/pages/client/ModelSelectionPage.dart';
import 'package:frontend_sage3/pages/client/ReportPage.dart';
import 'package:frontend_sage3/pages/client/SettingsPage.dart';
import 'package:frontend_sage3/pages/client/UploadPage.dart';
import 'package:frontend_sage3/pages/client/HistoryPage.dart';
import 'package:frontend_sage3/services/auth_service.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  final List<GlobalKey<NavigatorState>> _navigatorKeys = [
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
  ];

  Future<bool> _onWillPop() async {
    final nav = _navigatorKeys[_selectedIndex].currentState;
    if (nav != null && nav.canPop()) {
      nav.pop();
      return false;
    }
    return true;
  }

  final List<Map<String, dynamic>> _menuItems = [
    {'icon': Icons.home_outlined,       'activeIcon': Icons.home,       'label': 'Home'},
    {'icon': Icons.history,             'activeIcon': Icons.history,    'label': 'History'},
    {'icon': Icons.assessment_outlined, 'activeIcon': Icons.assessment, 'label': 'Reports'},
    {'icon': Icons.settings_outlined,   'activeIcon': Icons.settings,   'label': 'Settings'},
  ];

  final List<int> _badges = [0, 0, 3, 0];

  List<Widget> get _pages => [
    _TabNavigator(key: _navigatorKeys[0], child: _DashboardTab()),
    _TabNavigator(key: _navigatorKeys[1], child: HistoryPage()),
    _TabNavigator(key: _navigatorKeys[2], child: ReportsPage()),
    _TabNavigator(key: _navigatorKeys[3], child: SettingsPage()),
  ];

  // ── Helpers ──────────────────────────────────────────────────────────────
  String get _username =>
      AuthService.instance.currentUser?.username ?? 'User';

  String get _userRole =>
      AuthService.instance.currentUser?.role ?? 'User';

  // Two initials from username e.g. "John Doe" → "JD", "alice" → "AL"
  String get _initials {
    final parts = _username.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return _username.length >= 2
        ? _username.substring(0, 2).toUpperCase()
        : _username.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 1024;
    final theme     = Theme.of(context);
    final isDark    = theme.brightness == Brightness.dark;

    final navBg         = isDark ? Color(0xFF1a1d24) : Color(0xFFF4F6F9);
    final navBorder     = isDark ? Color(0xFF2d3139) : Color(0xFFE4E8EF);
    final activeColor   = theme.colorScheme.primary;
    final inactiveColor = isDark ? Color(0xFF8E95A5) : Color(0xFF8E9BB0);

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Row(children: [
          if (isDesktop)
            _buildSidebar(context, navBg, navBorder, activeColor, inactiveColor),
          Expanded(
            child: Column(children: [
              _buildTopBar(context, isDesktop, navBg, navBorder, inactiveColor),
              Expanded(
                child: IndexedStack(
                  index:    _selectedIndex,
                  children: _pages,
                ),
              ),
            ]),
          ),
        ]),
        bottomNavigationBar: isDesktop
            ? null
            : _buildBottomNavBar(
                context, navBg, navBorder, activeColor, inactiveColor),
      ),
    );
  }

  Widget _buildBottomNavBar(BuildContext context, Color navBg,
      Color navBorder, Color activeColor, Color inactiveColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: navBg,
        border: Border(top: BorderSide(color: navBorder, width: 1)),
        boxShadow: [
          BoxShadow(
              color:      isDark
                  ? Colors.black.withOpacity(0.3)
                  : activeColor.withOpacity(0.04),
              blurRadius: 0, offset: Offset(0, -1)),
          BoxShadow(
              color:      Colors.black
                  .withOpacity(isDark ? 0.2 : 0.06),
              blurRadius: 14, offset: Offset(0, -4)),
          BoxShadow(
              color:      Colors.black
                  .withOpacity(isDark ? 0.1 : 0.03),
              blurRadius: 28, offset: Offset(0, -10)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            children: List.generate(_menuItems.length, (index) {
              return _NavItem(
                icon:         _menuItems[index]['icon'],
                activeIcon:   _menuItems[index]['activeIcon'],
                label:        _menuItems[index]['label'],
                isSelected:   _selectedIndex == index,
                badgeCount:   _badges[index],
                activeColor:  activeColor,
                inactiveColor: inactiveColor,
                navBg:        navBg,
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedIndex = index);
                },
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, bool isDesktop, Color navBg,
      Color navBorder, Color inactiveColor) {
    final textColor   = Theme.of(context).colorScheme.onSurface;
    final pageTitles  = [
      'Welcome back, $_username 👋',
      'History',
      'Reports',
      'Settings',
    ];
    final pageSubtitles = [
      'Manage your data templates and uploads',
      'All your past actions in one place',
      'Analytics and reports',
      'Configure your preferences',
    ];
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 28, vertical: 18),
      decoration: BoxDecoration(
        color:  navBg,
        border: Border(bottom: BorderSide(color: navBorder, width: 1)),
      ),
      child: Row(children: [
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(pageTitles[_selectedIndex],
                style: TextStyle(
                  fontSize:   isDesktop ? 22 : 18,
                  fontWeight: FontWeight.w700,
                  color:      textColor,
                  letterSpacing: -0.3,
                )),
            SizedBox(height: 2),
            Text(pageSubtitles[_selectedIndex],
                style: TextStyle(fontSize: 13, color: inactiveColor)),
          ],
        )),
        _NotificationBell(color: inactiveColor, bgColor: navBg),
      ]),
    );
  }

  Widget _buildSidebar(BuildContext context, Color navBg, Color navBorder,
      Color activeColor, Color inactiveColor) {
    final theme     = Theme.of(context);
    final isDark    = theme.brightness == Brightness.dark;
    final textColor = theme.colorScheme.onSurface;

    return Container(
      width: 260,
      decoration: BoxDecoration(
        color:  navBg,
        border: Border(right: BorderSide(color: navBorder, width: 1)),
      ),
      child: Column(children: [
        // Logo
        Container(
          padding: EdgeInsets.fromLTRB(24, 28, 24, 20),
          child: Row(children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1e3a8a), Color(0xFF3b82f6)],
                  begin:  Alignment.topLeft,
                  end:    Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(Icons.analytics_outlined,
                  color: Colors.white, size: 22),
            ),
            SizedBox(width: 12),
            Text('SageX3',
                style: TextStyle(
                  fontSize:   20,
                  fontWeight: FontWeight.w800,
                  color:      textColor,
                  letterSpacing: -0.5,
                )),
          ]),
        ),
        Divider(height: 1, color: navBorder),
        SizedBox(height: 12),

        // Nav items
        ...List.generate(_menuItems.length, (index) {
          final isSelected = _selectedIndex == index;
          final badgeCount = _badges[index];
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            child: InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _selectedIndex = index);
              },
              borderRadius: BorderRadius.circular(10),
              child: AnimatedContainer(
                duration: Duration(milliseconds: 200),
                curve:    Curves.easeInOut,
                padding:  EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                decoration: BoxDecoration(
                  color:        isSelected
                      ? activeColor.withOpacity(0.12)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(children: [
                  AnimatedContainer(
                    duration: Duration(milliseconds: 200),
                    width: 3, height: 18,
                    margin: EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color:        isSelected
                          ? activeColor : Colors.transparent,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Icon(
                    isSelected
                        ? _menuItems[index]['activeIcon']
                        : _menuItems[index]['icon'],
                    color: isSelected ? activeColor : inactiveColor,
                    size:  20,
                  ),
                  SizedBox(width: 12),
                  Expanded(child: Text(_menuItems[index]['label'],
                      style: TextStyle(
                        fontSize:   14,
                        fontWeight: isSelected
                            ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected ? activeColor : inactiveColor,
                      ))),
                  if (badgeCount > 0)
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color:        Color(0xFFef4444),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('$badgeCount',
                          style: TextStyle(
                            color:      Colors.white,
                            fontSize:   11,
                            fontWeight: FontWeight.w700,
                          )),
                    )
                  else if (isSelected)
                    Container(
                      width: 5, height: 5,
                      decoration: BoxDecoration(
                        color: activeColor, shape: BoxShape.circle),
                    ),
                ]),
              ),
            ),
          );
        }),

        Spacer(),

        // ── User card at bottom of sidebar ─────────────────────────────
        Container(
          margin:  EdgeInsets.all(12),
          padding: EdgeInsets.all(14),
          decoration: BoxDecoration(
            color:        isDark
                ? Color(0xFF242830)
                : Colors.white.withOpacity(0.7),
            borderRadius: BorderRadius.circular(12),
            border:       Border.all(color: navBorder),
          ),
          child: Row(children: [
            CircleAvatar(
              radius:          20,
              backgroundColor: activeColor,
              child: Text(_initials,
                  style: TextStyle(
                    color:      Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize:   13,
                  )),
            ),
            SizedBox(width: 10),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_username,
                    style: TextStyle(
                      fontSize:   13,
                      fontWeight: FontWeight.w600,
                      color:      textColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text(_userRole,
                    style: TextStyle(
                        fontSize: 11, color: inactiveColor)),
              ],
            )),
          ]),
        ),
      ]),
    );
  }
}

// ── Nav item widget ───────────────────────────────────────────────────────────
class _NavItem extends StatefulWidget {
  final IconData icon, activeIcon;
  final String   label;
  final bool     isSelected;
  final int      badgeCount;
  final Color    activeColor, inactiveColor, navBg;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon, required this.activeIcon, required this.label,
    required this.isSelected, required this.badgeCount,
    required this.activeColor, required this.inactiveColor,
    required this.navBg, required this.onTap,
  });

  @override
  _NavItemState createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync:           this,
        duration:        Duration(milliseconds: 90),
        reverseDuration: Duration(milliseconds: 220));
    _scale = Tween<double>(begin: 1.0, end: 0.78)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeIn));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  void _onTapDown(_)  => _ctrl.forward();
  void _onTapUp(_)    { _ctrl.reverse(); widget.onTap(); }
  void _onTapCancel() => _ctrl.reverse();

  @override
  Widget build(BuildContext context) {
    final color = widget.isSelected
        ? widget.activeColor : widget.inactiveColor;
    return Expanded(
      child: GestureDetector(
        behavior:    HitTestBehavior.opaque,
        onTapDown:   _onTapDown,
        onTapUp:     _onTapUp,
        onTapCancel: _onTapCancel,
        child: Stack(alignment: Alignment.center, children: [
          Positioned(
            top: 0, left: 16, right: 16,
            child: AnimatedContainer(
              duration: Duration(milliseconds: 220),
              curve:    Curves.easeInOut,
              height:   2.5,
              decoration: BoxDecoration(
                color:        widget.isSelected
                    ? widget.activeColor : Colors.transparent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          ScaleTransition(
            scale: _scale,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: 6),
                Stack(clipBehavior: Clip.none, children: [
                  AnimatedContainer(
                    duration: Duration(milliseconds: 220),
                    curve:    Curves.easeInOut,
                    padding:  EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color:        widget.isSelected
                          ? widget.activeColor.withOpacity(0.12)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: AnimatedSwitcher(
                      duration: Duration(milliseconds: 180),
                      transitionBuilder: (child, anim) =>
                          ScaleTransition(scale: anim, child: child),
                      child: Icon(
                        widget.isSelected
                            ? widget.activeIcon : widget.icon,
                        key:   ValueKey(widget.isSelected),
                        color: color, size: 22,
                      ),
                    ),
                  ),
                  if (widget.badgeCount > 0)
                    Positioned(
                      top: -2, right: -2,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color:        Color(0xFFef4444),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: widget.navBg, width: 1.5),
                        ),
                        constraints: BoxConstraints(
                            minWidth: 15, minHeight: 15),
                        child: Text(
                          widget.badgeCount > 9
                              ? '9+' : '${widget.badgeCount}',
                          style: TextStyle(
                            color:      Colors.white,
                            fontSize:   9,
                            fontWeight: FontWeight.w800,
                            height:     1.1,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ]),
                SizedBox(height: 3),
                AnimatedDefaultTextStyle(
                  duration: Duration(milliseconds: 200),
                  style: TextStyle(
                    fontSize:   10.5,
                    fontWeight: widget.isSelected
                        ? FontWeight.w700 : FontWeight.w400,
                    color:       color,
                    letterSpacing: 0.1,
                  ),
                  child: Text(widget.label),
                ),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

// ── Notification bell ─────────────────────────────────────────────────────────
class _NotificationBell extends StatefulWidget {
  final Color color, bgColor;
  const _NotificationBell(
      {required this.color, required this.bgColor});
  @override
  _NotificationBellState createState() => _NotificationBellState();
}

class _NotificationBellState extends State<_NotificationBell>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync:           this,
        duration:        Duration(milliseconds: 90),
        reverseDuration: Duration(milliseconds: 200));
    _scale = Tween<double>(begin: 1.0, end: 0.82)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeIn));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown:   (_) => _ctrl.forward(),
      onTapUp:     (_) => _ctrl.reverse(),
      onTapCancel: ()  => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Padding(
          padding: EdgeInsets.all(6),
          child: Stack(children: [
            Icon(Icons.notifications_outlined,
                color: widget.color, size: 24),
            Positioned(
              right: 1, top: 1,
              child: Container(
                width: 7, height: 7,
                decoration: BoxDecoration(
                  color:  Color(0xFFef4444),
                  shape:  BoxShape.circle,
                  border: Border.all(
                      color: widget.bgColor, width: 1.5),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ── Dashboard tab ─────────────────────────────────────────────────────────────
class _DashboardTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 1024;
    return SingleChildScrollView(
      padding: EdgeInsets.all(isDesktop ? 32 : 16),
      child:   _buildContent(context, isDesktop),
    );
  }

  Widget _buildContent(BuildContext context, bool isDesktop) {
    final colorScheme = Theme.of(context).colorScheme;
    final sw          = MediaQuery.of(context).size.width;
    final available   = (sw - (isDesktop ? 260.0 : 0.0) -
            (isDesktop ? 64.0 : 32.0) - 24.0)
        .clamp(200.0, double.infinity)
        .toDouble();
    final cardWidth = isDesktop
        ? (available / 2.0).clamp(200.0, 800.0).toDouble()
        : available.clamp(200.0, 800.0).toDouble();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Wrap(spacing: 24, runSpacing: 24, children: [
        _actionCard(
          context:  context,
          title:    'Select Model & Download',
          subtitle: 'Choose a template and download Excel file',
          icon:     Icons.download_rounded,
          color:    Color(0xFF1e3a8a),
          stats:    '12 Templates',
          width:    cardWidth,
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => ModelSelectionPage())),
        ),
        _actionCard(
          context:  context,
          title:    'Upload Excel File',
          subtitle: 'Import and process your data files',
          icon:     Icons.cloud_upload_rounded,
          color:    Color(0xFF0ea5e9),
          stats:    '45 Files Uploaded',
          width:    cardWidth,
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => UploadPage())),
        ),
      ]),
      SizedBox(height: 40),
      Text('Overview',
          style: TextStyle(
              fontSize:   20,
              fontWeight: FontWeight.bold,
              color:      colorScheme.onSurface)),
      SizedBox(height: 20),
      Wrap(spacing: 16, runSpacing: 16, children: [
        _statCard(context, 'Total Templates', '12',
            Icons.description_outlined, Color(0xFF1e3a8a), isDesktop),
        _statCard(context, 'Total Uploads', '45',
            Icons.cloud_upload_outlined, Color(0xFF0ea5e9), isDesktop),
        _statCard(context, 'Success Rate', '98%',
            Icons.check_circle_outline, Color(0xFF10b981), isDesktop),
        _statCard(context, 'Processing', '3',
            Icons.pending_outlined, Color(0xFFf59e0b), isDesktop),
      ]),
      SizedBox(height: 40),
      Text('Recent Activity',
          style: TextStyle(
              fontSize:   20,
              fontWeight: FontWeight.bold,
              color:      colorScheme.onSurface)),
      SizedBox(height: 20),
      _recentActivity(context),
    ]);
  }

  Widget _actionCard({
    required BuildContext context,
    required String       title,
    required String       subtitle,
    required IconData     icon,
    required Color        color,
    required String       stats,
    required double       width,
    required VoidCallback onTap,
  }) {
    final theme       = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return ConstrainedBox(
      constraints: BoxConstraints(
          minWidth: 200, maxWidth: width, minHeight: 150),
      child: InkWell(
        onTap:         onTap,
        borderRadius:  BorderRadius.circular(20),
        child: Container(
          width:   width,
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin:  Alignment.topLeft,
              end:    Alignment.bottomRight,
              colors: [colorScheme.surface, color.withOpacity(0.05)],
            ),
            borderRadius: BorderRadius.circular(20),
            border:       Border.all(color: theme.dividerColor),
            boxShadow: [BoxShadow(
              color:      color.withOpacity(0.1),
              blurRadius: 20, offset: Offset(0, 8),
            )],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color:        color,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [BoxShadow(
                        color:      color.withOpacity(0.3),
                        blurRadius: 10, offset: Offset(0, 4),
                      )],
                    ),
                    child: Icon(icon, color: Colors.white, size: 30),
                  ),
                  Icon(Icons.arrow_forward, color: color, size: 26),
                ],
              ),
              SizedBox(height: 20),
              Text(title,
                  style: TextStyle(
                      fontSize:   20,
                      fontWeight: FontWeight.bold,
                      color:      colorScheme.onSurface)),
              SizedBox(height: 8),
              Text(subtitle,
                  style: TextStyle(
                      fontSize: 14,
                      color:    colorScheme.onSurface.withOpacity(0.6),
                      height:   1.4)),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color:        color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(stats,
                    style: TextStyle(
                      fontSize:   13,
                      fontWeight: FontWeight.w600,
                      color:      color,
                    )),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statCard(BuildContext context, String label, String value,
      IconData icon, Color color, bool isDesktop) {
    final theme       = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final sw          = MediaQuery.of(context).size.width;
    final width       = isDesktop
        ? ((sw - 260.0 - 64.0 - 48.0).clamp(0.0, double.infinity) / 4.0)
            .clamp(100.0, 300.0)
        : ((sw - 32.0 - 16.0).clamp(0.0, double.infinity) / 2.0)
            .clamp(100.0, 300.0);

    return ConstrainedBox(
      constraints: BoxConstraints(
          minWidth: 100, maxWidth: width, minHeight: 100),
      child: Container(
        width:   width,
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color:        colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border:       Border.all(color: theme.dividerColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color:        color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            SizedBox(height: 16),
            Text(value,
                style: TextStyle(
                    fontSize:   28,
                    fontWeight: FontWeight.bold,
                    color:      colorScheme.onSurface)),
            SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 13,
                    color:    colorScheme.onSurface.withOpacity(0.6))),
          ],
        ),
      ),
    );
  }

  Widget _recentActivity(BuildContext context) {
    final theme       = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final items = [
      {'title': 'Template MES01 downloaded',       'time': '2 hours ago', 'icon': Icons.download,    'color': Color(0xFF1e3a8a)},
      {'title': 'inventory_data.xlsx uploaded',    'time': '5 hours ago', 'icon': Icons.check_circle,'color': Color(0xFF10b981)},
      {'title': 'Processing completed',            'time': 'Yesterday',   'icon': Icons.task_alt,    'color': Color(0xFF0ea5e9)},
      {'title': 'Template MES03 downloaded',       'time': '2 days ago',  'icon': Icons.download,    'color': Color(0xFF1e3a8a)},
    ];
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color:        colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border:       Border.all(color: theme.dividerColor),
      ),
      child: Column(
        children: items.map((a) => Padding(
          padding: EdgeInsets.only(bottom: 20),
          child: Row(children: [
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color:        (a['color'] as Color).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(a['icon'] as IconData,
                  color: a['color'] as Color, size: 20),
            ),
            SizedBox(width: 16),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(a['title'] as String,
                    style: TextStyle(
                        fontSize:   14,
                        fontWeight: FontWeight.w500,
                        color:      colorScheme.onSurface)),
                SizedBox(height: 4),
                Text(a['time'] as String,
                    style: TextStyle(
                        fontSize: 12,
                        color:    colorScheme.onSurface.withOpacity(0.5))),
              ],
            )),
          ]),
        )).toList(),
      ),
    );
  }
}

// ── Tab navigator ─────────────────────────────────────────────────────────────
class _TabNavigator extends StatelessWidget {
  final Widget child;
  const _TabNavigator({super.key, required this.child});
  @override
  Widget build(BuildContext context) {
    return Navigator(
      onGenerateRoute: (settings) =>
          MaterialPageRoute(builder: (_) => child, settings: settings),
    );
  }
}