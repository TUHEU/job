// lib/screens/applications_screen.dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/application.dart';
import '../utils/app_theme.dart';
import '../widgets/shared_widgets.dart';

class ApplicationsScreen extends StatefulWidget {
  const ApplicationsScreen({super.key});
  @override
  State<ApplicationsScreen> createState() => _ApplicationsScreenState();
}

class _ApplicationsScreenState extends State<ApplicationsScreen> {
  List<InternshipApplication> _apps = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final apps = await ApiService.getApplications();
    if (!mounted) return;
    setState(() { _apps = apps; _loading = false; });
  }

  Future<void> _updateStatus(String id, String status) async {
    await ApiService.updateApplicationStatus(id, status);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('My Applications')),
      body: _loading
          ? const LoadingOverlay()
          : _apps.isEmpty
          ? Column(children: [
              GradientBanner(
                title: 'Your Applications',
                subtitle: 'Track all your internship applications here.',
              ),
              const SizedBox(height: 40),
              EmptyState(
                icon: Icons.description_outlined,
                message: 'No applications yet',
                sub: 'Browse internships and hit Apply to get started.',
              ),
            ])
          : RefreshIndicator(
              onRefresh: _load,
              color: AppColors.green,
              child: ListView(
                padding: const EdgeInsets.only(bottom: 24),
                children: [
                  GradientBanner(
                    title: 'Your Applications',
                    subtitle: 'Track all your internship applications here.',
                    chip: Chip(
                      label: Text('${_apps.length} application${_apps.length == 1 ? '' : 's'}'),
                      backgroundColor: Colors.white24,
                      labelStyle: const TextStyle(color: Colors.white,
                          fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ..._apps.map((a) => _AppCard(app: a, onStatus: _updateStatus)),
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
  const _AppCard({required this.app, required this.onStatus});
  final InternshipApplication app;
  final Future<void> Function(String id, String status) onStatus;

  @override
  Widget build(BuildContext context) {
    return GoCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Expanded(child: Text('Application #${app.id.substring(0, 8)}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
          StatusBadge(app.status),
        ]),
        const SizedBox(height: 10),
        _Row('Internship ID', app.internshipId.substring(0, 8)),
        if (app.gpa != null) _Row('GPA', app.gpa!.toStringAsFixed(2)),
        if (app.aboutMe != null && app.aboutMe!.isNotEmpty)
          _Row('About', app.aboutMe!),
        if (app.createdAt != null)
          _Row('Applied', app.createdAt!.split('T').first),
        if (app.documents != null && app.documents!.isNotEmpty) ...[
          const SizedBox(height: 8),
          const Text('Documents', style: TextStyle(
              fontWeight: FontWeight.w600, fontSize: 13,
              color: AppColors.textGrey)),
          const SizedBox(height: 4),
          ...app.documents!.map((d) => Row(children: [
            const Icon(Icons.attach_file, size: 14, color: AppColors.textGrey),
            const SizedBox(width: 4),
            Text(d, style: const TextStyle(fontSize: 13,
                color: AppColors.textGrey)),
          ])),
        ],
        const Divider(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Update Status',
                style: TextStyle(fontSize: 13,
                    color: AppColors.textGrey)),
            DropdownButton<String>(
              value: app.status,
              underline: const SizedBox(),
              borderRadius: BorderRadius.circular(12),
              items: const [
                DropdownMenuItem(value: 'pending',  child: Text('Pending')),
                DropdownMenuItem(value: 'accepted', child: Text('Accepted')),
                DropdownMenuItem(value: 'rejected', child: Text('Rejected')),
              ],
              onChanged: (v) {
                if (v != null) onStatus(app.id, v);
              },
            ),
          ],
        ),
      ]),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);
  final String label, value;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 90, child: Text('$label:',
            style: const TextStyle(color: AppColors.textGrey, fontSize: 13))),
        Expanded(child: Text(value,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13))),
      ]),
    );
  }
}
