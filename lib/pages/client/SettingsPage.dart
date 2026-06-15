import 'package:flutter/material.dart';
import 'package:frontend_sage3/main.dart';
import 'package:frontend_sage3/services/auth_service.dart';
import 'package:frontend_sage3/services/api_service.dart';
import 'package:frontend_sage3/app_strings.dart';

const _kPrimary  = Color(0xFF1D4ED8);
const _kSuccess  = Color(0xFF16A34A);
const _kDanger   = Color(0xFFDC2626);
const _kTextDark = Color(0xFF0F172A);
const _kTextSub  = Color(0xFF64748B);
const _kBorderL  = Color(0xFFE2E8F0);
const _kSurfaceL = Color(0xFFF8FAFC);

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool   darkMode         = false;
  String selectedLanguage = 'Français';

  AuthUser? get _user     => AuthService.instance.currentUser;
  String get _username    => _user?.username ?? 'Utilisateur';
  String get _email       => _user?.email    ?? '';
  String get _role        => _user?.role     ?? 'Utilisateur';

  AppStrings get _s => SageX3App.of(context)?.strings ?? AppStrings('fr');

  late TextEditingController _nameCtrl;
  late TextEditingController _emailCtrl;

  String get _initials {
    final parts = _username.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return _username.length >= 2 ? _username.substring(0, 2).toUpperCase() : _username.toUpperCase();
  }

  @override
  void initState() {
    super.initState();
    _nameCtrl  = TextEditingController(text: _username);
    _emailCtrl = TextEditingController(text: _email);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final appState = SageX3App.of(context);
    if (appState != null) {
      darkMode         = appState.isDarkMode;
      selectedLanguage = appState.currentLang == 'en' ? 'English' : 'Français';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s   = _s;
    final theme = Theme.of(context);
    final dk  = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: dk ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
      body: SafeArea(
        child: Column(children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                _buildProfileCard(context, dk),
                const SizedBox(height: 24),

                // ── COMPTE
                _sectionLabel(s.account, dk),
                const SizedBox(height: 8),
                _buildGroup(dk, [
                  _tile(dk: dk, icon: Icons.edit_outlined,
                      title: s.editProfile, subtitle: s.editProfileSub, onTap: _showEditProfileDialog),
                  _divider(dk),
                  _tile(dk: dk, icon: Icons.lock_outline,
                      title: s.changePassword, subtitle: s.changePasswordSub, onTap: _showChangePasswordDialog),
                ]),
                const SizedBox(height: 20),

                // ── PRÉFÉRENCES
                _sectionLabel(s.preferences, dk),
                const SizedBox(height: 8),
                _buildGroup(dk, [
                  _divider(dk),
                  _switchTile(
                    dk: dk, icon: Icons.dark_mode_outlined,
                    title: s.darkMode, subtitle: s.darkModeSub,
                    value: darkMode,
                    onChanged: (v) {
                      setState(() => darkMode = v);
                      SageX3App.of(context)?.toggleTheme(v);
                    },
                  ),
                  _divider(dk),
                  _tile(dk: dk, icon: Icons.language_outlined,
                      title: s.language, subtitle: selectedLanguage, onTap: _showLanguageDialog),
                ]),
                const SizedBox(height: 20),

                // ── SUPPORT
                _sectionLabel(s.support, dk),
                const SizedBox(height: 8),
                _buildGroup(dk, [
                  _tile(dk: dk, icon: Icons.feedback_outlined,
                      title: s.sendFeedback, subtitle: s.sendFeedbackSub, onTap: _showFeedbackDialog),
                  _divider(dk),
                  _tile(dk: dk, icon: Icons.help_outline,
                      title: s.help, subtitle: s.helpSub,
                      onTap: () => _snack(s.help)),
                  _divider(dk),
                  _tile(dk: dk, icon: Icons.privacy_tip_outlined,
                      title: s.privacy, subtitle: s.privacySub,
                      onTap: () => _snack(s.privacy)),
                ]),
                const SizedBox(height: 20),

                // ── À PROPOS
                _sectionLabel(s.about, dk),
                const SizedBox(height: 8),
                _buildGroup(dk, [
                  _tile(dk: dk, icon: Icons.info_outline,
                      title: s.appVersion, subtitle: '1.0.0', trailing: const SizedBox.shrink()),
                ]),
                const SizedBox(height: 28),

                _buildLogoutBtn(dk, s),
                const SizedBox(height: 40),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context, bool dk) {
    final bg     = dk ? const Color(0xFF1E293B) : Colors.white;
    final border = dk ? const Color(0xFF334155) : _kBorderL;
    final txt    = dk ? Colors.white : _kTextDark;
    final sub    = dk ? const Color(0xFF94A3B8) : _kTextSub;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12), border: Border.all(color: border)),
      child: Row(children: [
        CircleAvatar(radius: 26, backgroundColor: _kPrimary,
            child: Text(_initials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15))),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_username, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: txt)),
          const SizedBox(height: 2),
          Text(_email, style: TextStyle(fontSize: 13, color: sub)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: _kPrimary.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
            child: Text(_role, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _kPrimary)),
          ),
        ])),
      ]),
    );
  }

  Widget _sectionLabel(String title, bool dk) => Padding(
    padding: const EdgeInsets.only(left: 2),
    child: Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
        color: dk ? const Color(0xFF94A3B8) : _kTextSub, letterSpacing: 0.5)),
  );

  Widget _buildGroup(bool dk, List<Widget> children) {
    final bg     = dk ? const Color(0xFF1E293B) : Colors.white;
    final border = dk ? const Color(0xFF334155) : _kBorderL;
    return Container(
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12), border: Border.all(color: border)),
      child: Column(children: children),
    );
  }

  Widget _divider(bool dk) => Divider(
    height: 1, thickness: 1,
    color: dk ? const Color(0xFF334155) : _kBorderL,
    indent: 16, endIndent: 16,
  );

  Widget _tile({required bool dk, required IconData icon, required String title, required String subtitle, Widget? trailing, VoidCallback? onTap}) {
    final txt = dk ? Colors.white : _kTextDark;
    final sub = dk ? const Color(0xFF94A3B8) : _kTextSub;
    final ic  = dk ? const Color(0xFF94A3B8) : _kTextSub;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(width: 36, height: 36,
          decoration: BoxDecoration(color: _kPrimary.withOpacity(0.08), borderRadius: BorderRadius.circular(9)),
          child: Icon(icon, color: _kPrimary, size: 18)),
      title: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: txt)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: sub)),
      trailing: trailing ?? Icon(Icons.chevron_right, color: ic, size: 18),
      onTap: onTap, dense: true,
    );
  }

  Widget _switchTile({required bool dk, required IconData icon, required String title, required String subtitle, required bool value, required ValueChanged<bool> onChanged}) {
    final txt = dk ? Colors.white : _kTextDark;
    final sub = dk ? const Color(0xFF94A3B8) : _kTextSub;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(width: 36, height: 36,
          decoration: BoxDecoration(color: _kPrimary.withOpacity(0.08), borderRadius: BorderRadius.circular(9)),
          child: Icon(icon, color: _kPrimary, size: 18)),
      title: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: txt)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: sub)),
      trailing: Switch(value: value, onChanged: onChanged, activeColor: _kPrimary, materialTapTargetSize: MaterialTapTargetSize.shrinkWrap),
      dense: true,
    );
  }

  Widget _buildLogoutBtn(bool dk, AppStrings s) => SizedBox(
    width: double.infinity,
    child: OutlinedButton.icon(
      onPressed: _showLogoutDialog,
      icon: const Icon(Icons.logout, size: 18, color: _kDanger),
      label: Text(s.logout, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kDanger)),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 13),
        side: const BorderSide(color: _kDanger),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
  );

  void _snack(String feature) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text('$feature ${_s.comingSoon}'),
    behavior: SnackBarBehavior.floating,
    backgroundColor: _kPrimary,
  ));

  // ═══════════════════════════════════════════════════════════════════════════
  //  DIALOGUES
  // ═══════════════════════════════════════════════════════════════════════════

  void _showEditProfileDialog() {
    final s = _s;
    final nameCtrl    = TextEditingController(text: _username);
    final phoneCtrl   = TextEditingController(text: _user?.phone   ?? '');
    final companyCtrl = TextEditingController(text: _user?.company ?? '');

    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => _EditProfileDialog(
        nameCtrl: nameCtrl, phoneCtrl: phoneCtrl, companyCtrl: companyCtrl,
        initials: _initials, strings: s,
        onSave: (name, phone, company) async {
          await ApiService().updateUser(_user!.id, name, _user!.email, _user!.role, phone: phone, company: company);
          AuthService.instance.setUser(AuthUser(
            id: _user!.id, username: name, email: _user!.email,
            role: _user!.role, token: _user!.token, phone: phone, company: company,
          ));
          if (mounted) setState(() {});
        },
      ),
    );
  }

  void _showChangePasswordDialog() => showDialog(
    context: context,
    barrierColor: Colors.black54,
    builder: (_) => _ChangePasswordDialog(userId: _user!.id, strings: _s),
  );

  void _showFeedbackDialog() {
    final s           = _s;
    final colorScheme = Theme.of(context).colorScheme;
    final ctrl        = TextEditingController();
    bool loading      = false;
    String? error;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          backgroundColor: colorScheme.surface,
          title: Text(s.sendFeedback, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: colorScheme.onSurface)),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(s.feedbackSentTo, style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withOpacity(0.6))),
            const SizedBox(height: 12),
            if (error != null) ...[
              Container(padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: _kDanger.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
                  child: Text(error!, style: const TextStyle(color: _kDanger, fontSize: 12))),
              const SizedBox(height: 10),
            ],
            TextField(
              controller: ctrl, maxLines: 4,
              style: TextStyle(fontSize: 13, color: colorScheme.onSurface),
              decoration: InputDecoration(
                hintText: s.feedbackHint,
                hintStyle: TextStyle(fontSize: 13, color: colorScheme.onSurface.withOpacity(0.4)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: colorScheme.primary.withOpacity(0.3))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: colorScheme.primary, width: 1.5)),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ]),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(s.cancel, style: TextStyle(color: colorScheme.onSurface.withOpacity(0.6))),
            ),
            ElevatedButton(
              onPressed: loading ? null : () async {
                if (ctrl.text.trim().isEmpty) return;
                setDlg(() { loading = true; error = null; });
                try {
                  await ApiService().sendFeedback(ctrl.text.trim(), _user?.id ?? 0, _username);
                  if (mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(s.feedbackThanks),
                      backgroundColor: _kSuccess, behavior: SnackBarBehavior.floating,
                    ));
                  }
                } catch (e) {
                  setDlg(() { loading = false; error = e.toString().replaceFirst('Exception: ', ''); });
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: colorScheme.primary, foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              child: loading
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(s.send),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    final s           = _s;
    final colorScheme = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        backgroundColor: colorScheme.surface,
        title: Text(s.logout, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: colorScheme.onSurface)),
        content: Text(s.logoutConfirm, style: TextStyle(fontSize: 13, color: colorScheme.onSurface.withOpacity(0.7))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(s.cancel, style: TextStyle(color: colorScheme.onSurface.withOpacity(0.6))),
          ),
          ElevatedButton(
            onPressed: () {
              AuthService.instance.logout();
              SageX3App.of(context)?.toggleTheme(false);
              Navigator.pop(ctx);
              Navigator.of(context, rootNavigator: true).pushReplacementNamed('/login');
            },
            style: ElevatedButton.styleFrom(backgroundColor: _kDanger, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            child: Text(s.logout),
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog() {
    final appState    = SageX3App.of(context);
    final s           = appState?.strings ?? AppStrings('fr');
    final colorScheme = Theme.of(context).colorScheme;

    final options = [
      {'label': 'Français', 'flag': '🇫🇷', 'code': 'fr'},
      {'label': 'English',  'flag': '🇬🇧', 'code': 'en'},
    ];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        backgroundColor: colorScheme.surface,
        title: Text(s.chooseLanguage, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: colorScheme.onSurface)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: options.map((item) => RadioListTile<String>(
            dense: true,
            title: Text('${item['flag']}  ${item['label']}', style: TextStyle(fontSize: 14, color: colorScheme.onSurface)),
            value: item['code'] as String,
            groupValue: appState?.currentLang ?? 'fr',
            activeColor: _kPrimary,
            onChanged: (code) {
              appState?.setLang(code!);
              setState(() { selectedLanguage = code == 'fr' ? 'Français' : 'English'; });
              Navigator.pop(ctx);
            },
          )).toList(),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  EDIT PROFILE DIALOG
// ═══════════════════════════════════════════════════════════════════════════════
class _EditProfileDialog extends StatefulWidget {
  final TextEditingController nameCtrl, phoneCtrl, companyCtrl;
  final String initials;
  final AppStrings strings;
  final Future<void> Function(String name, String phone, String company) onSave;

  const _EditProfileDialog({
    required this.nameCtrl, required this.phoneCtrl, required this.companyCtrl,
    required this.initials, required this.strings, required this.onSave,
  });

  @override
  State<_EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<_EditProfileDialog> {
  bool    _loading  = false;
  String? _errorMsg;

  Future<void> _save() async {
    final s    = widget.strings;
    final name = widget.nameCtrl.text.trim();
    if (name.isEmpty) { setState(() => _errorMsg = s.nameRequired); return; }
    setState(() { _loading = true; _errorMsg = null; });
    try {
      await widget.onSave(name, widget.phoneCtrl.text.trim(), widget.companyCtrl.text.trim());
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(s.profileUpdated), backgroundColor: _kSuccess, behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      setState(() { _loading = false; _errorMsg = e.toString().replaceFirst('Exception: ', ''); });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s       = widget.strings;
    final dk      = Theme.of(context).brightness == Brightness.dark;
    final bg      = dk ? const Color(0xFF1E293B) : Colors.white;
    final border  = dk ? const Color(0xFF334155) : _kBorderL;
    final surface = dk ? const Color(0xFF0F172A) : _kSurfaceL;
    final txt     = dk ? Colors.white : _kTextDark;
    final sub     = dk ? const Color(0xFF94A3B8) : _kTextSub;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: Container(
        width: 440,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: border),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(dk ? 0.45 : 0.14), blurRadius: 32, offset: const Offset(0, 10))],
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          _DialogHeader(dk: dk, icon: Icons.person_outline_rounded, iconColor: _kPrimary,
              title: s.editProfile, subtitle: s.personalInfo, onClose: () => Navigator.pop(context)),

          // Avatar + initiales centré
          Padding(
            padding: const EdgeInsets.only(top: 18, bottom: 4),
            child: CircleAvatar(
              radius: 30,
              backgroundColor: _kPrimary,
              child: Text(
                widget.initials,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18),
              ),
            ),
          ),

          Padding(padding: const EdgeInsets.fromLTRB(20, 14, 20, 0), child: Column(children: [
            _InputRow(dk: dk, ctrl: widget.nameCtrl, icon: Icons.badge_outlined, label: s.fullName,
                border: border, surface: surface, sub: sub, txt: txt),
            const SizedBox(height: 10),
            _InputRow(dk: dk, ctrl: widget.phoneCtrl, icon: Icons.phone_outlined, label: s.phone,
                keyboard: TextInputType.phone, border: border, surface: surface, sub: sub, txt: txt),
            const SizedBox(height: 10),
            _InputRow(dk: dk, ctrl: widget.companyCtrl, icon: Icons.business_outlined, label: s.company,
                border: border, surface: surface, sub: sub, txt: txt),
            if (_errorMsg != null) ...[const SizedBox(height: 10), _ErrorBanner(msg: _errorMsg!)],
          ])),
          _DialogActions(dk: dk, border: border, sub: sub, loading: _loading,
              confirmLabel: s.save, confirmColor: _kPrimary,
              cancelLabel: s.cancel,
              onCancel: () => Navigator.pop(context), onConfirm: _save),
        ]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  CHANGE PASSWORD DIALOG
// ═══════════════════════════════════════════════════════════════════════════════
class _ChangePasswordDialog extends StatefulWidget {
  final int userId;
  final AppStrings strings;
  const _ChangePasswordDialog({required this.userId, required this.strings});
  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _currentCtrl = TextEditingController();
  final _newCtrl     = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _showCurrent = false, _showNew = false, _showConfirm = false;
  bool _loading = false;
  String? _errorMsg;

  int get _strength {
    final p = _newCtrl.text;
    if (p.isEmpty) return 0;
    int s = 0;
    if (p.length >= 8) s++;
    if (p.contains(RegExp(r'[A-Z]'))) s++;
    if (p.contains(RegExp(r'[0-9]'))) s++;
    if (p.contains(RegExp(r'[!@#\$%^&*]'))) s++;
    return s;
  }

  Color get _strengthColor => switch (_strength) {
    1 => const Color(0xFFEF4444),
    2 => const Color(0xFFF97316),
    3 => const Color(0xFFEAB308),
    4 => _kSuccess,
    _ => Colors.transparent,
  };

  String _strengthLabel(AppStrings s) => switch (_strength) {
    1 => s.weak, 2 => s.medium, 3 => s.good, 4 => s.strong, _ => '',
  };

  @override
  void initState() {
    super.initState();
    _newCtrl.addListener(() => setState(() {}));
    _confirmCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() { _currentCtrl.dispose(); _newCtrl.dispose(); _confirmCtrl.dispose(); super.dispose(); }

  Future<void> _save() async {
    final s = widget.strings;
    if (_newCtrl.text != _confirmCtrl.text) { setState(() => _errorMsg = s.passwordMismatch); return; }
    if (_newCtrl.text.length < 6)           { setState(() => _errorMsg = s.passwordMin);      return; }
    setState(() { _loading = true; _errorMsg = null; });
    try {
      await ApiService().changePassword(widget.userId, _currentCtrl.text, _newCtrl.text);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(s.passwordUpdated), backgroundColor: _kSuccess, behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      setState(() { _loading = false; _errorMsg = e.toString().replaceFirst('Exception: ', ''); });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s       = widget.strings;
    final dk      = Theme.of(context).brightness == Brightness.dark;
    final bg      = dk ? const Color(0xFF1E293B) : Colors.white;
    final border  = dk ? const Color(0xFF334155) : _kBorderL;
    final surface = dk ? const Color(0xFF0F172A) : _kSurfaceL;
    final txt     = dk ? Colors.white : _kTextDark;
    final sub     = dk ? const Color(0xFF94A3B8) : _kTextSub;
    final matchOk = _confirmCtrl.text.isNotEmpty && _confirmCtrl.text == _newCtrl.text;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: Container(
        width: 440,
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16), border: Border.all(color: border),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(dk ? 0.4 : 0.12), blurRadius: 24, offset: const Offset(0, 8))]),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          _DialogHeader(dk: dk, icon: Icons.lock_outline, iconColor: _kSuccess,
              title: s.changePassword, subtitle: s.passwordSecurity, onClose: () => Navigator.pop(context)),
          Padding(padding: const EdgeInsets.fromLTRB(20, 16, 20, 0), child: Column(children: [
            _PwdRow(dk: dk, ctrl: _currentCtrl, label: s.currentPassword, icon: Icons.lock_outline,
                show: _showCurrent, onToggle: () => setState(() => _showCurrent = !_showCurrent),
                border: border, surface: surface, txt: txt, sub: sub),
            const SizedBox(height: 10),
            _PwdRow(dk: dk, ctrl: _newCtrl, label: s.newPassword, icon: Icons.lock_open_outlined,
                show: _showNew, onToggle: () => setState(() => _showNew = !_showNew),
                border: border, surface: surface, txt: txt, sub: sub),
            if (_newCtrl.text.isNotEmpty) ...[
              const SizedBox(height: 8),
              _StrengthBar(strength: _strength, color: _strengthColor, label: _strengthLabel(s),
                  strengthPrefix: s.passwordStrength, sub: sub),
            ],
            const SizedBox(height: 10),
            _PwdRow(dk: dk, ctrl: _confirmCtrl, label: s.confirmPassword, icon: Icons.check_circle_outline,
                show: _showConfirm, onToggle: () => setState(() => _showConfirm = !_showConfirm),
                border: border, surface: surface, txt: txt, sub: sub,
                accentOverride: matchOk ? _kSuccess : null),
            if (_errorMsg != null) ...[const SizedBox(height: 10), _ErrorBanner(msg: _errorMsg!)],
          ])),
          _DialogActions(dk: dk, border: border, sub: sub, loading: _loading,
              confirmLabel: s.updatePassword, confirmColor: _kSuccess,
              cancelLabel: s.cancel,
              onCancel: () => Navigator.pop(context), onConfirm: _save),
        ]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  WIDGETS COMMUNS
// ═══════════════════════════════════════════════════════════════════════════════

class _DialogHeader extends StatelessWidget {
  final bool dk;
  final IconData icon;
  final Color iconColor;
  final String title, subtitle;
  final VoidCallback onClose;
  const _DialogHeader({required this.dk, required this.icon, required this.iconColor,
    required this.title, required this.subtitle, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final border = dk ? const Color(0xFF334155) : _kBorderL;
    final txt    = dk ? Colors.white : _kTextDark;
    final sub    = dk ? const Color(0xFF94A3B8) : _kTextSub;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 16, 16),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: border)),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16))),
      child: Row(children: [
        Container(width: 38, height: 38,
            decoration: BoxDecoration(color: iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: iconColor, size: 20)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: txt)),
          const SizedBox(height: 1),
          Text(subtitle, style: TextStyle(fontSize: 12, color: sub)),
        ])),
        GestureDetector(
          onTap: onClose,
          child: Container(width: 28, height: 28,
              decoration: BoxDecoration(
                  color: dk ? Colors.white.withOpacity(0.06) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(7)),
              child: Icon(Icons.close, size: 15, color: sub)),
        ),
      ]),
    );
  }
}

class _DialogActions extends StatelessWidget {
  final bool dk, loading;
  final Color border, sub, confirmColor;
  final String confirmLabel, cancelLabel;
  final VoidCallback onCancel, onConfirm;
  const _DialogActions({required this.dk, required this.border, required this.sub,
    required this.loading, required this.confirmLabel, required this.cancelLabel,
    required this.confirmColor, required this.onCancel, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Row(children: [
        Expanded(child: OutlinedButton(
          onPressed: loading ? null : onCancel,
          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 11),
              side: BorderSide(color: border), foregroundColor: sub,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9))),
          child: Text(cancelLabel, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: sub)),
        )),
        const SizedBox(width: 10),
        Expanded(flex: 2, child: ElevatedButton(
          onPressed: loading ? null : onConfirm,
          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 11),
              backgroundColor: confirmColor, foregroundColor: Colors.white, elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9))),
          child: loading
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
              : Text(confirmLabel, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
        )),
      ]),
    );
  }
}

class _ReadonlyRow extends StatelessWidget {
  final bool dk;
  final IconData icon;
  final String label, value, nonEditLabel;
  final Color border, surface, sub, txt;
  const _ReadonlyRow({required this.dk, required this.icon, required this.label, required this.value,
    required this.border, required this.surface, required this.sub, required this.txt, required this.nonEditLabel});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: border)),
      child: Row(children: [
        Icon(icon, color: _kPrimary, size: 16), const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(fontSize: 10, color: sub, fontWeight: FontWeight.w500)),
          const SizedBox(height: 1),
          Text(value, style: TextStyle(fontSize: 13, color: txt, fontWeight: FontWeight.w600)),
        ])),
        Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
                color: dk ? Colors.white.withOpacity(0.05) : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(5)),
            child: Text(nonEditLabel, style: TextStyle(fontSize: 10, color: sub))),
      ]),
    );
  }
}

class _InputRow extends StatelessWidget {
  final bool dk;
  final TextEditingController ctrl;
  final IconData icon;
  final String label;
  final TextInputType? keyboard;
  final Color border, surface, sub, txt;
  const _InputRow({required this.dk, required this.ctrl, required this.icon, required this.label,
    this.keyboard, required this.border, required this.surface, required this.sub, required this.txt});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: border)),
      child: Row(children: [
        const SizedBox(width: 14),
        Icon(icon, color: _kPrimary, size: 16), const SizedBox(width: 10),
        Expanded(child: TextField(
          controller: ctrl, keyboardType: keyboard,
          style: TextStyle(fontSize: 13, color: txt, fontWeight: FontWeight.w600),
          decoration: InputDecoration(labelText: label, labelStyle: TextStyle(fontSize: 11, color: sub),
              border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(vertical: 12)),
        )),
        const SizedBox(width: 14),
      ]),
    );
  }
}

class _PwdRow extends StatelessWidget {
  final bool dk, show;
  final TextEditingController ctrl;
  final IconData icon;
  final String label;
  final VoidCallback onToggle;
  final Color border, surface, txt, sub;
  final Color? accentOverride;
  const _PwdRow({required this.dk, required this.ctrl, required this.icon, required this.label,
    required this.show, required this.onToggle, required this.border, required this.surface,
    required this.txt, required this.sub, this.accentOverride});

  @override
  Widget build(BuildContext context) {
    final accent          = accentOverride ?? _kPrimary;
    final effectiveBorder = accentOverride != null ? accentOverride!.withOpacity(0.5) : border;
    return Container(
      decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: effectiveBorder)),
      child: Row(children: [
        const SizedBox(width: 14),
        Icon(icon, color: accent, size: 16), const SizedBox(width: 10),
        Expanded(child: TextField(
          controller: ctrl, obscureText: !show,
          style: TextStyle(fontSize: 13, color: txt, fontWeight: FontWeight.w600),
          decoration: InputDecoration(labelText: label, labelStyle: TextStyle(fontSize: 11, color: sub),
              border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(vertical: 12)),
        )),
        IconButton(
          icon: Icon(show ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: sub, size: 16),
          onPressed: onToggle, padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        ),
        const SizedBox(width: 4),
      ]),
    );
  }
}

class _StrengthBar extends StatelessWidget {
  final int strength;
  final Color color, sub;
  final String label, strengthPrefix;
  const _StrengthBar({required this.strength, required this.color, required this.label,
    required this.strengthPrefix, required this.sub});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      ...List.generate(4, (i) => Expanded(child: Container(
        height: 3, margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
        decoration: BoxDecoration(color: i < strength ? color : _kBorderL, borderRadius: BorderRadius.circular(2)),
      ))),
      const SizedBox(width: 10),
      Text(strengthPrefix, style: TextStyle(fontSize: 10, color: sub)),
      Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w700)),
    ]);
  }
}

class _ErrorBanner extends StatelessWidget {
  final String msg;
  const _ErrorBanner({required this.msg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(color: _kDanger.withOpacity(0.07), borderRadius: BorderRadius.circular(9),
          border: Border.all(color: _kDanger.withOpacity(0.2))),
      child: Row(children: [
        const Icon(Icons.error_outline, color: _kDanger, size: 15), const SizedBox(width: 8),
        Expanded(child: Text(msg, style: const TextStyle(color: _kDanger, fontSize: 12))),
      ]),
    );
  }
}