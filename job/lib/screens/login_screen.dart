// lib/screens/login_screen.dart
// FIXES:
//   1. result['message'] → null crash  (backend returns 'error', not 'message')
//   2. setUser() not awaited            (caused race condition before navigation)
//   3. Loading spinner never reset      (if exception thrown before setState)
//   4. No error shown for network down  (SocketException swallowed silently)
//   5. Navigator called after dispose   (missing mounted check after await)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscure = true;
  String? _errorMsg;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ── Login logic ────────────────────────────────────────────────────────────
  Future<void> _login() async {
    // Basic validation before hitting the network
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMsg = 'Please enter your email and password.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });

    try {
      final result = await ApiService.login(email, password);

      // FIX: guard every Navigator call with mounted check
      if (!mounted) return;

      if (result.containsKey('token')) {
        // ── Success path ──────────────────────────────────────────────────
        final rawUser = result['user'];
        if (rawUser is Map<String, dynamic>) {
          // FIX: await setUser so Provider state is ready before navigation
          await Provider.of<AuthProvider>(
            context,
            listen: false,
          ).setUser(User.fromJson(rawUser));
        }
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        // ── Error path ────────────────────────────────────────────────────
        // FIX: backend sends 'error' key, NOT 'message'
        final msg =
            result['error'] as String? ??
            result['message'] as String? ??
            'Login failed. Please try again.';
        setState(() => _errorMsg = msg);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMsg = 'Network error: $e');
    } finally {
      // FIX: always reset spinner, even when exception is thrown
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── UI ─────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF0F5132);
    const burgundy = Color(0xFF7B1023);
    const cream = Color(0xFFF7EFE5);

    return Scaffold(
      backgroundColor: cream,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),

              // ── Logo ──────────────────────────────────────────────────
              Row(
                children: const [
                  Icon(Icons.eco, color: green, size: 28),
                  SizedBox(width: 8),
                  Text(
                    'Goinus',
                    style: TextStyle(
                      color: green,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 36),

              // ── Heading ───────────────────────────────────────────────
              const Text(
                'Welcome back',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Login to access your matches and internship dashboard.',
                style: TextStyle(color: Colors.black54, height: 1.5),
              ),
              const SizedBox(height: 32),

              // ── Email ─────────────────────────────────────────────────
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autocorrect: false,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: const Icon(Icons.email_outlined),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: green, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Password ──────────────────────────────────────────────
              TextField(
                controller: _passwordController,
                obscureText: _obscure,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _login(),
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: green, width: 1.5),
                  ),
                ),
              ),

              // ── Error banner ──────────────────────────────────────────
              if (_errorMsg != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.red[700],
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _errorMsg!,
                          style: TextStyle(
                            color: Colors.red[700],
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 28),

              // ── Login button ──────────────────────────────────────────
              SizedBox(
                height: 52,
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: burgundy),
                      )
                    : ElevatedButton(
                        onPressed: _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: burgundy,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Login',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
              ),

              const SizedBox(height: 16),

              // ── Register link ─────────────────────────────────────────
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/register'),
                child: const Text(
                  "Don't have an account? Sign up",
                  style: TextStyle(color: green),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
