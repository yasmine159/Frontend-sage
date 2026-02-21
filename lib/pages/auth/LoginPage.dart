import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:frontend_sage3/pages/auth/RegisterPage.dart';
import 'package:frontend_sage3/pages/client/HomePage.dart';
import 'package:frontend_sage3/pages/admin/AdminDashboardPage.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isPasswordVisible = false;
  bool _isLoading = false;
  bool _rememberMe = false;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(vsync: this, duration: Duration(milliseconds: 800));
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    emailController.dispose();
    passController.dispose();
    super.dispose();
  }

  void _login() {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      Future.delayed(Duration(seconds: 1), () {
        setState(() => _isLoading = false);
        if (emailController.text.contains('admin')) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => AdminDashboardPage()));
        } else {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomePage()));
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 900;

    return Scaffold(
      body: Stack(
        children: [
          // ── Background image ────────────────────────────────
          Positioned.fill(
            child: Image.asset(
              "assets/images/backgroundimg.jpg",
              fit: BoxFit.cover,
            ),
          ),

          // ── Gradient overlay (dark + blue tint) ────────────
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.black.withOpacity(0.55),
                    Color(0xFF1e3a8a).withOpacity(0.30),
                    Colors.black.withOpacity(0.50),
                  ],
                ),
              ),
            ),
          ),

          // ── Content ─────────────────────────────────────────
          Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: FadeTransition(
                opacity: _fadeAnim,
                child: Center(
                  child: SizedBox(
                    width: isDesktop ? 460 : double.infinity,
                    child: _buildGlassCard(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Glass card with BackdropFilter blur ──────────────────
  Widget _buildGlassCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 36, vertical: 44),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.11),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 60,
                spreadRadius: -8,
                offset: Offset(0, 30),
              ),
            ],
          ),
          child: _buildForm(),
        ),
      ),
    );
  }

  // ─── Form ─────────────────────────────────────────────────
  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [



          SizedBox(height: 20),

          Center(
            child: Text(
              'Login',
              style: TextStyle(
                fontSize: 22, // slightly larger for better hierarchy
                fontWeight: FontWeight.w600, // modern professional weight
                color: Colors.white,
                letterSpacing: 1.0, // subtle spacing for elegance
              ),
            ),
          ),

          SizedBox(height: 20),

          // ── Email ──────────────────────────────────────────
          _label('Email address'),
          SizedBox(height: 7),
          TextFormField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            style: TextStyle(color: Colors.white, fontSize: 14),
            decoration: _inputDeco('you@company.com', Icons.email_outlined),
            validator: (v) => (v == null || v.isEmpty) ? 'Please enter your email' : null,
          ),

          SizedBox(height: 18),

          // ── Password ───────────────────────────────────────
          _label('Password'),
          SizedBox(height: 7),
          TextFormField(
            controller: passController,
            obscureText: !_isPasswordVisible,
            style: TextStyle(color: Colors.white, fontSize: 14),
            decoration: _inputDeco(
              '••••••••',
              Icons.lock_outline,
              suffix: IconButton(
                icon: Icon(
                  _isPasswordVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  color: Colors.white38,
                  size: 20,
                ),
                onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
              ),
            ),
            validator: (v) => (v == null || v.isEmpty) ? 'Please enter your password' : null,
          ),

          SizedBox(height: 16),

          // ── Remember me + Forgot password ──────────────────
          Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: Checkbox(
                  value: _rememberMe,
                  onChanged: (v) => setState(() => _rememberMe = v!),
                  activeColor: Color(0xFF3b82f6),
                  side: BorderSide(color: Colors.white30, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
              ),
              SizedBox(width: 8),
              Text('Remember me', style: TextStyle(color: Colors.white54, fontSize: 13)),
              Spacer(),
              GestureDetector(
                onTap: () {},
                child: Text(
                  'Forgot password?',
                  style: TextStyle(
                    color: Color(0xFF93c5fd),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 32),

          // ── Sign in button ─────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _login,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF3b82f6),
                disabledBackgroundColor: Color(0xFF3b82f6).withOpacity(0.4),
                foregroundColor: Colors.white,
                elevation: 0,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _isLoading
                  ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
                  : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Sign In', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.3)),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded, size: 18),
                ],
              ),
            ),
          ),

          SizedBox(height: 28),

          // ── OR divider ─────────────────────────────────────
          Row(
            children: [
              Expanded(child: Divider(color: Colors.white.withOpacity(0.12), thickness: 1)),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 14),
                child: Text('OR', style: TextStyle(color: Colors.white30, fontSize: 11, letterSpacing: 2)),
              ),
              Expanded(child: Divider(color: Colors.white.withOpacity(0.12), thickness: 1)),
            ],
          ),

          SizedBox(height: 24),

          // ── Register link ──────────────────────────────────
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Don't have an account? ", style: TextStyle(color: Colors.white, fontSize: 13)),
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RegisterPage())),
                  child: Text(
                    'Create account',
                    style: TextStyle(color: Color(0xFF93c5fd), fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 20),

          // ── Test credentials (discreet) ────────────────────

        ],
      ),
    );
  }

  // ─── Helpers ───────────────────────────────────────────────
  Widget _label(String text) {
    return Text(
      text,
      style: TextStyle(
        color: Colors.white.withOpacity(0.75),
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      ),
    );
  }

  InputDecoration _inputDeco(String hint, IconData icon, {Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.white24, fontSize: 14),
      prefixIcon: Padding(
        padding: EdgeInsets.only(left: 14, right: 10),
        child: Icon(icon, color: Colors.white38, size: 20),
      ),
      prefixIconConstraints: BoxConstraints(minWidth: 48),
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white.withOpacity(0.08),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.12), width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.12), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Color(0xFF3b82f6), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Color(0xFFf87171).withOpacity(0.8), width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Color(0xFFf87171), width: 1.5),
      ),
      errorStyle: TextStyle(color: Color(0xFFfca5a5), fontSize: 11),
    );
  }
}