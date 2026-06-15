import 'package:flutter/material.dart';
import '../widgets/admin_shared_widgets.dart';

class ActivitySection extends StatefulWidget {
  final bool desk, dk;
  final Color card, bord, txt, sub;
  final List<Map<String, dynamic>> activity;
  final bool loading;
  final String? error;
  final String search;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onReload;

  const ActivitySection({
    super.key,
    required this.desk,
    required this.dk,
    required this.card,
    required this.bord,
    required this.txt,
    required this.sub,
    required this.activity,
    required this.loading,
    required this.error,
    required this.search,
    required this.onSearchChanged,
    required this.onReload,
  });

  @override
  State<ActivitySection> createState() => _ActivitySectionState();
}

class _ActivitySectionState extends State<ActivitySection>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  int get _totalCount => widget.activity.length;
  int get _successCount => widget.activity
      .where((a) => ActivityHelpers.status(a) == 'Succès')
      .length;
  int get _failedCount => widget.activity
      .where((a) => ActivityHelpers.status(a) == 'Échoué')
      .length;
  int get _pendingCount => widget.activity
      .where((a) => ActivityHelpers.status(a) == 'En attente')
      .length;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _filtered(String? statusFilter) {
    return widget.activity.where((a) {
      if (statusFilter != null && ActivityHelpers.status(a) != statusFilter)
        return false;
      final q = widget.search.toLowerCase();
      return q.isEmpty ||
          ActivityHelpers.fileName(a).toLowerCase().contains(q) ||
          (a['modelCode'] ?? '').toString().toLowerCase().contains(q) ||
          _userName(a).toLowerCase().contains(q);
    }).toList();
  }

  String _userName(Map a) {
    final directName = a['username'] ?? a['userName'];
    if (directName != null && directName.toString().isNotEmpty)
      return directName.toString();

    final userObject = a['user'];
    if (userObject is Map) {
      final nestedName =
          userObject['username'] ??
          userObject['name'] ??
          userObject['fullName'];
      if (nestedName != null && nestedName.toString().isNotEmpty)
        return nestedName.toString();
    }

    final createdBy = a['createdBy'];
    if (createdBy is Map) {
      final createdByName =
          createdBy['username'] ?? createdBy['name'] ?? createdBy['fullName'];
      if (createdByName != null && createdByName.toString().isNotEmpty)
        return createdByName.toString();
    }

    if (a['userId'] != null) return 'Utilisateur #${a['userId']}';
    return '—';
  }

  String _userInitials(Map a) {
    final n = _userName(a);
    if (n.startsWith('Utilisateur #')) return '#';
    final parts = n.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return n.length >= 2 ? n.substring(0, 2).toUpperCase() : n.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(widget.desk ? 32 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── En-tête ──────────────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Historique des imports',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: widget.txt,
                      ),
                    ),
                    Text(
                      '${widget.activity.length} imports au total',
                      style: TextStyle(fontSize: 12, color: widget.sub),
                    ),
                  ],
                ),
              ),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: widget.dk
                      ? const Color(0xFF1a1d24)
                      : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    onTap: widget.onReload,
                    borderRadius: BorderRadius.circular(10),
                    child: Icon(Icons.refresh, size: 18, color: widget.sub),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Mini-stats ────────────────────────────────────────────────────
          Row(
            children: [
              _statChip(
                'Total',
                '$_totalCount',
                AdminColors.violet,
                Icons.layers_outlined,
              ),
              const SizedBox(width: 10),
              _statChip(
                'Réussis',
                '$_successCount',
                AdminColors.green,
                Icons.check_circle_outline,
              ),
              const SizedBox(width: 10),
              _statChip(
                'Échoués',
                '$_failedCount',
                AdminColors.red,
                Icons.highlight_off_outlined,
              ),
              const SizedBox(width: 10),
              _statChip(
                'En attente',
                '$_pendingCount',
                AdminColors.amber,
                Icons.hourglass_empty_outlined,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Recherche ─────────────────────────────────────────────────────
          AdminSharedWidgets.searchField(
            'Rechercher par fichier, modèle ou utilisateur...',
            widget.onSearchChanged,
            widget.dk,
            widget.card,
            widget.bord,
            widget.txt,
            widget.sub,
          ),
          const SizedBox(height: 16),

          // ── Onglets ───────────────────────────────────────────────────────
          _buildTabBar(),
          const SizedBox(height: 16),

          // ── Contenu ───────────────────────────────────────────────────────
          if (widget.loading)
            _buildLoading()
          else if (widget.error != null)
            AdminSharedWidgets.errWidget(
              widget.error!,
              widget.onReload,
              widget.card,
              widget.bord,
              widget.txt,
              widget.sub,
            )
          else
            _buildTabContent(),
        ],
      ),
    );
  }

  // ── Mini-stat chip ────────────────────────────────────────────────────
  Widget _statChip(String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: widget.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: widget.bord),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 15),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: widget.txt,
                    ),
                  ),
                  Text(
                    label,
                    style: TextStyle(fontSize: 10, color: widget.sub),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Barre d'onglets ───────────────────────────────────────────────────
  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: widget.dk ? const Color(0xFF1a1d24) : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(4),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: widget.card,
          borderRadius: BorderRadius.circular(9),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: widget.txt,
        unselectedLabelColor: widget.sub,
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w400,
        ),
        tabs: [
          Tab(child: _tabLabel('Tous', '$_totalCount', AdminColors.violet)),
          Tab(child: _tabLabel('Réussis', '$_successCount', AdminColors.green)),
          Tab(child: _tabLabel('Échoués', '$_failedCount', AdminColors.red)),
        ],
      ),
    );
  }

  Widget _tabLabel(String label, String count, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            count,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  // ── Contenu selon l'onglet actif ──────────────────────────────────────
  Widget _buildTabContent() {
    return AnimatedBuilder(
      animation: _tabController,
      builder: (_, __) {
        final idx = _tabController.index;
        final filter = idx == 1
            ? 'Succès'
            : idx == 2
            ? 'Échoué'
            : null;
        final items = _filtered(filter);

        if (items.isEmpty) {
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 48),
            decoration: BoxDecoration(
              color: widget.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: widget.bord),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.inbox_outlined,
                    size: 40,
                    color: widget.sub.withOpacity(0.4),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Aucun import trouvé',
                    style: TextStyle(fontSize: 13, color: widget.sub),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          children: items.take(50).map(_buildActivityCard).toList(),
        );
      },
    );
  }

  Widget _buildLoading() {
    return Container(
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: widget.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: widget.bord),
      ),
      child: Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: AdminColors.violet,
        ),
      ),
    );
  }

  // ── Card d'un import ──────────────────────────────────────────────────
  Widget _buildActivityCard(Map<String, dynamic> a) {
    final sc = ActivityHelpers.statusColor(a);
    final st = ActivityHelpers.status(a);
    final name = _userName(a);
    final initials = _userInitials(a);
    final isSuccess = st == 'Succès';
    final isFailed = st == 'Échoué';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: widget.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isFailed
              ? AdminColors.red.withOpacity(0.30)
              : isSuccess
              ? AdminColors.green.withOpacity(0.18)
              : widget.bord,
          width: isFailed ? 1.5 : 1.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Ligne 1 : icône + fichier + badge ────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icône statut
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: sc.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isSuccess
                        ? Icons.check_circle_rounded
                        : isFailed
                        ? Icons.cancel_rounded
                        : Icons.hourglass_empty_rounded,
                    color: sc,
                    size: 19,
                  ),
                ),
                const SizedBox(width: 12),

                // Nom du fichier + horodatage
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ActivityHelpers.fileName(a),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: widget.txt,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        ActivityHelpers.timeAgo(a),
                        style: TextStyle(fontSize: 11, color: widget.sub),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Badge statut
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: sc.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: sc,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        st,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: sc,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            Divider(height: 1, color: widget.bord),
            const SizedBox(height: 12),

            // ── Ligne 2 : métadonnées (utilisateur, modèle, lignes) ──────
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                // Utilisateur qui a fait l'import
                _metaTag(
                  Icons.person_outline,
                  'Importé par $name',
                  AdminColors.violet,
                ),

                // Code modèle
                if (a['modelCode'] != null &&
                    a['modelCode'].toString().isNotEmpty)
                  _metaTag(
                    Icons.description_outlined,
                    a['modelCode'].toString(),
                    AdminColors.blue,
                  ),

                // Statut explicite
                _metaTag(Icons.info_outline, st, sc),

                // Nombre de lignes
                if (a['rowCount'] != null)
                  _metaTag(
                    Icons.table_rows_outlined,
                    '${a['rowCount']} lignes',
                    widget.sub,
                  ),
              ],
            ),

            // ── Message d'erreur ──────────────────────────────────────────
            if (isFailed &&
                a['errorMessage'] != null &&
                a['errorMessage'].toString().isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AdminColors.red.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AdminColors.red.withOpacity(0.15)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 14,
                      color: AdminColors.red,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        a['errorMessage'].toString(),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AdminColors.red,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Tag de métadonnée ─────────────────────────────────────────────────
  Widget _metaTag(IconData icon, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color.withOpacity(0.75)),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: widget.txt,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
