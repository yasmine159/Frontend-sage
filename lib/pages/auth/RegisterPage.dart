import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:frontend_sage3/pages/auth/LoginPage.dart';
import 'package:frontend_sage3/services/api_service.dart';
import 'package:frontend_sage3/services/auth_service.dart';

class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> with SingleTickerProviderStateMixin {
  final TextEditingController fullNameController    = TextEditingController();
  final TextEditingController emailController       = TextEditingController();
  final TextEditingController passController        = TextEditingController();
  final TextEditingController confirmPassController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final ApiService _api = ApiService();

  bool _isPasswordVisible        = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading                = false;
  bool _acceptTerms              = false;
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
    _slideController = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _slideAnim = Tween<Offset>(begin: const Offset(0.06, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));
    _fadeAnim = CurvedAnimation(parent: _slideController, curve: Curves.easeOut);
    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose(); fullNameController.dispose();
    emailController.dispose(); passController.dispose();
    confirmPassController.dispose(); super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Veuillez accepter les conditions d\'utilisation'),
        backgroundColor: const Color(0xFFef4444), behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))));
      return;
    }
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final data = await _api.register(
          fullNameController.text.trim(), emailController.text.trim(), passController.text);
      final userMap = data['user'] as Map<String, dynamic>;
      AuthService.instance.setUser(AuthUser(
        id: userMap['id'] as int, username: userMap['username'] as String,
        email: userMap['email'] as String, role: userMap['role'] as String,
        token: data['token'] as String,
        phone: userMap['phone'] as String? ?? '',
        company: userMap['company'] as String? ?? '',
      ));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Compte créé avec succès !'),
        backgroundColor: const Color(0xFF10b981), behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))));
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      setState(() => _errorMessage = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _googleSignUp() {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(Icons.info_outline, color: Colors.white, size: 16), SizedBox(width: 10),
        Text('Inscription Google bientôt disponible', style: TextStyle(fontSize: 13)),
      ]),
      backgroundColor: _accent, behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: EdgeInsets.all(16)));
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 820;
    return Scaffold(backgroundColor: _bgPanel,
        body: isDesktop ? _buildDesktopLayout() : _buildMobileLayout());
  }

  Widget _buildDesktopLayout() {
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
              const Text('Commencez\nici.', style: TextStyle(fontSize: 42, fontWeight: FontWeight.w700,
                  color: _textDark, height: 1.15, letterSpacing: -0.5)),
              const SizedBox(height: 10),
              Text('Créez votre compte en quelques secondes.', style: TextStyle(fontSize: 14, color: _textMid)),
            ])),
      ])),
      Expanded(flex: 45, child: Container(color: _bgPanel,
        child: Center(child: SlideTransition(position: _slideAnim,
          child: FadeTransition(opacity: _fadeAnim,
            child: SizedBox(width: 400, child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 40), child: _buildCard()))))))),
    ]);
  }

  Widget _buildMobileLayout() {
    return Stack(children: [
      Positioned.fill(child: Image.asset('assets/images/backgroundimg.jpg', fit: BoxFit.cover)),
      Positioned.fill(child: Container(color: Colors.white.withOpacity(0.65))),
      SafeArea(child: Center(child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: SlideTransition(position: _slideAnim,
            child: FadeTransition(opacity: _fadeAnim, child: _buildCard()))))),
    ]);
  }

  Widget _buildCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 44),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(color: const Color(0xFF0891b2).withOpacity(0.10),
              blurRadius: 48, spreadRadius: -6, offset: const Offset(0, 20)),
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ]),
      child: _buildForm(),
    );
  }

  Widget _buildForm() {
    return Form(key: _formKey, child: Column(
      crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        // Logo
        Row(children: [
          _dot(size: 8), const SizedBox(width: 8),
          const Text('SAGE X3', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
              color: _textDark, letterSpacing: 3)),
        ]),
        const SizedBox(height: 32),

        const Text('Créer un compte', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700,
            color: _textDark, letterSpacing: -0.5, height: 1.1)),
        const SizedBox(height: 6),
        Text('Remplissez les informations ci-dessous pour commencer.', style: TextStyle(fontSize: 13, color: _textMid)),
        const SizedBox(height: 28),

        // ── Google button ───────────────────────────────────────────
        _googleButton(),
        const SizedBox(height: 24),

        // ── Divider ─────────────────────────────────────────────────
        Row(children: [
          Expanded(child: Divider(color: _border, thickness: 1)),
          Padding(padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text('ou', style: TextStyle(fontSize: 12, color: _textLight, fontWeight: FontWeight.w500))),
          Expanded(child: Divider(color: _border, thickness: 1)),
        ]),
        const SizedBox(height: 24),

        // Error
        if (_errorMessage != null) ...[
          _errorBanner(_errorMessage!), const SizedBox(height: 20),
        ],

        // Full name
        _label('Nom complet'), const SizedBox(height: 7),
        TextFormField(controller: fullNameController,
            style: const TextStyle(color: _textDark, fontSize: 14),
            decoration: _inputDeco('Prénom Nom', Icons.person_outline_rounded),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Veuillez entrer votre nom';
              if (v.length < 3) return 'Le nom doit contenir au moins 3 caractères';
              return null;
            }),
        const SizedBox(height: 16),

        // Email
        _label('Adresse e-mail'), const SizedBox(height: 7),
        TextFormField(controller: emailController, keyboardType: TextInputType.emailAddress,
            style: const TextStyle(color: _textDark, fontSize: 14),
            decoration: _inputDeco('vous@entreprise.com', Icons.alternate_email_rounded),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Veuillez entrer votre e-mail';
              if (!v.contains('@')) return 'Veuillez entrer un e-mail valide';
              return null;
            }),
        const SizedBox(height: 16),

        // Password
        _label('Mot de passe'), const SizedBox(height: 7),
        TextFormField(controller: passController, obscureText: !_isPasswordVisible,
            style: const TextStyle(color: _textDark, fontSize: 14),
            decoration: _inputDeco('••••••••', Icons.lock_outline_rounded,
              suffix: IconButton(
                icon: Icon(_isPasswordVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    color: _textLight, size: 18),
                onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible))),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Veuillez entrer un mot de passe';
              if (v.length < 6) return 'Le mot de passe doit contenir au moins 6 caractères';
              return null;
            }),
        const SizedBox(height: 16),

        // Confirm password
        _label('Confirmer le mot de passe'), const SizedBox(height: 7),
        TextFormField(controller: confirmPassController, obscureText: !_isConfirmPasswordVisible,
            style: const TextStyle(color: _textDark, fontSize: 14),
            decoration: _inputDeco('••••••••', Icons.lock_outline_rounded,
              suffix: IconButton(
                icon: Icon(_isConfirmPasswordVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    color: _textLight, size: 18),
                onPressed: () => setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible))),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Veuillez confirmer votre mot de passe';
              if (v != passController.text) return 'Les mots de passe ne correspondent pas';
              return null;
            }),
        const SizedBox(height: 20),

        // Terms
        GestureDetector(
          onTap: () => setState(() => _acceptTerms = !_acceptTerms),
          child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            AnimatedContainer(duration: const Duration(milliseconds: 180), width: 18, height: 18,
              decoration: BoxDecoration(color: _acceptTerms ? _accent : Colors.white,
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(color: _acceptTerms ? _accent : _textLight, width: 1.5)),
              child: _acceptTerms ? const Icon(Icons.check_rounded, color: Colors.white, size: 12) : null),
            const SizedBox(width: 10),
            Expanded(child: RichText(text: const TextSpan(
              style: TextStyle(fontSize: 12, color: _textMid), children: [
                TextSpan(text: "J'accepte les "),
                TextSpan(text: "conditions d'utilisation",
                    style: TextStyle(color: _accent, fontWeight: FontWeight.w600)),
              ]))),
          ])),
        const SizedBox(height: 30),

        // Submit
        SizedBox(width: double.infinity, height: 50,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleRegister,
            style: ElevatedButton.styleFrom(backgroundColor: _accent,
                disabledBackgroundColor: _accent.withOpacity(0.4),
                foregroundColor: Colors.white, elevation: 0, shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: _isLoading
                ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)))
                : const Text('Créer le compte', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.2)),
          )),
        const SizedBox(height: 28),

        // Login link
        Center(child: RichText(text: TextSpan(
          style: TextStyle(color: _textMid, fontSize: 12), children: [
            const TextSpan(text: "Vous avez déjà un compte ?  "),
            WidgetSpan(child: GestureDetector(
              onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => LoginPage())),
              child: const Text('Se connecter',
                  style: TextStyle(color: _accent, fontSize: 12, fontWeight: FontWeight.w600)))),
          ]))),
        const SizedBox(height: 4),
      ],
    ));
  }

  // ── Shared widgets ────────────────────────────────────────────────────────
  Widget _googleButton() {
    return SizedBox(width: double.infinity, height: 48,
      child: OutlinedButton(
        onPressed: _googleSignUp,
        style: OutlinedButton.styleFrom(foregroundColor: _textDark,
            side: BorderSide(color: _border),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)), elevation: 0),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          SizedBox(width: 20, height: 20, child: CustomPaint(painter: _GoogleLogoPainter())),
          const SizedBox(width: 12),
          Text("S'inscrire avec Google", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: _textDark)),
        ]),
      ));
  }

  Widget _errorBanner(String msg) {
    return Container(width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: const Color(0xFFfef2f2),
          borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFfecaca))),
      child: Row(children: [
        const Icon(Icons.error_outline, color: Color(0xFFef4444), size: 16),
        const SizedBox(width: 10),
        Expanded(child: Text(msg, style: const TextStyle(color: Color(0xFFdc2626), fontSize: 12))),
      ]));
  }

  Widget _dot({double size = 6}) => Container(width: size, height: size,
      decoration: const BoxDecoration(color: _accent, shape: BoxShape.circle));

  Widget _label(String text) => Text(text,
      style: const TextStyle(color: _textDark, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.1));

  InputDecoration _inputDeco(String hint, IconData icon, {Widget? suffix}) {
    return InputDecoration(
      hintText: hint, hintStyle: const TextStyle(color: _textLight, fontSize: 14),
      prefixIcon: Padding(padding: const EdgeInsets.only(left: 14, right: 10),
          child: Icon(icon, color: _textLight, size: 18)),
      prefixIconConstraints: const BoxConstraints(minWidth: 46),
      suffixIcon: suffix, filled: true, fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(11), borderSide: const BorderSide(color: _border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(11), borderSide: const BorderSide(color: _border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(11), borderSide: const BorderSide(color: _accent, width: 1.5)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(11), borderSide: const BorderSide(color: Color(0xFFf87171), width: 1.2)),
      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(11), borderSide: const BorderSide(color: Color(0xFFef4444), width: 1.5)),
      errorStyle: const TextStyle(color: Color(0xFFdc2626), fontSize: 11),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width, h = size.height, cx = w / 2, cy = h / 2, r = w * 0.45;
    final sw = w * 0.18;
    canvas.drawArc(Rect.fromCircle(center: Offset(cx, cy), radius: r), -0.9, 1.8, false,
        Paint()..color = const Color(0xFF4285F4)..style = PaintingStyle.stroke..strokeWidth = sw..strokeCap = StrokeCap.butt);
    canvas.drawArc(Rect.fromCircle(center: Offset(cx, cy), radius: r), 0.9, 1.2, false,
        Paint()..color = const Color(0xFF34A853)..style = PaintingStyle.stroke..strokeWidth = sw..strokeCap = StrokeCap.butt);
    canvas.drawArc(Rect.fromCircle(center: Offset(cx, cy), radius: r), 2.1, 1.0, false,
        Paint()..color = const Color(0xFFFBBC05)..style = PaintingStyle.stroke..strokeWidth = sw..strokeCap = StrokeCap.butt);
    canvas.drawArc(Rect.fromCircle(center: Offset(cx, cy), radius: r), -2.1, 1.2, false,
        Paint()..color = const Color(0xFFEA4335)..style = PaintingStyle.stroke..strokeWidth = sw..strokeCap = StrokeCap.butt);
    canvas.drawRect(Rect.fromLTWH(cx - w * 0.02, cy - h * 0.09, w * 0.48, h * 0.18),
        Paint()..color = const Color(0xFF4285F4)..style = PaintingStyle.fill);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}