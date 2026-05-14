// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/internship_provider.dart';
import '../models/internship.dart';
import '../models/user.dart';
import '../utils/app_theme.dart';
import '../widgets/shared_widgets.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Schedule data loading after first frame to avoid build phase issues
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final internshipProvider = Provider.of<InternshipProvider>(
      context,
      listen: false,
    );
    await internshipProvider.loadMatches();
  }

  int _profileStrength(User user) {
    var s = 40;
    if (user.gpa != null && user.gpa! >= 2.5) s += 20;
    if (user.skills != null && user.skills!.isNotEmpty) s += 20;
    if (user.documents != null && user.documents!.isNotEmpty) s += 10;
    if (user.aboutMe != null && user.aboutMe!.isNotEmpty) s += 10;
    return s.clamp(0, 100);
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;
    final internshipProvider = Provider.of<InternshipProvider>(context);
    final matches = internshipProvider.matches.take(3).toList();
    final strength = _profileStrength(user);

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Row(
          children: [
            Icon(Icons.eco, size: 20),
            SizedBox(width: 8),
            Text('Goinus'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notifications coming soon!')),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/profile'),
              child: CircleAvatar(
                radius: 17,
                backgroundColor: AppColors.burgundy,
                child: Text(
                  user.name.isNotEmpty ? user.name[0].toUpperCase() : 'G',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AppColors.green,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _WelcomeCard(user: user, strength: strength),
              const SizedBox(height: 18),

              // Stats Row
              Row(
                children: [
                  _StatTile(
                    'GPA',
                    user.gpa?.toStringAsFixed(2) ?? 'N/A',
                    Icons.grade_outlined,
                  ),
                  const SizedBox(width: 10),
                  _StatTile(
                    'Matches',
                    matches.length.toString(),
                    Icons.favorite_outline,
                  ),
                  const SizedBox(width: 10),
                  _StatTile('Profile', '$strength%', Icons.person_outline),
                ],
              ),

              const SizedBox(height: 20),

              // Quick Actions
              const SectionTitle('Quick Actions'),
              const SizedBox(height: 12),
              Row(
                children: [
                  _ActionTile(
                    'Browse',
                    Icons.search,
                    AppColors.green,
                    () => Navigator.pushNamed(context, '/internships'),
                  ),
                  const SizedBox(width: 10),
                  _ActionTile(
                    'Matches',
                    Icons.favorite,
                    AppColors.burgundy,
                    () => Navigator.pushNamed(context, '/matches'),
                  ),
                  if (user.isCompany) ...[
                    const SizedBox(width: 10),
                    _ActionTile(
                      'Post',
                      Icons.add_business,
                      Colors.teal,
                      () => Navigator.pushNamed(context, '/post-internship'),
                    ),
                  ],
                  if (user.isIntern) ...[
                    const SizedBox(width: 10),
                    _ActionTile(
                      'Photo',
                      Icons.camera_alt,
                      Colors.indigo,
                      () => Navigator.pushNamed(context, '/camera'),
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 22),

              // Top Matches
              SectionTitle(
                'Top Matches For You',
                trailing: TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/matches'),
                  child: const Text(
                    'View all',
                    style: TextStyle(color: AppColors.burgundy),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              if (internshipProvider.isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: LoadingOverlay(),
                )
              else if (matches.isEmpty)
                const EmptyState(
                  icon: Icons.work_off_outlined,
                  message: 'No matches yet',
                  sub:
                      'Complete your profile to get personalised recommendations.',
                )
              else
                ...matches.map((i) => _MatchRow(internship: i)),
            ],
          ),
        ),
      ),
      bottomNavigationBar: GoBottomNav(
        currentIndex: 0,
        onTap: (i) {
          const routes = ['/home', '/matches', '/applications', '/profile'];
          if (i != 0) Navigator.pushNamed(context, routes[i]);
        },
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard({required this.user, required this.strength});
  final User user;
  final int strength;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [AppColors.green, AppColors.burgundy],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.green.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Welcome back',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            user.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (user.major != null) ...[
            const SizedBox(height: 2),
            Text(
              user.major!,
              style: const TextStyle(color: Colors.white60, fontSize: 13),
            ),
          ],
          const SizedBox(height: 18),
          Row(
            children: [
              const Text(
                'Profile Strength',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const Spacer(),
              Text(
                '$strength%',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: strength / 100,
              backgroundColor: Colors.white24,
              color: Colors.white,
              minHeight: 7,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            strength >= 80
                ? '✓ Keep it up! Almost there.'
                : 'Add more details to improve your matches.',
            style: const TextStyle(color: Colors.white60, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile(this.label, this.value, this.icon);
  final String label, value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: AppColors.green),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: AppColors.textGrey),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile(this.label, this.icon, this.color, this.onTap);
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: color.withOpacity(0.12),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MatchRow extends StatelessWidget {
  const _MatchRow({required this.internship});
  final Internship internship;

  @override
  Widget build(BuildContext context) {
    final score = internship.matchScore ?? 75;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.green.withOpacity(0.1),
            child: Text(
              internship.companyName.isNotEmpty
                  ? internship.companyName[0].toUpperCase()
                  : '?',
              style: const TextStyle(
                color: AppColors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  internship.companyName,
                  style: const TextStyle(
                    color: AppColors.textGrey,
                    fontSize: 11,
                  ),
                ),
                Text(
                  internship.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$score% match',
                    style: const TextStyle(
                      color: AppColors.green,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pushNamed(
              context,
              '/internship-detail',
              arguments: {'id': internship.id},
            ),
            child: const Text(
              'View',
              style: TextStyle(color: AppColors.burgundy),
            ),
          ),
        ],
      ),
    );
  }
}
