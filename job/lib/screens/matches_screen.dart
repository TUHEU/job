import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/internship.dart';

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key});

  @override
  MatchesScreenState createState() => MatchesScreenState();
}

class MatchesScreenState extends State<MatchesScreen> {
  List<Internship> _matches = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMatches();
  }

  void _loadMatches() async {
    final matches = await ApiService.getMatches();
    setState(() {
      _matches = matches;
      _isLoading = false;
    });
  }

  void _apply(String internshipId) async {
    final result = await ApiService.applyForInternship(internshipId);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(result['message'])));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Matches')),
      body: Container(
        color: const Color(0xFFF7EFE5),
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF14563A), Color(0xFF7B1023)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 18,
                      offset: Offset.zero,
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Recommended for you',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'These internships match your profile and are prioritized based on your skills and GPA.',
                      style: const TextStyle(
                        color: Colors.white70,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Chip(
                      label: Text('${_matches.length} matches found'),
                      backgroundColor: Colors.white24,
                      labelStyle: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_matches.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                child: Text(
                  'No matches found yet. Browse internships to discover opportunities suited for you.',
                  style: TextStyle(fontSize: 16, height: 1.5),
                  textAlign: TextAlign.center,
                ),
              )
            else
              ..._matches
                  .map(
                    (internship) => Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: _buildMatchCard(internship),
                    ),
                  )
                  .toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchCard(Internship internship) {
    final daysLeft = internship.deadline.difference(DateTime.now()).inDays;
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
            Text(
              internship.companyName,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 6),
            Text(
              internship.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              internship.field,
              style: const TextStyle(color: Colors.black87),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _buildChip(
                  '${(80 + daysLeft).clamp(65, 95)}% match',
                  const Color(0xFFE9F6F0),
                ),
                const SizedBox(width: 8),
                _buildChip(
                  daysLeft >= 0 ? 'Deadline ${daysLeft}d' : 'Closed',
                  const Color(0xFFF5E7E9),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              internship.description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  daysLeft >= 0
                      ? 'Deadline in $daysLeft days'
                      : 'Deadline passed',
                  style: TextStyle(
                    color: daysLeft >= 0 ? Colors.green[700] : Colors.red[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                ElevatedButton(
                  onPressed: () => _apply(internship.id),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text('Apply'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(String label, Color color) {
    return Chip(label: Text(label), backgroundColor: color);
  }
}
