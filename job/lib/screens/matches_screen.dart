// lib/screens/matches_screen.dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';
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
  List<Internship> _matches = [];
  bool _loading = true;
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final matches = await ApiService.getMatches();
    if (!mounted) return;
    setState(() { _matches = matches; _loading = false; });
  }

  Future<void> _apply(String id) async {
    final res = await ApiService.applyForInternship(id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(res['message'] as String? ?? res['error'] as String? ?? 'Done'),
      backgroundColor: res.containsKey('error') ? Colors.red : AppColors.green,
    ));
  }

  List<Internship> get _recommended =>
      _matches.where((i) => (i.matchScore ?? 0) >= 70).toList();
  List<Internship> get _others =>
      _matches.where((i) => (i.matchScore ?? 0) < 70).toList();

  @override
  Widget build(BuildContext context) {
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
      body: Column(children: [
        GradientBanner(
          title: 'Recommended For You',
          subtitle: 'Ranked by skill and GPA match score.',
          chip: Chip(
            label: Text('${_matches.length} matches found'),
            backgroundColor: Colors.white24,
            labelStyle: const TextStyle(color: Colors.white,
                fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _loading
              ? const LoadingOverlay()
              : TabBarView(
                  controller: _tabs,
                  children: [
                    _MatchList(_recommended, _apply),
                    _MatchList(_matches, _apply),
                    _MatchList(_others, _apply),
                  ],
                ),
        ),
      ]),
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
  const _MatchList(this.items, this.onApply);
  final List<Internship> items;
  final Future<void> Function(String) onApply;

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
      onRefresh: () async {},
      color: AppColors.green,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 20),
        itemCount: items.length,
        itemBuilder: (_, i) => InternshipCard(
          internship: items[i],
          actionLabel: 'Apply',
          onAction: () => onApply(items[i].id),
          showScore: true,
        ),
      ),
    );
  }
}
