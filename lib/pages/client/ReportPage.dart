import 'dart:math';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';

class ReportsPage extends StatefulWidget {
  @override
  _ReportsPageState createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  String _period = '30d';
  Map<String, dynamic> _data = {};
  bool    _loading = true;
  String? _error;

  static const _blue   = Color(0xFF2563eb);
  static const _green  = Color(0xFF059669);
  static const _red    = Color(0xFFdc2626);
  static const _amber  = Color(0xFFd97706);
  static const _violet = Color(0xFF7c3aed);
  static const _cyan   = Color(0xFF0891b2);

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await ApiService().getAnalytics(
        userId: ApiService.userId, period: _period);
      setState(() { _data = data; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString().replaceFirst('Exception: ', ''); _loading = false; });
    }
  }

  // ── Accesseurs de données ─────────────────────────────────────────────
  Map<String, dynamic> get _overview   => (_data['overview'] ?? {}) as Map<String, dynamic>;
  Map<String, dynamic> get _trends     => (_overview['trends'] ?? {}) as Map<String, dynamic>;
  List<dynamic>        get _daily      => (_data['dailyChart'] ?? []) as List;
  List<dynamic>        get _weekly     => (_data['weeklyRates'] ?? []) as List;
  List<dynamic>        get _models     => (_data['topModels'] ?? []) as List;
  List<dynamic>        get _errors     => (_data['topErrors'] ?? []) as List;
  List<dynamic>        get _hourly     => (_data['hourlyActivity'] ?? []) as List;
  Map<String, dynamic> get _peak       => (_data['peakHour'] ?? {}) as Map<String, dynamic>;
  List<dynamic>        get _dayOfWeek  => (_data['dayOfWeek'] ?? []) as List;

  @override
  Widget build(BuildContext context) {
    final desk = MediaQuery.of(context).size.width >= 1024;
    final dk   = Theme.of(context).brightness == Brightness.dark;
    final card = dk ? Color(0xFF151921) : Colors.white;
    final bord = dk ? Color(0xFF1e2028) : Color(0xFFf0f0f5);
    final txt  = dk ? Colors.white : Color(0xFF111827);
    final sub  = dk ? Color(0xFF6b7280) : Color(0xFF9ca3af);

    return Column(children: [
      _headerBar(dk, card, bord, txt, sub, desk),
      Expanded(child: RefreshIndicator(
        onRefresh: _load, color: _blue,
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(desk ? 32 : 20),
          child: _loading ? _loadingState()
              : _error != null ? _errorState(txt, sub, card, bord)
              : _buildContent(desk, dk, card, bord, txt, sub),
        ),
      )),
    ]);
  }

  // ── Barre d'en-tête avec sélecteur de période ─────────────────────────
  Widget _headerBar(bool dk, Color card, Color bord, Color txt, Color sub, bool desk) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: desk ? 32 : 20, vertical: 14),
      decoration: BoxDecoration(color: card, border: Border(bottom: BorderSide(color: bord))),
      child: Row(children: [
        ...['7d', '30d', '90d'].map((p) {
          final sel = _period == p;
          final label = p == '7d' ? '7 Jours' : p == '30d' ? '30 Jours' : '90 Jours';
          return Padding(padding: EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () { setState(() => _period = p); _load(); },
              child: AnimatedContainer(
                duration: Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: sel ? _blue : _blue.withOpacity(dk ? 0.08 : 0.05),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(label, style: TextStyle(fontSize: 12, fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                    color: sel ? Colors.white : _blue)),
              ),
            ),
          );
        }),
        Spacer(),
        Container(width: 36, height: 36,
            decoration: BoxDecoration(color: dk ? Color(0xFF1a1d24) : Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(10)),
            child: Material(color: Colors.transparent, borderRadius: BorderRadius.circular(10),
                child: InkWell(onTap: _load, borderRadius: BorderRadius.circular(10),
                    child: Icon(Icons.refresh, size: 18, color: sub)))),
      ]),
    );
  }

  // ── Contenu principal ─────────────────────────────────────────────────
  Widget _buildContent(bool desk, bool dk, Color card, Color bord, Color txt, Color sub) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // ── KPI avec tendances ────────────────────────────────────────────
      _kpiSection(desk, dk, card, bord, txt, sub),
      SizedBox(height: 24),

     

      // ── Rangée de graphiques ──────────────────────────────────────────
      desk
          ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(flex: 3, child: _dailyChart(dk, card, bord, txt, sub)),
              SizedBox(width: 20),
              Expanded(flex: 2, child: _weeklyRatesCard(dk, card, bord, txt, sub)),
            ])
          : Column(children: [
              _dailyChart(dk, card, bord, txt, sub),
              SizedBox(height: 20),
              _weeklyRatesCard(dk, card, bord, txt, sub),
            ]),
      SizedBox(height: 24),

      // ── Rangée modèles + erreurs ──────────────────────────────────────
      desk
          ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: _modelsCard(dk, card, bord, txt, sub)),
              SizedBox(width: 20),
              Expanded(child: _errorsCard(dk, card, bord, txt, sub)),
            ])
          : Column(children: [
              _modelsCard(dk, card, bord, txt, sub),
              SizedBox(height: 20),
              _errorsCard(dk, card, bord, txt, sub),
            ]),
      SizedBox(height: 24),

      // ── Carte de chaleur horaire ──────────────────────────────────────
      _hourlyHeatmap(dk, card, bord, txt, sub),
    ]);
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  CARTES KPI AVEC BADGES DE TENDANCE
  // ═══════════════════════════════════════════════════════════════════════
  Widget _kpiSection(bool desk, bool dk, Color card, Color bord, Color txt, Color sub) {
    final total   = _overview['totalImports']  ?? 0;
    final success = _overview['successCount']  ?? 0;
    final failed  = _overview['failedCount']   ?? 0;
    final rate    = _overview['successRate']    ?? 0;
    final rows    = _overview['totalRows']      ?? 0;

    final tTotal   = (_trends['totalTrend']   ?? 0).toDouble();
    final tSuccess = (_trends['successTrend'] ?? 0).toDouble();
    final tFailed  = (_trends['failedTrend']  ?? 0).toDouble();
    final tRate    = (_trends['rateTrend']    ?? 0).toDouble();

    final kpis = [
      _KpiItem('Total Importations', '$total', Icons.layers_outlined, _blue, tTotal, true),
      _KpiItem('Réussies', '$success', Icons.check_circle_outlined, _green, tSuccess, true),
      _KpiItem('Échouées', '$failed', Icons.highlight_off_outlined, _red, tFailed, false),
      _KpiItem('Taux de Réussite', '$rate%', Icons.speed_outlined, _amber, tRate, true),
    ];

    if (desk) {
      return Row(children: kpis.asMap().entries.map((e) => Expanded(
        child: Padding(padding: EdgeInsets.only(right: e.key < 3 ? 16 : 0),
            child: _kpiCard(e.value, dk, card, bord, txt, sub)),
      )).toList());
    }
    return Column(children: [
      Row(children: [
        Expanded(child: _kpiCard(kpis[0], dk, card, bord, txt, sub)),
        SizedBox(width: 12),
        Expanded(child: _kpiCard(kpis[1], dk, card, bord, txt, sub)),
      ]),
      SizedBox(height: 12),
      Row(children: [
        Expanded(child: _kpiCard(kpis[2], dk, card, bord, txt, sub)),
        SizedBox(width: 12),
        Expanded(child: _kpiCard(kpis[3], dk, card, bord, txt, sub)),
      ]),
    ]);
  }

  Widget _kpiCard(_KpiItem k, bool dk, Color card, Color bord, Color txt, Color sub) {
    final isPositive = k.positiveIsGood ? k.trend >= 0 : k.trend <= 0;
    final trendColor = isPositive ? _green : _red;
    final trendIcon  = k.trend >= 0 ? Icons.trending_up : Icons.trending_down;
    final trendLabel = '${k.trend >= 0 ? '+' : ''}${k.trend.toStringAsFixed(1)}%';

    return Container(
      padding: EdgeInsets.all(18),
      decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(14), border: Border.all(color: bord)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Container(padding: EdgeInsets.all(8),
              decoration: BoxDecoration(color: k.color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Icon(k.icon, color: k.color, size: 18)),
          // Badge de tendance
          Container(
            padding: EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(color: trendColor.withOpacity(dk ? 0.15 : 0.08), borderRadius: BorderRadius.circular(6)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(trendIcon, size: 12, color: trendColor),
              SizedBox(width: 3),
              Text(trendLabel, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: trendColor)),
            ]),
          ),
        ]),
        SizedBox(height: 16),
        Text(k.value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: txt, letterSpacing: -0.5)),
        SizedBox(height: 4),
        Text(k.label, style: TextStyle(fontSize: 12, color: sub)),
      ]),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  BARRE D'INSIGHTS
  // ═══════════════════════════════════════════════════════════════════════
  Widget _insightsBar(bool dk, Color card, Color bord, Color txt, Color sub) {
    final total   = _overview['totalImports'] ?? 0;
    final rate    = _overview['successRate']  ?? 0;
    final tRate   = (_trends['rateTrend'] ?? 0).toDouble();
    final peak    = _peak['label'] ?? '—';
    final rows    = _overview['totalRows'] ?? 0;

    // Génération d'insights intelligents
    final insights = <_Insight>[];

    if (tRate > 0) {
      insights.add(_Insight(Icons.trending_up, 'Votre taux de réussite a augmenté de ${tRate.abs()}% cette période', _green));
    } else if (tRate < 0) {
      insights.add(_Insight(Icons.trending_down, 'Le taux de réussite a baissé de ${tRate.abs()}% — vérifiez le format de vos données', _amber));
    }

    if (total > 0) {
      insights.add(_Insight(Icons.schedule, 'Pic d\'activité à $peak — c\'est votre heure la plus productive', _blue));
    }

    if (rows > 100) {
      insights.add(_Insight(Icons.table_rows, '$rows lignes converties cette période', _violet));
    }

    if (_errors.isNotEmpty) {
      final topErr = (_errors[0] as Map)['error'] ?? 'Inconnu';
      insights.add(_Insight(Icons.lightbulb_outlined, 'Erreur la plus fréquente : "$topErr" — vérifiez ces champs', _amber));
    }

    if (insights.isEmpty) {
      insights.add(_Insight(Icons.info_outline, 'Commencez à importer pour voir des insights personnalisés', sub));
    }

    return Container(
      padding: EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: dk ? _blue.withOpacity(0.04) : Color(0xFFF0F7FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: dk ? _blue.withOpacity(0.12) : Color(0xFFDBEAFE)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.auto_awesome, size: 16, color: _blue),
          SizedBox(width: 8),
          Text('Insights', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _blue)),
        ]),
        SizedBox(height: 12),
        ...insights.take(3).map((i) => Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(i.icon, size: 14, color: i.color),
            SizedBox(width: 8),
            Expanded(child: Text(i.text, style: TextStyle(fontSize: 12, color: txt, height: 1.3))),
          ]),
        )),
      ]),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  GRAPHIQUE JOURNALIER (barres avec ligne)
  // ═══════════════════════════════════════════════════════════════════════
  Widget _dailyChart(bool dk, Color card, Color bord, Color txt, Color sub) {
    final data   = _daily.cast<Map<String, dynamic>>();
    final maxVal = data.map((d) => (d['total'] ?? 0) as int).fold(0, max).clamp(1, 9999);
    final total  = data.fold(0, (s, d) => s + ((d['total'] ?? 0) as int));

    // Afficher chaque Nième étiquette pour éviter l'encombrement
    final showEvery = data.length > 14 ? 5 : data.length > 7 ? 2 : 1;

    return Container(
      padding: EdgeInsets.all(22),
      decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(14), border: Border.all(color: bord)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Activité d\'Importation', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: txt)),
            SizedBox(height: 2),
            Text('Importations journalières sur la période sélectionnée', style: TextStyle(fontSize: 12, color: sub)),
          ])),
          Container(padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: _blue.withOpacity(0.08), borderRadius: BorderRadius.circular(20)),
              child: Text('Total : $total', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _blue))),
        ]),
        SizedBox(height: 8),
        Row(children: [
          _dot(_blue, 'Réussies'), SizedBox(width: 14),
          _dot(_red, 'Échouées'),
        ]),
        SizedBox(height: 20),
        SizedBox(
          height: 180,
          child: Row(crossAxisAlignment: CrossAxisAlignment.end,
            children: data.asMap().entries.map((e) {
              final i   = e.key;
              final d   = e.value;
              final t   = (d['total']   ?? 0) as int;
              final s   = (d['success'] ?? 0) as int;
              final f   = (d['failed']  ?? 0) as int;
              final h   = t == 0 ? 3.0 : (t / maxVal) * 120.0;
              final isLast = i == data.length - 1;
              final showLabel = i % showEvery == 0 || isLast;
              final dateStr = (d['date'] ?? '').toString();
              final label   = dateStr.length >= 10 ? '${dateStr.substring(8, 10)}/${dateStr.substring(5, 7)}' : '';

              return Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.end, mainAxisSize: MainAxisSize.min, children: [
                if (t > 0 && (showLabel || isLast))
                  SizedBox(height: 14, child: Text('$t', textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: isLast ? _blue : sub)))
                else SizedBox(height: 14),
                SizedBox(height: 4),
                ClipRRect(borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
                  child: SizedBox(height: h,
                    child: Column(children: [
                      if (f > 0) Flexible(flex: f, child: Container(color: _red)),
                      Flexible(flex: s == 0 ? 1 : s,
                          child: Container(color: isLast ? _blue : _blue.withOpacity(0.4))),
                    ]),
                  ),
                ),
                SizedBox(height: 6),
                SizedBox(height: 14, child: showLabel
                    ? Text(label, textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 8, color: isLast ? _blue : sub))
                    : SizedBox()),
              ]));
            }).toList(),
          ),
        ),
      ]),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  TAUX DE RÉUSSITE HEBDOMADAIRES
  // ═══════════════════════════════════════════════════════════════════════
  Widget _weeklyRatesCard(bool dk, Color card, Color bord, Color txt, Color sub) {
    final weeks = _weekly.cast<Map<String, dynamic>>();
    return Container(
      padding: EdgeInsets.all(22),
      decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(14), border: Border.all(color: bord)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Taux de Réussite Hebdomadaire', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: txt)),
        SizedBox(height: 2),
        Text('Évolution du taux par semaine', style: TextStyle(fontSize: 12, color: sub)),
        SizedBox(height: 20),
        if (weeks.isEmpty)
          Center(child: Padding(padding: EdgeInsets.all(20),
              child: Text('Aucune donnée', style: TextStyle(fontSize: 12, color: sub))))
        else
          ...weeks.asMap().entries.map((e) {
            final w    = e.value;
            final rate = (w['rate'] ?? 0).toDouble();
            final wk   = w['week'] ?? '';
            final ws   = w['weekStart'] ?? '';
            final color = rate >= 80 ? _green : rate >= 50 ? _amber : _red;

            return Padding(padding: EdgeInsets.only(bottom: 14), child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Row(children: [
                    Text(wk, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: txt)),
                    SizedBox(width: 6),
                    Text(ws, style: TextStyle(fontSize: 10, color: sub)),
                  ]),
                  Text('$rate%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
                ]),
                SizedBox(height: 6),
                ClipRRect(borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(value: rate / 100,
                        backgroundColor: color.withOpacity(0.08),
                        valueColor: AlwaysStoppedAnimation(color), minHeight: 5)),
              ],
            ));
          }),
      ]),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  TOP MODÈLES
  // ═══════════════════════════════════════════════════════════════════════
  Widget _modelsCard(bool dk, Color card, Color bord, Color txt, Color sub) {
    final models = _models.cast<Map<String, dynamic>>();
    final colors = [_blue, _green, _violet, _amber, _cyan];
    final mx = models.isNotEmpty ? (models[0]['count'] as int? ?? 1).toDouble() : 1.0;

    return Container(
      padding: EdgeInsets.all(22),
      decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(14), border: Border.all(color: bord)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Top Modèles', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: txt)),
        SizedBox(height: 2),
        Text('Modèles d\'importation les plus utilisés', style: TextStyle(fontSize: 12, color: sub)),
        SizedBox(height: 20),
        if (models.isEmpty)
          Center(child: Padding(padding: EdgeInsets.all(16), child: Text('Aucune donnée', style: TextStyle(fontSize: 12, color: sub))))
        else
          ...models.asMap().entries.map((e) {
            final i = e.key; final m = e.value;
            final c = colors[i % colors.length];
            final code = (m['model'] ?? '—').toString();
            final cnt  = m['count'] as int? ?? 0;
            final rate = (m['successRate'] ?? 0).toDouble();
            final pct  = mx > 0 ? cnt / mx : 0.0;

            return Padding(padding: EdgeInsets.only(bottom: 14), child: Row(children: [
              Container(width: 36, height: 36,
                  decoration: BoxDecoration(color: c.withOpacity(dk ? 0.15 : 0.08), borderRadius: BorderRadius.circular(8)),
                  child: Center(child: Text('${i + 1}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: c)))),
              SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text(code, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: txt)),
                  Text('$cnt imports · $rate%', style: TextStyle(fontSize: 10, color: sub)),
                ]),
                SizedBox(height: 6),
                ClipRRect(borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(value: pct, backgroundColor: c.withOpacity(0.08),
                        valueColor: AlwaysStoppedAnimation(c), minHeight: 5)),
              ])),
            ]));
          }),
      ]),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  ERREURS FRÉQUENTES — Graphique à barres horizontales
  // ═══════════════════════════════════════════════════════════════════════
  Widget _errorsCard(bool dk, Color card, Color bord, Color txt, Color sub) {
    final errors = _errors.cast<Map<String, dynamic>>();
    final mx = errors.isNotEmpty ? (errors[0]['count'] as int? ?? 1).toDouble() : 1.0;

    return Container(
      padding: EdgeInsets.all(22),
      decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(14), border: Border.all(color: bord)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('Erreurs Fréquentes', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: txt)),
          Spacer(),
          if (errors.isNotEmpty) Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: _red.withOpacity(0.08), borderRadius: BorderRadius.circular(6)),
            child: Text('${errors.length} types', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _red)),
          ),
        ]),
        SizedBox(height: 2),
        Text('Erreurs de validation les plus fréquentes', style: TextStyle(fontSize: 12, color: sub)),
        SizedBox(height: 20),
        if (errors.isEmpty)
          Container(
            padding: EdgeInsets.all(24),
            child: Center(child: Column(children: [
              Icon(Icons.check_circle_outline, size: 32, color: _green.withOpacity(0.4)),
              SizedBox(height: 8),
              Text('Aucune erreur — excellent travail !', style: TextStyle(fontSize: 12, color: _green)),
            ])),
          )
        else
          ...errors.asMap().entries.map((e) {
            final err = e.value;
            final name  = (err['error'] ?? '').toString();
            final count = err['count'] as int? ?? 0;
            final pct   = mx > 0 ? count / mx : 0.0;

            return Padding(padding: EdgeInsets.only(bottom: 14), child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Flexible(child: Text(name, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: txt),
                      maxLines: 1, overflow: TextOverflow.ellipsis)),
                  Text('$count', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _red)),
                ]),
                SizedBox(height: 6),
                ClipRRect(borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(value: pct,
                        backgroundColor: _red.withOpacity(0.06),
                        valueColor: AlwaysStoppedAnimation(_red.withOpacity(0.6)), minHeight: 5)),
              ],
            ));
          }),
      ]),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  CARTE DE CHALEUR HORAIRE
  // ═══════════════════════════════════════════════════════════════════════
  Widget _hourlyHeatmap(bool dk, Color card, Color bord, Color txt, Color sub) {
    final hours = _hourly.cast<Map<String, dynamic>>();
    final maxH  = hours.map((h) => (h['count'] ?? 0) as int).fold(0, max).clamp(1, 9999);
    final peakLabel = _peak['label'] ?? '—';

    return Container(
      padding: EdgeInsets.all(22),
      decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(14), border: Border.all(color: bord)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Activité par Heure', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: txt)),
            SizedBox(height: 2),
            Text('Vos heures d\'importation les plus actives', style: TextStyle(fontSize: 12, color: sub)),
          ])),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: _violet.withOpacity(0.08), borderRadius: BorderRadius.circular(20)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.access_time, size: 12, color: _violet),
              SizedBox(width: 4),
              Text('Pic : $peakLabel', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _violet)),
            ]),
          ),
        ]),
        SizedBox(height: 20),
        SizedBox(
          height: 60,
          child: Row(children: hours.map((h) {
            final count = (h['count'] ?? 0) as int;
            final hour  = (h['hour']  ?? 0) as int;
            final intensity = maxH > 0 ? count / maxH : 0.0;
            final isPeak = hour == (_peak['hour'] ?? -1);

            return Expanded(child: Tooltip(
              message: '${h['label']} : $count importations',
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 1),
                decoration: BoxDecoration(
                  color: count == 0
                      ? (dk ? Color(0xFF1a1d24) : Color(0xFFF3F4F6))
                      : _blue.withOpacity(0.15 + intensity * 0.75),
                  borderRadius: BorderRadius.circular(4),
                  border: isPeak ? Border.all(color: _violet, width: 1.5) : null,
                ),
                child: Center(child: hour % 4 == 0
                    ? Text('${hour}h', style: TextStyle(fontSize: 8, color: count > 0 ? Colors.white : sub))
                    : SizedBox()),
              ),
            ));
          }).toList()),
        ),
        SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('00:00', style: TextStyle(fontSize: 9, color: sub)),
          Text('12:00', style: TextStyle(fontSize: 9, color: sub)),
          Text('23:00', style: TextStyle(fontSize: 9, color: sub)),
        ]),
      ]),
    );
  }

  // ── Helpers partagés ──────────────────────────────────────────────────
  Widget _dot(Color c, String l) => Row(children: [
    Container(width: 8, height: 8, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
    SizedBox(width: 4), Text(l, style: TextStyle(fontSize: 11, color: Color(0xFF64748b)))]);

  Widget _loadingState() => Center(child: Padding(padding: EdgeInsets.all(64),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        CircularProgressIndicator(strokeWidth: 2.5, color: _blue), SizedBox(height: 16),
        Text('Chargement des analyses...', style: TextStyle(fontSize: 13, color: Color(0xFF9ca3af)))])));

  Widget _errorState(Color txt, Color sub, Color card, Color bord) => Container(
    padding: EdgeInsets.all(48),
    decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(14), border: Border.all(color: bord)),
    child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.cloud_off_outlined, size: 44, color: _red.withOpacity(0.4)), SizedBox(height: 14),
      Text('Impossible de charger les analyses', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: txt)),
      SizedBox(height: 6), Text(_error ?? '', style: TextStyle(fontSize: 12, color: sub), textAlign: TextAlign.center),
      SizedBox(height: 18), TextButton.icon(onPressed: _load, icon: Icon(Icons.refresh, size: 16),
          label: Text('Réessayer'), style: TextButton.styleFrom(foregroundColor: _blue))])));
}

class _KpiItem {
  final String label, value;
  final IconData icon;
  final Color color;
  final double trend;
  final bool positiveIsGood;
  const _KpiItem(this.label, this.value, this.icon, this.color, this.trend, this.positiveIsGood);
}

class _Insight {
  final IconData icon;
  final String text;
  final Color color;
  const _Insight(this.icon, this.text, this.color);
}