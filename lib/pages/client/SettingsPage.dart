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
    final colorScheme = Theme.of(context).colorScheme;
    _nameCtrl.text = _username;
    _emailCtrl.text = _email;
    bool isLoading = false;
    String? errorMsg;

    showDialog(context: context, builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDlgState) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Modifier le profil', style: TextStyle(color: colorScheme.onSurface)),
        backgroundColor: colorScheme.surface,
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          if (errorMsg != null) ...[
            Container(padding: EdgeInsets.all(10),
              decoration: BoxDecoration(color: colorScheme.error.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Text(errorMsg!, style: TextStyle(color: colorScheme.error, fontSize: 13))),
            SizedBox(height: 12),
          ],
          TextField(controller: _nameCtrl,
            style: TextStyle(color: colorScheme.onSurface),
            decoration: _fieldDeco('Nom complet', colorScheme)),
          SizedBox(height: 12),
          TextField(controller: _emailCtrl,
            style: TextStyle(color: colorScheme.onSurface),
            decoration: _fieldDeco('Adresse e-mail', colorScheme)),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx),
            child: Text('Annuler', style: TextStyle(color: colorScheme.onSurface))),
          ElevatedButton(
            onPressed: isLoading ? null : () async {
              if (_nameCtrl.text.trim().isEmpty || _emailCtrl.text.trim().isEmpty) {
                setDlgState(() => errorMsg = 'Tous les champs sont obligatoires');
                return;
              }
              setDlgState(() => isLoading = true);
              try {
                                await ApiService().updateUser(
                  _user!.id, _nameCtrl.text.trim(), _emailCtrl.text.trim(), _user!.role);
                AuthService.instance.setUser(AuthUser(
                  id: _user!.id, username: _nameCtrl.text.trim(),
                  email: _emailCtrl.text.trim(), role: _user!.role, token: _user!.token));
                if (mounted) {
                  Navigator.pop(ctx);
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Profil mis à jour !'),
                    backgroundColor: Color(0xFF10b981), behavior: SnackBarBehavior.floating));
                }
              } catch (e) {
                setDlgState(() { isLoading = false; errorMsg = e.toString().replaceFirst('Exception: ', ''); });
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: colorScheme.primary, foregroundColor: Colors.white),
            child: isLoading
                ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text('Enregistrer'),
          ),
        ],
      ),
    ));
  }

  // ═════════════════════════════════════════════════════════════════════════
  //  CHANGE PASSWORD
  // ═════════════════════════════════════════════════════════════════════════
  void _showChangePasswordDialog() {
    final colorScheme = Theme.of(context).colorScheme;
    final currentCtrl = TextEditingController();
    final newCtrl     = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool isLoading = false;
    String? errorMsg;

    showDialog(context: context, builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDlgState) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Changer le mot de passe', style: TextStyle(color: colorScheme.onSurface)),
        backgroundColor: colorScheme.surface,
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          if (errorMsg != null) ...[
            Container(padding: EdgeInsets.all(10),
              decoration: BoxDecoration(color: colorScheme.error.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Text(errorMsg!, style: TextStyle(color: colorScheme.error, fontSize: 13))),
            SizedBox(height: 12),
          ],
          _obscuredField(currentCtrl, 'Mot de passe actuel', colorScheme),
          SizedBox(height: 12),
          _obscuredField(newCtrl, 'Nouveau mot de passe', colorScheme),
          SizedBox(height: 12),
          _obscuredField(confirmCtrl, 'Confirmer le mot de passe', colorScheme),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx),
            child: Text('Annuler', style: TextStyle(color: colorScheme.onSurface))),
          ElevatedButton(
            onPressed: isLoading ? null : () async {
              if (newCtrl.text != confirmCtrl.text) {
                setDlgState(() => errorMsg = 'Les mots de passe ne correspondent pas'); return;
              }
              setDlgState(() => isLoading = true);
              try {
                await ApiService().changePassword(_user!.id, currentCtrl.text, newCtrl.text);
                if (mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Mot de passe mis à jour !'),
                    backgroundColor: Color(0xFF10b981), behavior: SnackBarBehavior.floating));
                }
              } catch (e) {
                setDlgState(() { isLoading = false; errorMsg = e.toString().replaceFirst('Exception: ', ''); });
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: colorScheme.primary, foregroundColor: Colors.white),
            child: isLoading
                ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text('Mettre à jour'),
          ),
        ],
      ),
    ));
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