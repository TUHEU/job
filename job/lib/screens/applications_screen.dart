import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/application.dart';

class ApplicationsScreen extends StatefulWidget {
  const ApplicationsScreen({super.key});

  @override
  ApplicationsScreenState createState() => ApplicationsScreenState();
}

class ApplicationsScreenState extends State<ApplicationsScreen> {
  List<InternshipApplication> _applications = [];
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

  void _updateStatus(String id, String status) async {
    await ApiService.updateApplicationStatus(id, status);
    _loadApplications();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Applications')),
      body: Container(
        color: const Color(0xFFF7EFE5),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _applications.isEmpty
            ? const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                child: Text(
                  'You have not applied to any internships yet. Explore opportunities and send your first application.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, height: 1.5),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 16),
                itemCount: _applications.length,
                itemBuilder: (context, index) {
                  final app = _applications[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: _buildApplicationCard(app),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildApplicationCard(InternshipApplication app) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Application ${app.id}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                _buildStatusBadge(app.status),
              ],
            ),
            const SizedBox(height: 12),
            Text('Intern: ${app.internId}'),
            if (app.gpa != null) ...[
              const SizedBox(height: 6),
              Text('GPA: ${app.gpa}'),
            ],
            if (app.aboutMe != null) ...[
              const SizedBox(height: 6),
              Text('About: ${app.aboutMe}'),
            ],
            if (app.documents != null && app.documents!.isNotEmpty) ...[
              const SizedBox(height: 10),
              const Text(
                'Documents:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              ...app.documents!.map((doc) => Text('- $doc')),
            ],
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Update status:'),
                DropdownButton<String>(
                  value: app.status,
                  items: ['pending', 'accepted', 'rejected']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      _updateStatus(app.id, value);
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final color = status == 'accepted'
        ? Colors.green[100]
        : status == 'rejected'
        ? Colors.red[100]
        : Colors.yellow[100];
    final textColor = status == 'accepted'
        ? Colors.green[800]
        : status == 'rejected'
        ? Colors.red[800]
        : Colors.orange[800];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
      ),
    );
  }
}
