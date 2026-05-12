import 'package:flutter/material.dart';
import 'package:frontend_sage3/services/api_service.dart';

class ResetPasswordPage extends StatefulWidget {
  final String token;
  final String email;
  const ResetPasswordPage({required this.token, required this.email, Key? key}) : super(key: key);

  @override
  _ResetPasswordPageState createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _passController    = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  final _formKey  = GlobalKey<FormState>();
  final ApiService _api = ApiService();

  bool _isLoading        = false;
  bool _passVisible      = false;
  bool _confirmVisible   = false;
  bool _success          = false;
  String? _errorMessage;

  late AnimationController _slideController;
  late Animation<Offset>   _slideAnim;
  late Animation<double>   _fadeAnim;

  static const Color _accent    = Color(0xFF0891b2);
  static const Color _bgPanel   = Color(0xFFF8FAFB);
  static const Color _textDark  = Color(0xFF0F172A);
  static const Color _textMid   = Color(0xFF64748B);
  static const Color _textLight = Color(0xFFCBD5E1);
  static const Color _border    = Color(0xFFE2E8F0);

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));
    _fadeAnim = CurvedAnimation(parent: _slideController, curve: Curves.easeOut);
    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _passController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      await _api.resetPassword(
          email: widget.email,
          token: widget.token,
          newPassword: _passController.text);
      setState(() => _success = true);
    } catch (e) {
      setState(() => _errorMessage = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 820;
    return Scaffold(
      backgroundColor: _bgPanel,
      resizeToAvoidBottomInset: false,
      body: isDesktop ? _buildDesktop() : _buildMobile(),
    );
  }

  Widget _buildDesktop() {
    return LayoutBuilder(builder: (context, constraints) {
      final vPad = (constraints.maxHeight * 0.06).clamp(20.0, 56.0);
      return Row(children: [
        Expanded(flex: 55, child: Stack(fit: StackFit.expand, children: [
          Image.asset('assets/images/backgroundimg.jpg', fit: BoxFit.cover),
          Container(decoration: BoxDecoration(gradient: LinearGradient(
              begin: Alignment.centerRight, end: Alignment.centerLeft,
              colors: [_bgPanel, _bgPanel.withOpacity(0.0)], stops: const [0.0, 0.28]))),
          Positioned(left: 44, bottom: 44, child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            _dot(),
            const SizedBox(height: 12),
            const Text('Nouveau\nmot de passe.', style: TextStyle(fontSize: 40,
                fontWeight: FontWeight.w700, color: _textDark, height: 1.15, letterSpacing: -0.5)),
            const SizedBox(height: 10),
            Text('Choisissez un mot de passe sécurisé.',
                style: TextStyle(fontSize: 14, color: _textMid)),
          ])),
        ])),
        Expanded(flex: 45, child: Container(color: _bgPanel,
            child: Center(child: SlideTransition(position: _slideAnim,
                child: FadeTransition(opacity: _fadeAnim,
                    child: SizedBox(width: 400, child: _buildCard(vPad: vPad))))))),
      ]);
    });
  }

  Widget _buildMobile() {
    return LayoutBuilder(builder: (context, constraints) {
      final vPad = (constraints.maxHeight * 0.05).clamp(16.0, 40.0);
      return Stack(children: [
        Positioned.fill(child: Image.asset('assets/images/backgroundimg.jpg', fit: BoxFit.cover)),
        Positioned.fill(child: Container(color: Colors.white.withOpacity(0.65))),
        SafeArea(child: Center(child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: vPad),
          child: SlideTransition(position: _slideAnim,
              child: FadeTransition(opacity: _fadeAnim, child: _buildCard(vPad: vPad))),
        ))),
      ]);
    });
  }

  Widget _buildCard({required double vPad}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 40, vertical: vPad),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _border),
          boxShadow: [
            BoxShadow(color: const Color(0xFF0891b2).withOpacity(0.10),
                blurRadius: 48, spreadRadius: -6, offset: const Offset(0, 20)),
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
          ]),
      child: _success ? _buildSuccess() : _buildForm(),
    );
  }

  Widget _buildForm() {
    return Form(key: _formKey, child: Column(
      crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      Row(children: [_dot(size: 8), const SizedBox(width: 8),
        const Text('SAGE X3', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
            color: _textDark, letterSpacing: 3))]),
      const SizedBox(height: 28),

      const Text('Nouveau mot de passe', style: TextStyle(fontSize: 26,
          fontWeight: FontWeight.w700, color: _textDark, letterSpacing: -0.5)),
      const SizedBox(height: 6),
      Text('Pour le compte : ${widget.email}',
          style: const TextStyle(fontSize: 12, color: _textMid)),
      const SizedBox(height: 24),

      if (_errorMessage != null) ...[
        _errorBanner(_errorMessage!), const SizedBox(height: 16),
      ],

      _label('Nouveau mot de passe'), const SizedBox(height: 7),
      TextFormField(
        controller: _passController, obscureText: !_passVisible,
        style: const TextStyle(color: _textDark, fontSize: 14),
        decoration: _inputDeco('••••••••', Icons.lock_outline_rounded,
          suffix: IconButton(
            icon: Icon(_passVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                color: _textLight, size: 18),
            onPressed: () => setState(() => _passVisible = !_passVisible))),
        validator: (v) {
          if (v == null || v.isEmpty) return 'Requis';
          if (v.length < 6) return 'Min. 6 caractères';
          return null;
        },
      ),
      const SizedBox(height: 14),

      _label('Confirmer le mot de passe'), const SizedBox(height: 7),
      TextFormField(
        controller: _confirmController, obscureText: !_confirmVisible,
        textInputAction: TextInputAction.done,
        onFieldSubmitted: (_) => _submit(),
        style: const TextStyle(color: _textDark, fontSize: 14),
        decoration: _inputDeco('••••••••', Icons.lock_outline_rounded,
          suffix: IconButton(
            icon: Icon(_confirmVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                color: _textLight, size: 18),
            onPressed: () => setState(() => _confirmVisible = !_confirmVisible))),
        validator: (v) {
          if (v == null || v.isEmpty) return 'Requis';
          if (v != _passController.text) return 'Les mots de passe ne correspondent pas';
          return null;
        },
      ),
      const SizedBox(height: 24),

      SizedBox(width: double.infinity, height: 48,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          style: ElevatedButton.styleFrom(backgroundColor: _accent,
              disabledBackgroundColor: _accent.withOpacity(0.4),
              foregroundColor: Colors.white, elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          child: _isLoading
              ? const SizedBox(width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.white)))
              : const Text('Confirmer', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        )),
    ]));
  }

  Widget _buildSuccess() {
    return Column(mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center, children: [
      const SizedBox(height: 8),
      Container(width: 64, height: 64,
        decoration: const BoxDecoration(color: Color(0xFFd1fae5), shape: BoxShape.circle),
        child: const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF10b981), size: 32)),
      const SizedBox(height: 20),
      const Text('Mot de passe modifié !', style: TextStyle(fontSize: 24,
          fontWeight: FontWeight.w700, color: _textDark, letterSpacing: -0.3)),
      const SizedBox(height: 10),
      const Text('Votre mot de passe a été réinitialisé avec succès.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: _textMid, height: 1.5)),
      const SizedBox(height: 28),
      SizedBox(width: double.infinity, height: 48,
        child: ElevatedButton(
          onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false),
          style: ElevatedButton.styleFrom(backgroundColor: _accent,
              foregroundColor: Colors.white, elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          child: const Text('Se connecter', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        )),
    ]);
  }

  Widget _errorBanner(String msg) => Container(width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(color: const Color(0xFFfef2f2),
        borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFfecaca))),
    child: Row(children: [
      const Icon(Icons.error_outline, color: Color(0xFFef4444), size: 16),
      const SizedBox(width: 10),
      Expanded(child: Text(msg, style: const TextStyle(color: Color(0xFFdc2626), fontSize: 12))),
    ]));

  Widget _dot({double size = 6}) => Container(width: size, height: size,
      decoration: const BoxDecoration(color: _accent, shape: BoxShape.circle));

  Widget _label(String t) => Text(t, style: const TextStyle(color: _textDark,
      fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.1));

  InputDecoration _inputDeco(String hint, IconData icon, {Widget? suffix}) => InputDecoration(
    hintText: hint, hintStyle: const TextStyle(color: _textLight, fontSize: 14),
    prefixIcon: Padding(padding: const EdgeInsets.only(left: 14, right: 10),
        child: Icon(icon, color: _textLight, size: 18)),
    prefixIconConstraints: const BoxConstraints(minWidth: 46),
    suffixIcon: suffix, filled: true, fillColor: const Color(0xFFF8FAFC),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(11), borderSide: const BorderSide(color: _border)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(11), borderSide: const BorderSide(color: _border)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(11), borderSide: const BorderSide(color: _accent, width: 1.5)),
    errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(11), borderSide: const BorderSide(color: Color(0xFFf87171), width: 1.2)),
    focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(11), borderSide: const BorderSide(color: Color(0xFFef4444), width: 1.5)),
    errorStyle: const TextStyle(color: Color(0xFFdc2626), fontSize: 11),
  );
}