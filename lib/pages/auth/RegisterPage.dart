import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:frontend_sage3/pages/auth/LoginPage.dart';
import 'package:frontend_sage3/services/api_service.dart';
import 'package:frontend_sage3/services/auth_service.dart';
import 'package:frontend_sage3/main.dart';
import 'package:frontend_sage3/app_strings.dart';

class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> with SingleTickerProviderStateMixin {
  final TextEditingController fullNameController    = TextEditingController();
  final TextEditingController emailController       = TextEditingController();
  final TextEditingController passController        = TextEditingController();
  final TextEditingController confirmPassController = TextEditingController();
  final TextEditingController phoneController       = TextEditingController();
  final TextEditingController companyController     = TextEditingController();
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

  AppStrings get _s => SageX3App.of(context)?.strings ?? AppStrings('fr');

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
    fullNameController.dispose(); emailController.dispose();
    passController.dispose(); confirmPassController.dispose();
    phoneController.dispose(); companyController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    final s = _s;
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(s.acceptTermsRequired),
          backgroundColor: const Color(0xFFef4444), behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))));
      return;
    }
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final data = await _api.register(
          fullNameController.text.trim(), emailController.text.trim(), passController.text,
          phone: phoneController.text.trim(), company: companyController.text.trim());
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
          content: Text(s.accountCreated),
          backgroundColor: const Color(0xFF10b981), behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))));
      Navigator.pushReplacementNamed(context, '/home');
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
      body: isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
    );
  }

  Widget _buildDesktopLayout() {
    final s = _s;
    return LayoutBuilder(builder: (context, constraints) {
      final h     = constraints.maxHeight;
      final vPad  = (h * 0.045).clamp(14.0, 40.0);
      final gap   = (h * 0.025).clamp(8.0, 24.0);
      final gapSm = (h * 0.015).clamp(6.0, 14.0);
      return Row(children: [
        Expanded(flex: 55, child: Stack(fit: StackFit.expand, children: [
          Image.asset('assets/images/backgroundimg.jpg', fit: BoxFit.cover),
          Container(decoration: BoxDecoration(gradient: LinearGradient(
              begin: Alignment.centerRight, end: Alignment.centerLeft,
              colors: [_bgPanel, _bgPanel.withOpacity(0.0)], stops: const [0.0, 0.28]))),
          Positioned(left: 44, bottom: 44, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _dot(),
            const SizedBox(height: 12),
            Text(s.registerHero, style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w700,
                color: _textDark, height: 1.15, letterSpacing: -0.5)),
            const SizedBox(height: 10),
            Text(s.registerSubtitle, style: const TextStyle(fontSize: 14, color: _textMid)),
          ])),
        ])),
        Expanded(flex: 45, child: Container(color: _bgPanel,
            child: Center(child: SlideTransition(position: _slideAnim,
                child: FadeTransition(opacity: _fadeAnim,
                    child: SizedBox(width: 520, child: _buildCard(hPad: 40, vPad: vPad, gap: gap, gapSm: gapSm))))))),
      ]);
    });
  }

  Widget _buildMobileLayout() {
    return LayoutBuilder(builder: (context, constraints) {
      final h     = constraints.maxHeight;
      final vPad  = (h * 0.035).clamp(10.0, 30.0);
      final gap   = (h * 0.02).clamp(6.0, 20.0);
      final gapSm = (h * 0.012).clamp(4.0, 12.0);
      return Stack(children: [
        Positioned.fill(child: Image.asset('assets/images/backgroundimg.jpg', fit: BoxFit.cover)),
        Positioned.fill(child: Container(color: Colors.white.withOpacity(0.65))),
        SafeArea(child: Center(child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: vPad),
          child: SlideTransition(position: _slideAnim,
              child: FadeTransition(opacity: _fadeAnim,
                  child: _buildCard(hPad: 28, vPad: vPad, gap: gap, gapSm: gapSm))),
        ))),
      ]);
    });
  }

  Widget _buildCard({required double hPad, required double vPad, required double gap, required double gapSm}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _border),
          boxShadow: [
            BoxShadow(color: const Color(0xFF0891b2).withOpacity(0.10), blurRadius: 48, spreadRadius: -6, offset: const Offset(0, 20)),
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
          ]),
      child: _buildForm(gap: gap, gapSm: gapSm),
    );
  }

  Widget _buildForm({double gap = 20, double gapSm = 12}) {
    final s = _s;
    return Form(key: _formKey, child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      Row(children: [
        _dot(size: 8), const SizedBox(width: 8),
        const Text('SAGE X3', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _textDark, letterSpacing: 3)),
      ]),
      SizedBox(height: gap),

      Text(s.createAccountTitle, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: _textDark, letterSpacing: -0.5, height: 1.1)),
      const SizedBox(height: 4),
      Text(s.registerFormSubtitle, style: const TextStyle(fontSize: 13, color: _textMid)),
      SizedBox(height: gap),

      if (_errorMessage != null) ...[
        _errorBanner(_errorMessage!), SizedBox(height: gapSm),
      ],

      _twoFields(
        left: _fieldCol(s.fullName, fullNameController, 'Prénom Nom', Icons.person_outline_rounded,
            validator: (v) {
              if (v == null || v.isEmpty) return s.required;
              if (v.length < 3) return s.min3chars;
              return null;
            }),
        right: _fieldCol(s.email, emailController, 'vous@entreprise.com', Icons.alternate_email_rounded,
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.isEmpty) return s.required;
              if (!v.contains('@')) return s.emailInvalid;
              return null;
            }),
      ),
      SizedBox(height: gapSm),

      _twoFields(
        left:  _fieldCol(s.phone,   phoneController,   '+216 XX XXX XXX', Icons.phone_outlined,   keyboardType: TextInputType.phone),
        right: _fieldCol(s.company, companyController, s.yourCompany,     Icons.business_outlined),
      ),
      SizedBox(height: gapSm),

      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _label(s.password), const SizedBox(height: 6),
          TextFormField(controller: passController, obscureText: !_isPasswordVisible,
              style: const TextStyle(color: _textDark, fontSize: 14),
              decoration: _inputDeco('••••••••', Icons.lock_outline_rounded,
                  suffix: IconButton(
                      icon: Icon(_isPasswordVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: _textLight, size: 18),
                      onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible))),
              validator: (v) {
                if (v == null || v.isEmpty) return s.required;
                if (v.length < 6) return s.min6chars;
                return null;
              }),
        ])),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _label(s.confirmPasswordLabel), const SizedBox(height: 6),
          TextFormField(controller: confirmPassController, obscureText: !_isConfirmPasswordVisible,
              style: const TextStyle(color: _textDark, fontSize: 14),
              decoration: _inputDeco('••••••••', Icons.lock_outline_rounded,
                  suffix: IconButton(
                      icon: Icon(_isConfirmPasswordVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: _textLight, size: 18),
                      onPressed: () => setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible))),
              validator: (v) {
                if (v == null || v.isEmpty) return s.required;
                if (v != passController.text) return s.notIdentical;
                return null;
              }),
        ])),
      ]),
      SizedBox(height: gapSm),

      GestureDetector(
          onTap: () => setState(() => _acceptTerms = !_acceptTerms),
          child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            AnimatedContainer(duration: const Duration(milliseconds: 180), width: 18, height: 18,
                decoration: BoxDecoration(color: _acceptTerms ? _accent : Colors.white,
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: _acceptTerms ? _accent : _textLight, width: 1.5)),
                child: _acceptTerms ? const Icon(Icons.check_rounded, color: Colors.white, size: 12) : null),
            const SizedBox(width: 10),
            Expanded(child: RichText(text: TextSpan(
                style: const TextStyle(fontSize: 12, color: _textMid), children: [
              TextSpan(text: s.iAccept),
              TextSpan(text: s.termsOfUse, style: const TextStyle(color: _accent, fontWeight: FontWeight.w600)),
            ]))),
          ])),
      SizedBox(height: gap),

      SizedBox(width: double.infinity, height: 48,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleRegister,
            style: ElevatedButton.styleFrom(backgroundColor: _accent,
                disabledBackgroundColor: _accent.withOpacity(0.4),
                foregroundColor: Colors.white, elevation: 0, shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: _isLoading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)))
                : Text(s.createAccountBtn, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.2)),
          )),
      SizedBox(height: gapSm),

      Center(child: RichText(text: TextSpan(
          style: const TextStyle(color: _textMid, fontSize: 12), children: [
        TextSpan(text: s.alreadyAccount),
        WidgetSpan(child: GestureDetector(
            onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => LoginPage())),
            child: Text(s.signIn, style: const TextStyle(color: _accent, fontSize: 12, fontWeight: FontWeight.w600)))),
      ]))),
    ]));
  }

  Widget _twoFields({required Widget left, required Widget right}) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(child: left), const SizedBox(width: 12), Expanded(child: right),
    ]);
  }

  Widget _fieldCol(String label, TextEditingController ctrl, String hint, IconData icon,
      {TextInputType? keyboardType, String? Function(String?)? validator}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _label(label), const SizedBox(height: 6),
      TextFormField(controller: ctrl, keyboardType: keyboardType,
          style: const TextStyle(color: _textDark, fontSize: 14),
          decoration: _inputDeco(hint, icon), validator: validator),
    ]);
  }

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
      hintText: hint, hintStyle: const TextStyle(color: _textLight, fontSize: 13),
      prefixIcon: Padding(padding: const EdgeInsets.only(left: 12, right: 8),
          child: Icon(icon, color: _textLight, size: 17)),
      prefixIconConstraints: const BoxConstraints(minWidth: 40),
      suffixIcon: suffix, filled: true, fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(11), borderSide: const BorderSide(color: _border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(11), borderSide: const BorderSide(color: _border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(11), borderSide: const BorderSide(color: _accent, width: 1.5)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(11), borderSide: const BorderSide(color: Color(0xFFf87171), width: 1.2)),
      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(11), borderSide: const BorderSide(color: Color(0xFFef4444), width: 1.5)),
      errorStyle: const TextStyle(color: Color(0xFFdc2626), fontSize: 10),
    );
  }
}