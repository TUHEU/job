import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../models/internship.dart';
import '../models/user.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  bool _isLoading = true;
  List<Internship> _matches = [];

  @override
  void initState() {
    super.initState();
    _loadMatches();
  }

  Future<void> _loadMatches() async {
    final matches = await ApiService.getMatches();
    if (!mounted) return;
    setState(() {
      _matches = matches;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<AuthProvider>(context);
    final user =
        userProvider.user ??
        User(
          id: 'guest',
          name: 'Guest User',
          email: 'guest@jobmatch.cameroon',
          type: 'intern',
          skills: ['Local hiring', 'Career coaching'],
          gpa: 0.0,
        );
    final topMatches = _matches.take(3).toList();
    final profileStrength = _calculateProfileStrength(user);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Goinus Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            tooltip: 'Profile',
            onPressed: () => Navigator.pushNamed(context, '/profile'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: ListView(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(26),
                gradient: const LinearGradient(
                  colors: [Color(0xFF14563A), Color(0xFF7B1023)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Welcome back',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    user.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Your GPA',
                          style: TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${user.gpa?.toStringAsFixed(2) ?? 'N/A'} / 4.00',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 14),
                        LinearProgressIndicator(
                          value: profileStrength / 100,
                          backgroundColor: Colors.white24,
                          color: Colors.white,
                          minHeight: 8,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Profile strength: $profileStrength%',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                _buildStatCard('Matches', _matches.length.toString()),
                _buildStatCard('Applications', '—'),
                _buildStatCard('Profile', '${profileStrength}%'),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildActionCard(
                  'Browse',
                  Icons.search,
                  () => Navigator.pushNamed(context, '/internships'),
                ),
                _buildActionCard(
                  'Matches',
                  Icons.favorite,
                  () => Navigator.pushNamed(context, '/matches'),
                ),
                _buildActionCard(
                  'Documents',
                  Icons.upload_file,
                  () => Navigator.pushNamed(context, '/profile'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Top matches for you',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : topMatches.isEmpty
                ? const Text('No matches available yet.')
                : Column(
                    children: topMatches
                        .map((item) => _buildMatchCard(item, context))
                        .toList(),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(String label, IconData icon, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(right: 10),
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 12,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFF14563A),
                child: Icon(icon, color: Colors.white),
              ),
              const SizedBox(height: 12),
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMatchCard(Internship internship, BuildContext context) {
    final daysLeft = internship.deadline.difference(DateTime.now()).inDays;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
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
          const SizedBox(height: 10),
          Text(internship.field, style: const TextStyle(color: Colors.black87)),
          const SizedBox(height: 10),
          Row(
            children: [
              Chip(
                label: Text('${(80 + daysLeft).clamp(65, 95)}% match'),
                backgroundColor: const Color(0xFF14563A).withOpacity(0.1),
              ),
              const SizedBox(width: 10),
              Chip(
                label: Text(
                  daysLeft >= 0 ? 'Deadline in $daysLeft days' : 'Closed',
                ),
                backgroundColor: const Color(0xFF7B1023).withOpacity(0.1),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/internships'),
              child: const Text('View details'),
            ),
          ),
        ],
      ),
    );
  }

  int _calculateProfileStrength(User user) {
    var strength = 40;
    if (user.gpa != null && user.gpa! >= 3.0) strength += 20;
    if (user.skills != null && user.skills!.isNotEmpty) strength += 20;
    if (user.documents != null && user.documents!.isNotEmpty) strength += 20;
    return strength.clamp(0, 100);
  }
}
