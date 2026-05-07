import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/application.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class ApplicationsScreen extends StatefulWidget {
  const ApplicationsScreen({super.key});

  @override
  ApplicationsScreenState createState() => ApplicationsScreenState();
}

class ApplicationsScreenState extends State<ApplicationsScreen> {
  List<Application> _applications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadApplications();
  }

  void _loadApplications() async {
    final applications = await ApiService.getApplications();
    setState(() {
      _applications = applications;
      _isLoading = false;
    });
  }

  Future<void> _updateStatus(String id, String status) async {
    final result = await ApiService.updateApplicationStatus(id, status);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result['message'] ?? 'Status updated')),
    );
    _loadApplications();
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          user?.type == 'employer' ? 'Applications' : 'My Applications',
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _applications.isEmpty
          ? const Center(child: Text('No applications found'))
          : ListView.builder(
              itemCount: _applications.length,
              itemBuilder: (context, index) {
                final application = _applications[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Application #${application.id}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text('Job ID: ${application.jobId}'),
                        const SizedBox(height: 8),
                        Text('Status: ${application.status}'),
                        const SizedBox(height: 8),
                        Text('Applied: ${application.appliedAt.toLocal()}'),
                        if (user?.type == 'employer') ...[
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              ElevatedButton(
                                onPressed: application.status != 'accepted'
                                    ? () => _updateStatus(
                                        application.id,
                                        'accepted',
                                      )
                                    : null,
                                child: const Text('Accept'),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: application.status != 'rejected'
                                    ? () => _updateStatus(
                                        application.id,
                                        'rejected',
                                      )
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                                child: const Text('Reject'),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
