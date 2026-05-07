import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  RegisterScreenState createState() => RegisterScreenState();
}

class RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _companyController = TextEditingController();
  final _skillsController = TextEditingController();
  String _type = 'jobseeker';
  bool _isLoading = false;

  void _register() async {
    setState(() => _isLoading = true);
    try {
      final result = await ApiService.register(
        _nameController.text,
        _emailController.text,
        _passwordController.text,
        _type,
        company: _type == 'employer' ? _companyController.text : null,
        skills: _type == 'jobseeker'
            ? _skillsController.text.split(',').map((e) => e.trim()).toList()
            : null,
      );
      if (!mounted) return;
      if (result.containsKey('token')) {
        final rawUser = result['user'];
        if (rawUser is Map<String, dynamic>) {
          Provider.of<AuthProvider>(
            context,
            listen: false,
          ).setUser(User.fromJson(rawUser));
        }
        Navigator.pushReplacementNamed(context, '/home');
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Registration failed')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Registration failed')));
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: Container(
        color: const Color(0xFFF7EFE5),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Create your profile',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Register as a student or company to manage your matches and internships.',
                  style: TextStyle(color: Colors.black87, height: 1.5),
                ),
                const SizedBox(height: 28),
                _buildTextField('Full Name', _nameController, false),
                const SizedBox(height: 16),
                _buildTextField('Email', _emailController, false),
                const SizedBox(height: 16),
                _buildTextField('Password', _passwordController, true),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: DropdownButton<String>(
                    value: _type,
                    isExpanded: true,
                    underline: const SizedBox.shrink(),
                    items: const [
                      DropdownMenuItem(
                        value: 'jobseeker',
                        child: Text('Student'),
                      ),
                      DropdownMenuItem(
                        value: 'employer',
                        child: Text('Company'),
                      ),
                    ],
                    onChanged: (value) => setState(() => _type = value!),
                  ),
                ),
                const SizedBox(height: 16),
                if (_type == 'employer')
                  _buildTextField('Company', _companyController, false),
                if (_type == 'jobseeker')
                  _buildTextField(
                    'Skills',
                    _skillsController,
                    false,
                    helper: 'Add comma separated skills',
                  ),
                const SizedBox(height: 24),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: _register,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Text('Register'),
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    bool obscure, {
    String? helper,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        helperText: helper,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
