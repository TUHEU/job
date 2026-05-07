import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../models/user.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  ProfileScreenState createState() => ProfileScreenState();
}

class ProfileScreenState extends State<ProfileScreen> {
  bool _isUploading = false;
  final _gpaController = TextEditingController();
  final _aboutMeController = TextEditingController();
  final _educationController = TextEditingController();

  Future<void> _uploadDocument() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'png'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() => _isUploading = true);
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Document uploaded successfully')),
      );
    }
  }

  void _saveProfile() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Profile saved successfully')));
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user =
        authProvider.user ??
        User(
          id: 'guest',
          name: 'Guest User',
          email: 'guest@jobmatch.cameroon',
          type: 'intern',
          skills: ['Local hiring', 'Career coaching'],
        );

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionCard(
            title: 'Personal Info',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Name', user.name),
                _buildInfoRow('Email', user.email),
                if (user.type == 'company')
                  _buildInfoRow('Company', user.company ?? 'N/A'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            title: 'Academic Info',
            child: Column(
              children: [
                _buildTextField(
                  'GPA',
                  _gpaController,
                  user.gpa?.toStringAsFixed(2) ?? 'Enter GPA',
                ),
                const SizedBox(height: 14),
                _buildTextField(
                  'Education',
                  _educationController,
                  user.educationHistory ?? 'Your degree and institution',
                ),
                const SizedBox(height: 14),
                _buildTextField(
                  'About',
                  _aboutMeController,
                  user.aboutMe ?? 'Short summary of your academic profile',
                  multiline: true,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _saveProfile,
                  child: const Text('Save'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            title: 'Documents',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (user.documents != null && user.documents!.isNotEmpty)
                  ...user.documents!.map(
                    (doc) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text('- $doc'),
                    ),
                  )
                else
                  const Text('No documents uploaded.'),
                const SizedBox(height: 18),
                _isUploading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton.icon(
                        onPressed: _uploadDocument,
                        icon: const Icon(Icons.upload_file),
                        label: const Text('Upload Document'),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '$label:',
              style: const TextStyle(color: Colors.black54),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    String hint, {
    bool multiline = false,
  }) {
    return TextField(
      controller: controller,
      maxLines: multiline ? 4 : 1,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFF5F2EE),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
