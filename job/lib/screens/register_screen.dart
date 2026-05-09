// lib/screens/register_screen.dart
// FIXES:
//   1. Same 'message' vs 'error' key crash as login
//   2. setUser() not awaited before navigation
//   3. Loading spinner not reset in finally block
//   4. Missing mounted guards after every await

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _companyCtrl = TextEditingController();
  final _skillsCtrl = TextEditingController();
  final _majorCtrl = TextEditingController();
  final _gpaCtrl = TextEditingController();

  String _type = 'intern';
  bool _loading = false;
  bool _obscure = true;
  String? _errorMsg;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _companyCtrl.dispose();
    _skillsCtrl.dispose();
    _majorCtrl.dispose();
    _gpaCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      setState(() => _errorMsg = 'Name, email and password are required.');
      return;
    }
    if (password.length < 6) {
      setState(() => _errorMsg = 'Password must be at least 6 characters.');
      return;
    }

    setState(() {
      _loading = true;
      _errorMsg = null;
    });

    try {
      final skills = _skillsCtrl.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      final result = await ApiService.register(
        name,
        email,
        password,
        _type,
        company: _type == 'company' ? _companyCtrl.text.trim() : null,
        skills: _type == 'intern' ? skills : null,
        major: _type == 'intern' ? _majorCtrl.text.trim() : null,
        gpa: (_type == 'intern' && _gpaCtrl.text.isNotEmpty)
            ? double.tryParse(_gpaCtrl.text)
            : null,
      );

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
            'Registration failed. Please try again.';
        setState(() => _errorMsg = msg);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMsg = 'Network error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF0F5132);
    const burgundy = Color(0xFF7B1023);
    const cream = Color(0xFFF7EFE5);

    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        backgroundColor: green,
        foregroundColor: Colors.white,
        title: const Text('Create Account'),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Join Goinus',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Register as a student or company.',
                style: TextStyle(color: Colors.black54, height: 1.4),
              ),
              const SizedBox(height: 24),

              // ── Type selector ─────────────────────────────────────────
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    _TypeTab(
                      label: 'Student',
                      icon: Icons.school_outlined,
                      selected: _type == 'intern',
                      onTap: () => setState(() => _type = 'intern'),
                    ),
                    _TypeTab(
                      label: 'Company',
                      icon: Icons.business_outlined,
                      selected: _type == 'company',
                      onTap: () => setState(() => _type = 'company'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Shared fields ─────────────────────────────────────────
              _Field('Full Name', _nameCtrl, icon: Icons.person_outline),
              const SizedBox(height: 14),
              _Field(
                'Email',
                _emailCtrl,
                icon: Icons.email_outlined,
                type: TextInputType.emailAddress,
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _passwordCtrl,
                obscureText: _obscure,
                decoration: _dec(
                  'Password',
                  icon: Icons.lock_outline,
                  suffix: IconButton(
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // ── Conditional fields ────────────────────────────────────
              if (_type == 'company') ...[
                _Field(
                  'Company Name',
                  _companyCtrl,
                  icon: Icons.business_outlined,
                ),
              ] else ...[
                _Field(
                  'Major / Field of Study',
                  _majorCtrl,
                  icon: Icons.school_outlined,
                ),
                const SizedBox(height: 14),
                _Field(
                  'GPA (e.g. 3.5)',
                  _gpaCtrl,
                  icon: Icons.grade_outlined,
                  type: const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 14),
                _Field(
                  'Skills (comma separated)',
                  _skillsCtrl,
                  icon: Icons.label_outline,
                  hint: 'Python, Excel, Communication…',
                ),
              ],

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

              SizedBox(
                height: 52,
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(color: burgundy),
                      )
                    : ElevatedButton(
                        onPressed: _register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: burgundy,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Create Account',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
              ),
              const SizedBox(height: 14),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Already have an account? Login',
                  style: TextStyle(color: green),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _dec(
    String label, {
    IconData? icon,
    Widget? suffix,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: icon != null ? Icon(icon) : null,
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF0F5132), width: 1.5),
      ),
    );
  }

  Widget _Field(
    String label,
    TextEditingController ctrl, {
    IconData? icon,
    TextInputType? type,
    String? hint,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      autocorrect: false,
      decoration: _dec(label, icon: icon, hint: hint),
    );
  }
}

class _TypeTab extends StatelessWidget {
  const _TypeTab({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF0F5132);
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.all(4),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? green : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected ? Colors.white : Colors.grey,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : Colors.grey,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
