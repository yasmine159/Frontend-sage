import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ChatWidget extends StatefulWidget {
  final String? currentModelCode;
  const ChatWidget({super.key, this.currentModelCode});

  @override
  _ChatWidgetState createState() => _ChatWidgetState();
}

class _ChatWidgetState extends State<ChatWidget> with SingleTickerProviderStateMixin {
  bool _isOpen = false;
  final TextEditingController _msgCtrl = TextEditingController();
  final ScrollController _scrollCtrl  = ScrollController();
  final List<_ChatMessage> _messages  = [];
  bool _sending = false;

  // Position du bouton flottant
  double? _btnRight;
  double? _btnBottom;
  bool   _isDragging   = false;
  Offset _dragStart    = Offset.zero;
  double _dragRightStart  = 0;
  double _dragBottomStart = 0;

  static const _blue   = Color(0xFF2563eb);
  static const _violet = Color(0xFF7c3aed);
  static const _green  = Color(0xFF059669);

  late AnimationController _animCtrl;
  late Animation<double>   _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 250));
    _scaleAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutBack);

    // Message de bienvenue en français
    _messages.add(_ChatMessage(
      text: 'Bonjour ! Je suis SageBot, votre assistant pour SageX3 Import Manager.\n\n'
            'Je peux vous aider à :\n'
            '• Choisir le bon modèle d\'import\n'
            '• Comprendre les formats de champs\n'
            '• Corriger les erreurs de conversion\n'
            '• Guider chaque étape du processus\n\n'
            'Que puis-je faire pour vous ?',
      isUser: false,
      time: DateTime.now(),
    ));
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _isOpen = !_isOpen);
    if (_isOpen) _animCtrl.forward(); else _animCtrl.reverse();
  }

  Future<void> _send() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true, time: DateTime.now()));
      _sending = true;
    });
    _msgCtrl.clear();
    _scrollToBottom();

    try {
      final reply = await ApiService().sendChatMessage(
        text,
        currentModelCode: widget.currentModelCode,
      );
      setState(() {
        _messages.add(_ChatMessage(text: reply, isUser: false, time: DateTime.now()));
        _sending = false;
      });
    } catch (e) {
      setState(() {
        _messages.add(_ChatMessage(
          text: 'Désolé, je n\'ai pas pu traiter votre demande. Veuillez réessayer.',
          isUser: false,
          time: DateTime.now(),
        ));
        _sending = false;
      });
    }
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendQuickAction(String text) {
    _msgCtrl.text = text;
    _send();
  }

  void _clearChat() {
    setState(() {
      _messages.clear();
      _messages.add(_ChatMessage(
        text: 'Conversation effacée. Comment puis-je vous aider ?',
        isUser: false,
        time: DateTime.now(),
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    final dk   = Theme.of(context).brightness == Brightness.dark;
    final card = dk ? const Color(0xFF151921) : Colors.white;
    final bord = dk ? const Color(0xFF1e2028) : const Color(0xFFf0f0f5);
    final txt  = dk ? Colors.white : const Color(0xFF111827);
    final sub  = dk ? const Color(0xFF6b7280) : const Color(0xFF9ca3af);
    final desk = MediaQuery.of(context).size.width >= 1024;

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenW = constraints.maxWidth;
        final screenH = constraints.maxHeight;
        final btnRight  = (_btnRight  ?? 20).clamp(8.0, screenW - 64);
        final btnBottom = (_btnBottom ?? 20).clamp(8.0, screenH - 64);

        final panelW = desk ? 420.0 : (screenW - 40).clamp(280.0, 420.0);
        final panelH = desk ? 540.0 : (screenH * 0.70).clamp(320.0, 540.0);
        double panelRight  = (btnRight - (panelW - 56) / 2).clamp(8.0, screenW - panelW - 8);
        double panelBottom = btnBottom + 64 + 8;
        if (panelBottom + panelH > screenH - 8) {
          panelBottom = (btnBottom - panelH - 8).clamp(8.0, screenH - panelH);
        }

        return Stack(children: [
          // ── Panneau chat ─────────────────────────────────────────────
          if (_isOpen)
            Positioned(
              right: panelRight,
              bottom: panelBottom,
              child: ScaleTransition(
                scale: _scaleAnim,
                alignment: Alignment.bottomRight,
                child: Material(
                  elevation: 20,
                  shadowColor: Colors.black.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: panelW,
                    height: panelH,
                    decoration: BoxDecoration(
                      color: card,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: bord),
                    ),
                    child: Column(children: [
                      _chatHeader(dk, txt, sub),
                      Expanded(child: _chatMessages(dk, txt, sub)),
                      if (_messages.length <= 1) _quickActions(dk, bord, txt, sub),
                      _chatInput(dk, bord, txt, sub),
                    ]),
                  ),
                ),
              ),
            ),

          // ── Bouton flottant déplaçable ────────────────────────────────
          Positioned(
            right: btnRight,
            bottom: btnBottom,
            child: GestureDetector(
              onPanStart: (d) {
                setState(() {
                  _isDragging      = false;
                  _dragStart       = d.globalPosition;
                  _dragRightStart  = btnRight;
                  _dragBottomStart = btnBottom;
                });
              },
              onPanUpdate: (d) {
                final dx = d.globalPosition.dx - _dragStart.dx;
                final dy = d.globalPosition.dy - _dragStart.dy;
                if (dx.abs() > 4 || dy.abs() > 4) {
                  setState(() {
                    _isDragging = true;
                    _btnRight   = (_dragRightStart  - dx).clamp(8.0, screenW - 64);
                    _btnBottom  = (_dragBottomStart - dy).clamp(8.0, screenH - 64);
                  });
                }
              },
              onPanEnd: (_) {
                final mid         = screenW / 2;
                final currentLeft = screenW - (_btnRight ?? 20) - 56;
                setState(() {
                  _btnRight   = currentLeft < mid ? (screenW - 56 - 16) : 16;
                  _isDragging = false;
                });
              },
              onTap: () { if (!_isDragging) _toggle(); },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 56, height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _isOpen ? [_violet, _blue] : [_blue, _violet],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: _blue.withOpacity(0.35), blurRadius: 20, offset: const Offset(0, 8)),
                  ],
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                  child: Icon(
                    _isOpen ? Icons.close_rounded : Icons.auto_awesome,
                    key: ValueKey(_isOpen),
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
          ),
        ]);
      },
    );
  }

  // ── En-tête du chat ───────────────────────────────────────────────────
  Widget _chatHeader(bool dk, Color txt, Color sub) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 14, 14),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_blue, _violet],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('SageBot', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
          Row(children: [
            Container(width: 6, height: 6,
                decoration: const BoxDecoration(color: Color(0xFF4ade80), shape: BoxShape.circle)),
            const SizedBox(width: 5),
            Text('En ligne — Propulsé par l\'IA',
                style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.75))),
          ]),
        ])),
        // Effacer la conversation
        IconButton(
          icon: Icon(Icons.delete_outline, color: Colors.white.withOpacity(0.6), size: 18),
          onPressed: _clearChat,
          tooltip: 'Effacer la conversation',
        ),
        IconButton(
          icon: Icon(Icons.close, color: Colors.white.withOpacity(0.6), size: 18),
          onPressed: _toggle,
          tooltip: 'Fermer',
        ),
      ]),
    );
  }

  // ── Messages ──────────────────────────────────────────────────────────
  Widget _chatMessages(bool dk, Color txt, Color sub) {
    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: _messages.length + (_sending ? 1 : 0),
      itemBuilder: (_, i) {
        if (i == _messages.length && _sending) return _typingIndicator(dk);
        return _messageBubble(_messages[i], dk, txt, sub);
      },
    );
  }

  Widget _messageBubble(_ChatMessage msg, bool dk, Color txt, Color sub) {
    final isUser = msg.isUser;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [_blue, _violet]),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 14),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser
                    ? _blue
                    : dk ? const Color(0xFF1a1d24) : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.only(
                  topLeft:     const Radius.circular(16),
                  topRight:    const Radius.circular(16),
                  bottomLeft:  Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  msg.text,
                  style: TextStyle(
                    fontSize: 13,
                    color: isUser ? Colors.white : txt,
                    height: 1.55,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${msg.time.hour.toString().padLeft(2, '0')}:${msg.time.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    fontSize: 9,
                    color: isUser ? Colors.white.withOpacity(0.6) : sub,
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _typingIndicator(bool dk) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(children: [
        Container(
          width: 28, height: 28,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [_blue, _violet]),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.auto_awesome, color: Colors.white, size: 14),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: dk ? const Color(0xFF1a1d24) : const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            _dot(0), const SizedBox(width: 4),
            _dot(1), const SizedBox(width: 4),
            _dot(2),
          ]),
        ),
      ]),
    );
  }

  Widget _dot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 600),
      curve: Interval(index * 0.2, 0.6 + index * 0.2, curve: Curves.easeInOut),
      builder: (_, value, __) => Opacity(
        opacity: 0.3 + value * 0.7,
        child: Container(
          width: 6, height: 6,
          decoration: const BoxDecoration(color: _blue, shape: BoxShape.circle),
        ),
      ),
    );
  }

  // ── Actions rapides (affichées au démarrage) ──────────────────────────
  Widget _quickActions(bool dk, Color bord, Color txt, Color sub) {
    final actions = [
      {
        'icon': Icons.help_outline,
        'text': 'Quel modèle dois-je utiliser ?',
        'msg':  'Je veux importer des données mais je ne sais pas quel modèle choisir. Peux-tu m\'aider ?',
      },
      {
        'icon': Icons.list_alt,
        'text': 'Voir les modèles disponibles',
        'msg':  'Liste tous les modèles d\'import disponibles avec une courte description.',
      },
      {
        'icon': Icons.route,
        'text': 'Comment fonctionne l\'import ?',
        'msg':  'Explique-moi le processus d\'import étape par étape.',
      },
      {
        'icon': Icons.bug_report_outlined,
        'text': 'Comment corriger une erreur ?',
        'msg':  'J\'ai des erreurs lors de la conversion. Comment les corriger ?',
      },
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text('Actions rapides',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: sub)),
        ),
        ...actions.map((a) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              onTap: () => _sendQuickAction(a['msg'] as String),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                decoration: BoxDecoration(
                  border: Border.all(color: bord),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(children: [
                  Icon(a['icon'] as IconData, size: 14, color: _blue),
                  const SizedBox(width: 8),
                  Expanded(child: Text(a['text'] as String,
                      style: TextStyle(fontSize: 12, color: txt))),
                  Icon(Icons.arrow_forward_ios, size: 10, color: sub.withOpacity(0.4)),
                ]),
              ),
            ),
          ),
        )),
      ]),
    );
  }

  // ── Zone de saisie ────────────────────────────────────────────────────
  Widget _chatInput(bool dk, Color bord, Color txt, Color sub) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: bord))),
      child: Row(children: [
        Expanded(
          child: Container(
            height: 42,
            decoration: BoxDecoration(
              color: dk ? const Color(0xFF1a1d24) : const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: _msgCtrl,
              style: TextStyle(fontSize: 13, color: txt),
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(),
              decoration: InputDecoration(
                hintText: 'Posez votre question…',
                hintStyle: TextStyle(fontSize: 13, color: sub),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: _sending ? null : _send,
          child: Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [_blue, _violet]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _sending ? Icons.hourglass_empty : Icons.send_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
        ),
      ]),
    );
  }
}

class _ChatMessage {
  final String   text;
  final bool     isUser;
  final DateTime time;
  const _ChatMessage({required this.text, required this.isUser, required this.time});
}