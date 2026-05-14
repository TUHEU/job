// lib/screens/internship_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/internship_provider.dart';
import '../providers/auth_provider.dart';
import '../models/internship.dart';
import '../utils/app_theme.dart';
import '../widgets/shared_widgets.dart';

class InternshipListScreen extends StatefulWidget {
  const InternshipListScreen({super.key});

  @override
  State<InternshipListScreen> createState() => _InternshipListScreenState();
}

class _InternshipListScreenState extends State<InternshipListScreen> {
  final _searchCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _fieldCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadInternships();
  }

  Future<void> _loadInternships() async {
    final provider = Provider.of<InternshipProvider>(context, listen: false);
    await provider.loadInternships();
  }

  void _filter() {
    final provider = Provider.of<InternshipProvider>(context, listen: false);
    provider.loadInternships(
      keyword: _searchCtrl.text,
      location: _locationCtrl.text,
      field: _fieldCtrl.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final provider = Provider.of<InternshipProvider>(context);
    final internships = provider.internships;
    final isLoading = provider.isLoading;

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('Browse Internships')),
      body: Column(
        children: [
          const GradientBanner(
            title: 'Find Your Next Internship',
            subtitle: 'Browse active listings from employers across Cameroon.',
          ),
          const SizedBox(height: 12),
          // Search filters
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _searchCtrl,
                    onChanged: (_) => _filter(),
                    decoration: const InputDecoration(
                      hintText: 'Search by title, skill...',
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _locationCtrl,
                          onChanged: (_) => _filter(),
                          decoration: const InputDecoration(
                            hintText: 'Location',
                            prefixIcon: Icon(
                              Icons.location_on_outlined,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _fieldCtrl,
                          onChanged: (_) => _filter(),
                          decoration: const InputDecoration(
                            hintText: 'Field',
                            prefixIcon: Icon(Icons.work_outline, size: 18),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text(
                  '${internships.length} internship${internships.length == 1 ? '' : 's'}',
                  style: const TextStyle(
                    color: AppColors.textGrey,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: isLoading
                ? const LoadingOverlay()
                : internships.isEmpty
                ? const EmptyState(
                    icon: Icons.search_off_outlined,
                    message: 'No internships found',
                    sub: 'Try changing your filters.',
                  )
                : RefreshIndicator(
                    onRefresh: _loadInternships,
                    color: AppColors.green,
                    child: ListView.builder(
                      padding: const EdgeInsets.only(bottom: 20),
                      itemCount: internships.length,
                      itemBuilder: (_, i) => InternshipCard(
                        internship: internships[i],
                        actionLabel: 'Apply',
                        onAction: () => _apply(internships[i].id, auth),
                      ),
                    ),
                  ),
          ),
        ],
      ),
      bottomNavigationBar: GoBottomNav(
        currentIndex: -1,
        onTap: (i) {
          const routes = ['/home', '/matches', '/applications', '/profile'];
          Navigator.pushNamed(context, routes[i]);
        },
      ),
    );
  }

  Future<void> _apply(String id, AuthProvider auth) async {
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
    Navigator.pushNamed(context, '/internship-detail', arguments: {'id': id});
  }
}
