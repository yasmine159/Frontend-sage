import 'package:flutter/material.dart';

/// Couleurs globales de l'admin (partagées entre toutes les sections)
class AdminColors {
  static const blue   = Color(0xFF2563eb);
  static const green  = Color(0xFF059669);
  static const red    = Color(0xFFdc2626);
  static const amber  = Color(0xFFd97706);
  static const violet = Color(0xFF7c3aed);
  static const cyan   = Color(0xFF0891b2);
}

/// KPI data model
class KpiData {
  final String label, value;
  final IconData icon;
  final Color color;
  final double trend;
  final bool posGood;
  const KpiData(this.label, this.value, this.icon, this.color, this.trend, this.posGood);
}

/// Widgets statiques réutilisables dans toutes les sections admin
class AdminSharedWidgets {
  // ── Badge (compteur coloré) ────────────────────────────────────────────
  static Widget badge(String v, Color c) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: BoxDecoration(color: c.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
    child: Text(v, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: c)),
  );

  // ── Champ de recherche ────────────────────────────────────────────────
  static Widget searchField(String hint, ValueChanged<String> onChanged, bool dk, Color card, Color bord, Color txt, Color sub) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: dk ? const Color(0xFF1a1d24) : card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: bord),
      ),
      child: TextField(
        onChanged: onChanged,
        style: TextStyle(fontSize: 14, color: txt),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(fontSize: 13, color: sub),
          prefixIcon: Icon(Icons.search, size: 18, color: sub),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  // ── Widget d'erreur avec bouton Réessayer ─────────────────────────────
  static Widget errWidget(String msg, VoidCallback retry, Color card, Color bord, Color txt, Color sub) {
    return Padding(padding: const EdgeInsets.all(24), child: Center(child: Column(children: [
      Icon(Icons.cloud_off_outlined, size: 36, color: AdminColors.red.withOpacity(0.4)),
      const SizedBox(height: 8),
      Text(msg, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: sub)),
      const SizedBox(height: 10),
      TextButton.icon(
        onPressed: retry,
        icon: const Icon(Icons.refresh, size: 14),
        label: const Text('Réessayer'),
        style: TextButton.styleFrom(foregroundColor: AdminColors.violet),
      ),
    ])));
  }

  // ── Champ de dialogue ─────────────────────────────────────────────────
  static Widget dlgField(TextEditingController c, String label, IconData icon, {bool obscure = false}) {
    return TextField(
      controller: c,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: const Color(0xFFF7F8FA),
      ),
    );
  }

  // ── Tuile KPI ─────────────────────────────────────────────────────────
  static Widget kpiTile(KpiData k, bool dk, Color card, Color bord, Color txt, Color sub) {
    final pos = k.posGood ? k.trend >= 0 : k.trend <= 0;
    final tc  = pos ? AdminColors.green : AdminColors.red;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(14), border: Border.all(color: bord)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: k.color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(k.icon, color: k.color, size: 18),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(color: tc.withOpacity(dk ? 0.15 : 0.08), borderRadius: BorderRadius.circular(6)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(k.trend >= 0 ? Icons.trending_up : Icons.trending_down, size: 12, color: tc),
              const SizedBox(width: 3),
              Text('${k.trend >= 0 ? '+' : ''}${k.trend.toStringAsFixed(1)}%',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: tc)),
            ]),
          ),
        ]),
        const SizedBox(height: 16),
        Text(k.value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: txt, letterSpacing: -0.5)),
        const SizedBox(height: 4),
        Text(k.label, style: TextStyle(fontSize: 12, color: sub)),
      ]),
    );
  }

  // ── Mini-stat (section utilisateurs) ─────────────────────────────────
  static Widget miniStat(String label, String value, IconData icon, Color color, bool dk, Color card, Color bord, Color txt, Color sub) {
    return Expanded(child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(12), border: Border.all(color: bord)),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: color, size: 15),
        ),
        const SizedBox(width: 10),
        Flexible(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: txt)),
          Text(label, style: TextStyle(fontSize: 10, color: sub), overflow: TextOverflow.ellipsis),
        ])),
      ]),
    ));
  }

  // ── Champ mot de passe ────────────────────────────────────────────────
  static Widget pwdField(TextEditingController c, String label, bool dk, Color bord, Color txt, Color sub) {
    return TextField(
      controller: c,
      obscureText: true,
      style: TextStyle(color: txt, fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: sub, fontSize: 12),
        border:        OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: bord)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: bord)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AdminColors.violet, width: 1.5)),
        filled: true,
        fillColor: dk ? const Color(0xFF1a1d24) : const Color(0xFFF7F8FA),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }
}

/// Helpers d'affichage pour les utilisateurs
class UserHelpers {
  static String status(Map u) {
    final r = u['isActive'];
    if (r == null) return 'Actif';
    if (r is bool) return r ? 'Actif' : 'Suspendu';
    if (r is int)  return r == 1 ? 'Actif' : 'Suspendu';
    return r.toString().toLowerCase() == 'true' ? 'Actif' : 'Suspendu';
  }

  static String name(Map u)  => u['username'] ?? u['userName'] ?? '—';
  static String email(Map u) => u['email'] ?? '—';
  static String role(Map u)  => u['role'] ?? 'Utilisateur';

  static Color statusColor(String s) => s == 'Actif' ? AdminColors.green : AdminColors.red;
  static Color roleColor(String r)   => r.toLowerCase() == 'admin' ? AdminColors.violet : AdminColors.blue;
}

/// Helpers d'affichage pour l'activité
class ActivityHelpers {
  static String fileName(Map a) => a['fileName'] ?? a['file'] ?? '—';

  static String status(Map a) {
    final r = (a['status'] ?? '').toString().toLowerCase();
    return r == 'converted' ? 'Succès'
        : r == 'error'     ? 'Échoué'
        : r == 'pending'   ? 'En attente'
        : r.isEmpty        ? '—'
        : r;
  }

  static Color statusColor(Map a) => switch (status(a)) {
    'Succès'     => AdminColors.green,
    'Échoué'     => AdminColors.red,
    'En attente' => AdminColors.amber,
    _            => const Color(0xFF9ca3af),
  };

  static String timeAgo(Map a) {
    final r = a['uploadDate'] ?? a['date'] ?? a['createdAt'];
    if (r == null) return '—';
    try {
      final d  = DateTime.parse(r.toString()).toLocal();
      final df = DateTime.now().difference(d);
      if (df.inDays > 7)    return '${d.day}/${d.month}/${d.year}';
      if (df.inDays > 0)    return 'Il y a ${df.inDays}j';
      if (df.inHours > 0)   return 'Il y a ${df.inHours}h';
      if (df.inMinutes > 0) return 'Il y a ${df.inMinutes}min';
      return 'À l\'instant';
    } catch (_) { return '—'; }
  }
}