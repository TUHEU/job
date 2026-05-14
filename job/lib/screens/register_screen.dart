// lib/screens/register_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../utils/app_theme.dart';

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
      setState(() => _errorMsg = 'All fields are required.');
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
            result['error'] as String ??
            result['message'] as String ??
            'Registration failed.';
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
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('Create Account'), elevation: 0),
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
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Register as a student or company',
                style: TextStyle(color: AppColors.textGrey),
              ),
              const SizedBox(height: 24),
              // Type selector
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
              // Fields
              _buildField('Full Name', _nameCtrl, Icons.person_outline),
              const SizedBox(height: 14),
              _buildField(
                'Email',
                _emailCtrl,
                Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _passwordCtrl,
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
              if (_type == 'company') ...[
                const SizedBox(height: 14),
                _buildField(
                  'Company Name',
                  _companyCtrl,
                  Icons.business_outlined,
                ),
              ] else ...[
                const SizedBox(height: 14),
                _buildField('Major', _majorCtrl, Icons.school_outlined),
                const SizedBox(height: 14),
                _buildField(
                  'GPA',
                  _gpaCtrl,
                  Icons.grade_outlined,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 14),
                _buildField(
                  'Skills (comma separated)',
                  _skillsCtrl,
                  Icons.code_outlined,
                ),
              ],
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
                    style: TextStyle(color: Colors.red.shade700),
                  ),
                ),
              ],
              const SizedBox(height: 32),
              SizedBox(
                height: 52,
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.burgundy,
                        ),
                      )
                    : ElevatedButton(
                        onPressed: _register,
                        child: const Text('Create Account'),
                      ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Already have an account? Login',
                  style: TextStyle(color: AppColors.green),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller,
    IconData icon, {
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
    );
  }
}

class _TypeTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _TypeTab({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.all(4),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppColors.green : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected ? Colors.white : AppColors.textGrey,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : AppColors.textGrey,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
