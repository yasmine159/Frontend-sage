import 'package:flutter/material.dart';
import 'package:frontend_sage3/services/api_service.dart';
import '../widgets/admin_shared_widgets.dart';

class TemplatesSection extends StatelessWidget {
  final bool desk, dk;
  final Color card, bord, txt, sub;
  final List<Map<String, dynamic>> models;
  final bool loading;
  final String? error;
  final String search;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onReload;
  final Function(String, Color) onSnack;

  const TemplatesSection({
    super.key,
    required this.desk,
    required this.dk,
    required this.card,
    required this.bord,
    required this.txt,
    required this.sub,
    required this.models,
    required this.loading,
    required this.error,
    required this.search,
    required this.onSearchChanged,
    required this.onReload,
    required this.onSnack,
  });

  @override
  Widget build(BuildContext context) {
    final filtered = models.where((m) {
      final q = search.toLowerCase();
      return q.isEmpty
          || (m['codeModele'] ?? '').toString().toLowerCase().contains(q)
          || (m['texte']      ?? '').toString().toLowerCase().contains(q);
    }).toList();

    return SingleChildScrollView(
      padding: EdgeInsets.all(desk ? 32 : 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Modèles d\'import', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: txt)),
        Text('${models.length} modèles disponibles', style: TextStyle(fontSize: 12, color: sub)),
        const SizedBox(height: 20),

        AdminSharedWidgets.searchField('Rechercher par code ou description...', onSearchChanged, dk, card, bord, txt, sub),
        const SizedBox(height: 16),

        if (loading)
          Center(child: Padding(padding: const EdgeInsets.all(48), child: CircularProgressIndicator(strokeWidth: 2, color: AdminColors.violet)))
        else if (error != null)
          AdminSharedWidgets.errWidget(error!, onReload, card, bord, txt, sub)
        else if (filtered.isEmpty)
          Center(child: Text('Aucun modèle trouvé', style: TextStyle(color: sub)))

        // ── Bureau : grille 3 colonnes ──
        else if (desk)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              mainAxisExtent: 72,
            ),
            itemCount: filtered.length,
            itemBuilder: (_, i) => _buildDesktopCard(filtered[i]),
          )

        // ── Mobile : liste verticale ──
        else
          Column(children: filtered.map((m) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _buildMobileCard(m),
          )).toList()),
      ]),
    );
  }

  // ── Carte bureau ───────────────────────────────────────────────────────
  Widget _buildDesktopCard(Map<String, dynamic> m) {
    final code  = (m['codeModele'] ?? '—').toString();
    final texte = (m['texte']      ?? '').toString();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(12), border: Border.all(color: bord)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: AdminColors.blue.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
          child: const Icon(Icons.description_outlined, color: AdminColors.blue, size: 16),
        ),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(code,  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: txt), maxLines: 1, overflow: TextOverflow.ellipsis),
          if (texte.isNotEmpty) Text(texte, style: TextStyle(fontSize: 10, color: sub), maxLines: 1, overflow: TextOverflow.ellipsis),
        ])),
        TextButton.icon(
          onPressed: () => _downloadTemplate(code),
          icon: const Icon(Icons.download_outlined, size: 12),
          label: const Text('Obtenir', style: TextStyle(fontSize: 11)),
          style: TextButton.styleFrom(
            foregroundColor: AdminColors.blue,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      ]),
    );
  }

  // ── Carte mobile ───────────────────────────────────────────────────────
  Widget _buildMobileCard(Map<String, dynamic> m) {
    final code  = (m['codeModele'] ?? '—').toString();
    final texte = (m['texte']      ?? '').toString();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(12), border: Border.all(color: bord)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: AdminColors.blue.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.description_outlined, color: AdminColors.blue, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(code, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: txt), maxLines: 2, overflow: TextOverflow.ellipsis),
          if (texte.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(texte, style: TextStyle(fontSize: 12, color: sub), maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
        ])),
        const SizedBox(width: 8),
        TextButton.icon(
          onPressed: () => _downloadTemplate(code),
          icon: const Icon(Icons.download_outlined, size: 14),
          label: const Text('Télécharger', style: TextStyle(fontSize: 12)),
          style: TextButton.styleFrom(
            foregroundColor: AdminColors.blue,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      ]),
    );
  }

  Future<void> _downloadTemplate(String code) async {
    try {
      await ApiService().downloadTemplate(code);
      onSnack('$code téléchargé !', AdminColors.green);
    } catch (e) {
      onSnack('$e', AdminColors.red);
    }
  }
}