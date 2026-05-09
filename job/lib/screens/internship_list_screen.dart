// lib/screens/internship_list_screen.dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/internship.dart';
import '../utils/app_theme.dart';
import '../widgets/shared_widgets.dart';

class InternshipListScreen extends StatefulWidget {
  const InternshipListScreen({super.key});
  @override
  State<InternshipListScreen> createState() => _InternshipListScreenState();
}

class _InternshipListScreenState extends State<InternshipListScreen> {
  List<Internship> _all = [];
  List<Internship> _filtered = [];
  bool _loading = true;

  final _searchCtrl   = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _fieldCtrl    = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await ApiService.getInternships();
    if (!mounted) return;
    setState(() { _all = list; _filtered = list; _loading = false; });
  }

  void _filter() {
    final q  = _searchCtrl.text.toLowerCase();
    final lo = _locationCtrl.text.toLowerCase();
    final fi = _fieldCtrl.text.toLowerCase();
    setState(() {
      _filtered = _all.where((i) {
        final matchQ  = q.isEmpty  || i.title.toLowerCase().contains(q) ||
            i.description.toLowerCase().contains(q) ||
            i.requirements.any((r) => r.toLowerCase().contains(q));
        final matchLo = lo.isEmpty || i.location.toLowerCase().contains(lo);
        final matchFi = fi.isEmpty || i.field.toLowerCase().contains(fi);
        return matchQ && matchLo && matchFi;
      }).toList();
    });
  }

  Future<void> _apply(String id) async {
    final res = await ApiService.applyForInternship(id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(res['message'] as String? ?? res['error'] as String? ?? 'Done'),
      backgroundColor: res.containsKey('error') ? Colors.red : AppColors.green,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(title: const Text('Browse Internships')),
      body: Column(children: [
        GradientBanner(
          title: 'Find Your Next Internship',
          subtitle: 'Browse active listings from employers across Cameroon.',
        ),
        const SizedBox(height: 12),

        // ── Search & filter ───────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05),
                  blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: Column(children: [
              TextField(
                controller: _searchCtrl,
                onChanged: (_) => _filter(),
                decoration: const InputDecoration(
                  hintText: 'Search by title, skill, keyword…',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: TextField(
                  controller: _locationCtrl,
                  onChanged: (_) => _filter(),
                  decoration: const InputDecoration(
                    hintText: 'Location',
                    prefixIcon: Icon(Icons.location_on_outlined, size: 18),
                  ),
                )),
                const SizedBox(width: 10),
                Expanded(child: TextField(
                  controller: _fieldCtrl,
                  onChanged: (_) => _filter(),
                  decoration: const InputDecoration(
                    hintText: 'Field',
                    prefixIcon: Icon(Icons.work_outline, size: 18),
                  ),
                )),
              ]),
            ]),
          ),
        ),
        const SizedBox(height: 8),

        // ── Results count ─────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(children: [
            Text('${_filtered.length} internship${_filtered.length == 1 ? '' : 's'}',
                style: const TextStyle(color: AppColors.textGrey,
                    fontSize: 13, fontWeight: FontWeight.w500)),
          ]),
        ),

        // ── List ──────────────────────────────────────────────────────────
        Expanded(
          child: _loading
              ? const LoadingOverlay()
              : _filtered.isEmpty
              ? EmptyState(
                  icon: Icons.search_off_outlined,
                  message: 'No internships found',
                  sub: 'Try changing your filters or search terms.',
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppColors.green,
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 20),
                    itemCount: _filtered.length,
                    itemBuilder: (_, i) => InternshipCard(
                      internship: _filtered[i],
                      actionLabel: 'Apply',
                      onAction: () => _apply(_filtered[i].id),
                    ),
                  ),
                ),
        ),
      ]),
      bottomNavigationBar: GoBottomNav(
        currentIndex: -1,
        onTap: (i) {
          const routes = ['/home', '/matches', '/applications', '/profile'];
          Navigator.pushNamed(context, routes[i]);
        },
      ),
    );
  }
}
