import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:frontend_sage3/pages/auth/LoginPage.dart';
import 'package:frontend_sage3/pages/client/HomePage.dart';

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

  bool _isPasswordVisible        = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading                = false;
  bool _acceptTerms              = false;

  late AnimationController _fadeController;
  late Animation<double>   _fadeAnim;

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
    fullNameController.dispose();
    emailController.dispose();
    passController.dispose();
    confirmPassController.dispose();
    super.dispose();
  }

  void _handleRegister() {
    if (_formKey.currentState!.validate()) {
      if (!_acceptTerms) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please accept the terms and conditions'),
            backgroundColor: Color(0xFFef4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        return;
      }
      setState(() => _isLoading = true);
      Future.delayed(Duration(seconds: 2), () {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Account created successfully!'),
            backgroundColor: Color(0xFF10b981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomePage()));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final width     = MediaQuery.of(context).size.width;
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

          // ── Gradient overlay (same as LoginPage) ────────────
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

  // ─── Glass card ────────────────────────────────────────────
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

  // ─── Form ──────────────────────────────────────────────────
  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 24),
          Center(
            child: Text('Create Account',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Colors.white)
            ),
          ),
          SizedBox(height: 30),
          // ── Full name ──────────────────────────────────────
          _label('Full name'),
          SizedBox(height: 7),
          TextFormField(
            controller: fullNameController,
            style: TextStyle(color: Colors.white, fontSize: 14),
            decoration: _inputDeco('John Doe', Icons.person_outline),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Please enter your name';
              if (v.length < 3) return 'Name must be at least 3 characters';
              return null;
            },
          ),

          SizedBox(height: 16),

          // ── Email ──────────────────────────────────────────
          _label('Email address'),
          SizedBox(height: 7),
          TextFormField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            style: TextStyle(color: Colors.white, fontSize: 14),
            decoration: _inputDeco('you@company.com', Icons.email_outlined),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Please enter your email';
              if (!v.contains('@')) return 'Please enter a valid email';
              return null;
            },
          ),

          SizedBox(height: 16),

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
            validator: (v) {
              if (v == null || v.isEmpty) return 'Please enter a password';
              if (v.length < 6) return 'Password must be at least 6 characters';
              return null;
            },
          ),

          SizedBox(height: 16),

          // ── Confirm password ───────────────────────────────
          _label('Confirm password'),
          SizedBox(height: 7),
          TextFormField(
            controller: confirmPassController,
            obscureText: !_isConfirmPasswordVisible,
            style: TextStyle(color: Colors.white, fontSize: 14),
            decoration: _inputDeco(
              '••••••••',
              Icons.lock_outline,
              suffix: IconButton(
                icon: Icon(
                  _isConfirmPasswordVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  color: Colors.white38,
                  size: 20,
                ),
                onPressed: () => setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Please confirm your password';
              if (v != passController.text) return 'Passwords do not match';
              return null;
            },
          ),

          SizedBox(height: 18),

          // ── Accept terms ───────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: Checkbox(
                  value: _acceptTerms,
                  onChanged: (v) => setState(() => _acceptTerms = v!),
                  activeColor: Color(0xFF3b82f6),
                  side: BorderSide(color: Colors.white30, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(fontSize: 13, color: Colors.white54),
                    children: [
                      TextSpan(text: 'I agree to the '),
                      TextSpan(
                        text: 'Terms & Conditions',
                        style: TextStyle(color: Color(0xFF93c5fd), fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 28),

          // ── Create account button ──────────────────────────
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleRegister,
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
                  Text('Create Account', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.3)),
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

          // ── Login link ─────────────────────────────────────
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Already have an account? ', style: TextStyle(color: Colors.white, fontSize: 13)),
                GestureDetector(
                  onTap: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => LoginPage()),
                  ),
                  child: Text(
                    'Sign in',
                    style: TextStyle(color: Color(0xFF93c5fd), fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
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