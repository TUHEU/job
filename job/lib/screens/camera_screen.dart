// lib/screens/camera_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../utils/app_theme.dart';
import '../widgets/shared_widgets.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  XFile? _image;
  bool _sending = false;

  Future<void> _pickCamera() async {
    try {
      final picker = ImagePicker();
      final photo = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1600,
        maxHeight: 1200,
        imageQuality: 85,
      );
      if (photo != null && mounted) setState(() => _image = photo);
    } catch (_) {
      _showSnackbar('Could not open camera.', error: true);
    }
  }

  Future<void> _pickGallery() async {
    try {
      final picker = ImagePicker();
      final photo = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        maxHeight: 1200,
        imageQuality: 85,
      );
      if (photo != null && mounted) setState(() => _image = photo);
    } catch (_) {
      _showSnackbar('Could not open gallery.', error: true);
    }
  }

  Future<void> _upload() async {
    if (_image == null) return;
    setState(() => _sending = true);
    final res = await ApiService.sendPicture(File(_image!.path));
    if (!mounted) return;
    setState(() => _sending = false);
    _showSnackbar(
      res['message'] as String? ?? res['error'] as String? ?? 'Upload complete',
      error: res.containsKey('error'),
    );
    if (!res.containsKey('error')) Navigator.pop(context);
  }

  void _showSnackbar(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? Colors.red : AppColors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('Profile Photo')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const GradientBanner(
            title: 'Upload Profile Photo',
            subtitle: 'A professional photo helps recruiters recognise you.',
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 12,
                ),
              ],
            ),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: _image == null
                      ? Container(
                          height: 280,
                          color: AppColors.inputFill,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(
                                Icons.person_outline,
                                size: 72,
                                color: AppColors.textGrey,
                              ),
                              SizedBox(height: 12),
                              Text('No photo selected'),
                              SizedBox(height: 4),
                              Text(
                                'Tap a button below to get started.',
                                style: TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        )
                      : Image.file(
                          File(_image!.path),
                          height: 280,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickCamera,
                        icon: const Icon(Icons.camera_alt_outlined),
                        label: const Text('Camera'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.green,
                          side: const BorderSide(color: AppColors.green),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickGallery,
                        icon: const Icon(Icons.photo_library_outlined),
                        label: const Text('Gallery'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.burgundy,
                          side: const BorderSide(color: AppColors.burgundy),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _sending
                    ? const LoadingOverlay()
                    : ElevatedButton.icon(
                        onPressed: _image == null ? null : _upload,
                        icon: const Icon(Icons.cloud_upload_outlined),
                        label: Text(
                          _image == null
                              ? 'Select a photo first'
                              : 'Upload Photo',
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
