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
  final ScrollController _scrollCtrl = ScrollController();
  final List<_ChatMessage> _messages = [];
  bool _sending = false;

  static const _blue   = Color(0xFF2563eb);
  static const _violet = Color(0xFF7c3aed);
  static const _green  = Color(0xFF059669);

  late AnimationController _animCtrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: Duration(milliseconds: 250));
    _scaleAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutBack);

    // Welcome message
    _messages.add(_ChatMessage(
      text: 'Hi! I\'m your Sage X3 assistant. I can help you:\n\n'
          '• Choose the right import model\n'
          '• Explain field formats\n'
          '• Guide you through the import process\n\n'
          'What would you like to know?',
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
      final reply = await ApiService().sendChatMessage(text, currentModelCode: widget.currentModelCode);
      setState(() {
        _messages.add(_ChatMessage(text: reply, isUser: false, time: DateTime.now()));
        _sending = false;
      });
    } catch (e) {
      setState(() {
        _messages.add(_ChatMessage(
          text: 'Sorry, I couldn\'t process your request. Please try again.',
          isUser: false, time: DateTime.now(),
        ));
        _sending = false;
      });
    }
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(Duration(milliseconds: 100), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent,
            duration: Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  void _sendQuickAction(String text) {
    _msgCtrl.text = text;
    _send();
  }

  @override
  Widget build(BuildContext context) {
    final dk   = Theme.of(context).brightness == Brightness.dark;
    final card = dk ? Color(0xFF151921) : Colors.white;
    final bord = dk ? Color(0xFF1e2028) : Color(0xFFf0f0f5);
    final txt  = dk ? Colors.white : Color(0xFF111827);
    final sub  = dk ? Color(0xFF6b7280) : Color(0xFF9ca3af);
    final desk = MediaQuery.of(context).size.width >= 1024;

    return Stack(children: [
      // ── Chat panel ────────────────────────────────────────────────────
      if (_isOpen)
        Positioned(
          right: 20, bottom: 80,
          child: ScaleTransition(
            scale: _scaleAnim,
            alignment: Alignment.bottomRight,
            child: Material(
              elevation: 20,
              shadowColor: Colors.black.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: desk ? 400 : MediaQuery.of(context).size.width - 40,
                height: desk ? 520 : MediaQuery.of(context).size.height * 0.65,
                decoration: BoxDecoration(
                  color: card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: bord),
                ),
                child: Column(children: [
                  _chatHeader(dk, txt, sub),
                  Expanded(child: _chatMessages(dk, card, bord, txt, sub)),
                  if (_messages.length <= 1) _quickActions(dk, bord, txt, sub),
                  _chatInput(dk, card, bord, txt, sub),
                ]),
              ),
            ),
          ),
        ),

      // ── Floating button ───────────────────────────────────────────────
      Positioned(
        right: 20, bottom: 20,
        child: GestureDetector(
          onTap: _toggle,
          child: AnimatedContainer(
            duration: Duration(milliseconds: 300),
            width: 56, height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _isOpen ? [_violet, _blue] : [_blue, _violet],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: _blue.withOpacity(0.35), blurRadius: 20, offset: Offset(0, 8)),
              ],
            ),
            child: AnimatedSwitcher(
              duration: Duration(milliseconds: 200),
              transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
              child: Icon(
                _isOpen ? Icons.close_rounded : Icons.auto_awesome,
                key: ValueKey(_isOpen),
                color: Colors.white, size: 24,
              ),
            ),
          ),
        ),
      ),
    ]);
  }

  // ── Header ────────────────────────────────────────────────────────────
  Widget _chatHeader(bool dk, Color txt, Color sub) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 18, 14, 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [_blue, _violet],
            begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.auto_awesome, color: Colors.white, size: 18),
        ),
        SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('SageX3 Assistant', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
          Row(children: [
            Container(width: 6, height: 6,
                decoration: BoxDecoration(color: Color(0xFF4ade80), shape: BoxShape.circle)),
            SizedBox(width: 5),
            Text('Online — powered by AI', style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.7))),
          ]),
        ])),
        // Clear chat
        IconButton(
          icon: Icon(Icons.delete_outline, color: Colors.white.withOpacity(0.6), size: 18),
          onPressed: () => setState(() {
            _messages.clear();
            _messages.add(_ChatMessage(
              text: 'Chat cleared. How can I help you?',
              isUser: false, time: DateTime.now(),
            ));
          }),
          tooltip: 'Clear chat',
        ),
        IconButton(
          icon: Icon(Icons.close, color: Colors.white.withOpacity(0.6), size: 18),
          onPressed: _toggle,
        ),
      ]),
    );
  }

  // ── Messages ──────────────────────────────────────────────────────────
  Widget _chatMessages(bool dk, Color card, Color bord, Color txt, Color sub) {
    return ListView.builder(
      controller: _scrollCtrl,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: _messages.length + (_sending ? 1 : 0),
      itemBuilder: (_, i) {
        // Typing indicator
        if (i == _messages.length && _sending) {
          return _typingIndicator(dk, sub);
        }
        final msg = _messages[i];
        return _messageBubble(msg, dk, txt, sub);
      },
    );
  }

  Widget _messageBubble(_ChatMessage msg, bool dk, Color txt, Color sub) {
    final isUser = msg.isUser;
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [_blue, _violet]),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.auto_awesome, color: Colors.white, size: 14),
            ),
            SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser
                    ? _blue
                    : dk ? Color(0xFF1a1d24) : Color(0xFFF3F4F6),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(msg.text, style: TextStyle(
                    fontSize: 13,
                    color: isUser ? Colors.white : txt,
                    height: 1.5)),
                SizedBox(height: 4),
                Text(
                  '${msg.time.hour.toString().padLeft(2, '0')}:${msg.time.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(fontSize: 9,
                      color: isUser ? Colors.white.withOpacity(0.6) : sub),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _typingIndicator(bool dk, Color sub) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(children: [
        Container(width: 28, height: 28,
            decoration: BoxDecoration(gradient: LinearGradient(colors: [_blue, _violet]),
                borderRadius: BorderRadius.circular(8)),
            child: Icon(Icons.auto_awesome, color: Colors.white, size: 14)),
        SizedBox(width: 8),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: dk ? Color(0xFF1a1d24) : Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            _dot(0), SizedBox(width: 4),
            _dot(1), SizedBox(width: 4),
            _dot(2),
          ]),
        ),
      ]),
    );
  }

  Widget _dot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 600),
      curve: Interval(index * 0.2, 0.6 + index * 0.2, curve: Curves.easeInOut),
      builder: (_, value, child) => Opacity(
        opacity: 0.3 + value * 0.7,
        child: Container(width: 6, height: 6,
            decoration: BoxDecoration(color: _blue, shape: BoxShape.circle)),
      ),
    );
  }

  // ── Quick actions (shown only at start) ───────────────────────────────
  Widget _quickActions(bool dk, Color bord, Color txt, Color sub) {
    final actions = [
      {'icon': Icons.help_outline, 'text': 'Which model should I use?', 'msg': 'I want to import data but I don\'t know which model to choose. Can you help me?'},
      {'icon': Icons.list_alt, 'text': 'Show available models', 'msg': 'List all available import models with a brief description of each.'},
      {'icon': Icons.route, 'text': 'How does import work?', 'msg': 'Explain the import process step by step.'},
    ];

    return Container(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: EdgeInsets.only(left: 4, bottom: 8),
            child: Text('Quick actions', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: sub))),
        ...actions.map((a) => Padding(
          padding: EdgeInsets.only(bottom: 6),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              onTap: () => _sendQuickAction(a['msg'] as String),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                decoration: BoxDecoration(
                  border: Border.all(color: bord),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(children: [
                  Icon(a['icon'] as IconData, size: 14, color: _blue),
                  SizedBox(width: 8),
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

  // ── Input ─────────────────────────────────────────────────────────────
  Widget _chatInput(bool dk, Color card, Color bord, Color txt, Color sub) {
    return Container(
      padding: EdgeInsets.fromLTRB(12, 10, 12, 14),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: bord)),
      ),
      child: Row(children: [
        Expanded(
          child: Container(
            height: 42,
            decoration: BoxDecoration(
              color: dk ? Color(0xFF1a1d24) : Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: _msgCtrl,
              style: TextStyle(fontSize: 13, color: txt),
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(),
              decoration: InputDecoration(
                hintText: 'Ask me anything...',
                hintStyle: TextStyle(fontSize: 13, color: sub),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              ),
            ),
          ),
        ),
        SizedBox(width: 8),
        GestureDetector(
          onTap: _sending ? null : _send,
          child: Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [_blue, _violet]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _sending ? Icons.hourglass_empty : Icons.send_rounded,
              color: Colors.white, size: 18,
            ),
          ),
        ),
      ]),
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isUser;
  final DateTime time;
  const _ChatMessage({required this.text, required this.isUser, required this.time});
}