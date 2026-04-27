import 'package:flutter/material.dart';
import 'package:frontend_sage3/main.dart';
import 'package:frontend_sage3/services/auth_service.dart';
import 'package:frontend_sage3/services/api_service.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool   notificationsEnabled = true;
  bool   darkMode             = false;
  String selectedLanguage     = 'Français';

  AuthUser? get _user => AuthService.instance.currentUser;
  String get _username => _user?.username ?? 'Utilisateur';
  String get _email    => _user?.email    ?? '';
  String get _role     => _user?.role     ?? 'Utilisateur';

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
    _nameCtrl = TextEditingController(text: _username);
    _emailCtrl = TextEditingController(text: _email);
    final appState = SageX3App.of(context);
    if (appState != null) darkMode = appState.isDarkMode;
  }

  @override
  void dispose() { _nameCtrl.dispose(); _emailCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [theme.scaffoldBackgroundColor,
              theme.brightness == Brightness.light ? Color(0xFFe2e8f0) : Color(0xFF0F172A)])),
        child: SafeArea(
          child: Column(children: [
            _buildCustomAppBar(context),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(24),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _buildSection('Compte', [
                    _buildProfileTile(),
                    _buildSettingTile(
                      icon: Icons.edit_outlined, title: 'Modifier le profil',
                      subtitle: 'Nom, e-mail', onTap: () => _showEditProfileDialog()),
                    _buildSettingTile(
                      icon: Icons.lock_outlined, title: 'Changer le mot de passe',
                      subtitle: 'Mettez à jour votre mot de passe', onTap: () => _showChangePasswordDialog()),
                  ]),
                  SizedBox(height: 24),

                  _buildSection('Préférences', [
                    _buildSwitchTile(
                      icon: Icons.notifications_outlined, title: 'Notifications',
                      subtitle: 'Recevoir les mises à jour des imports',
                      value: notificationsEnabled,
                      onChanged: (v) => setState(() => notificationsEnabled = v)),
                    _buildSwitchTile(
                      icon: Icons.dark_mode_outlined, title: 'Mode sombre',
                      subtitle: 'Activer le thème sombre',
                      value: darkMode,
                      onChanged: (v) {
                        setState(() => darkMode = v);
                        SageX3App.of(context)?.toggleTheme(v);
                      }),
                    _buildSettingTile(
                      icon: Icons.language, title: 'Langue',
                      subtitle: selectedLanguage, onTap: () => _showLanguageDialog()),
                  ]),
                  SizedBox(height: 24),

                  _buildSection('Support', [
                    _buildSettingTile(
                      icon: Icons.feedback_outlined, title: 'Envoyer un commentaire',
                      subtitle: 'Signalez un problème ou suggérez une amélioration',
                      onTap: () => _showFeedbackDialog()),
                    _buildSettingTile(
                      icon: Icons.help_outline, title: 'Aide & FAQ',
                      subtitle: 'Obtenir de l\'aide',
                      onTap: () => _showComingSoonSnackBar('Centre d\'aide')),
                    _buildSettingTile(
                      icon: Icons.privacy_tip_outlined, title: 'Politique de confidentialité',
                      subtitle: 'Voir la politique de confidentialité',
                      onTap: () => _showComingSoonSnackBar('Politique de confidentialité')),
                  ]),
                  SizedBox(height: 24),

                  _buildSection('À propos', [
                    _buildSettingTile(
                      icon: Icons.info_outline, title: 'Version',
                      subtitle: '1.0.0', trailing: SizedBox.shrink()),
                  ]),
                  SizedBox(height: 24),

                  _buildLogoutButton(),
                  SizedBox(height: 40),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildCustomAppBar(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(color: theme.colorScheme.surface,
        boxShadow: [BoxShadow(color: theme.brightness == Brightness.light ? Colors.black12 : Colors.black54,
            blurRadius: 10, offset: Offset(0, 2))]),
      child: Row(children: [
        IconButton(icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
            onPressed: () => Navigator.pop(context)),
        SizedBox(width: 8),
        Text('Paramètres', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
      ]),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    final theme = Theme.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: EdgeInsets.only(left: 4, bottom: 12),
        child: Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface.withOpacity(0.7)))),
      Container(
        decoration: BoxDecoration(color: theme.colorScheme.surface, borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: theme.brightness == Brightness.light ? Colors.black12 : Colors.black54,
              blurRadius: 8, offset: Offset(0, 4))]),
        child: Column(children: children)),
    ]);
  }

  Widget _buildProfileTile() {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: CircleAvatar(radius: 28, backgroundColor: colorScheme.primary,
        child: Text(_initials, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))),
      title: Text(_username, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
      subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(_email, style: TextStyle(fontSize: 13, color: colorScheme.onSurface.withOpacity(0.7))),
        SizedBox(height: 4),
        Container(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(color: colorScheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
          child: Text(_role, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: colorScheme.primary))),
      ]),
    );
  }

  Widget _buildSettingTile({required IconData icon, required String title, required String subtitle,
      Widget? trailing, VoidCallback? onTap}) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(padding: EdgeInsets.all(8),
        decoration: BoxDecoration(color: colorScheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: colorScheme.primary, size: 24)),
      title: Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: colorScheme.onSurface)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 13, color: colorScheme.onSurface.withOpacity(0.7))),
      trailing: trailing ?? Icon(Icons.chevron_right, color: colorScheme.onSurface.withOpacity(0.5)),
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile({required IconData icon, required String title, required String subtitle,
      required bool value, required ValueChanged<bool> onChanged}) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(padding: EdgeInsets.all(8),
        decoration: BoxDecoration(color: colorScheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: colorScheme.primary, size: 24)),
      title: Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: colorScheme.onSurface)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 13, color: colorScheme.onSurface.withOpacity(0.7))),
      trailing: Switch(value: value, onChanged: onChanged, activeColor: colorScheme.primary),
    );
  }

  Widget _buildLogoutButton() {
    final theme = Theme.of(context);
    return Center(
      child: OutlinedButton.icon(
        onPressed: () => _showLogoutDialog(),
        icon: Icon(Icons.logout, color: theme.colorScheme.error),
        label: Text('Se déconnecter',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.colorScheme.error)),
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.symmetric(horizontal: 32, vertical: 14),
          side: BorderSide(color: theme.colorScheme.error, width: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  //  EDIT PROFILE
  // ═════════════════════════════════════════════════════════════════════════
   void _showEditProfileDialog() {
  final nameCtrl    = TextEditingController(text: _username);
  final phoneCtrl   = TextEditingController(text: _user?.phone    ?? '');
  final companyCtrl = TextEditingController(text: _user?.company  ?? '');
 
  showDialog(
    context: context,
    barrierColor: Colors.black54,
    builder: (ctx) => _EditProfileDialog(
      nameCtrl:    nameCtrl,
      phoneCtrl:   phoneCtrl,
      companyCtrl: companyCtrl,
      email:       _email,
      initials:    _initials,
      onSave: (name, phone, company) async {
        await ApiService().updateUser(
          _user!.id, name, _user!.email, _user!.role,
          phone: phone, company: company,
        );
        AuthService.instance.setUser(AuthUser(
          id:       _user!.id,
          username: name,
          email:    _user!.email,
          role:     _user!.role,
          token:    _user!.token,
          phone:    phone,
          company:  company,
        ));
        if (mounted) setState(() {});
      },
    ),
  );
}
  // ═════════════════════════════════════════════════════════════════════════
  //  CHANGE PASSWORD
  // ═════════════════════════════════════════════════════════════════════════
  void _showChangePasswordDialog() {
  showDialog(
    context: context,
    barrierColor: Colors.black54,
    builder: (ctx) => _ChangePasswordDialog(
      userId: _user!.id,
    ),
  );
}
  // ═════════════════════════════════════════════════════════════════════════
  //  FEEDBACK — visual only, no API call
  // ═════════════════════════════════════════════════════════════════════════
  void _showFeedbackDialog() {
    final colorScheme = Theme.of(context).colorScheme;
    final feedbackCtrl = TextEditingController();
    bool isLoading = false;
    String? errorMsg;

    showDialog(context: context, builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDlgState) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Envoyer un commentaire', style: TextStyle(color: colorScheme.onSurface)),
        backgroundColor: colorScheme.surface,
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Votre commentaire sera envoyé à l\'administrateur.',
              style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withOpacity(0.6))),
          SizedBox(height: 12),
          if (errorMsg != null) ...[
            Container(padding: EdgeInsets.all(10),
              decoration: BoxDecoration(color: colorScheme.error.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Text(errorMsg!, style: TextStyle(color: colorScheme.error, fontSize: 13))),
            SizedBox(height: 12),
          ],
          TextField(controller: feedbackCtrl, maxLines: 5,
            style: TextStyle(color: colorScheme.onSurface),
            decoration: InputDecoration(
              hintText: 'Décrivez votre problème ou suggestion...',
              hintStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.4)),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colorScheme.primary.withOpacity(0.3))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colorScheme.primary, width: 1.5)),
            )),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx),
            child: Text('Annuler', style: TextStyle(color: colorScheme.onSurface))),
          ElevatedButton(
            onPressed: isLoading ? null : () async {
              if (feedbackCtrl.text.trim().isEmpty) return;
              setDlgState(() => isLoading = true);
              try {
                await ApiService().sendFeedback(
                  feedbackCtrl.text.trim(),
                  _user?.id ?? 0,
                  _username,
                );
                if (mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Merci pour votre commentaire !'),
                    backgroundColor: Color(0xFF10b981), behavior: SnackBarBehavior.floating));
                }
              } catch (e) {
                setDlgState(() { isLoading = false; errorMsg = e.toString().replaceFirst('Exception: ', ''); });
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: colorScheme.primary, foregroundColor: Colors.white),
            child: isLoading
                ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text('Envoyer'),
          ),
        ],
      ),
    ));
  }

  // ═════════════════════════════════════════════════════════════════════════
  //  LOGOUT
  // ═════════════════════════════════════════════════════════════════════════
  void _showLogoutDialog() {
    final colorScheme = Theme.of(context).colorScheme;
    showDialog(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('Se déconnecter', style: TextStyle(color: colorScheme.onSurface)),
      content: Text('Êtes-vous sûr de vouloir vous déconnecter ?',
          style: TextStyle(color: colorScheme.onSurface)),
      backgroundColor: colorScheme.surface,
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx),
          child: Text('Annuler', style: TextStyle(color: colorScheme.onSurface))),
        ElevatedButton(
          onPressed: () {
            AuthService.instance.logout();
            Navigator.pop(ctx);
            Navigator.of(context, rootNavigator: true).pushReplacementNamed('/login');
          },
          style: ElevatedButton.styleFrom(backgroundColor: colorScheme.error, foregroundColor: Colors.white),
          child: Text('Se déconnecter'),
        ),
      ],
    ));
  }

  // ═════════════════════════════════════════════════════════════════════════
  //  LANGUAGE
  // ═════════════════════════════════════════════════════════════════════════
  void _showLanguageDialog() {
    final colorScheme = Theme.of(context).colorScheme;
    showDialog(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('Choisir la langue', style: TextStyle(color: colorScheme.onSurface)),
      backgroundColor: colorScheme.surface,
      content: Column(mainAxisSize: MainAxisSize.min,
        children: ['Français', 'English'].map((lang) => RadioListTile<String>(
          title: Text(lang, style: TextStyle(color: colorScheme.onSurface)),
          value: lang, groupValue: selectedLanguage, activeColor: colorScheme.primary,
          onChanged: (v) {
            setState(() => selectedLanguage = v!);
            Navigator.pop(ctx);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Changement de langue bientôt disponible'),
              backgroundColor: colorScheme.primary, behavior: SnackBarBehavior.floating));
          },
        )).toList()),
    ));
  }

  // ═════════════════════════════════════════════════════════════════════════
  //  HELPERS
  // ═════════════════════════════════════════════════════════════════════════
  InputDecoration _fieldDeco(String label, ColorScheme cs) => InputDecoration(
    labelText: label, labelStyle: TextStyle(color: cs.onSurface.withOpacity(0.7)),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: cs.primary.withOpacity(0.3))),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: cs.primary.withOpacity(0.3))),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: cs.primary, width: 1.5)),
  );

  Widget _obscuredField(TextEditingController ctrl, String label, ColorScheme cs) => TextField(
    controller: ctrl, obscureText: true,
    style: TextStyle(color: cs.onSurface),
    decoration: _fieldDeco(label, cs),
  );

  void _showComingSoonSnackBar(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('$feature bientôt disponible !'),
      behavior: SnackBarBehavior.floating,
      backgroundColor: Theme.of(context).colorScheme.primary));
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  COPIEZ ces widgets en bas de votre fichier settings_page.dart
//  (après la classe SettingsPage, avant la dernière accolade du fichier)
// ═══════════════════════════════════════════════════════════════════════════
 
// ─── EDIT PROFILE DIALOG ────────────────────────────────────────────────────
class _EditProfileDialog extends StatefulWidget {
  final TextEditingController nameCtrl, phoneCtrl, companyCtrl;
  final String email, initials;
  final Future<void> Function(String name, String phone, String company) onSave;
 
  const _EditProfileDialog({
    required this.nameCtrl,
    required this.phoneCtrl,
    required this.companyCtrl,
    required this.email,
    required this.initials,
    required this.onSave,
  });
 
  @override
  State<_EditProfileDialog> createState() => _EditProfileDialogState();
}
 
class _EditProfileDialogState extends State<_EditProfileDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  late Animation<double>   _scale, _fade;
 
  bool    _loading  = false;
  String? _errorMsg;
 
  static const _blue  = Color(0xFF2563eb);
  static const _red   = Color(0xFFdc2626);
 
  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: Duration(milliseconds: 320));
    _scale = CurvedAnimation(parent: _anim, curve: Curves.easeOutBack);
    _fade  = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
    _anim.forward();
  }
 
  @override
  void dispose() { _anim.dispose(); super.dispose(); }
 
  Future<void> _save() async {
    final name = widget.nameCtrl.text.trim();
    if (name.isEmpty) { setState(() => _errorMsg = 'Le nom est obligatoire'); return; }
    setState(() { _loading = true; _errorMsg = null; });
    try {
      await widget.onSave(name, widget.phoneCtrl.text.trim(), widget.companyCtrl.text.trim());
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Row(children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            SizedBox(width: 10),
            Text('Profil mis à jour avec succès !'),
          ]),
          backgroundColor: Color(0xFF10b981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: EdgeInsets.all(16),
        ));
      }
    } catch (e) {
      setState(() { _loading = false; _errorMsg = e.toString().replaceFirst('Exception: ', ''); });
    }
  }
 
  @override
  Widget build(BuildContext context) {
    final dk = Theme.of(context).brightness == Brightness.dark;
    final bg = dk ? Color(0xFF151921) : Colors.white;
    final surface = dk ? Color(0xFF1e2330) : Color(0xFFF8FAFC);
    final border  = dk ? Color(0xFF2a3040) : Color(0xFFE2E8F0);
    final txt     = dk ? Colors.white : Color(0xFF0F172A);
    final sub     = dk ? Color(0xFF94A3B8) : Color(0xFF64748B);
 
    return FadeTransition(
      opacity: _fade,
      child: ScaleTransition(
        scale: _scale,
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 40),
          child: Container(
            width: 480,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(dk ? 0.5 : 0.15), blurRadius: 40, offset: Offset(0, 20)),
              ],
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
 
              // ── HEADER ──────────────────────────────────────────────────
              Container(
                padding: EdgeInsets.fromLTRB(28, 28, 28, 24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                    colors: dk
                        ? [Color(0xFF1e3a5f), Color(0xFF1a2a4a)]
                        : [Color(0xFFEFF6FF), Color(0xFFDBEAFE)],
                  ),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Row(children: [
                  // Avatar
                  Container(
                    width: 64, height: 64,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [Color(0xFF2563eb), Color(0xFF3B82F6)]),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: _blue.withOpacity(0.35), blurRadius: 16, offset: Offset(0, 6))],
                    ),
                    child: Center(child: Text(widget.initials,
                        style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800))),
                  ),
                  SizedBox(width: 18),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Modifier le profil',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800,
                            color: dk ? Colors.white : Color(0xFF1E3A5F), letterSpacing: -0.4)),
                    SizedBox(height: 4),
                    Text('Mettez à jour vos informations personnelles',
                        style: TextStyle(fontSize: 12.5, color: sub, height: 1.4)),
                  ])),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color: dk ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.close_rounded, size: 16, color: sub),
                    ),
                  ),
                ]),
              ),
 
              // ── EMAIL (lecture seule, stylisé) ────────────────────────
              Padding(
                padding: EdgeInsets.fromLTRB(28, 24, 28, 0),
                child: _readonlyField(
                  icon: Icons.alternate_email_rounded,
                  label: 'Adresse e-mail',
                  value: widget.email,
                  note: 'Non modifiable',
                  surface: surface, border: border, txt: txt, sub: sub, dk: dk,
                ),
              ),
 
              // ── FIELDS ────────────────────────────────────────────────
              Padding(
                padding: EdgeInsets.fromLTRB(28, 16, 28, 0),
                child: _buildField(
                  ctrl: widget.nameCtrl,
                  icon: Icons.person_outline_rounded,
                  label: 'Nom complet',
                  surface: surface, border: border, txt: txt, sub: sub, dk: dk,
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(28, 12, 28, 0),
                child: _buildField(
                  ctrl: widget.phoneCtrl,
                  icon: Icons.phone_outlined,
                  label: 'Numéro de téléphone',
                  keyboard: TextInputType.phone,
                  surface: surface, border: border, txt: txt, sub: sub, dk: dk,
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(28, 12, 28, 0),
                child: _buildField(
                  ctrl: widget.companyCtrl,
                  icon: Icons.business_outlined,
                  label: 'Société / Entreprise',
                  surface: surface, border: border, txt: txt, sub: sub, dk: dk,
                ),
              ),
 
              // ── ERROR ─────────────────────────────────────────────────
              if (_errorMsg != null)
                Padding(
                  padding: EdgeInsets.fromLTRB(28, 12, 28, 0),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: _red.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _red.withOpacity(0.25)),
                    ),
                    child: Row(children: [
                      Icon(Icons.error_outline_rounded, color: _red, size: 16),
                      SizedBox(width: 8),
                      Expanded(child: Text(_errorMsg!, style: TextStyle(color: _red, fontSize: 12.5))),
                    ]),
                  ),
                ),
 
              // ── ACTIONS ───────────────────────────────────────────────
              Padding(
                padding: EdgeInsets.fromLTRB(28, 20, 28, 28),
                child: Row(children: [
                  Expanded(
                    child: TextButton(
                      onPressed: _loading ? null : () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: border)),
                        foregroundColor: sub,
                      ),
                      child: Text('Annuler', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _save,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: _blue,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        shadowColor: _blue.withOpacity(0.4),
                      ),
                      child: _loading
                          ? SizedBox(width: 20, height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                          : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                              Icon(Icons.check_rounded, size: 18),
                              SizedBox(width: 8),
                              Text('Enregistrer', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
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
 
  Widget _readonlyField({
    required IconData icon, required String label,
    required String value, required String note,
    required Color surface, required Color border,
    required Color txt, required Color sub, required bool dk,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Row(children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Color(0xFF2563eb).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Color(0xFF2563eb), size: 16),
        ),
        SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(fontSize: 11, color: sub, fontWeight: FontWeight.w500)),
          SizedBox(height: 2),
          Text(value, style: TextStyle(fontSize: 14, color: txt, fontWeight: FontWeight.w600)),
        ])),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: dk ? Colors.white.withOpacity(0.05) : Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(note, style: TextStyle(fontSize: 10.5, color: sub, fontWeight: FontWeight.w500)),
        ),
      ]),
    );
  }
 
  Widget _buildField({
    required TextEditingController ctrl,
    required IconData icon,
    required String label,
    TextInputType? keyboard,
    required Color surface, required Color border,
    required Color txt, required Color sub, required bool dk,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Row(children: [
        SizedBox(width: 16),
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Color(0xFF2563eb).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Color(0xFF2563eb), size: 16),
        ),
        SizedBox(width: 12),
        Expanded(
          child: TextField(
            controller: ctrl,
            keyboardType: keyboard,
            style: TextStyle(fontSize: 14, color: txt, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              labelText: label,
              labelStyle: TextStyle(fontSize: 12, color: sub, fontWeight: FontWeight.w500),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        SizedBox(width: 16),
      ]),
    );
  }
}
 
 
// ─── CHANGE PASSWORD DIALOG ─────────────────────────────────────────────────
class _ChangePasswordDialog extends StatefulWidget {
  final int userId;
  const _ChangePasswordDialog({required this.userId});
 
  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}
 
class _ChangePasswordDialogState extends State<_ChangePasswordDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  late Animation<double>   _scale, _fade;
 
  final _currentCtrl = TextEditingController();
  final _newCtrl     = TextEditingController();
  final _confirmCtrl = TextEditingController();
 
  bool _showCurrent = false, _showNew = false, _showConfirm = false;
  bool _loading = false;
  String? _errorMsg;
 
  static const _blue  = Color(0xFF2563eb);
  static const _red   = Color(0xFFdc2626);
  static const _green = Color(0xFF10b981);
 
  // Password strength
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
 
  Color get _strengthColor {
    switch (_strength) {
      case 1: return Color(0xFFef4444);
      case 2: return Color(0xFFf97316);
      case 3: return Color(0xFFeab308);
      case 4: return _green;
      default: return Colors.transparent;
    }
  }
 
  String get _strengthLabel {
    switch (_strength) {
      case 1: return 'Faible';
      case 2: return 'Moyen';
      case 3: return 'Bon';
      case 4: return 'Fort';
      default: return '';
    }
  }
 
  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: Duration(milliseconds: 320));
    _scale = CurvedAnimation(parent: _anim, curve: Curves.easeOutBack);
    _fade  = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
    _anim.forward();
    _newCtrl.addListener(() => setState(() {}));
  }
 
  @override
  void dispose() {
    _anim.dispose();
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }
 
  Future<void> _save() async {
    if (_newCtrl.text != _confirmCtrl.text) {
      setState(() => _errorMsg = 'Les mots de passe ne correspondent pas');
      return;
    }
    if (_newCtrl.text.length < 6) {
      setState(() => _errorMsg = 'Le mot de passe doit contenir au moins 6 caractères');
      return;
    }
    setState(() { _loading = true; _errorMsg = null; });
    try {
      await ApiService().changePassword(widget.userId, _currentCtrl.text, _newCtrl.text);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Row(children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            SizedBox(width: 10),
            Text('Mot de passe mis à jour !'),
          ]),
          backgroundColor: _green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: EdgeInsets.all(16),
        ));
      }
    } catch (e) {
      setState(() { _loading = false; _errorMsg = e.toString().replaceFirst('Exception: ', ''); });
    }
  }
 
  @override
  Widget build(BuildContext context) {
    final dk = Theme.of(context).brightness == Brightness.dark;
    final bg = dk ? Color(0xFF151921) : Colors.white;
    final surface = dk ? Color(0xFF1e2330) : Color(0xFFF8FAFC);
    final border  = dk ? Color(0xFF2a3040) : Color(0xFFE2E8F0);
    final txt     = dk ? Colors.white : Color(0xFF0F172A);
    final sub     = dk ? Color(0xFF94A3B8) : Color(0xFF64748B);
 
    return FadeTransition(
      opacity: _fade,
      child: ScaleTransition(
        scale: _scale,
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 40),
          child: Container(
            width: 480,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(dk ? 0.5 : 0.15), blurRadius: 40, offset: Offset(0, 20)),
              ],
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
 
              // ── HEADER ──────────────────────────────────────────────────
              Container(
                padding: EdgeInsets.fromLTRB(28, 28, 28, 24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                    colors: dk
                        ? [Color(0xFF1a2a1a), Color(0xFF1a3a2a)]
                        : [Color(0xFFF0FDF4), Color(0xFFDCFCE7)],
                  ),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Row(children: [
                  Container(
                    width: 52, height: 52,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [Color(0xFF059669), Color(0xFF10b981)]),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: _green.withOpacity(0.35), blurRadius: 14, offset: Offset(0, 6))],
                    ),
                    child: Icon(Icons.lock_outline_rounded, color: Colors.white, size: 24),
                  ),
                  SizedBox(width: 18),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Sécurité du compte',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800,
                            color: dk ? Colors.white : Color(0xFF064E3B), letterSpacing: -0.4)),
                    SizedBox(height: 4),
                    Text('Choisissez un mot de passe fort et unique',
                        style: TextStyle(fontSize: 12.5, color: sub, height: 1.4)),
                  ])),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color: dk ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.close_rounded, size: 16, color: sub),
                    ),
                  ),
                ]),
              ),
 
              Padding(
                padding: EdgeInsets.fromLTRB(28, 24, 28, 0),
                child: _pwdField(
                  ctrl: _currentCtrl, label: 'Mot de passe actuel',
                  icon: Icons.lock_outline_rounded,
                  show: _showCurrent,
                  onToggle: () => setState(() => _showCurrent = !_showCurrent),
                  surface: surface, border: border, txt: txt, sub: sub,
                ),
              ),
 
              // Divider with "Nouveau"
              Padding(
                padding: EdgeInsets.fromLTRB(28, 20, 28, 0),
                child: Row(children: [
                  Expanded(child: Divider(color: border)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text('Nouveau mot de passe',
                        style: TextStyle(fontSize: 11, color: sub, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                  ),
                  Expanded(child: Divider(color: border)),
                ]),
              ),
 
              Padding(
                padding: EdgeInsets.fromLTRB(28, 12, 28, 0),
                child: _pwdField(
                  ctrl: _newCtrl, label: 'Nouveau mot de passe',
                  icon: Icons.lock_open_outlined,
                  show: _showNew,
                  onToggle: () => setState(() => _showNew = !_showNew),
                  surface: surface, border: border, txt: txt, sub: sub,
                ),
              ),
 
              // ── STRENGTH BAR ─────────────────────────────────────────
              if (_newCtrl.text.isNotEmpty)
                Padding(
                  padding: EdgeInsets.fromLTRB(28, 10, 28, 0),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      ...List.generate(4, (i) => Expanded(
                        child: Container(
                          height: 4,
                          margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
                          decoration: BoxDecoration(
                            color: i < _strength ? _strengthColor : border,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      )),
                    ]),
                    SizedBox(height: 6),
                    Row(children: [
                      Text('Force : ', style: TextStyle(fontSize: 11, color: sub)),
                      Text(_strengthLabel,
                          style: TextStyle(fontSize: 11, color: _strengthColor, fontWeight: FontWeight.w700)),
                      Spacer(),
                      // Hints
                      _hint(_newCtrl.text.length >= 8, '8+ car.', sub),
                      SizedBox(width: 8),
                      _hint(_newCtrl.text.contains(RegExp(r'[A-Z]')), 'A-Z', sub),
                      SizedBox(width: 8),
                      _hint(_newCtrl.text.contains(RegExp(r'[0-9]')), '0-9', sub),
                    ]),
                  ]),
                ),
 
              Padding(
                padding: EdgeInsets.fromLTRB(28, 12, 28, 0),
                child: _pwdField(
                  ctrl: _confirmCtrl, label: 'Confirmer le mot de passe',
                  icon: Icons.check_circle_outline_rounded,
                  show: _showConfirm,
                  onToggle: () => setState(() => _showConfirm = !_showConfirm),
                  surface: surface, border: border, txt: txt, sub: sub,
                  accentOverride: (_confirmCtrl.text.isNotEmpty && _confirmCtrl.text == _newCtrl.text)
                      ? _green : null,
                ),
              ),
 
              // ── ERROR ─────────────────────────────────────────────────
              if (_errorMsg != null)
                Padding(
                  padding: EdgeInsets.fromLTRB(28, 12, 28, 0),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: _red.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _red.withOpacity(0.25)),
                    ),
                    child: Row(children: [
                      Icon(Icons.error_outline_rounded, color: _red, size: 16),
                      SizedBox(width: 8),
                      Expanded(child: Text(_errorMsg!, style: TextStyle(color: _red, fontSize: 12.5))),
                    ]),
                  ),
                ),
 
              // ── ACTIONS ───────────────────────────────────────────────
              Padding(
                padding: EdgeInsets.fromLTRB(28, 20, 28, 28),
                child: Row(children: [
                  Expanded(
                    child: TextButton(
                      onPressed: _loading ? null : () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: border)),
                        foregroundColor: sub,
                      ),
                      child: Text('Annuler', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _save,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: _green,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _loading
                          ? SizedBox(width: 20, height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                          : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                              Icon(Icons.shield_outlined, size: 18),
                              SizedBox(width: 8),
                              Text('Mettre à jour', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
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
 
  Widget _pwdField({
    required TextEditingController ctrl,
    required String label,
    required IconData icon,
    required bool show,
    required VoidCallback onToggle,
    required Color surface, required Color border,
    required Color txt, required Color sub,
    Color? accentOverride,
  }) {
    final accent = accentOverride ?? _blue;
    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accentOverride != null ? accentOverride!.withOpacity(0.5) : border),
      ),
      child: Row(children: [
        SizedBox(width: 16),
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: accent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: accent, size: 16),
        ),
        SizedBox(width: 12),
        Expanded(
          child: TextField(
            controller: ctrl,
            obscureText: !show,
            style: TextStyle(fontSize: 14, color: txt, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              labelText: label,
              labelStyle: TextStyle(fontSize: 12, color: sub, fontWeight: FontWeight.w500),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        IconButton(
          icon: Icon(show ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: sub, size: 18),
          onPressed: onToggle,
        ),
      ]),
    );
  }
 
  Widget _hint(bool ok, String label, Color sub) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(ok ? Icons.check_circle_rounded : Icons.circle_outlined,
          size: 12, color: ok ? _green : sub.withOpacity(0.4)),
      SizedBox(width: 3),
      Text(label, style: TextStyle(fontSize: 10, color: ok ? _green : sub.withOpacity(0.5))),
    ]);
  }
}