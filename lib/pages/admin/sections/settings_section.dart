import 'package:flutter/material.dart';
import 'package:frontend_sage3/services/api_service.dart';
import 'package:frontend_sage3/services/auth_service.dart';
import '../widgets/admin_shared_widgets.dart';

class SettingsSection extends StatelessWidget {
  final bool desk, dk;
  final Color card, bord, txt, sub;
  final String adminUsername;
  final String adminEmail;
  final VoidCallback onLogout;
  final Function(String, Color) onSnack;

  const SettingsSection({
    super.key,
    required this.desk,
    required this.dk,
    required this.card,
    required this.bord,
    required this.txt,
    required this.sub,
    required this.adminUsername,
    required this.adminEmail,
    required this.onLogout,
    required this.onSnack,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(desk ? 32 : 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Paramètres', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: txt)),
        const SizedBox(height: 24),

        // ── Profil ──
        _settingsCard('Profil', Icons.person_outline, AdminColors.violet,
          child: Column(children: [
            _settingsRow('Nom d\'utilisateur', adminUsername),
            Divider(height: 1, color: bord),
            _settingsRow('Adresse e-mail', adminEmail),
            Divider(height: 1, color: bord),
            _settingsRow('Rôle', 'Administrateur'),
          ]),
        ),
        const SizedBox(height: 16),

        // ── Sécurité ──
        _settingsCard('Sécurité', Icons.lock_outline, AdminColors.green,
          child: _ChangePasswordWidget(dk: dk, bord: bord, txt: txt, sub: sub, onSnack: onSnack),
        ),
        const SizedBox(height: 16),

        // ── Session ──
        _settingsCard('Session', Icons.logout_rounded, AdminColors.red,
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Se déconnecter', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: txt)),
              Text('Terminer votre session', style: TextStyle(fontSize: 12, color: sub)),
            ])),
            ElevatedButton(
              onPressed: onLogout,
              style: ElevatedButton.styleFrom(
                backgroundColor: AdminColors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              child: const Text('Déconnexion'),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _settingsCard(String title, IconData icon, Color color, {required Widget child}) {
    return Container(
      decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(14), border: Border.all(color: bord)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: const EdgeInsets.all(18), child: Row(children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: txt)),
        ])),
        Divider(height: 1, color: bord),
        Padding(padding: const EdgeInsets.all(18), child: child),
      ]),
    );
  }

  Widget _settingsRow(String label, String value) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Row(children: [
      SizedBox(width: 160, child: Text(label, style: TextStyle(fontSize: 13, color: sub))),
      Expanded(child: Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: txt), overflow: TextOverflow.ellipsis)),
    ]));
  }
}

/// Widget de changement de mot de passe (stateful interne)
class _ChangePasswordWidget extends StatefulWidget {
  final bool dk;
  final Color bord, txt, sub;
  final Function(String, Color) onSnack;

  const _ChangePasswordWidget({
    required this.dk,
    required this.bord,
    required this.txt,
    required this.sub,
    required this.onSnack,
  });

  @override
  State<_ChangePasswordWidget> createState() => _ChangePasswordWidgetState();
}

class _ChangePasswordWidgetState extends State<_ChangePasswordWidget> {
  final _oldC = TextEditingController();
  final _newC = TextEditingController();
  final _cnfC = TextEditingController();
  bool _loading = false;
  String? _err;
  String? _ok;

  @override
  void dispose() {
    _oldC.dispose(); _newC.dispose(); _cnfC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (_err != null)
        Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AdminColors.red.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
            child: Text(_err!, style: const TextStyle(color: AdminColors.red, fontSize: 12))),
      if (_ok != null)
        Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AdminColors.green.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
            child: Text(_ok!, style: const TextStyle(color: AdminColors.green, fontSize: 12))),

      AdminSharedWidgets.pwdField(_oldC, 'Mot de passe actuel',    widget.dk, widget.bord, widget.txt, widget.sub),
      const SizedBox(height: 10),
      AdminSharedWidgets.pwdField(_newC, 'Nouveau mot de passe',   widget.dk, widget.bord, widget.txt, widget.sub),
      const SizedBox(height: 10),
      AdminSharedWidgets.pwdField(_cnfC, 'Confirmer le mot de passe', widget.dk, widget.bord, widget.txt, widget.sub),
      const SizedBox(height: 14),

      ElevatedButton(
        onPressed: _loading ? null : _changePassword,
        style: ElevatedButton.styleFrom(
          backgroundColor: AdminColors.green,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 0,
          minimumSize: const Size(double.infinity, 44),
        ),
        child: _loading
            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Text('Changer le mot de passe'),
      ),
    ]);
  }

  Future<void> _changePassword() async {
    if (_newC.text != _cnfC.text) {
      setState(() => _err = 'Les mots de passe ne correspondent pas');
      return;
    }
    setState(() { _loading = true; _err = null; _ok = null; });
    try {
      await ApiService().changePassword(AuthService.instance.currentUser!.id, _oldC.text, _newC.text);
      setState(() { _loading = false; _ok = 'Mot de passe modifié avec succès !'; });
      _oldC.clear(); _newC.clear(); _cnfC.clear();
    } catch (e) {
      setState(() { _loading = false; _err = e.toString().replaceFirst('Exception: ', ''); });
    }
  }
}