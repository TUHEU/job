// lib/screens/internship_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../models/internship.dart';
import '../providers/auth_provider.dart';
import '../providers/application_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/shared_widgets.dart';

class InternshipDetailScreen extends StatefulWidget {
  final String internshipId;
  const InternshipDetailScreen({super.key, required this.internshipId});

  @override
  State<InternshipDetailScreen> createState() => _InternshipDetailScreenState();
}

class _InternshipDetailScreenState extends State<InternshipDetailScreen> {
  Internship? _internship;
  bool _loading = true;
  bool _applying = false;
  final _aboutMeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadInternship();
  }

  Future<void> _loadInternship() async {
    final internship = await ApiService.getInternshipById(widget.internshipId);
    if (mounted)
      setState(() {
        _internship = internship;
        _loading = false;
      });
  }

  Future<void> _apply() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!auth.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login to apply'),
          backgroundColor: Colors.orange,
        ),
      );
      Navigator.pushNamed(context, '/login');
      return;
    }
    if (!auth.isIntern) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Only students can apply'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _applying = true);
    final appProvider = Provider.of<ApplicationProvider>(
      context,
      listen: false,
    );
    final success = await appProvider.applyForInternship(
      widget.internshipId,
      aboutMe: _aboutMeController.text.isEmpty ? null : _aboutMeController.text,
    );

    if (mounted) {
      setState(() => _applying = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Application submitted!' : appProvider.error ?? 'Failed',
          ),
          backgroundColor: success ? AppColors.green : Colors.red,
        ),
      );
      if (success) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_internship == null)
      return const Scaffold(body: Center(child: Text('Internship not found')));

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: Text(_internship!.title)),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.green, AppColors.burgundy],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _internship!.companyName,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _internship!.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 16, color: Colors.white70),
                      const SizedBox(width: 4),
                      Text(
                        _internship!.location,
                        style: const TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.work, size: 16, color: Colors.white70),
                      const SizedBox(width: 4),
                      Text(
                        _internship!.field,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _internship!.isExpired
                          ? Colors.red
                          : AppColors.green,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _internship!.deadlineLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Description',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _internship!.description,
                    style: const TextStyle(height: 1.5),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Requirements',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ..._internship!.requirements.map(
                    (req) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle,
                            size: 16,
                            color: AppColors.green,
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: Text(req)),
                        ],
                      ),
                    ),
                  ),
                  if (!_internship!.isExpired && _internship!.isActive) ...[
                    const Divider(),
                    const SizedBox(height: 16),
                    const Text(
                      'Apply Now',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _aboutMeController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Why are you a good fit? (Optional)',
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: _applying
                          ? const Center(child: CircularProgressIndicator())
                          : ElevatedButton(
                              onPressed: _apply,
                              child: const Text('Submit Application'),
                            ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
