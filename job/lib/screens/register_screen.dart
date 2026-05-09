// lib/screens/register_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../utils/app_theme.dart';
import '../widgets/shared_widgets.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameCtrl     = TextEditingController();
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _companyCtrl  = TextEditingController();
  final _skillsCtrl   = TextEditingController();
  final _majorCtrl    = TextEditingController();
  final _gpaCtrl      = TextEditingController();

  String _type    = 'intern';
  bool _loading   = false;
  bool _obscure   = true;
  String? _error;

  Future<void> _register() async {
    if (_nameCtrl.text.trim().isEmpty || _emailCtrl.text.trim().isEmpty ||
        _passwordCtrl.text.isEmpty) {
      setState(() => _error = 'Please fill in all required fields.');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final skills = _skillsCtrl.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      final result = await ApiService.register(
        _nameCtrl.text.trim(),
        _emailCtrl.text.trim(),
        _passwordCtrl.text,
        _type,
        company: _type == 'company' ? _companyCtrl.text.trim() : null,
        skills:  _type == 'intern'  ? skills : null,
        major:   _type == 'intern'  ? _majorCtrl.text.trim() : null,
        gpa:     _type == 'intern' && _gpaCtrl.text.isNotEmpty
            ? double.tryParse(_gpaCtrl.text) : null,
      );

      if (!mounted) return;
      if (result.containsKey('token')) {
        final rawUser = result['user'];
        if (rawUser is Map<String, dynamic>) {
          await Provider.of<AuthProvider>(context, listen: false)
              .setUser(User.fromJson(rawUser));
        }
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        setState(() =>
            _error = result['error'] as String? ?? 'Registration failed');
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
        Container(
          height: 180,
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
                Row(children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Icon(Icons.eco, color: Colors.white, size: 22),
                  const SizedBox(width: 6),
                  const Text('Goinus', style: TextStyle(color: Colors.white,
                      fontSize: 18, fontWeight: FontWeight.w800)),
                ]),
                const SizedBox(height: 30),
                Container(
                  padding: const EdgeInsets.all(26),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 24, offset: const Offset(0, 10))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('Create Account',
                          style: TextStyle(fontSize: 22,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      const Text('Join Goinus as a student or company.',
                          style: TextStyle(color: AppColors.textGrey)),
                      const SizedBox(height: 22),

                      // ── Account type toggle ───────────────────────────
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.inputFill,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(children: [
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
                        ]),
                      ),
                      const SizedBox(height: 20),

                      GoTextField(label: 'Full Name', controller: _nameCtrl,
                          prefixIcon: Icons.person_outline),
                      const SizedBox(height: 14),
                      GoTextField(label: 'Email', controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          prefixIcon: Icons.email_outlined),
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
                      const SizedBox(height: 14),

                      // ── Conditional fields ────────────────────────────
                      if (_type == 'company') ...[
                        GoTextField(label: 'Company Name',
                            controller: _companyCtrl,
                            prefixIcon: Icons.business_outlined),
                      ] else ...[
                        GoTextField(label: 'Major / Field of Study',
                            controller: _majorCtrl,
                            prefixIcon: Icons.school_outlined),
                        const SizedBox(height: 14),
                        GoTextField(label: 'GPA (e.g. 3.5)',
                            controller: _gpaCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            prefixIcon: Icons.grade_outlined),
                        const SizedBox(height: 14),
                        GoTextField(
                          label: 'Skills (comma separated)',
                          controller: _skillsCtrl,
                          hint: 'Python, Excel, Communication…',
                          prefixIcon: Icons.label_outline,
                        ),
                      ],

                      if (_error != null) ...[
                        const SizedBox(height: 14),
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
                              onPressed: _register,
                              child: const Text('Create Account'),
                            ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Already have an account? Login',
                            style: TextStyle(color: AppColors.green)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
              ],
            ),
          ),
        ),
      ]),
    );
  }
}

class _TypeTab extends StatelessWidget {
  const _TypeTab({
    required this.label, required this.icon,
    required this.selected, required this.onTap,
  });
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(4),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppColors.green : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, size: 16,
                color: selected ? Colors.white : AppColors.textGrey),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(
                color: selected ? Colors.white : AppColors.textGrey,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 13)),
          ]),
        ),
      ),
    );
  }
}
