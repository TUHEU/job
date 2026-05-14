// lib/screens/application_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../models/application.dart';
import '../providers/auth_provider.dart';
import '../providers/application_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/shared_widgets.dart';

class ApplicationDetailScreen extends StatefulWidget {
  final String applicationId;
  const ApplicationDetailScreen({super.key, required this.applicationId});

  @override
  State<ApplicationDetailScreen> createState() =>
      _ApplicationDetailScreenState();
}

class _ApplicationDetailScreenState extends State<ApplicationDetailScreen> {
  InternshipApplication? _application;
  bool _loading = true;
  bool _updating = false;

  @override
  void initState() {
    super.initState();
    _loadApplication();
  }

  Future<void> _loadApplication() async {
    try {
      final apps = await ApiService.getApplications();

      // FIXED: Use a simple loop instead of firstWhere to avoid type issues
      InternshipApplication? foundApp;
      for (var app in apps) {
        if (app.id == widget.applicationId) {
          foundApp = app;
          break;
        }
      }

      if (mounted) {
        setState(() {
          _application = foundApp;
          _loading = false;
        });
      }
    } catch (e) {
      print('Error loading application: $e');
      if (mounted) {
        setState(() {
          _loading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading application: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateStatus(String status) async {
    setState(() => _updating = true);
    final provider = Provider.of<ApplicationProvider>(context, listen: false);
    final success = await provider.updateApplicationStatus(
      widget.applicationId,
      status,
    );

    if (mounted) {
      setState(() => _updating = false);
      if (success) {
        await _loadApplication();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Application $status'),
            backgroundColor: AppColors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update status'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final isCompany = auth.isCompany;

    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.cream,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_application == null) {
      return Scaffold(
        backgroundColor: AppColors.cream,
        appBar: AppBar(title: const Text('Application Details')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Application not found',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 8),
              Text(
                'The application may have been deleted or you may not have access.',
                style: TextStyle(color: AppColors.textGrey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('Application Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Status Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    'Current Status',
                    style: TextStyle(color: AppColors.textGrey),
                  ),
                  const SizedBox(height: 8),
                  StatusBadge(_application!.status, large: true),
                  const SizedBox(height: 8),
                  Text(
                    'Applied on ${_application!.createdAt?.split('T').first ?? 'Unknown'}',
                    style: const TextStyle(
                      color: AppColors.textGrey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Application Details Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Application Details',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _DetailRow('Application ID', _application!.id),
                  _DetailRow('Internship ID', _application!.internshipId),
                  if (_application!.gpa != null)
                    _DetailRow('GPA', _application!.gpa!.toStringAsFixed(2)),
                  if (_application!.aboutMe != null &&
                      _application!.aboutMe!.isNotEmpty)
                    _DetailRow('About Me', _application!.aboutMe!),
                  if (_application!.documents != null &&
                      _application!.documents!.isNotEmpty)
                    _DetailRow(
                      'Documents',
                      _application!.documents!.join(', '),
                    ),
                ],
              ),
            ),

            // Status Update Section (Companies only)
            if (isCompany && _application!.status == 'pending') ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Update Application Status',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Review this application and decide whether to accept or reject the candidate.',
                      style: TextStyle(color: AppColors.textGrey, fontSize: 12),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _updating
                              ? const Center(
                                  child: SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                )
                              : ElevatedButton(
                                  onPressed: () => _updateStatus('accepted'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.green,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('Accept'),
                                ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _updating
                              ? const Center(
                                  child: SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                )
                              : ElevatedButton(
                                  onPressed: () => _updateStatus('rejected'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('Reject'),
                                ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(color: AppColors.textGrey, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
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
