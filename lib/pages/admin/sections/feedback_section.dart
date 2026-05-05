import 'package:flutter/material.dart';
import 'package:frontend_sage3/services/api_service.dart';

class FeedbackSection extends StatefulWidget {
  final bool desk;
  final bool dk;
  final Color card;
  final Color bord;
  final Color txt;
  final Color sub;
  final void Function(String msg, Color color) onSnack;

  const FeedbackSection({
    Key? key,
    required this.desk,
    required this.dk,
    required this.card,
    required this.bord,
    required this.txt,
    required this.sub,
    required this.onSnack,
  }) : super(key: key);

  @override
  State<FeedbackSection> createState() => _FeedbackSectionState();
}

class _FeedbackSectionState extends State<FeedbackSection> {
  static const _violet = Color(0xFF7c3aed);
  static const _green  = Color(0xFF059669);
  static const _red    = Color(0xFFdc2626);
  static const _amber  = Color(0xFFd97706);

  List<Map<String, dynamic>> _feedbacks = [];
  bool _loading = true;
  String? _error;
  String _filter = 'all'; // 'all' | 'unread' | 'read'

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await ApiService().getFeedbacks();
      setState(() { _feedbacks = data; _loading = false; });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _markRead(int id) async {
    try {
      await ApiService().markFeedbackRead(id);
      setState(() {
        final idx = _feedbacks.indexWhere((f) => f['id'] == id);
        if (idx != -1) _feedbacks[idx]['isRead'] = true;
      });
      widget.onSnack('✅ Marqué comme lu', _green);
    } catch (e) {
      widget.onSnack('❌ ${e.toString().replaceFirst('Exception: ', '')}', _red);
    }
  }

  Future<void> _delete(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Supprimer le feedback', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Voulez-vous vraiment supprimer ce feedback ? Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ApiService().deleteFeedback(id);
      setState(() => _feedbacks.removeWhere((f) => f['id'] == id));
      widget.onSnack('🗑️ Feedback supprimé', _red);
    } catch (e) {
      widget.onSnack('❌ ${e.toString().replaceFirst('Exception: ', '')}', _red);
    }
  }

  List<Map<String, dynamic>> get _filtered {
    if (_filter == 'unread') return _feedbacks.where((f) => f['isRead'] == false).toList();
    if (_filter == 'read')   return _feedbacks.where((f) => f['isRead'] == true).toList();
    return _feedbacks;
  }

  int get _unreadCount => _feedbacks.where((f) => f['isRead'] == false).length;

  String _formatDate(String? raw) {
    if (raw == null) return '—';
    try {
      final dt = DateTime.parse(raw).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── En-tête ────────────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
          decoration: BoxDecoration(
            color: widget.card,
            border: Border(bottom: BorderSide(color: widget.bord)),
          ),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _violet.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.feedback_outlined, color: _violet, size: 22),
            ),
            const SizedBox(width: 14),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Feedbacks', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: widget.txt)),
              Text('Commentaires envoyés par les utilisateurs', style: TextStyle(fontSize: 13, color: widget.sub)),
            ]),
            const Spacer(),
            // Badge non-lus
            if (_unreadCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: _amber.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
                child: Row(children: [
                  const Icon(Icons.mark_email_unread_outlined, color: _amber, size: 15),
                  const SizedBox(width: 6),
                  Text('$_unreadCount non lu${_unreadCount > 1 ? 's' : ''}',
                      style: const TextStyle(color: _amber, fontSize: 13, fontWeight: FontWeight.w600)),
                ]),
              ),
            const SizedBox(width: 12),
            // Bouton recharger
            IconButton(
              tooltip: 'Actualiser',
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded),
              color: widget.sub,
            ),
          ]),
        ),

        // ── Filtres ────────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          child: Row(children: [
            _filterChip('Tous', 'all'),
            const SizedBox(width: 8),
            _filterChip('Non lus', 'unread'),
            const SizedBox(width: 8),
            _filterChip('Lus', 'read'),
          ]),
        ),

        // ── Contenu ────────────────────────────────────────────────────────
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: _violet))
              : _error != null
                  ? _buildError()
                  : _filtered.isEmpty
                      ? _buildEmpty()
                      : ListView.builder(
                          padding: const EdgeInsets.all(24),
                          itemCount: _filtered.length,
                          itemBuilder: (_, i) => _buildCard(_filtered[i]),
                        ),
        ),
      ],
    );
  }

  Widget _filterChip(String label, String value) {
    final sel = _filter == value;
    return GestureDetector(
      onTap: () => setState(() => _filter = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: sel ? _violet : (widget.dk ? const Color(0xFF1e2028) : const Color(0xFFF3F4F6)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: sel ? Colors.white : widget.sub,
            )),
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> fb) {
    final isRead = fb['isRead'] as bool? ?? false;
    final id       = fb['id'] as int? ?? 0;
    final username = fb['username'] as String? ?? '—';
    final message  = fb['message'] as String? ?? '';
    final date     = _formatDate(fb['createdAt'] as String?);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: widget.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isRead ? widget.bord : _violet.withOpacity(0.35),
          width: isRead ? 1 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(widget.dk ? 0.15 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // ── Header carte ───────────────────────────────────────────────
          Row(children: [
            // Avatar initiales
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: _violet.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  username.isNotEmpty ? username[0].toUpperCase() : '?',
                  style: const TextStyle(color: _violet, fontWeight: FontWeight.w700, fontSize: 15),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(username, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: widget.txt)),
              Text(date, style: TextStyle(fontSize: 11, color: widget.sub)),
            ]),
            const Spacer(),
            // Badge lu/non-lu
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isRead ? _green.withOpacity(0.1) : _amber.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                isRead ? 'Lu' : 'Non lu',
                style: TextStyle(
                  color: isRead ? _green : _amber,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ]),

          const SizedBox(height: 14),

          // ── Message ────────────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: widget.dk ? const Color(0xFF0b0e13) : const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: widget.bord),
            ),
            child: Text(message, style: TextStyle(fontSize: 14, color: widget.txt, height: 1.55)),
          ),

          const SizedBox(height: 14),

          // ── Actions ────────────────────────────────────────────────────
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            if (!isRead)
              OutlinedButton.icon(
                onPressed: () => _markRead(id),
                icon: const Icon(Icons.done_all, size: 15),
                label: const Text('Marquer comme lu', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _green,
                  side: BorderSide(color: _green.withOpacity(0.5)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            if (!isRead) const SizedBox(width: 10),
            OutlinedButton.icon(
              onPressed: () => _delete(id),
              icon: const Icon(Icons.delete_outline, size: 15),
              label: const Text('Supprimer', style: TextStyle(fontSize: 12)),
              style: OutlinedButton.styleFrom(
                foregroundColor: _red,
                side: BorderSide(color: _red.withOpacity(0.4)),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ]),
        ]),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.error_outline, color: _red, size: 48),
        const SizedBox(height: 12),
        Text('Erreur : $_error', style: const TextStyle(color: _red)),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: _load,
          icon: const Icon(Icons.refresh),
          label: const Text('Réessayer'),
          style: ElevatedButton.styleFrom(backgroundColor: _violet, foregroundColor: Colors.white),
        ),
      ]),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.inbox_outlined, size: 64, color: widget.sub.withOpacity(0.4)),
        const SizedBox(height: 16),
        Text('Aucun feedback', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: widget.sub)),
        const SizedBox(height: 6),
        Text(
          _filter == 'unread' ? 'Tous les feedbacks ont été lus.' : 'Aucun commentaire reçu pour l\'instant.',
          style: TextStyle(fontSize: 13, color: widget.sub.withOpacity(0.7)),
        ),
      ]),
    );
  }
}