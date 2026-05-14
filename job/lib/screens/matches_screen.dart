// lib/screens/matches_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/internship_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/application_provider.dart';
import '../models/internship.dart';
import '../utils/app_theme.dart';
import '../widgets/shared_widgets.dart';

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  String? _applyingId;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    // Schedule data loading after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMatches();
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _loadMatches() async {
    final provider = Provider.of<InternshipProvider>(context, listen: false);
    await provider.loadMatches();
  }

  Future<void> _apply(Internship internship) async {
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

    setState(() => _applyingId = internship.id);

    final appProvider = Provider.of<ApplicationProvider>(
      context,
      listen: false,
    );
    final success = await appProvider.applyForInternship(internship.id);

    if (mounted) {
      setState(() => _applyingId = null);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Application submitted!'
                : appProvider.error ?? 'Failed to apply',
          ),
          backgroundColor: success ? AppColors.green : Colors.red,
        ),
      );
    }
  }

  List<Internship> get _recommended => Provider.of<InternshipProvider>(
    context,
  ).matches.where((i) => (i.matchScore ?? 0) >= 70).toList();

  List<Internship> get _all => Provider.of<InternshipProvider>(context).matches;

  List<Internship> get _others => Provider.of<InternshipProvider>(
    context,
  ).matches.where((i) => (i.matchScore ?? 0) < 70).toList();

  @override
  Widget build(BuildContext context) {
    final isLoading = Provider.of<InternshipProvider>(context).isLoading;
    final matches = Provider.of<InternshipProvider>(context).matches;

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('My Matches'),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'Recommended'),
            Tab(text: 'All'),
            Tab(text: 'Others'),
          ],
        ),
      ),
      body: Column(
        children: [
          GradientBanner(
            title: 'Recommended For You',
            subtitle: 'Ranked by skill and GPA match score.',
            chip: Chip(
              label: Text('${matches.length} matches found'),
              backgroundColor: Colors.white24,
              labelStyle: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: isLoading
                ? const LoadingOverlay()
                : TabBarView(
                    controller: _tabs,
                    children: [
                      _MatchList(_recommended, _apply, _applyingId),
                      _MatchList(_all, _apply, _applyingId),
                      _MatchList(_others, _apply, _applyingId),
                    ],
                  ),
          ),
        ],
      ),
      bottomNavigationBar: GoBottomNav(
        currentIndex: 1,
        onTap: (i) {
          const routes = ['/home', '/matches', '/applications', '/profile'];
          if (i != 1) Navigator.pushNamed(context, routes[i]);
        },
      ),
    );
  }
}

class _MatchList extends StatelessWidget {
  const _MatchList(this.items, this.onApply, this.applyingId);
  final List<Internship> items;
  final Future<void> Function(Internship) onApply;
  final String? applyingId;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const EmptyState(
        icon: Icons.favorite_border,
        message: 'No matches here',
        sub: 'Complete your profile to improve your match score.',
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        final provider = Provider.of<InternshipProvider>(
          context,
          listen: false,
        );
        await provider.loadMatches();
      },
      color: AppColors.green,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 20),
        itemCount: items.length,
        itemBuilder: (_, i) => InternshipCard(
          internship: items[i],
          actionLabel: applyingId == items[i].id ? 'Applying...' : 'Apply',
          onAction: () => onApply(items[i]),
          showScore: true,
          isApplying: applyingId == items[i].id,
        ),
      ),
    );
  }
}
