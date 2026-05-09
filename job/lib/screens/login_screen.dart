// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../utils/app_theme.dart';
import '../widgets/shared_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading       = false;
  bool _obscure       = true;
  String? _error;

  Future<void> _login() async {
    setState(() { _loading = true; _error = null; });
    try {
      final result = await ApiService.login(
          _emailCtrl.text.trim(), _passwordCtrl.text);
      if (!mounted) return;
      if (result.containsKey('token')) {
        final rawUser = result['user'];
        if (rawUser is Map<String, dynamic>) {
          await Provider.of<AuthProvider>(context, listen: false)
              .setUser(User.fromJson(rawUser));
        }
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        setState(() => _error = result['error'] as String? ?? 'Login failed');
      }
    } catch (_) {
      setState(() => _error = 'Network error. Is the server running?');
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(children: [
        // top gradient
        Container(height: 200,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.green, AppColors.burgundy],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.only(
              bottomLeft:  Radius.circular(40),
              bottomRight: Radius.circular(40),
            ),
          ),
        ),
        SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),
                // logo row
                Row(children: const [
                  Icon(Icons.eco, color: Colors.white, size: 24),
                  SizedBox(width: 8),
                  Text('Goinus', style: TextStyle(color: Colors.white,
                      fontSize: 20, fontWeight: FontWeight.w800)),
                ]),
                const SizedBox(height: 40),
                // card
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08),
                        blurRadius: 24, offset: const Offset(0, 10))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('Welcome back',
                          style: TextStyle(fontSize: 24,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      const Text('Login to access your dashboard.',
                          style: TextStyle(color: AppColors.textGrey,
                              height: 1.4)),
                      const SizedBox(height: 26),
                      GoTextField(
                        label: 'Email', controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: Icons.email_outlined,
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _passwordCtrl,
                        obscureText: _obscure,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(_obscure
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined),
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                          ),
                        ),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(_error!,
                              style: TextStyle(color: Colors.red[700],
                                  fontSize: 13)),
                        ),
                      ],
                      const SizedBox(height: 24),
                      _loading
                          ? const LoadingOverlay()
                          : ElevatedButton(
                              onPressed: _login,
                              child: const Text('Login'),
                            ),
                      const SizedBox(height: 14),
                      TextButton(
                        onPressed: () =>
                            Navigator.pushNamed(context, '/register'),
                        child: const Text('New here? Create an account',
                            style: TextStyle(color: AppColors.green)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ]),
    );
  }
}
