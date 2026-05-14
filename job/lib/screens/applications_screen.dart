// lib/screens/applications_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/application_provider.dart';
import '../providers/auth_provider.dart';
import '../models/application.dart';
import '../utils/app_theme.dart';
import '../widgets/shared_widgets.dart';

class ApplicationsScreen extends StatefulWidget {
  const ApplicationsScreen({super.key});

  @override
  State<ApplicationsScreen> createState() => _ApplicationsScreenState();
}

class _ApplicationsScreenState extends State<ApplicationsScreen> {
  @override
  void initState() {
    super.initState();
    _loadApplications();
  }

  Future<void> _loadApplications() async {
    final provider = Provider.of<ApplicationProvider>(context, listen: false);
    await provider.loadApplications();
  }

  Future<void> _updateStatus(String id, String status) async {
    final provider = Provider.of<ApplicationProvider>(context, listen: false);
    final success = await provider.updateApplicationStatus(id, status);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Status updated to $status' : 'Failed'),
          backgroundColor: success ? AppColors.green : Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final provider = Provider.of<ApplicationProvider>(context);
    final applications = provider.applications;
    final isLoading = provider.isLoading;

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('My Applications')),
      body: RefreshIndicator(
        onRefresh: _loadApplications,
        color: AppColors.green,
        child: isLoading
            ? const LoadingOverlay()
            : applications.isEmpty
            ? Column(
                children: [
                  const GradientBanner(
                    title: 'Your Applications',
                    subtitle: 'Track all your internship applications here.',
                  ),
                  const SizedBox(height: 40),
                  const EmptyState(
                    icon: Icons.description_outlined,
                    message: 'No applications yet',
                    sub: 'Browse internships and hit Apply to get started.',
                  ),
                ],
              )
            : ListView(
                padding: const EdgeInsets.only(bottom: 24),
                children: [
                  GradientBanner(
                    title: 'Your Applications',
                    subtitle: 'Track all your internship applications here.',
                    chip: Chip(
                      label: Text(
                        '${applications.length} application${applications.length == 1 ? '' : 's'}',
                      ),
                      backgroundColor: Colors.white24,
                      labelStyle: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...applications.map(
                    (a) => _AppCard(
                      app: a,
                      onStatus: auth.isCompany ? _updateStatus : null,
                    ),
                  ),
                ],
              ),
      ),
      bottomNavigationBar: GoBottomNav(
        currentIndex: 2,
        onTap: (i) {
          const routes = ['/home', '/matches', '/applications', '/profile'];
          if (i != 2) Navigator.pushNamed(context, routes[i]);
        },
      ),
    );
  }
}

class _AppCard extends StatelessWidget {
  final InternshipApplication app;
  final Future<void> Function(String id, String status)? onStatus;

  const _AppCard({required this.app, this.onStatus});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(
        context,
        '/application-detail',
        arguments: {'id': app.id},
      ),
      child: GoCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Application #${app.id.substring(0, 8)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                StatusBadge(app.status),
              ],
            ),
            const SizedBox(height: 10),
            _Row('Internship ID', app.internshipId.substring(0, 8)),
            if (app.gpa != null) _Row('GPA', app.gpa!.toStringAsFixed(2)),
            if (app.aboutMe != null && app.aboutMe!.isNotEmpty)
              _Row(
                'About',
                app.aboutMe!.length > 50
                    ? '${app.aboutMe!.substring(0, 50)}...'
                    : app.aboutMe!,
              ),
            if (app.createdAt != null)
              _Row('Applied', app.createdAt!.split('T').first),
            if (onStatus != null && app.status == 'pending') ...[
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Update Status',
                    style: TextStyle(color: AppColors.textGrey),
                  ),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => onStatus!(app.id, 'accepted'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.green,
                        ),
                        child: const Text('Accept'),
                      ),
                      TextButton(
                        onPressed: () => onStatus!(app.id, 'rejected'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                        child: const Text('Reject'),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label, value;
  const _Row(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              '$label:',
              style: const TextStyle(color: AppColors.textGrey, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
