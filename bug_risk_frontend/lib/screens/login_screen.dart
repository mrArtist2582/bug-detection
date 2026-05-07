// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../widgets/glitch_text.dart';
import '../widgets/cyber_button.dart';
import '../widgets/cyber_text_field.dart';
import 'dashboard_screen.dart';
import 'repo_connect_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  bool _isLogin = true;
  String? _error;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text.trim();
    if (email.isEmpty || pass.isEmpty) {
      setState(() => _error = 'All fields required');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      if (_isLogin) {
        await AuthService.signIn(email, pass);
      } else {
        await AuthService.signUp(email, pass);
      }
      final profile = await ApiService.verifyUser();
      if (!mounted) return;
      if (profile['hasRepo'] == true) {
        Navigator.pushReplacement(context, _route(DashboardScreen(repo: profile['repo'])));
      } else {
        Navigator.pushReplacement(context, _route(const RepoConnectScreen()));
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _error = _friendlyError(e.code));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _forgotPassword() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      setState(() => _error = 'Enter your email first');
      return;
    }
    try {
      await AuthService.resetPassword(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Password reset email sent'),
            backgroundColor: const Color(0xFF00FF41).withOpacity(0.2),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _error = _friendlyError(e.code));
    }
  }

  String _friendlyError(String code) {
    switch (code) {
      case 'user-not-found': return 'No account found with this email';
      case 'wrong-password': return 'Incorrect password';
      case 'email-already-in-use': return 'Email already registered';
      case 'weak-password': return 'Password must be at least 6 characters';
      case 'invalid-email': return 'Invalid email address';
      case 'invalid-credential': return 'Invalid email or password';
      default: return 'Authentication failed. Try again.';
    }
  }

  PageRoute _route(Widget page) =>
      PageRouteBuilder(pageBuilder: (_, _, _) => page, transitionDuration: Duration.zero);

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isWide = w > 700;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      body: Stack(
        children: [
          _gridBackground(),
          Center(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isWide ? w * 0.3 : 24,
                  vertical: 40,
                ),
                child: Column(
                  children: [
                    _logo(),
                    const SizedBox(height: 40),
                    _card(isWide),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _gridBackground() {
    return CustomPaint(
      painter: _GridPainter(),
      child: const SizedBox.expand(),
    );
  }

  Widget _logo() {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF00FF41), width: 2),
            boxShadow: [BoxShadow(color: const Color(0xFF00FF41).withOpacity(0.3), blurRadius: 20)],
          ),
          child: ClipOval(
            child: Image.asset('assets/logo.png', fit: BoxFit.cover),
          ),
        ),
        const SizedBox(height: 16),
        const GlitchText('BUG RISK ANALYZER', fontSize: 24),
        const SizedBox(height: 6),
        const Text(
          'AI-POWERED COMMIT RISK DETECTION',
          style: TextStyle(color: Color(0xFF00FF41), fontSize: 11, letterSpacing: 3),
        ),
      ],
    );
  }

  Widget _card(bool isWide) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117).withOpacity(0.95),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFF00FF41).withOpacity(0.3)),
        boxShadow: [BoxShadow(color: const Color(0xFF00FF41).withOpacity(0.05), blurRadius: 40)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _tabBtn('LOGIN', _isLogin),
              const SizedBox(width: 8),
              _tabBtn('REGISTER', !_isLogin),
            ],
          ),
          const SizedBox(height: 28),
          CyberTextField(controller: _emailCtrl, label: 'EMAIL', icon: Icons.alternate_email),
          const SizedBox(height: 16),
          CyberTextField(controller: _passCtrl, label: 'PASSWORD', icon: Icons.lock_outline, obscure: true),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.redAccent, size: 14),
                const SizedBox(width: 6),
                Expanded(child: Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 13))),
              ],
            ),
          ],
          const SizedBox(height: 24),
          CyberButton(
            label: _isLogin ? 'INITIALIZE SESSION' : 'CREATE ACCOUNT',
            loading: _loading,
            onPressed: _submit,
          ),
          if (_isLogin) ...[
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: _forgotPassword,
                child: const Text(
                  'FORGOT PASSWORD?',
                  style: TextStyle(color: Color(0xFF58A6FF), fontSize: 12, letterSpacing: 1),
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: () => setState(() { _isLogin = !_isLogin; _error = null; }),
              child: Text(
                _isLogin ? 'NO ACCOUNT? REGISTER' : 'HAVE ACCOUNT? LOGIN',
                style: const TextStyle(color: Color(0xFF8B949E), fontSize: 12, letterSpacing: 1),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabBtn(String label, bool active) {
    return GestureDetector(
      onTap: () => setState(() { _isLogin = label == 'LOGIN'; _error = null; }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF00FF41).withOpacity(0.1) : Colors.transparent,
          border: Border(bottom: BorderSide(color: active ? const Color(0xFF00FF41) : Colors.transparent, width: 2)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? const Color(0xFF00FF41) : const Color(0xFF484F58),
            fontSize: 13,
            letterSpacing: 2,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00FF41).withOpacity(0.03)
      ..strokeWidth = 1;
    const step = 40.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
