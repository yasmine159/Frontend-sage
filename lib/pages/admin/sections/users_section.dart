import 'package:flutter/material.dart';
import '../widgets/admin_shared_widgets.dart';

class UsersSection extends StatelessWidget {
  final bool desk, dk;
  final Color card, bord, txt, sub;
  final List<Map<String, dynamic>> users;
  final bool loading;
  final String? error;
  final String search;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onAddUser;
  final Function(Map<String, dynamic>) onEditUser;
  final Function(Map<String, dynamic>) onDeleteUser;
  final Function(Map<String, dynamic>, bool) onToggleUser;
  final VoidCallback onReload;

  const UsersSection({
    super.key,
    required this.desk,
    required this.dk,
    required this.card,
    required this.bord,
    required this.txt,
    required this.sub,
    required this.users,
    required this.loading,
    required this.error,
    required this.search,
    required this.onSearchChanged,
    required this.onAddUser,
    required this.onEditUser,
    required this.onDeleteUser,
    required this.onToggleUser,
    required this.onReload,
  });

  @override
  Widget build(BuildContext context) {
    final filtered = users.where((u) {
      final q = search.toLowerCase();
      return q.isEmpty
          || UserHelpers.name(u).toLowerCase().contains(q)
          || UserHelpers.email(u).toLowerCase().contains(q)
          || UserHelpers.role(u).toLowerCase().contains(q);
    }).toList();

    return SingleChildScrollView(
      padding: EdgeInsets.all(desk ? 32 : 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── En-tête ──
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Utilisateurs', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: txt)),
            Text('${users.length} utilisateurs inscrits', style: TextStyle(fontSize: 12, color: sub)),
          ])),
          ElevatedButton.icon(
            onPressed: onAddUser,
            icon: const Icon(Icons.person_add_outlined, size: 14),
            label: const Text('Ajouter', style: TextStyle(fontSize: 12)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AdminColors.violet,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
          ),
        ]),
        const SizedBox(height: 20),

        // ── Mini-stats ──
        Row(children: [
          AdminSharedWidgets.miniStat('Total',      '${users.length}',                                                                    Icons.people_outline,          AdminColors.blue,   dk, card, bord, txt, sub),
          const SizedBox(width: 12),
          AdminSharedWidgets.miniStat('Actifs',     '${users.where((u) => UserHelpers.status(u) == 'Actif').length}',     Icons.check_circle_outline,    AdminColors.green,  dk, card, bord, txt, sub),
          const SizedBox(width: 12),
          AdminSharedWidgets.miniStat('Suspendus',  '${users.where((u) => UserHelpers.status(u) == 'Suspendu').length}',  Icons.block_outlined,          AdminColors.red,    dk, card, bord, txt, sub),
          const SizedBox(width: 12),
          AdminSharedWidgets.miniStat('Admins',     '${users.where((u) => UserHelpers.role(u).toLowerCase() == 'admin').length}', Icons.shield_outlined, AdminColors.violet, dk, card, bord, txt, sub),
        ]),
        const SizedBox(height: 20),

        AdminSharedWidgets.searchField('Rechercher par nom, e-mail ou rôle...', onSearchChanged, dk, card, bord, txt, sub),
        const SizedBox(height: 16),

        _buildTable(filtered),
      ]),
    );
  }

  Widget _buildTable(List<Map<String, dynamic>> filtered) {
    return Container(
      decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(14), border: Border.all(color: bord)),
      child: Column(children: [
        if (loading)
          Padding(padding: const EdgeInsets.all(32), child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: AdminColors.violet)))
        else if (error != null)
          AdminSharedWidgets.errWidget(error!, onReload, card, bord, txt, sub)
        else if (filtered.isEmpty)
          Padding(padding: const EdgeInsets.all(32), child: Center(child: Text('Aucun utilisateur trouvé', style: TextStyle(color: sub))))
        else ...filtered.map((u) => _buildUserRow(u)),
      ]),
    );
  }

  Widget _buildUserRow(Map<String, dynamic> u) {
    final name   = UserHelpers.name(u);
    final email  = UserHelpers.email(u);
    final role   = UserHelpers.role(u);
    final status = UserHelpers.status(u);
    final sc     = UserHelpers.statusColor(status);
    final rc     = UserHelpers.roleColor(role);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: bord))),
      child: Row(children: [
        // Avatar
        Container(
          width: 34, height: 34,
          decoration: BoxDecoration(color: rc.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
          child: Center(child: Text(
            name.length >= 2 ? name.substring(0, 2).toUpperCase() : name.toUpperCase(),
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: rc),
          )),
        ),
        const SizedBox(width: 12),

        // Nom + email
        Expanded(flex: 3, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name,  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: txt)),
          Text(email, style: TextStyle(fontSize: 11, color: sub)),
        ])),

        // Rôle
        Expanded(flex: 1, child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(color: rc.withOpacity(0.08), borderRadius: BorderRadius.circular(5)),
          child: Text(role, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: rc), textAlign: TextAlign.center),
        )),
        const SizedBox(width: 12),

        // Statut
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(color: sc.withOpacity(0.08), borderRadius: BorderRadius.circular(5)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 5, height: 5, decoration: BoxDecoration(color: sc, shape: BoxShape.circle)),
            const SizedBox(width: 4),
            Text(status, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: sc)),
          ]),
        ),

        // Menu d'actions
        PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, size: 16, color: sub),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          onSelected: (v) => _handleAction(v, u),
          itemBuilder: (_) => [
            PopupMenuItem(value: 'edit', child: Row(children: [
              Icon(Icons.edit_outlined, size: 14, color: AdminColors.blue),
              const SizedBox(width: 8), const Text('Modifier', style: TextStyle(fontSize: 13)),
            ])),
            if (status == 'Actif')
              PopupMenuItem(value: 'suspend', child: Row(children: [
                Icon(Icons.block_outlined, size: 14, color: AdminColors.amber),
                const SizedBox(width: 8), const Text('Suspendre', style: TextStyle(fontSize: 13)),
              ]))
            else
              PopupMenuItem(value: 'activate', child: Row(children: [
                Icon(Icons.check_circle_outline, size: 14, color: AdminColors.green),
                const SizedBox(width: 8), const Text('Activer', style: TextStyle(fontSize: 13)),
              ])),
            PopupMenuItem(value: 'delete', child: Row(children: [
              Icon(Icons.delete_outline, size: 14, color: AdminColors.red),
              const SizedBox(width: 8), const Text('Supprimer', style: TextStyle(fontSize: 13, color: AdminColors.red)),
            ])),
          ],
        ),
      ]),
    );
  }

  void _handleAction(String action, Map<String, dynamic> user) {
    switch (action) {
      case 'edit':     onEditUser(user); break;
      case 'delete':   onDeleteUser(user); break;
      case 'suspend':  onToggleUser(user, true); break;
      case 'activate': onToggleUser(user, false); break;
    }
  }
}