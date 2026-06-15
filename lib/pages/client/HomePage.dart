import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend_sage3/pages/client/ModelSelectionPage.dart';
import 'package:frontend_sage3/pages/client/MappingPage.dart';
import 'package:frontend_sage3/pages/client/ReportPage.dart';
import 'package:frontend_sage3/pages/client/SettingsPage.dart';
import 'package:frontend_sage3/pages/client/UploadPage.dart';
import 'package:frontend_sage3/pages/client/HistoryPage.dart';
import 'package:frontend_sage3/pages/client/OcrScanPage.dart';
import 'package:frontend_sage3/widgets/ChatWidget.dart';
import 'package:frontend_sage3/services/api_service.dart';
import 'package:frontend_sage3/services/auth_service.dart';
import 'package:frontend_sage3/main.dart';
import 'package:frontend_sage3/app_strings.dart';

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
    if (nav != null && nav.canPop()) { nav.pop(); return false; }
    return true;
  }

  String get _username => AuthService.instance.currentUser?.username ?? 'Utilisateur';

  AppStrings get _s => SageX3App.of(context)?.strings ?? AppStrings('fr');

  List<Map<String, dynamic>> get _menuItems => [
    {'icon': Icons.space_dashboard_outlined, 'activeIcon': Icons.space_dashboard, 'label': _s.home},
    {'icon': Icons.history_outlined,         'activeIcon': Icons.history,          'label': _s.history},
    {'icon': Icons.insights_outlined,        'activeIcon': Icons.insights,         'label': _s.reports},
    {'icon': Icons.tune_outlined,            'activeIcon': Icons.tune,             'label': _s.settings},
  ];

  late final List<Widget> _pages = [
    _TabNavigator(key: _navigatorKeys[0], child: _DashboardTab()),
    _TabNavigator(key: _navigatorKeys[1], child: HistoryPage()),
    _TabNavigator(key: _navigatorKeys[2], child: ReportsPage()),
    _TabNavigator(key: _navigatorKeys[3], child: SettingsPage()),
  ];

  void _showLogoutDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => _LogoutDialog(
        username: _username,
        strings: _s,
        onConfirm: () {
          AuthService.instance.logout();
          Navigator.pushReplacementNamed(context, '/login');
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 1024;
    final isDark    = Theme.of(context).brightness == Brightness.dark;
    final sidebarBg     = isDark ? const Color(0xFF101318) : Colors.white;
    final sidebarBorder = isDark ? const Color(0xFF1e2028) : const Color(0xFFf0f0f5);
    final activeColor   = const Color(0xFF2563eb);
    final inactiveColor = isDark ? const Color(0xFF6b7280) : const Color(0xFF9ca3af);
    final scaffoldBg    = isDark ? const Color(0xFF0b0e13) : const Color(0xFFF7F8FA);

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Stack(
        children: [
          Scaffold(
            backgroundColor: scaffoldBg,
            body: Row(children: [
              if (isDesktop) _buildSidebar(context, sidebarBg, sidebarBorder, activeColor, inactiveColor, isDark),
              Expanded(child: Column(children: [
                _buildTopBar(context, isDesktop, sidebarBg, sidebarBorder, activeColor, inactiveColor, isDark),
                Expanded(child: IndexedStack(index: _selectedIndex, children: _pages)),
              ])),
            ]),
            bottomNavigationBar: isDesktop
                ? null
                : _buildBottomNav(context, sidebarBg, sidebarBorder, activeColor, inactiveColor),
          ),
          ChatWidget(),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  SIDEBAR
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildSidebar(BuildContext ctx, Color bg, Color border, Color active, Color inactive, bool isDark) {
    final text = isDark ? Colors.white : const Color(0xFF111827);
    return Container(
      width: 240,
      decoration: BoxDecoration(color: bg, border: Border(right: BorderSide(color: border))),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
          child: Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(color: active, borderRadius: BorderRadius.circular(10)),
              child: const Center(child: Text('S', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800))),
            ),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('SageX3', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: text, letterSpacing: -0.3)),
              Text(_s.importManager, style: TextStyle(fontSize: 11, color: inactive, letterSpacing: 0.2)),
            ]),
          ]),
        ),
        _sidebarSection('MENU', inactive),
        ...List.generate(_menuItems.length, (i) => _sidebarItem(i, active, inactive)),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: Column(children: [
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  Colors.transparent,
                  isDark ? const Color(0xFF1e2028) : const Color(0xFFf0f0f5),
                  Colors.transparent,
                ]),
              ),
            ),
            Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: _showLogoutDialog,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  decoration: BoxDecoration(
                    color: const Color(0xFFdc2626).withOpacity(isDark ? 0.10 : 0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFdc2626).withOpacity(0.22)),
                  ),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.logout_rounded, color: Color(0xFFdc2626), size: 16),
                    const SizedBox(width: 8),
                    Text(_s.logout, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFFdc2626))),
                  ]),
                ),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _sidebarSection(String title, Color inactive) => Padding(
    padding: const EdgeInsets.fromLTRB(28, 20, 28, 8),
    child: Text(title, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
        color: inactive.withOpacity(0.5), letterSpacing: 1.2)),
  );

  Widget _sidebarItem(int i, Color active, Color inactive) {
    final sel = _selectedIndex == i;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 1),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: () { HapticFeedback.selectionClick(); setState(() => _selectedIndex = i); },
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: sel ? active.withOpacity(0.08) : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(children: [
              Icon(sel ? _menuItems[i]['activeIcon'] : _menuItems[i]['icon'], color: sel ? active : inactive, size: 19),
              const SizedBox(width: 12),
              Text(_menuItems[i]['label'], style: TextStyle(fontSize: 13, fontWeight: sel ? FontWeight.w600 : FontWeight.w400, color: sel ? active : inactive)),
            ]),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  TOP BAR
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildTopBar(BuildContext ctx, bool isDesktop, Color bg, Color border, Color active, Color inactive, bool isDark) {
    final text = isDark ? Colors.white : const Color(0xFF111827);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 32 : 20, vertical: 16),
      decoration: BoxDecoration(color: bg, border: Border(bottom: BorderSide(color: border))),
      child: Row(children: [
        if (!isDesktop) Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: active, borderRadius: BorderRadius.circular(10)),
            child: const Center(child: Text('S', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800))),
          ),
        ),
        Text(_menuItems[_selectedIndex]['label'], style: TextStyle(fontSize: isDesktop ? 20 : 17, fontWeight: FontWeight.w700, color: text, letterSpacing: -0.3)),
        const Spacer(),
      ]),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  BOTTOM NAV
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildBottomNav(BuildContext ctx, Color bg, Color border, Color active, Color inactive) {
    return Container(
      decoration: BoxDecoration(
        color: bg,
        border: Border(top: BorderSide(color: border)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4))],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(children: List.generate(_menuItems.length, (i) {
            final sel = _selectedIndex == i;
            return Expanded(child: GestureDetector(
              onTap: () { HapticFeedback.selectionClick(); setState(() => _selectedIndex = i); },
              behavior: HitTestBehavior.opaque,
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: sel ? 32 : 0, height: 3,
                  margin: const EdgeInsets.only(bottom: 6),
                  decoration: BoxDecoration(color: sel ? active : Colors.transparent, borderRadius: BorderRadius.circular(2)),
                ),
                Icon(sel ? _menuItems[i]['activeIcon'] : _menuItems[i]['icon'], color: sel ? active : inactive, size: 20),
                const SizedBox(height: 4),
                Text(_menuItems[i]['label'], style: TextStyle(fontSize: 10, fontWeight: sel ? FontWeight.w600 : FontWeight.w400, color: sel ? active : inactive)),
              ]),
            ));
          })),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  DASHBOARD TAB
// ═══════════════════════════════════════════════════════════════════════════════
class _DashboardTab extends StatefulWidget {
  @override
  _DashboardTabState createState() => _DashboardTabState();
}

class _DashboardTabState extends State<_DashboardTab> {
  Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _history = [];
  bool _loading = true;
  String? _error;

  static const _blue   = Color(0xFF2563eb);
  static const _green  = Color(0xFF059669);
  static const _red    = Color(0xFFdc2626);
  static const _amber  = Color(0xFFd97706);
  static const _violet = Color(0xFF7c3aed);
  static const _cyan   = Color(0xFF0891b2);

  AppStrings get _s => SageX3App.of(context)?.strings ?? AppStrings('fr');

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final r = await Future.wait([
        ApiService().getUserStats(),
        ApiService().getHistory(userId: ApiService.userId),
      ]);
      setState(() {
        _stats   = r[0] as Map<String, dynamic>;
        _history = (r[1] as List<Map<String, dynamic>>).take(5).toList();
        _loading = false;
      });
    } catch (e) {
      setState(() { _error = e.toString().replaceFirst('Exception: ', ''); _loading = false; });
    }
  }

  String get _user    => AuthService.instance.currentUser?.username ?? 'Utilisateur';
  bool   get _isNew   => !_loading && _error == null && (_stats['totalImports'] ?? 0) == 0;
  int    get _total   => _stats['totalImports'] ?? 0;
  int    get _success => _stats['successCount'] ?? 0;
  int    get _failed  => _stats['failedCount']  ?? 0;
  num    get _rate    => _stats['successRate']   ?? 0;
  int    get _rows    => _stats['totalRows']     ?? 0;
  List<Map<String, dynamic>> get _models =>
      (_stats['topModels'] as List?)?.cast<Map<String, dynamic>>() ?? [];

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 1024;
    return RefreshIndicator(
      onRefresh: _load,
      color: _blue,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(isDesktop ? 32 : 20),
        child: _content(context, isDesktop),
      ),
    );
  }

  Widget _content(BuildContext ctx, bool desk) {
    final dk   = Theme.of(ctx).brightness == Brightness.dark;
    final txt  = dk ? Colors.white : const Color(0xFF111827);
    final sub  = dk ? const Color(0xFF6b7280) : const Color(0xFF9ca3af);
    final card = dk ? const Color(0xFF151921) : Colors.white;
    final bord = dk ? const Color(0xFF1e2028) : const Color(0xFFf0f0f5);
    final s    = _s;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (_loading)
        _loader(desk, card, bord)
      else if (_error != null)
        _err(card, bord, txt)
      else ...[
          // ── HERO CARDS ─────────────────────────────────────────────────────
          desk
              ? IntrinsicHeight(
            child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Expanded(child: _heroCard(ctx, dk,
                  title: s.heroModelTitle,
                  desc: s.heroModelDesc,
                  icon: Icons.grid_view_rounded,
                  gradient: [const Color(0xFF7c3aed), const Color(0xFF8b5cf6)],
                  buttonLabel: s.heroModelBtn, buttonIcon: Icons.grid_view_rounded,
                  stat: _isNew ? null : '${_models.length} ${s.modelsCount}',
                  stretch: true,
                  onTap: () => Navigator.push(ctx, MaterialPageRoute(builder: (_) => ModelSelectionPage())))),
              const SizedBox(width: 16),
              Expanded(child: _heroCard(ctx, dk,
                  title: s.heroCsvTitle,
                  desc: s.heroCsvDesc,
                  icon: Icons.cloud_upload_rounded,
                  gradient: [const Color(0xFF2563eb), const Color(0xFF3b82f6)],
                  buttonLabel: s.heroCsvBtn, buttonIcon: Icons.upload_file_rounded,
                  stat: _isNew ? null : '$_total ${s.importsCount}',
                  stretch: true,
                  onTap: () => Navigator.push(ctx, MaterialPageRoute(builder: (_) => UploadPage())))),
              const SizedBox(width: 16),
              Expanded(child: _heroCard(ctx, dk,
                  title: s.heroMappingTitle,
                  desc: s.heroMappingDesc,
                  icon: Icons.account_tree_rounded,
                  gradient: [const Color(0xFF0891b2), const Color(0xFF06b6d4)],
                  buttonLabel: s.heroMappingBtn, buttonIcon: Icons.account_tree_rounded,
                  stat: null,
                  stretch: true,
                  onTap: () => Navigator.push(ctx, MaterialPageRoute(builder: (_) => MappingPage())))),
              const SizedBox(width: 16),
              Expanded(child: _heroCard(ctx, dk,
                  title: s.heroScanTitle,
                  desc: s.heroScanDesc,
                  icon: Icons.document_scanner_rounded,
                  gradient: [const Color(0xFF059669), const Color(0xFF10b981)],
                  buttonLabel: s.heroScanBtn, buttonIcon: Icons.camera_alt_rounded,
                  stat: null,
                  stretch: true,
                  onTap: () => Navigator.push(ctx, MaterialPageRoute(builder: (_) => const OcrScanPage())))),
            ]),
          )
              : Column(children: [
            _heroCard(ctx, dk,
                title: s.heroModelTitle,
                desc: s.heroModelDescShort,
                icon: Icons.grid_view_rounded,
                gradient: [const Color(0xFF7c3aed), const Color(0xFF8b5cf6)],
                buttonLabel: s.heroModelBtn, buttonIcon: Icons.grid_view_rounded,
                stat: _isNew ? null : '${_models.length} ${s.modelsCount}',
                onTap: () => Navigator.push(ctx, MaterialPageRoute(builder: (_) => ModelSelectionPage()))),
            const SizedBox(height: 16),
            _heroCard(ctx, dk,
                title: s.heroCsvTitle,
                desc: s.heroCsvDescShort,
                icon: Icons.cloud_upload_rounded,
                gradient: [const Color(0xFF2563eb), const Color(0xFF3b82f6)],
                buttonLabel: s.heroCsvBtn, buttonIcon: Icons.upload_file_rounded,
                stat: _isNew ? null : '$_total ${s.importsCount}',
                onTap: () => Navigator.push(ctx, MaterialPageRoute(builder: (_) => UploadPage()))),
            const SizedBox(height: 16),
            _heroCard(ctx, dk,
                title: s.heroMappingTitle,
                desc: s.heroMappingDescShort,
                icon: Icons.account_tree_rounded,
                gradient: [const Color(0xFF0891b2), const Color(0xFF06b6d4)],
                buttonLabel: s.heroMappingBtn, buttonIcon: Icons.account_tree_rounded,
                stat: null,
                onTap: () => Navigator.push(ctx, MaterialPageRoute(builder: (_) => MappingPage()))),
            const SizedBox(height: 16),
            _heroCard(ctx, dk,
                title: s.heroScanTitle,
                desc: s.heroScanDescShort,
                icon: Icons.document_scanner_rounded,
                gradient: [const Color(0xFF059669), const Color(0xFF10b981)],
                buttonLabel: s.heroScanBtn, buttonIcon: Icons.camera_alt_rounded,
                stat: null,
                onTap: () => Navigator.push(ctx, MaterialPageRoute(builder: (_) => const OcrScanPage()))),
          ]),

          const SizedBox(height: 28),

          // ── CONTENU SECONDAIRE ─────────────────────────────────────────────
          if (_isNew) ...[
            _howItWorks(ctx, desk, dk, card, bord, txt, sub),
            const SizedBox(height: 24),
            _proTip(ctx, dk, card, bord, txt, sub),
          ] else ...[
            _kpiRow(desk, card, bord, txt, sub),
            const SizedBox(height: 24),
            desk
                ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(flex: 3, child: _activityCard(card, bord, txt, sub)),
              const SizedBox(width: 20),
              Expanded(flex: 2, child: Column(children: [
                _modelsCard(card, bord, txt, sub),
                const SizedBox(height: 20),
                _statsCard(card, bord, txt, sub),
              ])),
            ])
                : Column(children: [
              _activityCard(card, bord, txt, sub),
              const SizedBox(height: 20),
              _modelsCard(card, bord, txt, sub),
              const SizedBox(height: 20),
              _statsCard(card, bord, txt, sub),
            ]),
          ],
        ],
    ]);
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  HERO CARD
  // ─────────────────────────────────────────────────────────────────────────
  Widget _heroCard(
      BuildContext ctx,
      bool dk, {
        required String title,
        required String desc,
        required IconData icon,
        required List<Color> gradient,
        required String buttonLabel,
        required IconData buttonIcon,
        String? stat,
        required VoidCallback onTap,
        bool stretch = false, // true en desktop pour remplir IntrinsicHeight
      }) {
    return Container(
      // En mode stretch (desktop), on laisse IntrinsicHeight dicter la hauteur
      height: stretch ? double.infinity : null,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: dk
              ? [gradient[0].withOpacity(0.2), gradient[1].withOpacity(0.08)]
              : [gradient[0].withOpacity(0.06), gradient[1].withOpacity(0.02)],
        ),
        border: Border.all(color: dk ? gradient[0].withOpacity(0.25) : gradient[0].withOpacity(0.15)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              // stretch=true → mainAxisSize.max pour que le Spacer pousse le bouton en bas
              mainAxisSize: stretch ? MainAxisSize.max : MainAxisSize.min,
              children: [
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: gradient),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [BoxShadow(color: gradient[0].withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6))],
                    ),
                    child: Icon(icon, color: Colors.white, size: 26),
                  ),
                  const Spacer(),
                  if (stat != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: gradient[0].withOpacity(dk ? 0.2 : 0.08),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(stat, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: gradient[0])),
                    ),
                ]),
                const SizedBox(height: 20),
                Text(title, style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: dk ? Colors.white : const Color(0xFF111827),
                  letterSpacing: -0.3,
                )),
                const SizedBox(height: 8),
                Text(desc, style: TextStyle(
                  fontSize: 13,
                  color: dk ? const Color(0xFF9ca3af) : const Color(0xFF6b7280),
                  height: 1.5,
                )),
                // Spacer uniquement en desktop → bouton toujours aligné en bas
                if (stretch) const Spacer() else const SizedBox(height: 22),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: gradient),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: gradient[0].withOpacity(0.25), blurRadius: 12, offset: const Offset(0, 4))],
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(buttonIcon, color: Colors.white, size: 16),
                    const SizedBox(width: 8),
                    Text(buttonLabel, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
                    const SizedBox(width: 6),
                    Icon(Icons.arrow_forward, color: Colors.white.withOpacity(0.8), size: 14),
                  ]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  HOW IT WORKS
  // ─────────────────────────────────────────────────────────────────────────
  Widget _howItWorks(BuildContext ctx, bool desk, bool dk, Color card, Color bord, Color txt, Color sub) {
    final s = _s;
    final steps = [
      _Step(1, s.step1Title, s.step1Desc, Icons.download_rounded, _blue),
      _Step(2, s.step2Title, s.step2Desc, Icons.edit_note_rounded, _violet),
      _Step(3, s.step3Title, s.step3Desc, Icons.rocket_launch_rounded, _green),
    ];
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(16), border: Border.all(color: bord)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(color: _cyan.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.route_rounded, color: _cyan, size: 16),
          ),
          const SizedBox(width: 10),
          Text(s.howItWorks, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: txt)),
        ]),
        const SizedBox(height: 20),
        desk
            ? Row(children: steps.asMap().entries.map((e) {
          final st = e.value; final isLast = e.key == steps.length - 1;
          return Expanded(child: Row(children: [
            Expanded(child: _stepTile(st, dk, txt, sub)),
            if (!isLast) Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Icon(Icons.arrow_forward, size: 16, color: sub.withOpacity(0.3)),
            ),
          ]));
        }).toList())
            : Column(children: steps.asMap().entries.map((e) {
          return Padding(
            padding: EdgeInsets.only(bottom: e.key < steps.length - 1 ? 12 : 0),
            child: _stepTile(e.value, dk, txt, sub),
          );
        }).toList()),
      ]),
    );
  }

  Widget _stepTile(_Step s, bool dk, Color txt, Color sub) {
    return Row(children: [
      Container(
        width: 40, height: 40,
        decoration: BoxDecoration(color: s.color.withOpacity(dk ? 0.15 : 0.08), borderRadius: BorderRadius.circular(10)),
        child: Center(child: Text('${s.num}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: s.color))),
      ),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(s.title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: txt)),
        const SizedBox(height: 2),
        Text(s.desc, style: TextStyle(fontSize: 11, color: sub, height: 1.3), maxLines: 2, overflow: TextOverflow.ellipsis),
      ])),
    ]);
  }

  Widget _proTip(BuildContext ctx, bool dk, Color card, Color bord, Color txt, Color sub) {
    final s = _s;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: dk ? _amber.withOpacity(0.06) : const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: dk ? _amber.withOpacity(0.15) : const Color(0xFFFDE68A)),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: _amber.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.lightbulb_rounded, color: _amber, size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(s.proTipTitle, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: txt)),
          const SizedBox(height: 2),
          Text(s.proTipDesc, style: TextStyle(fontSize: 12, color: sub, height: 1.4)),
        ])),
      ]),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  KPI ROW
  // ─────────────────────────────────────────────────────────────────────────
  Widget _kpiRow(bool desk, Color card, Color bord, Color txt, Color sub) {
    final s = _s;
    final items = [
      _KD(s.kpiImports,  '$_total',   Icons.layers_outlined,        _blue),
      _KD(s.kpiSuccess,  '$_success', Icons.check_circle_outlined,  _green),
      _KD(s.kpiFailed,   '$_failed',  Icons.highlight_off_outlined, _red),
      _KD(s.kpiRate,     '$_rate%',   Icons.speed_outlined,         _amber),
    ];
    if (desk) {
      return Row(children: items.asMap().entries.map((e) =>
          Expanded(child: Padding(
            padding: EdgeInsets.only(right: e.key < 3 ? 16 : 0),
            child: _kpi(e.value, card, bord, txt, sub),
          ))).toList());
    }
    return Column(children: [
      Row(children: [
        Expanded(child: _kpi(items[0], card, bord, txt, sub)),
        const SizedBox(width: 12),
        Expanded(child: _kpi(items[1], card, bord, txt, sub)),
      ]),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: _kpi(items[2], card, bord, txt, sub)),
        const SizedBox(width: 12),
        Expanded(child: _kpi(items[3], card, bord, txt, sub)),
      ]),
    ]);
  }

  Widget _kpi(_KD k, Color card, Color bord, Color txt, Color sub) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(14), border: Border.all(color: bord)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: k.c.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(k.i, color: k.c, size: 18)),
        const SizedBox(height: 16),
        Text(k.v, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: txt, letterSpacing: -0.5)),
        const SizedBox(height: 4),
        Text(k.l, style: TextStyle(fontSize: 12, color: sub)),
      ]),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  ACTIVITY CARD
  // ─────────────────────────────────────────────────────────────────────────
  Widget _activityCard(Color card, Color bord, Color txt, Color sub) {
    final s = _s;
    return Container(
      decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(14), border: Border.all(color: bord)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
          child: Row(children: [
            Text(s.recentActivity, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: txt)),
            const Spacer(),
            if (_history.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: _blue.withOpacity(0.08), borderRadius: BorderRadius.circular(6)),
                child: Text('${_history.length}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _blue)),
              ),
          ]),
        ),
        Divider(height: 1, color: bord),
        if (_history.isEmpty)
          Padding(padding: const EdgeInsets.all(40),
              child: Center(child: Text(s.noActivity, style: TextStyle(fontSize: 13, color: sub))))
        else
          ...List.generate(_history.length, (i) {
            final h = _history[i];
            final ok = (h['status'] ?? '').toString().toLowerCase() == 'converted';
            final c = ok ? _green : _red;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(border: i < _history.length - 1 ? Border(bottom: BorderSide(color: bord)) : null),
              child: Row(children: [
                Container(width: 34, height: 34,
                    decoration: BoxDecoration(color: c.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
                    child: Icon(ok ? Icons.check_rounded : Icons.close_rounded, color: c, size: 16)),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(h['fileName'] ?? '—', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: txt), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Row(children: [
                    Text(h['modelCode'] ?? '—', style: const TextStyle(fontSize: 11, color: _blue, fontWeight: FontWeight.w500)),
                    const SizedBox(width: 10),
                    Text(_ago(h), style: TextStyle(fontSize: 11, color: sub)),
                  ]),
                ])),
                if (ok) Text('${h['rowCount'] ?? 0} ${s.lines}', style: TextStyle(fontSize: 11, color: sub)),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: c.withOpacity(0.08), borderRadius: BorderRadius.circular(6)),
                  child: Text(ok ? s.statusDone : s.statusFailed, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: c)),
                ),
              ]),
            );
          }),
      ]),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  MODELS CARD
  // ─────────────────────────────────────────────────────────────────────────
  Widget _modelsCard(Color card, Color bord, Color txt, Color sub) {
    final s = _s;
    final cs = [_blue, _green, _violet, _amber, _red];
    final mx = _models.isNotEmpty ? (_models[0]['count'] as int? ?? 1).toDouble() : 1.0;
    return Container(
      decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(14), border: Border.all(color: bord)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
          child: Text(s.topModels, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: txt)),
        ),
        Divider(height: 1, color: bord),
        if (_models.isEmpty)
          Padding(padding: const EdgeInsets.all(24),
              child: Center(child: Text(s.noData, style: TextStyle(fontSize: 12, color: sub))))
        else
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: _models.asMap().entries.map((e) {
              final c = cs[e.key % cs.length];
              final m = e.value;
              final cd = (m['model'] ?? '—').toString();
              final n = m['count'] as int? ?? 0;
              return Padding(
                padding: EdgeInsets.only(bottom: e.key < _models.length - 1 ? 14 : 0),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text(cd, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: txt)),
                    Text('$n', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c)),
                  ]),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: mx > 0 ? n / mx : 0,
                      backgroundColor: c.withOpacity(0.08),
                      valueColor: AlwaysStoppedAnimation(c),
                      minHeight: 5,
                    ),
                  ),
                ]),
              );
            }).toList()),
          ),
      ]),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  STATS CARD
  // ─────────────────────────────────────────────────────────────────────────
  Widget _statsCard(Color card, Color bord, Color txt, Color sub) {
    final s = _s;
    return Container(
      decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(14), border: Border.all(color: bord)),
      child: Column(children: [
        _sr(Icons.table_rows_outlined,  s.convertedRows,   '$_rows',           _blue,   bord, txt, sub, true),
        _sr(Icons.schema_outlined,      s.usedModels,      '${_models.length}',_violet, bord, txt, sub, false),
      ]),
    );
  }

  Widget _sr(IconData ic, String l, String v, Color c, Color bord, Color txt, Color sub, bool bb) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(border: bb ? Border(bottom: BorderSide(color: bord)) : null),
      child: Row(children: [
        Container(padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(color: c.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
            child: Icon(ic, size: 16, color: c)),
        const SizedBox(width: 12),
        Expanded(child: Text(l, style: TextStyle(fontSize: 12, color: sub))),
        Text(v, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: txt)),
      ]),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  LOADER / ERROR
  // ─────────────────────────────────────────────────────────────────────────
  Widget _loader(bool d, Color c, Color b) {
    Widget x() => Container(
      padding: const EdgeInsets.all(18), height: 120,
      decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(14), border: Border.all(color: b)),
      child: const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: _blue))),
    );
    if (d) return Row(children: List.generate(4, (i) => Expanded(child: Padding(padding: EdgeInsets.only(right: i < 3 ? 16 : 0), child: x()))));
    return Column(children: [
      Row(children: [Expanded(child: x()), const SizedBox(width: 12), Expanded(child: x())]),
      const SizedBox(height: 12),
      Row(children: [Expanded(child: x()), const SizedBox(width: 12), Expanded(child: x())]),
    ]);
  }

  Widget _err(Color c, Color b, Color t) => Container(
    padding: const EdgeInsets.all(40),
    decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(14), border: Border.all(color: b)),
    child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.cloud_off_outlined, size: 40, color: _red.withOpacity(0.5)),
      const SizedBox(height: 12),
      Text(_s.loadError, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: t)),
      const SizedBox(height: 6),
      Text(_error ?? '', style: const TextStyle(fontSize: 12, color: Color(0xFF9ca3af)), textAlign: TextAlign.center),
      const SizedBox(height: 16),
      TextButton.icon(onPressed: _load, icon: const Icon(Icons.refresh, size: 16), label: Text(_s.retry),
          style: TextButton.styleFrom(foregroundColor: _blue)),
    ])),
  );

  String _ago(Map<String, dynamic> h) {
    final s = _s;
    final r = h['uploadDate'] ?? h['date'];
    if (r == null) return '—';
    try {
      final d = DateTime.parse(r.toString()).toLocal();
      final df = DateTime.now().difference(d);
      if (df.inDays > 7)  return '${d.day}/${d.month}/${d.year}';
      if (df.inDays > 0)  return s.daysAgo(df.inDays);
      if (df.inHours > 0) return s.hoursAgo(df.inHours);
      if (df.inMinutes > 0) return s.minutesAgo(df.inMinutes);
      return s.justNow;
    } catch (_) { return '—'; }
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  HELPERS
// ═══════════════════════════════════════════════════════════════════════════════
class _KD { final String l, v; final IconData i; final Color c; const _KD(this.l, this.v, this.i, this.c); }
class _Step { final int num; final String title, desc; final IconData icon; final Color color; const _Step(this.num, this.title, this.desc, this.icon, this.color); }

class _TabNavigator extends StatelessWidget {
  final Widget child;
  const _TabNavigator({super.key, required this.child});
  @override
  Widget build(BuildContext context) => Navigator(
      onGenerateRoute: (s) => MaterialPageRoute(builder: (_) => child, settings: s));
}

// ═══════════════════════════════════════════════════════════════════════════════
//  LOGOUT DIALOG
// ═══════════════════════════════════════════════════════════════════════════════
class _LogoutDialog extends StatefulWidget {
  final String username;
  final VoidCallback onConfirm;
  final AppStrings strings;
  const _LogoutDialog({required this.username, required this.onConfirm, required this.strings});
  @override
  State<_LogoutDialog> createState() => _LogoutDialogState();
}

class _LogoutDialogState extends State<_LogoutDialog> with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  late Animation<double> _scale, _fade;
  bool _loading = false;

  static const _red = Color(0xFFdc2626);

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 280));
    _scale = CurvedAnimation(parent: _anim, curve: Curves.easeOutBack);
    _fade  = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
    _anim.forward();
  }

  @override
  void dispose() { _anim.dispose(); super.dispose(); }

  Future<void> _confirm() async {
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 400));
    if (mounted) {
      Navigator.pop(context);
      widget.onConfirm();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s    = widget.strings;
    final dk   = Theme.of(context).brightness == Brightness.dark;
    final bg   = dk ? const Color(0xFF151921) : Colors.white;
    final border = dk ? const Color(0xFF2a3040) : const Color(0xFFE2E8F0);
    final txt  = dk ? Colors.white : const Color(0xFF0F172A);
    final sub  = dk ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return FadeTransition(
      opacity: _fade,
      child: ScaleTransition(
        scale: _scale,
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 28),
          child: Container(
            width: 380,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(
                color: Colors.black.withOpacity(dk ? 0.55 : 0.18),
                blurRadius: 48, offset: const Offset(0, 24),
              )],
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
                decoration: BoxDecoration(
                  color: dk ? const Color(0xFF1a1014) : const Color(0xFFFFF5F5),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  border: Border(bottom: BorderSide(color: border)),
                ),
                child: Column(children: [
                  Stack(alignment: Alignment.center, children: [
                    Container(width: 72, height: 72,
                        decoration: BoxDecoration(color: _red.withOpacity(0.08), shape: BoxShape.circle,
                            border: Border.all(color: _red.withOpacity(0.2), width: 1.5))),
                    Container(width: 52, height: 52,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFFef4444), _red], begin: Alignment.topLeft, end: Alignment.bottomRight),
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: _red.withOpacity(0.35), blurRadius: 16, offset: const Offset(0, 6))],
                        ),
                        child: const Icon(Icons.logout_rounded, color: Colors.white, size: 24)),
                  ]),
                  const SizedBox(height: 18),
                  Text(s.logoutQuestion, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: txt, letterSpacing: -0.4)),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(children: [
                  Expanded(
                    child: TextButton(
                      onPressed: _loading ? null : () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        foregroundColor: sub,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: border)),
                      ),
                      child: Text(s.cancel, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _loading ? null : _confirm,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: _red, foregroundColor: Colors.white, elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _loading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                          : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const Icon(Icons.logout_rounded, size: 16),
                        const SizedBox(width: 6),
                        Text(s.logoutConfirmBtn, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                      ]),
                    ),
                  ),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}