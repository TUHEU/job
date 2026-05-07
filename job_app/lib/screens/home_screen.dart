import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import 'job_list_screen.dart';
import 'post_job_screen.dart';
import 'applications_screen.dart';
import 'matches_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('JobMatch Cameroon'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            tooltip: 'Profile',
            onPressed: () => Navigator.pushNamed(context, '/profile'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Log out',
            onPressed: () async {
              final authProvider = Provider.of<AuthProvider>(
                context,
                listen: false,
              );
              final navigator = Navigator.of(context);
              if (!mounted) return;
              await ApiService.clearToken();
              if (!mounted) return;
              await authProvider.clearAuth();
              if (!mounted) return;
              navigator.pushReplacementNamed('/login');
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Welcome, ${user?.name ?? 'User'}!',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 20),
          if (user?.type == 'jobseeker') ..._buildJobSeekerCards(),
          if (user?.type == 'employer') ..._buildEmployerCards(),
        ],
      ),
    );
  }

  List<Widget> _buildJobSeekerCards() {
    return [
      _buildFeatureCard(
        'Browse Jobs',
        'Find your dream job',
        Icons.work,
        () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const JobListScreen()),
        ),
      ),
      _buildFeatureCard(
        'My Matches',
        'Jobs that match your skills',
        Icons.thumb_up,
        () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MatchesScreen()),
        ),
      ),
      _buildFeatureCard(
        'My Applications',
        'Track your job applications',
        Icons.assignment,
        () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ApplicationsScreen()),
        ),
      ),
    ];
  }

  List<Widget> _buildEmployerCards() {
    return [
      _buildFeatureCard(
        'Post a Job',
        'Find the perfect candidate',
        Icons.add_circle,
        () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const PostJobScreen()),
        ),
      ),
      _buildFeatureCard(
        'View Applications',
        'Review job applications',
        Icons.people,
        () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ApplicationsScreen()),
        ),
      ),
      _buildFeatureCard(
        'Browse All Jobs',
        'See all posted jobs',
        Icons.list,
        () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const JobListScreen()),
        ),
      ),
    ];
  }

  Widget _buildFeatureCard(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: Icon(icon, size: 40, color: Theme.of(context).primaryColor),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }
}
