import 'package:flutter/material.dart';
import 'package:frontend_sage3/services/api_service.dart';
import 'package:frontend_sage3/services/auth_service.dart';
import 'dart:math';

import 'sections/dashboard_section.dart';
import 'sections/users_section.dart';
import 'sections/activity_section.dart';
import 'sections/templates_section.dart';
import 'sections/settings_section.dart';
import 'widgets/admin_shared_widgets.dart';
import 'sections/feedback_section.dart';

class AdminDashboardPage extends StatefulWidget {
  @override
  _AdminDashboardPageState createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Données
  List<Map<String, dynamic>> _users    = [];
  List<Map<String, dynamic>> _activity = [];
  List<Map<String, dynamic>> _models   = [];
  Map<String, dynamic>       _analytics = {};

  bool _loadingUsers     = true;
  bool _loadingActivity  = true;
  bool _loadingModels    = true;
  bool _loadingAnalytics = true;

  String? _usersError;
  String? _activityError;
  String? _modelsError;
  String? _analyticsError;

  String _userSearch      = '';
  String _activitySearch  = '';
  String _modelSearch     = '';
  String _analyticsPeriod = '30d';

  // Couleurs du thème
  static const _blue   = Color(0xFF2563eb);
  static const _green  = Color(0xFF059669);
  static const _red    = Color(0xFFdc2626);
  static const _amber  = Color(0xFFd97706);
  static const _violet = Color(0xFF7c3aed);

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
    {'icon': Icons.space_dashboard_outlined, 'active': Icons.space_dashboard,   'label': 'Tableau de bord'},
    {'icon': Icons.people_outline,           'active': Icons.people,            'label': 'Utilisateurs'},
    {'icon': Icons.history_outlined,         'active': Icons.history,           'label': 'Activité'},
    {'icon': Icons.description_outlined,     'active': Icons.description,       'label': 'Modèles'},
    {'icon': Icons.tune_outlined,            'active': Icons.tune,              'label': 'Paramètres'},
    {'icon': Icons.feedback_outlined, 'active': Icons.feedback, 'label': 'Feedbacks'},
  ];

  @override
  void initState() { super.initState(); _loadAll(); }

  Future<void> _loadAll() async {
    await Future.wait([_loadUsers(), _loadActivity(), _loadModels(), _loadAnalytics()]);
  }

  Future<void> _loadUsers() async {
    setState(() { _loadingUsers = true; _usersError = null; });
    try {
      final d = await ApiService().getUsers();
      setState(() { _users = d; _loadingUsers = false; });
    } catch (e) {
      setState(() { _usersError = e.toString().replaceFirst('Exception: ', ''); _loadingUsers = false; });
    }
  }

  Future<void> _loadActivity() async {
    setState(() { _loadingActivity = true; _activityError = null; });
    try {
      final d = await ApiService().getAllHistory();
      setState(() { _activity = d; _loadingActivity = false; });
    } catch (e) {
      setState(() { _activityError = e.toString().replaceFirst('Exception: ', ''); _loadingActivity = false; });
    }
  }

  Future<void> _loadModels() async {
    setState(() { _loadingModels = true; _modelsError = null; });
    try {
      final d = await ApiService().getModels();
      setState(() { _models = d; _loadingModels = false; });
    } catch (e) {
      setState(() { _modelsError = e.toString().replaceFirst('Exception: ', ''); _loadingModels = false; });
    }
  }

  Future<void> _loadAnalytics() async {
    setState(() { _loadingAnalytics = true; _analyticsError = null; });
    try {
      final d = await ApiService().getAnalytics(period: _analyticsPeriod);
      setState(() { _analytics = d; _loadingAnalytics = false; });
    } catch (e) {
      setState(() { _analyticsError = e.toString().replaceFirst('Exception: ', ''); _loadingAnalytics = false; });
    }
  }

  void _navigate(int i) => setState(() => _selectedIndex = i);

  @override
  Widget build(BuildContext context) {
    final desk = MediaQuery.of(context).size.width >= 1024;
    final dk   = Theme.of(context).brightness == Brightness.dark;
    final bg        = dk ? const Color(0xFF0b0e13) : const Color(0xFFF7F8FA);
    final cardBg    = dk ? const Color(0xFF151921) : Colors.white;
    final bord      = dk ? const Color(0xFF1e2028) : const Color(0xFFf0f0f5);
    final txt       = dk ? Colors.white : const Color(0xFF111827);
    final sub       = dk ? const Color(0xFF6b7280) : const Color(0xFF9ca3af);
    final sidebarBg = dk ? const Color(0xFF101318) : Colors.white;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: bg,
      drawer: desk ? null : _buildDrawer(dk, sidebarBg, bord, txt, sub),
      body: Row(children: [
        if (desk) _buildSidebar(dk, sidebarBg, bord, txt, sub),
        Expanded(child: Column(children: [
          _buildTopBar(desk, dk, cardBg, bord, txt, sub),
          Expanded(child: _buildSection(desk, dk, cardBg, bord, txt, sub)),
        ])),
      ]),
    );
  }

  Widget _buildSection(bool desk, bool dk, Color card, Color bord, Color txt, Color sub) {
    switch (_selectedIndex) {
      case 0:
        return DashboardSection(
          desk: desk, dk: dk, card: card, bord: bord, txt: txt, sub: sub,
          analytics: _analytics,
          loading: _loadingAnalytics,
          error: _analyticsError,
          analyticsPeriod: _analyticsPeriod,
          users: _users,
          onPeriodChanged: (p) { setState(() => _analyticsPeriod = p); _loadAnalytics(); },
          onAddUser: _showAddUserDialog,
          onReload: _loadAnalytics,
        );
      case 1:
        return UsersSection(
          desk: desk, dk: dk, card: card, bord: bord, txt: txt, sub: sub,
          users: _users,
          loading: _loadingUsers,
          error: _usersError,
          search: _userSearch,
          onSearchChanged: (v) => setState(() => _userSearch = v),
          onAddUser: _showAddUserDialog,
          onEditUser: _showEditUserDialog,
          onDeleteUser: _showDeleteConfirm,
          onToggleUser: _confirmToggle,
          onReload: _loadUsers,
        );
      case 2:
        return ActivitySection(
          desk: desk, dk: dk, card: card, bord: bord, txt: txt, sub: sub,
          activity: _activity,
          loading: _loadingActivity,
          error: _activityError,
          search: _activitySearch,
          onSearchChanged: (v) => setState(() => _activitySearch = v),
          onReload: _loadActivity,
        );
      case 3:
        return TemplatesSection(
          desk: desk, dk: dk, card: card, bord: bord, txt: txt, sub: sub,
          models: _models,
          loading: _loadingModels,
          error: _modelsError,
          search: _modelSearch,
          onSearchChanged: (v) => setState(() => _modelSearch = v),
          onReload: _loadModels,
          onSnack: _snack,
        );
      case 4:
        return SettingsSection(
          desk: desk, dk: dk, card: card, bord: bord, txt: txt, sub: sub,
          adminUsername: _adminUsername,
          adminEmail: _adminEmail,
          onLogout: _showLogoutDialog,
          onSnack: _snack,
        );
      case 5:
  return FeedbackSection(
    desk: desk, dk: dk, card: card, bord: bord, txt: txt, sub: sub,
    onSnack: _snack,
  );
      default:
        return const SizedBox();
    }
  }

  // ── Sidebar ────────────────────────────────────────────────────────────
  Widget _buildSidebar(bool dk, Color bg, Color bord, Color txt, Color sub) {
    return Container(
      width: 240,
      decoration: BoxDecoration(color: bg, border: Border(right: BorderSide(color: bord))),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
          child: Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [_violet, _blue]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.admin_panel_settings, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('SageX3', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: txt, letterSpacing: -0.3)),
              Text('Panneau Admin', style: TextStyle(fontSize: 11, color: _violet, fontWeight: FontWeight.w500, letterSpacing: 0.2)),
            ]),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 28, bottom: 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text('MENU', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: sub.withOpacity(0.5), letterSpacing: 1.2)),
          ),
        ),
        ...List.generate(_menuItems.length, (i) {
          final sel = _selectedIndex == i;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 1),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                onTap: () => _navigate(i),
                borderRadius: BorderRadius.circular(10),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: sel ? _violet.withOpacity(0.08) : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(children: [
                    Icon(sel ? _menuItems[i]['active'] : _menuItems[i]['icon'],
                        color: sel ? _violet : sub, size: 19),
                    const SizedBox(width: 12),
                    Expanded(child: Text(_menuItems[i]['label'],
                        style: TextStyle(fontSize: 13, fontWeight: sel ? FontWeight.w600 : FontWeight.w400, color: sel ? _violet : sub))),
                    if (i == 1 && _users.isNotEmpty)
                      AdminSharedWidgets.badge('${_users.length}', _violet),
                    if (i == 2 && _activity.isNotEmpty)
                      AdminSharedWidgets.badge('${_activity.length > 99 ? '99+' : _activity.length}', _red),
                  ]),
                ),
              ),
            ),
          );
        }),
        const Spacer(),
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: dk ? const Color(0xFF1a1d24) : const Color(0xFFF7F8FA),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [_violet, _blue]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(child: Text(_adminInitials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12))),
            ),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_adminUsername, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: txt), maxLines: 1, overflow: TextOverflow.ellipsis),
              Text(_adminEmail,    style: TextStyle(fontSize: 10, color: sub),                              maxLines: 1, overflow: TextOverflow.ellipsis),
            ])),
          ]),
        ),
      ]),
    );
  }

  // ── Tiroir (mobile) ────────────────────────────────────────────────────
  Widget _buildDrawer(bool dk, Color bg, Color bord, Color txt, Color sub) {
    return Drawer(
      backgroundColor: bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(topRight: Radius.circular(24), bottomRight: Radius.circular(24)),
      ),
      child: SafeArea(child: Column(children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(gradient: const LinearGradient(colors: [_violet, _blue]), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.admin_panel_settings, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Text('Panneau Admin', style: TextStyle(color: txt, fontSize: 16, fontWeight: FontWeight.bold)),
            const Spacer(),
            IconButton(icon: Icon(Icons.close, color: sub), onPressed: () => Navigator.pop(context)),
          ]),
        ),
        Divider(color: bord),
        ...List.generate(_menuItems.length, (i) {
          final sel = _selectedIndex == i;
          return ListTile(
            leading: Icon(sel ? _menuItems[i]['active'] : _menuItems[i]['icon'], color: sel ? _violet : sub, size: 20),
            title: Text(_menuItems[i]['label'], style: TextStyle(color: sel ? _violet : sub, fontSize: 14)),
            tileColor: sel ? _violet.withOpacity(0.08) : Colors.transparent,
            onTap: () { Navigator.pop(context); _navigate(i); },
          );
        }),
      ])),
    );
  }

  // ── Barre supérieure ───────────────────────────────────────────────────
  Widget _buildTopBar(bool desk, bool dk, Color card, Color bord, Color txt, Color sub) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: desk ? 32 : 20, vertical: 14),
      decoration: BoxDecoration(color: card, border: Border(bottom: BorderSide(color: bord))),
      child: Row(children: [
        if (!desk)
          IconButton(icon: Icon(Icons.menu, color: txt), onPressed: () => _scaffoldKey.currentState?.openDrawer()),
        Text(_menuItems[_selectedIndex]['label'],
            style: TextStyle(fontSize: desk ? 20 : 17, fontWeight: FontWeight.w700, color: txt, letterSpacing: -0.3)),
        const Spacer(),
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: dk ? const Color(0xFF1a1d24) : const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              onTap: _loadAll,
              borderRadius: BorderRadius.circular(10),
              child: Icon(Icons.refresh, size: 18, color: sub),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: 34, height: 34,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [_violet, _blue]),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(child: Text(_adminInitials, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700))),
        ),
        const SizedBox(width: 10),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _showLogoutDialog,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(color: _red, borderRadius: BorderRadius.circular(10)),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.logout_rounded, size: 14, color: Colors.white),
                SizedBox(width: 6),
                Text('Déconnexion', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
              ]),
            ),
          ),
        ),
      ]),
    );
  }

  // ── Snackbar ───────────────────────────────────────────────────────────
  void _snack(String msg, Color c) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontSize: 13)),
      backgroundColor: c,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  // ==================== DIALOGUE D'AJOUT D'UTILISATEUR PROFESSIONNEL ====================
  void _showAddUserDialog() {
    final _formKey = GlobalKey<FormState>();
    final _usernameController = TextEditingController();
    final _emailController = TextEditingController();
    final _passwordController = TextEditingController();
    String _selectedRole = 'Utilisateur';
    bool _isLoading = false;
    bool _obscurePassword = true;
    String? _generatedPassword;

    // Génération d'un mot de passe fort
    String _generateStrongPassword() {
      const lower = 'abcdefghijklmnopqrstuvwxyz';
      const upper = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
      const digits = '0123456789';
      const symbols = '!@#%^&*()_+';
      final all = lower + upper + digits + symbols;
      final random = Random.secure();
      // Au moins 1 caractère de chaque catégorie
      String password = String.fromCharCodes([
        lower.codeUnitAt(random.nextInt(lower.length)),
        upper.codeUnitAt(random.nextInt(upper.length)),
        digits.codeUnitAt(random.nextInt(digits.length)),
        symbols.codeUnitAt(random.nextInt(symbols.length)),
      ]);
      // Compléter jusqu'à 12 caractères
      for (int i = password.length; i < 12; i++) {
        password += all[random.nextInt(all.length)];
      }
      // Mélanger
      final chars = password.split('')..shuffle(random);
      return chars.join();
    }

    void _applyGeneratedPassword() {
      final newPwd = _generateStrongPassword();
      _passwordController.text = newPwd;
      _generatedPassword = newPwd;
      _snack('🔑 Mot de passe généré : $newPwd', Colors.blueGrey);
      Future.delayed(const Duration(seconds: 5), () {
        if (_generatedPassword == newPwd) _generatedPassword = null;
      });
    }

    showDialog(
      context: context,
      barrierDismissible: !_isLoading,
      builder: (context) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            elevation: 8,
            backgroundColor: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF1E1E2E)
                : Colors.white,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // En-tête avec dégradé
                  Container(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_violet, _blue],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(28),
                        topRight: Radius.circular(28),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.person_add_alt_1, color: Colors.white, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Ajouter un utilisateur',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Remplissez les informations ci-dessous',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white.withOpacity(0.85),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Formulaire
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Nom d'utilisateur
                          TextFormField(
                            controller: _usernameController,
                            style: const TextStyle(fontSize: 15),
                            decoration: InputDecoration(
                              labelText: 'Nom d\'utilisateur',
                              hintText: 'ex: jean.dupont',
                              prefixIcon: Icon(Icons.person_outline, color: _violet),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Theme.of(context).brightness == Brightness.dark
                                  ? const Color(0xFF2A2A3A)
                                  : const Color(0xFFF3F4F6),
                              contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Le nom d\'utilisateur est requis';
                              }
                              if (value.length < 3) {
                                return 'Minimum 3 caractères';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          // Email
                          TextFormField(
                            controller: _emailController,
                            style: const TextStyle(fontSize: 15),
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: 'Adresse e-mail',
                              hintText: 'ex: contact@exemple.com',
                              prefixIcon: Icon(Icons.email_outlined, color: _violet),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Theme.of(context).brightness == Brightness.dark
                                  ? const Color(0xFF2A2A3A)
                                  : const Color(0xFFF3F4F6),
                              contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'L\'adresse e-mail est requise';
                              }
                              final emailRegex = RegExp(
                                r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                              );
                              if (!emailRegex.hasMatch(value)) {
                                return 'Format d\'e-mail invalide';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          // Mot de passe avec bouton générer
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            style: const TextStyle(fontSize: 15),
                            decoration: InputDecoration(
                              labelText: 'Mot de passe',
                              prefixIcon: Icon(Icons.lock_outline, color: _violet),
                              suffixIcon: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                      color: Colors.grey,
                                      size: 20,
                                    ),
                                    onPressed: () => setDialogState(() {
                                      _obscurePassword = !_obscurePassword;
                                    }),
                                  ),
                                  const SizedBox(width: 4),
                                  IconButton(
                                    icon: const Icon(Icons.password, color: _violet, size: 20),
                                    tooltip: 'Générer un mot de passe fort',
                                    onPressed: () {
                                      _applyGeneratedPassword();
                                      setDialogState(() {});
                                    },
                                  ),
                                ],
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Theme.of(context).brightness == Brightness.dark
                                  ? const Color(0xFF2A2A3A)
                                  : const Color(0xFFF3F4F6),
                              contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Le mot de passe est requis';
                              }
                              if (value.length < 6) {
                                return 'Minimum 6 caractères';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          // Rôle
                          DropdownButtonFormField<String>(
                            value: _selectedRole,
                            decoration: InputDecoration(
                              labelText: 'Rôle',
                              prefixIcon: Icon(Icons.admin_panel_settings, color: _violet),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Theme.of(context).brightness == Brightness.dark
                                  ? const Color(0xFF2A2A3A)
                                  : const Color(0xFFF3F4F6),
                              contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'Utilisateur', child: Text('👤 Utilisateur standard')),
                              DropdownMenuItem(value: 'Admin', child: Text('🛡️ Administrateur')),
                            ],
                            onChanged: (value) => setDialogState(() => _selectedRole = value!),
                            dropdownColor: Theme.of(context).brightness == Brightness.dark
                                ? const Color(0xFF2A2A3A)
                                : Colors.white,
                          ),
                          const SizedBox(height: 12),
                          // Message temporaire du mot de passe généré
                          if (_generatedPassword != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: _violet.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.info_outline, size: 16, color: _violet),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Mot de passe temporaire : $_generatedPassword',
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  // Boutons d'action
                  Container(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: _isLoading ? null : () => Navigator.pop(ctx),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(40),
                            ),
                          ),
                          child: const Text('Annuler', style: TextStyle(fontSize: 14)),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: _isLoading
                              ? null
                              : () async {
                                  if (!_formKey.currentState!.validate()) return;
                                  setDialogState(() => _isLoading = true);
                                  try {
                                    await ApiService().register(
                                      _usernameController.text.trim(),
                                      _emailController.text.trim(),
                                      _passwordController.text,
                                    );
                                    if (ctx.mounted) Navigator.pop(ctx);
                                    await _loadUsers();
                                    await _loadAnalytics();
                                    _snack('✅ Utilisateur ajouté avec succès !', _green);
                                  } catch (e) {
                                    setDialogState(() => _isLoading = false);
                                    _snack('❌ ${e.toString().replaceFirst('Exception: ', '')}', _red);
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _violet,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(40),
                            ),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.check, size: 18),
                                    SizedBox(width: 8),
                                    Text('Ajouter', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ==================== AUTRES DIALOGUES (inchangés mais fonctionnels) ====================
  void _showEditUserDialog(Map<String, dynamic> user) {
    final uname = user['username'] ?? user['userName'] ?? '';
    final email = user['email'] ?? '';
    final uC = TextEditingController(text: uname);
    final eC = TextEditingController(text: email);
    String role = user['role'] ?? 'Utilisateur';
    bool loading = false;
    String? err;

    showDialog(context: context, builder: (_) => StatefulBuilder(builder: (ctx, setD) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Modifier l\'utilisateur', style: TextStyle(fontWeight: FontWeight.bold)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        if (err != null)
          Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: _red.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
              child: Text(err!, style: const TextStyle(color: _red, fontSize: 12))),
        AdminSharedWidgets.dlgField(uC, 'Nom d\'utilisateur', Icons.person_outline),
        const SizedBox(height: 10),
        AdminSharedWidgets.dlgField(eC, 'Adresse e-mail', Icons.email_outlined),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          value: role,
          decoration: InputDecoration(labelText: 'Rôle', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), filled: true, fillColor: const Color(0xFFF7F8FA)),
          items: ['Utilisateur', 'Admin'].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
          onChanged: (v) => setD(() => role = v!),
        ),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
        ElevatedButton(
          onPressed: loading ? null : () async {
            setD(() => loading = true);
            try {
              await ApiService().updateUser(user['id'] as int, uC.text.trim(), eC.text.trim(), role);
              Navigator.pop(ctx);
              _loadUsers();
              _snack('Utilisateur mis à jour !', _green);
            } catch (e) {
              setD(() { loading = false; err = e.toString().replaceFirst('Exception: ', ''); });
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: _violet, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          child: loading
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Enregistrer'),
        ),
      ],
    )));
  }

  void _showDeleteConfirm(Map<String, dynamic> user) {
    final name = user['username'] ?? user['userName'] ?? '—';
    showDialog(context: context, builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Supprimer l\'utilisateur', style: TextStyle(fontWeight: FontWeight.bold)),
      content: Text('Supprimer $name ? Cette action est irréversible.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
        ElevatedButton(
          onPressed: () async {
            Navigator.pop(context);
            try {
              await ApiService().deleteUser(user['id'] as int);
              _loadUsers();
              _loadAnalytics();
              _snack('Utilisateur supprimé', _red);
            } catch (e) {
              _snack(e.toString().replaceFirst('Exception: ', ''), _red);
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: _red, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          child: const Text('Supprimer'),
        ),
      ],
    ));
  }

  void _confirmToggle(Map<String, dynamic> user, bool suspend) {
    final name = user['username'] ?? user['userName'] ?? '—';
    showDialog(context: context, builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(suspend ? 'Suspendre l\'utilisateur' : 'Activer l\'utilisateur', style: const TextStyle(fontWeight: FontWeight.bold)),
      content: Text(suspend ? 'Suspendre $name ?' : 'Activer $name ?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
        ElevatedButton(
          onPressed: () async {
            Navigator.pop(context);
            try {
              suspend
                  ? await ApiService().suspendUser(user['id'] as int)
                  : await ApiService().activateUser(user['id'] as int);
              _loadUsers();
              _snack('$name ${suspend ? 'suspendu' : 'activé'}', suspend ? _amber : _green);
            } catch (e) {
              _snack(e.toString().replaceFirst('Exception: ', ''), _red);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: suspend ? _amber : _green,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: Text(suspend ? 'Suspendre' : 'Activer'),
        ),
      ],
    ));
  }

  void _showLogoutDialog() {
    showDialog(context: context, builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Déconnexion', style: TextStyle(fontWeight: FontWeight.bold)),
      content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
        ElevatedButton(
          onPressed: () {
            AuthService.instance.logout();
            Navigator.pop(context);
            Navigator.pushReplacementNamed(context, '/login');
          },
          style: ElevatedButton.styleFrom(backgroundColor: _red, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          child: const Text('Déconnexion'),
        ),
      ],
    ));
  }
}