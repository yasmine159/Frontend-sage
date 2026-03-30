import 'dart:ui';
import 'package:flutter/material.dart';
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
  final _formKey = GlobalKey<FormState>();
  final ApiService _api = ApiService();

  bool _isPasswordVisible = false;
  bool _isLoading         = false;
  bool _rememberMe        = false;
  String? _errorMessage;

  late AnimationController _slideController;
  late Animation<Offset>   _slideAnim;
  late Animation<double>   _fadeAnim;

  // ── Design tokens — pulled from teal wave image ──────────────────────────
  static const Color _accent    = Color(0xFF0891b2); // teal-600
  static const Color _bgPanel   = Color(0xFFF8FAFB); // off-white
  static const Color _textDark  = Color(0xFF0F172A); // slate-900
  static const Color _textMid   = Color(0xFF64748B); // slate-500
  static const Color _textLight = Color(0xFFCBD5E1); // slate-300
  static const Color _border    = Color(0xFFE2E8F0); // slate-200

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _slideAnim = Tween<Offset>(
      begin: const Offset(0.06, 0),
      end:   Offset.zero,
    ).animate(CurvedAnimation(
        parent: _slideController, curve: Curves.easeOutCubic));
    _fadeAnim = CurvedAnimation(
        parent: _slideController, curve: Curves.easeOut);
    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    emailController.dispose();
    passController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _errorMessage = null; });

    try {
      final data = await _api.login(
        emailController.text.trim(),
        passController.text,
      );

      final userMap = data['user'] as Map<String, dynamic>;
      AuthService.instance.setUser(AuthUser(
        id:       userMap['id']       as int,
        username: userMap['username'] as String,
        email:    userMap['email']    as String,
        role:     userMap['role']     as String,
        token:    data['token']       as String,
      ));

      if (!mounted) return;

      if (AuthService.instance.currentUser!.isAdmin) {
        Navigator.pushReplacementNamed(context, '/admin');
      } else {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final width     = MediaQuery.of(context).size.width;
    final isDesktop = width > 820;

    return Scaffold(
      backgroundColor: _bgPanel,
      body: isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
    );
  }

  // ── DESKTOP ─────────────────────────────────────────────────────────────────
  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // Left — wave image + branding
        Expanded(
          flex: 55,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset('assets/images/backgroundimg.jpg',
                  fit: BoxFit.cover),
              // Soft fade into white right panel
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerRight,
                    end:   Alignment.centerLeft,
                    colors: [_bgPanel, _bgPanel.withOpacity(0.0)],
                    stops: const [0.0, 0.28],
                  ),
                ),
              ),
              // Branding overlay bottom-left
              Positioned(
                left: 44, bottom: 44,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _dot(),
                    const SizedBox(height: 12),
                    const Text('Welcome\nback.',
                        style: TextStyle(
                          fontSize:      42,
                          fontWeight:    FontWeight.w700,
                          color:         _textDark,
                          height:        1.15,
                          letterSpacing: -0.5,
                        )),
                    const SizedBox(height: 10),
                    Text('Sign in to continue to your workspace.',
                        style: TextStyle(
                            fontSize: 14, color: _textMid)),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Right — clean white panel
        Expanded(
          flex: 45,
          child: Container(
            color: _bgPanel,
            child: Center(
              child: SlideTransition(
                position: _slideAnim,
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: SizedBox(width: 400, child: _buildCard()),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── MOBILE ──────────────────────────────────────────────────────────────────
  Widget _buildMobileLayout() {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset('assets/images/backgroundimg.jpg',
              fit: BoxFit.cover),
        ),
        Positioned.fill(
          child: Container(color: Colors.white.withOpacity(0.65)),
        ),
        SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 40),
              child: SlideTransition(
                position: _slideAnim,
                child: FadeTransition(
                    opacity: _fadeAnim, child: _buildCard()),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── White card ───────────────────────────────────────────────────────────────
  Widget _buildCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 44),
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(20),
        border:       Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color:        const Color(0xFF0891b2).withOpacity(0.10),
            blurRadius:   48,
            spreadRadius: -6,
            offset:       const Offset(0, 20),
          ),
          BoxShadow(
            color:      Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset:     const Offset(0, 4),
          ),
        ],
      ),
      child: _buildForm(),
    );
  }

  // ── Form ────────────────────────────────────────────────────────────────────
  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [

          // Wordmark
          Row(children: [
            _dot(size: 8),
            const SizedBox(width: 8),
            const Text('SAGE',
                style: TextStyle(
                  fontSize:      13,
                  fontWeight:    FontWeight.w700,
                  color:         _textDark,
                  letterSpacing: 4,
                )),
          ]),

          const SizedBox(height: 32),

          const Text('Sign in',
              style: TextStyle(
                fontSize:      28,
                fontWeight:    FontWeight.w700,
                color:         _textDark,
                letterSpacing: -0.5,
                height:        1.1,
              )),
          const SizedBox(height: 6),
          Text('Enter your credentials to continue.',
              style: TextStyle(fontSize: 13, color: _textMid)),

          const SizedBox(height: 32),

          // Error banner
          if (_errorMessage != null) ...[
            Container(
              width:   double.infinity,
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color:        const Color(0xFFfef2f2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFfecaca)),
              ),
              child: Row(children: [
                const Icon(Icons.error_outline,
                    color: Color(0xFFef4444), size: 16),
                const SizedBox(width: 10),
                Expanded(child: Text(_errorMessage!,
                    style: const TextStyle(
                        color: Color(0xFFdc2626), fontSize: 12))),
              ]),
            ),
            const SizedBox(height: 20),
          ],

          // Email
          _label('Email address'),
          const SizedBox(height: 7),
          TextFormField(
            controller:   emailController,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(color: _textDark, fontSize: 14),
            decoration: _inputDeco(
                'you@company.com', Icons.alternate_email_rounded),
            validator: (v) => (v == null || v.isEmpty)
                ? 'Please enter your email' : null,
          ),

          const SizedBox(height: 18),

          // Password
          _label('Password'),
          const SizedBox(height: 7),
          TextFormField(
            controller:  passController,
            obscureText: !_isPasswordVisible,
            style: const TextStyle(color: _textDark, fontSize: 14),
            decoration: _inputDeco(
              '••••••••', Icons.lock_outline_rounded,
              suffix: IconButton(
                icon: Icon(
                  _isPasswordVisible
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: _textLight, size: 18,
                ),
                onPressed: () => setState(
                    () => _isPasswordVisible = !_isPasswordVisible),
              ),
            ),
            validator: (v) => (v == null || v.isEmpty)
                ? 'Please enter your password' : null,
          ),

          const SizedBox(height: 18),

          // Remember me + Forgot
          Row(children: [
            GestureDetector(
              onTap: () =>
                  setState(() => _rememberMe = !_rememberMe),
              child: Row(children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 18, height: 18,
                  decoration: BoxDecoration(
                    color:        _rememberMe ? _accent : Colors.white,
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(
                      color: _rememberMe ? _accent : _textLight,
                      width: 1.5,
                    ),
                  ),
                  child: _rememberMe
                      ? const Icon(Icons.check_rounded,
                          color: Colors.white, size: 12)
                      : null,
                ),
                const SizedBox(width: 8),
                Text('Remember me',
                    style: TextStyle(
                        color: _textMid, fontSize: 12)),
              ]),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () {},
              child: const Text('Forgot password?',
                  style: TextStyle(
                    color:      _accent,
                    fontSize:   12,
                    fontWeight: FontWeight.w500,
                  )),
            ),
          ]),

          const SizedBox(height: 32),

          // Sign in button
          SizedBox(
            width: double.infinity, height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _login,
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent,
                disabledBackgroundColor: _accent.withOpacity(0.4),
                foregroundColor: Colors.white,
                elevation: 0,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation(Colors.white)))
                  : const Text('Continue',
                      style: TextStyle(
                          fontSize:      14,
                          fontWeight:    FontWeight.w600,
                          letterSpacing: 0.2)),
            ),
          ),

          const SizedBox(height: 28),

          // Register link
          Center(
            child: RichText(
              text: TextSpan(
                style: TextStyle(color: _textMid, fontSize: 12),
                children: [
                  const TextSpan(text: "Don't have an account?  "),
                  WidgetSpan(
                    child: GestureDetector(
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(
                              builder: (_) => RegisterPage())),
                      child: const Text('Create one',
                          style: TextStyle(
                            color:      _accent,
                            fontSize:   12,
                            fontWeight: FontWeight.w600,
                          )),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────
  Widget _dot({double size = 6}) => Container(
        width: size, height: size,
        decoration: const BoxDecoration(
            color: _accent, shape: BoxShape.circle));

  Widget _label(String text) => Text(text,
      style: const TextStyle(
        color:         _textDark,
        fontSize:      12,
        fontWeight:    FontWeight.w600,
        letterSpacing: 0.1,
      ));

  InputDecoration _inputDeco(String hint, IconData icon,
      {Widget? suffix}) {
    return InputDecoration(
      hintText:  hint,
      hintStyle: const TextStyle(color: _textLight, fontSize: 14),
      prefixIcon: Padding(
        padding: const EdgeInsets.only(left: 14, right: 10),
        child: Icon(icon, color: _textLight, size: 18),
      ),
      prefixIconConstraints: const BoxConstraints(minWidth: 46),
      suffixIcon:     suffix,
      filled:         true,
      fillColor:      const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide:   const BorderSide(color: _border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide:   const BorderSide(color: _border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: const BorderSide(color: _accent, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: const BorderSide(
            color: Color(0xFFf87171), width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: const BorderSide(
            color: Color(0xFFef4444), width: 1.5),
      ),
      errorStyle: const TextStyle(
          color: Color(0xFFdc2626), fontSize: 11),
    );
  }
}