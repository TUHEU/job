// lib/screens/landing_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/app_theme.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final isLoggedIn = auth.isLoggedIn;

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Stack(children: [
        // ── Top gradient header ───────────────────────────────────────────
        Positioned(
          top: 0, left: 0, right: 0, height: 360,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.green, AppColors.burgundy],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft:  Radius.circular(44),
                bottomRight: Radius.circular(44),
              ),
            ),
          ),
        ),

        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Top nav ───────────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(children: const [
                      Icon(Icons.eco, color: Colors.white, size: 26),
                      SizedBox(width: 8),
                      Text('Goinus', style: TextStyle(
                          color: Colors.white, fontSize: 22,
                          fontWeight: FontWeight.w800)),
                    ]),
                    Row(children: [
                      TextButton(
                        onPressed: () => Navigator.pushNamed(context, '/login'),
                        child: const Text('Login',
                            style: TextStyle(color: Colors.white,
                                fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(width: 6),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white70),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                        ),
                        onPressed: () =>
                            Navigator.pushNamed(context, '/register'),
                        child: const Text('Sign up'),
                      ),
                    ]),
                  ],
                ),
                const SizedBox(height: 22),

                // ── Hero card ─────────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.13),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Connect. Match. Grow.',
                          style: TextStyle(color: Colors.white,
                              fontSize: 28, fontWeight: FontWeight.bold,
                              height: 1.2)),
                      const SizedBox(height: 10),
                      const Text(
                        'Find internships, build your profile, and match with top companies in Cameroon.',
                        style: TextStyle(color: Colors.white70,
                            fontSize: 14, height: 1.5),
                      ),
                      const SizedBox(height: 20),
                      Row(children: [
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.burgundy,
                              minimumSize: const Size(0, 48),
                            ),
                            onPressed: () =>
                                Navigator.pushNamed(context, '/login'),
                            child: const Text('Login'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.white38),
                              foregroundColor: Colors.white,
                              minimumSize: const Size(0, 48),
                            ),
                            onPressed: () =>
                                Navigator.pushNamed(context, '/register'),
                            child: const Text('Create Account'),
                          ),
                        ),
                      ]),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // ── Scrollable body ───────────────────────────────────────
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      const _SectionHeading('Who is Goinus for?'),
                      const SizedBox(height: 14),
                      Row(children: [
                        Expanded(child: _RoleCard(
                          title: 'Students',
                          sub: 'Upload your profile, GPA, and documents to get matched.',
                          icon: Icons.school_outlined,
                        )),
                        const SizedBox(width: 14),
                        Expanded(child: _RoleCard(
                          title: 'Companies',
                          sub: 'Post internships and find the best local talent.',
                          icon: Icons.business_outlined,
                        )),
                      ]),
                      const SizedBox(height: 22),
                      const _SectionHeading('Key Features'),
                      const SizedBox(height: 12),
                      _FeatureRow(Icons.upload_file_outlined,
                          'Upload CV, transcripts and motivation letter'),
                      const SizedBox(height: 10),
                      _FeatureRow(Icons.auto_awesome_outlined,
                          'Smart matching based on GPA, skills, and field'),
                      const SizedBox(height: 10),
                      _FeatureRow(Icons.notifications_active_outlined,
                          'Track your applications in real-time'),
                      const SizedBox(height: 24),

                      if (isLoggedIn)
                        _LoggedInBanner(name: auth.user!.name)
                      else
                        _GuestBanner(onContinue: () =>
                            Navigator.pushNamed(context, '/home')),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ]),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
          color: AppColors.green));
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({required this.title, required this.sub, required this.icon});
  final String title, sub;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05),
            blurRadius: 14, offset: const Offset(0, 6))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        CircleAvatar(
          backgroundColor: AppColors.chipGreen,
          child: Icon(icon, color: AppColors.green),
        ),
        const SizedBox(height: 14),
        Text(title, style: const TextStyle(
            fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text(sub, style: const TextStyle(
            color: AppColors.textGrey, height: 1.4, fontSize: 13)),
      ]),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow(this.icon, this.label);
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
            blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(children: [
        CircleAvatar(
          backgroundColor: AppColors.green,
          radius: 18,
          child: Icon(icon, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(child: Text(label, style: const TextStyle(
            fontWeight: FontWeight.w500, fontSize: 14))),
      ]),
    );
  }
}

class _GuestBanner extends StatelessWidget {
  const _GuestBanner({required this.onContinue});
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05),
            blurRadius: 14, offset: const Offset(0, 6))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Browsing as Guest',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text(
          'You can explore internships without an account. Login for personalised matches and to track applications.',
          style: TextStyle(color: AppColors.textGrey, height: 1.45, fontSize: 13),
        ),
        const SizedBox(height: 14),
        TextButton.icon(
          onPressed: onContinue,
          icon: const Icon(Icons.arrow_forward, size: 16),
          label: const Text('Continue as Guest'),
          style: TextButton.styleFrom(foregroundColor: AppColors.green),
        ),
      ]),
    );
  }
}

class _LoggedInBanner extends StatelessWidget {
  const _LoggedInBanner({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.green, AppColors.greenLight],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(children: [
        const Icon(Icons.check_circle, color: Colors.white),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Welcome back, $name!',
              style: const TextStyle(color: Colors.white,
                  fontWeight: FontWeight.bold)),
          const Text('Tap below to go to your dashboard.',
              style: TextStyle(color: Colors.white70, fontSize: 13)),
        ])),
        ElevatedButton(
          onPressed: () => Navigator.pushNamed(context, '/home'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.white,
              foregroundColor: AppColors.green),
          child: const Text('Dashboard'),
        ),
      ]),
    );
  }
}
