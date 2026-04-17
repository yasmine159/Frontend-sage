import 'dart:math';
import 'package:flutter/material.dart';
import '../widgets/admin_shared_widgets.dart';

class DashboardSection extends StatelessWidget {
  final bool desk, dk;
  final Color card, bord, txt, sub;
  final Map<String, dynamic> analytics;
  final bool loading;
  final String? error;
  final String analyticsPeriod;
  final List<Map<String, dynamic>> users;
  final ValueChanged<String> onPeriodChanged;
  final VoidCallback onAddUser;
  final VoidCallback onReload;

  const DashboardSection({
    super.key,
    required this.desk,
    required this.dk,
    required this.card,
    required this.bord,
    required this.txt,
    required this.sub,
    required this.analytics,
    required this.loading,
    required this.error,
    required this.analyticsPeriod,
    required this.users,
    required this.onPeriodChanged,
    required this.onAddUser,
    required this.onReload,
  });

  @override
  Widget build(BuildContext context) {
    final overview = Map<String, dynamic>.from((analytics['overview'] ?? {}) as Map);
    final trends   = Map<String, dynamic>.from((overview['trends']   ?? {}) as Map);
    final daily    = ((analytics['dailyChart']     ?? []) as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    final models   = ((analytics['topModels']      ?? []) as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    final errors   = ((analytics['topErrors']      ?? []) as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    final hourly   = ((analytics['hourlyActivity'] ?? []) as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    final peak     = Map<String, dynamic>.from((analytics['peakHour']   ?? {}) as Map);
    final ranking  = ((analytics['userRanking']    ?? []) as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();

    return SingleChildScrollView(
      padding: EdgeInsets.all(desk ? 32 : 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── Sélecteur de période + bouton Ajouter ──
        Row(children: [
          ...['7d', '30d', '90d'].map((p) {
            final sel   = analyticsPeriod == p;
            final label = p == '7d' ? '7 jours' : p == '30d' ? '30 jours' : '90 jours';
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => onPeriodChanged(p),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: sel ? AdminColors.violet : AdminColors.violet.withOpacity(dk ? 0.08 : 0.05),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(label, style: TextStyle(fontSize: 12, fontWeight: sel ? FontWeight.w600 : FontWeight.w400, color: sel ? Colors.white : AdminColors.violet)),
                ),
              ),
            );
          }),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: onAddUser,
            icon: const Icon(Icons.person_add_outlined, size: 14),
            label: const Text('Ajouter un utilisateur', style: TextStyle(fontSize: 12)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AdminColors.violet,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
          ),
        ]),
        const SizedBox(height: 24),

        // ── Contenu principal ──
        if (loading)
          Center(child: Padding(padding: const EdgeInsets.all(48), child: CircularProgressIndicator(strokeWidth: 2.5, color: AdminColors.violet)))
        else if (error != null)
          AdminSharedWidgets.errWidget(error!, onReload, card, bord, txt, sub)
        else ...[
          _buildKpis(overview, trends),
          const SizedBox(height: 24),
          desk
              ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(flex: 3, child: _buildChartCard(daily)),
                  const SizedBox(width: 20),
                  Expanded(flex: 2, child: _buildUserRankingCard(ranking)),
                ])
              : Column(children: [
                  _buildChartCard(daily),
                  const SizedBox(height: 20),
                  _buildUserRankingCard(ranking),
                ]),
          const SizedBox(height: 24),
          desk
              ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(child: _buildTopModelsCard(models)),
                  const SizedBox(width: 20),
                  Expanded(child: _buildTopErrorsCard(errors)),
                ])
              : Column(children: [
                  _buildTopModelsCard(models),
                  const SizedBox(height: 20),
                  _buildTopErrorsCard(errors),
                ]),
          const SizedBox(height: 24),
          _buildHeatmapCard(hourly, peak),
        ],
      ]),
    );
  }

  // ── KPIs ───────────────────────────────────────────────────────────────
  Widget _buildKpis(Map<String, dynamic> ov, Map<String, dynamic> tr) {
    final kpis = [
      KpiData('Total imports',  '${ov['totalImports'] ?? 0}', Icons.layers_outlined,        AdminColors.blue,   (tr['totalTrend']   ?? 0).toDouble(), true),
      KpiData('Réussis',        '${ov['successCount'] ?? 0}', Icons.check_circle_outlined,  AdminColors.green,  (tr['successTrend'] ?? 0).toDouble(), true),
      KpiData('Échoués',        '${ov['failedCount']  ?? 0}', Icons.highlight_off_outlined, AdminColors.red,    (tr['failedTrend']  ?? 0).toDouble(), false),
      KpiData('Taux de succès', '${ov['successRate']  ?? 0}%',Icons.speed_outlined,         AdminColors.amber,  (tr['rateTrend']    ?? 0).toDouble(), true),
    ];

    if (desk) {
      return Row(children: kpis.asMap().entries.map((e) =>
          Expanded(child: Padding(
            padding: EdgeInsets.only(right: e.key < 3 ? 16 : 0),
            child: AdminSharedWidgets.kpiTile(e.value, dk, card, bord, txt, sub),
          ))).toList());
    }
    return Column(children: [
      Row(children: [
        Expanded(child: AdminSharedWidgets.kpiTile(kpis[0], dk, card, bord, txt, sub)),
        const SizedBox(width: 12),
        Expanded(child: AdminSharedWidgets.kpiTile(kpis[1], dk, card, bord, txt, sub)),
      ]),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: AdminSharedWidgets.kpiTile(kpis[2], dk, card, bord, txt, sub)),
        const SizedBox(width: 12),
        Expanded(child: AdminSharedWidgets.kpiTile(kpis[3], dk, card, bord, txt, sub)),
      ]),
    ]);
  }

  // ── Graphique d'activité quotidienne ───────────────────────────────────
  Widget _buildChartCard(List<Map<String, dynamic>> data) {
    final mx        = data.map((d) => (d['total'] ?? 0) as int).fold(0, max).clamp(1, 9999);
    final total     = data.fold(0, (s, d) => s + ((d['total'] ?? 0) as int));
    final showEvery = data.length > 14 ? 5 : data.length > 7 ? 2 : 1;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(14), border: Border.all(color: bord)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Activité d\'import', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: txt)),
            Text('Tous les utilisateurs — imports quotidiens', style: TextStyle(fontSize: 12, color: sub)),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: AdminColors.violet.withOpacity(0.08), borderRadius: BorderRadius.circular(20)),
            child: Text('Total : $total', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AdminColors.violet)),
          ),
        ]),
        const SizedBox(height: 20),
        SizedBox(height: 180, child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: data.asMap().entries.map((e) {
            final i = e.key; final d = e.value;
            final t = (d['total']   ?? 0) as int;
            final s = (d['success'] ?? 0) as int;
            final f = (d['failed']  ?? 0) as int;
            final h      = t == 0 ? 3.0 : (t / mx) * 120.0;
            final isLast = i == data.length - 1;
            final showLbl = i % showEvery == 0 || isLast;
            final ds  = (d['date'] ?? '').toString();
            final lbl = ds.length >= 10 ? '${ds.substring(8, 10)}/${ds.substring(5, 7)}' : '';

            return Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.end, mainAxisSize: MainAxisSize.min, children: [
              SizedBox(height: 14, child: t > 0 && showLbl
                  ? Text('$t', textAlign: TextAlign.center, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: isLast ? AdminColors.violet : sub))
                  : const SizedBox()),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                child: SizedBox(height: h, child: Column(children: [
                  if (f > 0) Flexible(flex: f, child: Container(color: AdminColors.red)),
                  Flexible(flex: s == 0 ? 1 : s, child: Container(color: isLast ? AdminColors.violet : AdminColors.violet.withOpacity(0.4))),
                ])),
              ),
              const SizedBox(height: 6),
              SizedBox(height: 14, child: showLbl
                  ? Text(lbl, textAlign: TextAlign.center, style: TextStyle(fontSize: 8, color: isLast ? AdminColors.violet : sub))
                  : const SizedBox()),
            ]));
          }).toList(),
        )),
      ]),
    );
  }

  // ── Classement des utilisateurs ────────────────────────────────────────
  Widget _buildUserRankingCard(List<Map<String, dynamic>> ranking) {
    return Container(
      decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(14), border: Border.all(color: bord)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: const EdgeInsets.fromLTRB(22, 18, 22, 14),
          child: Row(children: [
            const Icon(Icons.leaderboard_outlined, size: 16, color: AdminColors.violet),
            const SizedBox(width: 8),
            Text('Classement', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: txt)),
          ])),
        Divider(height: 1, color: bord),
        if (ranking.isEmpty)
          Padding(padding: const EdgeInsets.all(24), child: Center(child: Text('Aucune donnée', style: TextStyle(fontSize: 12, color: sub))))
        else ...ranking.asMap().entries.map((e) {
          final i    = e.key; final u = e.value;
          final name = u['username'] ?? 'Utilisateur #${u['userId']}';
          final cnt  = u['totalImports'] as int? ?? 0;
          final rate = (u['successRate'] ?? 0).toDouble();
          final rc   = rate >= 80 ? AdminColors.green : rate >= 50 ? AdminColors.amber : AdminColors.red;
          const medals = ['🥇', '🥈', '🥉'];

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
            decoration: BoxDecoration(border: i < ranking.length - 1 ? Border(bottom: BorderSide(color: bord)) : null),
            child: Row(children: [
              SizedBox(width: 24, child: Text(
                i < 3 ? medals[i] : '${i + 1}',
                style: TextStyle(fontSize: i < 3 ? 16 : 12, fontWeight: FontWeight.w600, color: sub),
              )),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: txt), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text('$cnt imports', style: TextStyle(fontSize: 11, color: sub)),
              ])),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: rc.withOpacity(0.08), borderRadius: BorderRadius.circular(6)),
                child: Text('$rate%', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: rc)),
              ),
            ]),
          );
        }),
      ]),
    );
  }

  // ── Top modèles ────────────────────────────────────────────────────────
  Widget _buildTopModelsCard(List<Map<String, dynamic>> models) {
    const cs = [AdminColors.blue, AdminColors.green, AdminColors.violet, AdminColors.amber, AdminColors.cyan];
    final mx = models.isNotEmpty ? (models[0]['count'] as int? ?? 1).toDouble() : 1.0;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(14), border: Border.all(color: bord)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Modèles les plus utilisés', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: txt)),
        const SizedBox(height: 16),
        if (models.isEmpty)
          Center(child: Padding(padding: const EdgeInsets.all(16), child: Text('Aucune donnée', style: TextStyle(fontSize: 12, color: sub))))
        else ...models.asMap().entries.map((e) {
          final i = e.key; final m = e.value; final c = cs[i % cs.length];
          return Padding(padding: const EdgeInsets.only(bottom: 12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text((m['model'] ?? '—').toString(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: txt)),
              Text('${m['count'] ?? 0} • ${m['successRate'] ?? 0}%', style: TextStyle(fontSize: 10, color: sub)),
            ]),
            const SizedBox(height: 6),
            ClipRRect(borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: mx > 0 ? (m['count'] as int? ?? 0) / mx : 0,
                  backgroundColor: c.withOpacity(0.08),
                  valueColor: AlwaysStoppedAnimation(c),
                  minHeight: 5,
                )),
          ]));
        }),
      ]),
    );
  }

  // ── Erreurs fréquentes ─────────────────────────────────────────────────
  Widget _buildTopErrorsCard(List<Map<String, dynamic>> errors) {
    final mx = errors.isNotEmpty ? (errors[0]['count'] as int? ?? 1).toDouble() : 1.0;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(14), border: Border.all(color: bord)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Erreurs fréquentes', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: txt)),
        const SizedBox(height: 16),
        if (errors.isEmpty)
          Center(child: Padding(padding: const EdgeInsets.all(16), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.check_circle_outline, size: 18, color: AdminColors.green),
            const SizedBox(width: 6),
            const Text('Aucune erreur !', style: TextStyle(fontSize: 12, color: AdminColors.green)),
          ])))
        else ...errors.map((e) {
          final n = (e['error'] ?? '').toString(); final c = e['count'] as int? ?? 0;
          return Padding(padding: const EdgeInsets.only(bottom: 12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Flexible(child: Text(n, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: txt), maxLines: 1, overflow: TextOverflow.ellipsis)),
              Text('$c', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AdminColors.red)),
            ]),
            const SizedBox(height: 6),
            ClipRRect(borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: mx > 0 ? c / mx : 0,
                  backgroundColor: AdminColors.red.withOpacity(0.06),
                  valueColor: AlwaysStoppedAnimation(AdminColors.red.withOpacity(0.6)),
                  minHeight: 5,
                )),
          ]));
        }),
      ]),
    );
  }

  // ── Carte d'activité par heure ─────────────────────────────────────────
  Widget _buildHeatmapCard(List<Map<String, dynamic>> hourly, Map<String, dynamic> peak) {
    final mx = hourly.map((h) => (h['count'] ?? 0) as int).fold(0, max).clamp(1, 9999);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(14), border: Border.all(color: bord)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text('Activité par heure', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: txt))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: AdminColors.violet.withOpacity(0.08), borderRadius: BorderRadius.circular(20)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.access_time, size: 12, color: AdminColors.violet),
              const SizedBox(width: 4),
              Text('Pic : ${peak['label'] ?? '—'}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AdminColors.violet)),
            ]),
          ),
        ]),
        const SizedBox(height: 20),
        SizedBox(height: 60, child: Row(children: hourly.map((h) {
          final c         = (h['count'] ?? 0) as int;
          final hr        = (h['hour']  ?? 0) as int;
          final intensity = mx > 0 ? c / mx : 0.0;
          final isPeak    = hr == (peak['hour'] ?? -1);
          return Expanded(child: Tooltip(
            message: '${h['label']}: $c imports',
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 1),
              decoration: BoxDecoration(
                color: c == 0
                    ? (dk ? const Color(0xFF1a1d24) : const Color(0xFFF3F4F6))
                    : AdminColors.violet.withOpacity(0.15 + intensity * 0.75),
                borderRadius: BorderRadius.circular(4),
                border: isPeak ? Border.all(color: AdminColors.amber, width: 1.5) : null,
              ),
              child: Center(child: hr % 4 == 0
                  ? Text('${hr}h', style: TextStyle(fontSize: 8, color: c > 0 ? Colors.white : sub))
                  : const SizedBox()),
            ),
          ));
        }).toList())),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('00:00', style: TextStyle(fontSize: 9, color: sub)),
          Text('12:00', style: TextStyle(fontSize: 9, color: sub)),
          Text('23:00', style: TextStyle(fontSize: 9, color: sub)),
        ]),
      ]),
    );
  }
} 