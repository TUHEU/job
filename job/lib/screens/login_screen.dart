// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../utils/app_theme.dart';

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

  Future<void> _login() async {
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
      if (!mounted) return;

      if (result.containsKey('token')) {
        final rawUser = result['user'];
        if (rawUser is Map<String, dynamic>) {
          await Provider.of<AuthProvider>(
            context,
            listen: false,
          ).setUser(User.fromJson(rawUser));
        }
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        final msg =
            result['error'] as String? ??
            result['message'] as String? ??
            'Login failed.';
        setState(() => _errorMsg = msg);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMsg = 'Network error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              // Logo
              const Row(
                children: [
                  Icon(Icons.eco, color: AppColors.green, size: 28),
                  SizedBox(width: 8),
                  Text(
                    'Goinus',
                    style: TextStyle(
                      color: AppColors.green,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              // Heading
              const Text(
                'Welcome Back',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Login to access your account',
                style: TextStyle(color: AppColors.textGrey),
              ),
              const SizedBox(height: 32),
              // Email
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 16),
              // Password
              TextField(
                controller: _passwordController,
                obscureText: _obscure,
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
                ),
              ),
              if (_errorMsg != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _errorMsg!,
                    style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                  ),
                ),
              ],
              const SizedBox(height: 32),
              SizedBox(
                height: 52,
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.burgundy,
                        ),
                      )
                    : ElevatedButton(
                        onPressed: _login,
                        child: const Text(
                          'Login',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/register'),
                child: const Text(
                  "Don't have an account? Sign up",
                  style: TextStyle(color: AppColors.green),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
