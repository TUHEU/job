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
    // Schedule data loading after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInternships();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _locationCtrl.dispose();
    _fieldCtrl.dispose();
    super.dispose();
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
          content: Text('Only students can apply for internships'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Navigate to detail screen where user can apply
    Navigator.pushNamed(context, '/internship-detail', arguments: {'id': id});
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final provider = Provider.of<InternshipProvider>(context);
    final internships = provider.internships;
    final isLoading = provider.isLoading;

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('Browse Internships'), elevation: 0),
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
                    offset: const Offset(0, 4),
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
                      border: InputBorder.none,
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
                            border: InputBorder.none,
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
                            border: InputBorder.none,
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

          // Results count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text(
                  '${internships.length} internship${internships.length == 1 ? '' : 's'}',
                  style: const TextStyle(
                    color: AppColors.textGrey,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                if (isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.green,
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Internship list
          Expanded(
            child: isLoading && internships.isEmpty
                ? const LoadingOverlay()
                : internships.isEmpty
                ? const EmptyState(
                    icon: Icons.search_off_outlined,
                    message: 'No internships found',
                    sub: 'Try changing your filters or search terms.',
                  )
                : RefreshIndicator(
                    onRefresh: _loadInternships,
                    color: AppColors.green,
                    child: ListView.builder(
                      padding: const EdgeInsets.only(bottom: 20),
                      itemCount: internships.length,
                      itemBuilder: (_, index) {
                        final internship = internships[index];
                        return InternshipCard(
                          internship: internship,
                          actionLabel: 'Apply',
                          onAction: () => _apply(internship.id, auth),
                          showScore: false,
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
      bottomNavigationBar: GoBottomNav(
        currentIndex: 0, // FIXED: Changed from -1 to 0
        onTap: (index) {
          const routes = ['/home', '/matches', '/applications', '/profile'];
          if (index >= 0 && index < routes.length) {
            Navigator.pushNamed(context, routes[index]);
          }
        },
      ),
    );
  }
}
