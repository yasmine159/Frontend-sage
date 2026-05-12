import 'package:flutter/material.dart';
import 'package:frontend_sage3/pages/auth/ForgotPasswordPage.dart';
import 'package:frontend_sage3/pages/auth/RegisterPage.dart';
import 'package:frontend_sage3/services/api_service.dart';
import 'package:frontend_sage3/services/auth_service.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passController  = TextEditingController();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passFocus  = FocusNode();
  final _formKey = GlobalKey<FormState>();
  final ApiService _api = ApiService();

  // ── State ─────────────────────────────────────────────────────────────────
  bool _isPasswordVisible = false;
  bool _isLoading         = false;
  bool _rememberMe        = false;
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
    _slideController.dispose();
    emailController.dispose();
    passController.dispose();
    _emailFocus.dispose();
    _passFocus.dispose();
    super.dispose();
  }

  // ── Login email/password ──────────────────────────────────────────────────
  Future<void> _login() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final data = await _api.login(emailController.text.trim(), passController.text);
      _setUserAndNavigate(data);
    } catch (e) {
      setState(() => _errorMessage = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _setUserAndNavigate(Map<String, dynamic> data) {
    final userMap = data['user'] as Map<String, dynamic>;
    AuthService.instance.setUser(AuthUser(
      id:       userMap['id']       as int,
      username: userMap['username'] as String,
      email:    userMap['email']    as String,
      role:     userMap['role']     as String,
      token:    data['token']       as String,
      phone:    userMap['phone']    as String? ?? '',
      company:  userMap['company']  as String? ?? '',
    ));
    if (!mounted) return;
    if (AuthService.instance.currentUser!.isAdmin) {
      Navigator.pushReplacementNamed(context, '/admin');
    } else {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 820;
    return Scaffold(
      backgroundColor: _bgPanel,
      resizeToAvoidBottomInset: false,
      body: isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
    );
  }

  Widget _buildDesktopLayout() {
    return LayoutBuilder(builder: (context, constraints) {
      final h     = constraints.maxHeight;
      final vPad  = (h * 0.05).clamp(16.0, 44.0);
      final gap   = (h * 0.028).clamp(10.0, 28.0);
      final gapSm = (h * 0.018).clamp(7.0, 18.0);
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
            const Text('Bon\nretour.', style: TextStyle(fontSize: 42, fontWeight: FontWeight.w700,
                color: _textDark, height: 1.15, letterSpacing: -0.5)),
            const SizedBox(height: 10),
            Text('Connectez-vous pour accéder à votre espace.',
                style: TextStyle(fontSize: 14, color: _textMid)),
          ])),
        ])),
        Expanded(flex: 45, child: Container(color: _bgPanel,
            child: Center(child: SlideTransition(position: _slideAnim,
                child: FadeTransition(opacity: _fadeAnim,
                    child: SizedBox(width: 400,
                        child: _buildCard(hPad: 40, vPad: vPad, gap: gap, gapSm: gapSm))))))),
      ]);
    });
  }

  Widget _buildMobileLayout() {
    return LayoutBuilder(builder: (context, constraints) {
      final h     = constraints.maxHeight;
      final vPad  = (h * 0.04).clamp(12.0, 36.0);
      final gap   = (h * 0.022).clamp(8.0, 24.0);
      final gapSm = (h * 0.014).clamp(5.0, 16.0);
      return GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Stack(children: [
          Positioned.fill(child: Image.asset('assets/images/backgroundimg.jpg', fit: BoxFit.cover)),
          Positioned.fill(child: Container(color: Colors.white.withOpacity(0.65))),
          SafeArea(child: Center(child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: vPad),
            child: SlideTransition(position: _slideAnim,
                child: FadeTransition(opacity: _fadeAnim,
                    child: _buildCard(hPad: 28, vPad: vPad, gap: gap, gapSm: gapSm))),
          ))),
        ]),
      );
    });
  }

  Widget _buildCard({required double hPad, required double vPad, required double gap, required double gapSm}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(color: const Color(0xFF0891b2).withOpacity(0.10),
              blurRadius: 48, spreadRadius: -6, offset: const Offset(0, 20)),
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: _buildForm(gap: gap, gapSm: gapSm),
    );
  }

  Widget _buildForm({double gap = 24, double gapSm = 18}) {
    return Form(key: _formKey, child: Column(
      crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      // Logo
      Row(children: [
        _dot(size: 8), const SizedBox(width: 8),
        const Text('SAGE X3', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
            color: _textDark, letterSpacing: 3)),
      ]),
      SizedBox(height: gap),

      const Text('Connexion', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700,
          color: _textDark, letterSpacing: -0.5, height: 1.1)),
      const SizedBox(height: 4),
      Text('Entrez vos identifiants pour continuer.',
          style: TextStyle(fontSize: 13, color: _textMid)),
      SizedBox(height: gap),

      if (_errorMessage != null) ...[
        _errorBanner(_errorMessage!),
        SizedBox(height: gapSm),
      ],

      // Email
      _label('Adresse e-mail'), const SizedBox(height: 7),
      TextFormField(
        controller: emailController, focusNode: _emailFocus,
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.next,
        onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_passFocus),
        style: const TextStyle(color: _textDark, fontSize: 14),
        decoration: _inputDeco('vous@entreprise.com', Icons.alternate_email_rounded),
        validator: (v) => (v == null || v.isEmpty) ? 'Veuillez entrer votre e-mail' : null,
      ),
      SizedBox(height: gapSm),

      // Password
      _label('Mot de passe'), const SizedBox(height: 7),
      TextFormField(
        controller: passController, focusNode: _passFocus,
        obscureText: !_isPasswordVisible,
        textInputAction: TextInputAction.done,
        onFieldSubmitted: (_) => _login(),
        style: const TextStyle(color: _textDark, fontSize: 14),
        decoration: _inputDeco('••••••••', Icons.lock_outline_rounded,
            suffix: IconButton(
                icon: Icon(_isPasswordVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    color: _textLight, size: 18),
                onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible))),
        validator: (v) => (v == null || v.isEmpty) ? 'Veuillez entrer votre mot de passe' : null,
      ),
      SizedBox(height: gapSm),

      // Remember + Forgot
      Row(children: [
        GestureDetector(onTap: () => setState(() => _rememberMe = !_rememberMe),
            child: Row(children: [
              AnimatedContainer(duration: const Duration(milliseconds: 180), width: 18, height: 18,
                  decoration: BoxDecoration(color: _rememberMe ? _accent : Colors.white,
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(color: _rememberMe ? _accent : _textLight, width: 1.5)),
                  child: _rememberMe ? const Icon(Icons.check_rounded, color: Colors.white, size: 12) : null),
              const SizedBox(width: 8),
              Text('Se souvenir de moi', style: TextStyle(color: _textMid, fontSize: 12)),
            ])),
        const Spacer(),
        GestureDetector(onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => ForgotPasswordPage())),
            child: const Text('Mot de passe oublié ?',
                style: TextStyle(color: _accent, fontSize: 12, fontWeight: FontWeight.w500))),
      ]),
      SizedBox(height: gap),

      // Submit
      SizedBox(width: double.infinity, height: 48,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _login,
            style: ElevatedButton.styleFrom(backgroundColor: _accent,
                disabledBackgroundColor: _accent.withOpacity(0.4),
                foregroundColor: Colors.white, elevation: 0, shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: _isLoading
                ? const SizedBox(width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)))
                : const Text('Se connecter', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.2)),
          )),
      SizedBox(height: gapSm),

      // Register link
      Center(child: RichText(text: TextSpan(
          style: TextStyle(color: _textMid, fontSize: 12), children: [
        const TextSpan(text: "Pas encore de compte ?  "),
        WidgetSpan(child: GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RegisterPage())),
            child: const Text('Créer un compte',
                style: TextStyle(color: _accent, fontSize: 12, fontWeight: FontWeight.w600)))),
      ]))),
    ]));
  }

  // ── Shared widgets ────────────────────────────────────────────────────────

  Widget _errorBanner(String msg) {
    return Container(width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(11), borderSide: const BorderSide(color: _border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(11), borderSide: const BorderSide(color: _border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(11), borderSide: const BorderSide(color: _accent, width: 1.5)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(11), borderSide: const BorderSide(color: Color(0xFFf87171), width: 1.2)),
      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(11), borderSide: const BorderSide(color: Color(0xFFef4444), width: 1.5)),
      errorStyle: const TextStyle(color: Color(0xFFdc2626), fontSize: 11),
    );
  }
}