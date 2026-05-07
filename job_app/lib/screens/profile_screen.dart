import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  ProfileScreenState createState() => ProfileScreenState();
}

class ProfileScreenState extends State<ProfileScreen> {
  bool _isUploading = false;

  Future<void> _uploadCV() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() => _isUploading = true);
      try {
        final cvFile = File(result.files.single.path!);
        final response = await ApiService.uploadCV(cvFile);
        if (!mounted) return;
        if (response['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('CV uploaded successfully')),
          );
          // Optionally refresh user data
          final authProvider = Provider.of<AuthProvider>(
            context,
            listen: false,
          );
          // Assuming backend returns updated user data
          if (response['user'] != null) {
            authProvider.setUser(response['user']);
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'Failed to upload CV'),
            ),
          );
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to upload CV')));
      }
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;

    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Name: ${user?.name ?? 'N/A'}'),
                  const SizedBox(height: 8),
                  Text('Email: ${user?.email ?? 'N/A'}'),
                  const SizedBox(height: 8),
                  if (user?.type == 'employer')
                    Text('Company: ${user?.company ?? 'N/A'}'),
                  if (user?.type == 'jobseeker') ...[
                    const SizedBox(height: 8),
                    Text('Skills: ${user?.skills?.join(', ') ?? 'None'}'),
                    const SizedBox(height: 16),
                    const Text(
                      'CV Status',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    user?.cvPath != null
                        ? const Text(
                            'CV uploaded',
                            style: TextStyle(color: Colors.green),
                          )
                        : const Text(
                            'No CV uploaded',
                            style: TextStyle(color: Colors.red),
                          ),
                    const SizedBox(height: 16),
                    _isUploading
                        ? const CircularProgressIndicator()
                        : ElevatedButton.icon(
                            onPressed: _uploadCV,
                            icon: const Icon(Icons.upload_file),
                            label: const Text('Upload CV'),
                          ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
