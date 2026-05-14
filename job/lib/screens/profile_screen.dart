// lib/screens/profile_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../models/user.dart';
import '../utils/app_theme.dart';
import '../widgets/shared_widgets.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _gpaCtrl = TextEditingController();
  final _aboutCtrl = TextEditingController();
  final _educCtrl = TextEditingController();
  final _majorCtrl = TextEditingController();
  final _skillsCtrl = TextEditingController();
  final _companyCtrl = TextEditingController();
  final _industryCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();

  bool _uploading = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _prefill();
  }

  @override
  void dispose() {
    _gpaCtrl.dispose();
    _aboutCtrl.dispose();
    _educCtrl.dispose();
    _majorCtrl.dispose();
    _skillsCtrl.dispose();
    _companyCtrl.dispose();
    _industryCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  void _prefill() {
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    _gpaCtrl.text = user.gpa?.toStringAsFixed(2) ?? '';
    _aboutCtrl.text = user.aboutMe ?? '';
    _educCtrl.text = user.educationHistory ?? '';
    _majorCtrl.text = user.major ?? '';
    _skillsCtrl.text = user.skills?.join(', ') ?? '';
    _companyCtrl.text = user.company ?? '';
    _industryCtrl.text = user.industry ?? '';
    _locationCtrl.text = user.location ?? '';
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.user;

    final Map<String, dynamic> payload;
    if (user.isIntern) {
      payload = {
        'gpa': double.tryParse(_gpaCtrl.text),
        'aboutMe': _aboutCtrl.text,
        'educationHistory': _educCtrl.text,
        'major': _majorCtrl.text,
        'skills': _skillsCtrl.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList(),
      };
    } else {
      payload = {
        'companyName': _companyCtrl.text,
        'industry': _industryCtrl.text,
        'location': _locationCtrl.text,
        'about': _aboutCtrl.text,
      };
    }

    final res = await ApiService.updateProfile(payload);
    if (!mounted) return;

    if (res.containsKey('user')) {
      await auth.setUser(User.fromJson(res['user'] as Map<String, dynamic>));
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          res['message'] as String? ??
              res['error'] as String? ??
              'Profile saved',
        ),
        backgroundColor: res.containsKey('error')
            ? Colors.red
            : AppColors.green,
      ),
    );
    if (mounted) setState(() => _saving = false);
  }

  // FIXED: Using image_picker instead of file_picker
  Future<void> _uploadDoc() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? file = await picker.pickImage(source: ImageSource.gallery);

      if (file == null) return;

      setState(() => _uploading = true);

      final res = await ApiService.uploadCV(File(file.path));

      if (!mounted) return;

      if (res.containsKey('error')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['error'] as String),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              res['message'] as String? ?? 'File uploaded successfully!',
            ),
            backgroundColor: AppColors.green,
          ),
        );

        // Refresh user data
        final auth = Provider.of<AuthProvider>(context, listen: false);
        final me = await ApiService.getMe();
        if (me != null) {
          await auth.setUser(User.fromJson(me));
        }
      }

      if (mounted) setState(() => _uploading = false);
    } catch (e) {
      if (mounted) {
        setState(() => _uploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _logout() async {
    await ApiService.clearToken();
    if (!mounted) return;
    await Provider.of<AuthProvider>(context, listen: false).clearAuth();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ProfileHeader(user: user),
          const SizedBox(height: 16),
          _Section(
            title: 'Personal Info',
            child: Column(
              children: [
                _InfoRow('Name', user.name),
                _InfoRow('Email', user.email),
                _InfoRow('Role', user.isIntern ? 'Student' : 'Company'),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (user.isIntern)
            _Section(
              title: 'Academic Info',
              child: Column(
                children: [
                  GoTextField(
                    label: 'GPA',
                    controller: _gpaCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    prefixIcon: Icons.grade_outlined,
                  ),
                  const SizedBox(height: 12),
                  GoTextField(
                    label: 'Major',
                    controller: _majorCtrl,
                    prefixIcon: Icons.school_outlined,
                  ),
                  const SizedBox(height: 12),
                  GoTextField(
                    label: 'Skills (comma separated)',
                    controller: _skillsCtrl,
                    prefixIcon: Icons.code_outlined,
                  ),
                  const SizedBox(height: 12),
                  GoTextField(
                    label: 'Education History',
                    controller: _educCtrl,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  GoTextField(
                    label: 'About Me',
                    controller: _aboutCtrl,
                    maxLines: 4,
                  ),
                ],
              ),
            )
          else
            _Section(
              title: 'Company Info',
              child: Column(
                children: [
                  GoTextField(
                    label: 'Company Name',
                    controller: _companyCtrl,
                    prefixIcon: Icons.business_outlined,
                  ),
                  const SizedBox(height: 12),
                  GoTextField(
                    label: 'Industry',
                    controller: _industryCtrl,
                    prefixIcon: Icons.category_outlined,
                  ),
                  const SizedBox(height: 12),
                  GoTextField(
                    label: 'Location',
                    controller: _locationCtrl,
                    prefixIcon: Icons.location_on_outlined,
                  ),
                  const SizedBox(height: 12),
                  GoTextField(
                    label: 'About',
                    controller: _aboutCtrl,
                    maxLines: 4,
                  ),
                ],
              ),
            ),
          const SizedBox(height: 14),
          _saving
              ? const LoadingOverlay()
              : ElevatedButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Save Profile'),
                ),
          const SizedBox(height: 20),
          _Section(
            title: 'Documents',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (user.documents != null && user.documents!.isNotEmpty)
                  ...user.documents!.map(
                    (d) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.picture_as_pdf_outlined,
                            size: 16,
                            color: AppColors.burgundy,
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: Text(d)),
                        ],
                      ),
                    ),
                  )
                else
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Text(
                      'No documents uploaded yet.',
                      style: TextStyle(color: AppColors.textGrey),
                    ),
                  ),
                const SizedBox(height: 14),
                _uploading
                    ? const Center(child: CircularProgressIndicator())
                    : OutlinedButton.icon(
                        onPressed: _uploadDoc,
                        icon: const Icon(Icons.upload_file),
                        label: const Text('Upload CV/Resume'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.green,
                          side: const BorderSide(color: AppColors.green),
                        ),
                      ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/camera'),
            icon: const Icon(Icons.camera_alt_outlined),
            label: const Text('Update Profile Photo'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.burgundy,
              side: const BorderSide(color: AppColors.burgundy),
            ),
          ),
          const SizedBox(height: 28),
        ],
      ),
      bottomNavigationBar: GoBottomNav(
        currentIndex: 3,
        onTap: (i) {
          const routes = ['/home', '/matches', '/applications', '/profile'];
          if (i != 3) Navigator.pushNamed(context, routes[i]);
        },
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final User user;
  const _ProfileHeader({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.green, AppColors.greenLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.green.withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 34,
            backgroundColor: Colors.white.withOpacity(0.25),
            child: Text(
              user.name.isNotEmpty ? user.name[0].toUpperCase() : 'G',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  user.email,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                if (user.gpa != null) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'GPA ${user.gpa!.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label, value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(
              '$label:',
              style: const TextStyle(color: AppColors.textGrey, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: AppColors.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
