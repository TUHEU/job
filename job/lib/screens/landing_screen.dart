// lib/screens/landing_screen.dart
// FIX: ElevatedButton with minimumSize(double.infinity) inside a Row → crash
// Rule: NEVER use double.infinity width on a button inside a Row.
//       Either wrap with Expanded, or override minimumSize to a fixed/zero value.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/app_theme.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  // Button style safe inside a Row (no infinite width)
  static ButtonStyle get _rowBtnStyle => ElevatedButton.styleFrom(
    minimumSize: const Size(0, 48), // ← fixed, not double.infinity
    padding: const EdgeInsets.symmetric(horizontal: 22),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
  );

  static ButtonStyle get _rowOutlineStyle => OutlinedButton.styleFrom(
    minimumSize: const Size(0, 48),
    padding: const EdgeInsets.symmetric(horizontal: 22),
    foregroundColor: Colors.white,
    side: const BorderSide(color: Colors.white38),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
  );

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final isLoggedIn = auth.isLoggedIn;

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Stack(
        children: [
          // ── Gradient header ────────────────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 360,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.green, AppColors.burgundy],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(44),
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
                  // ── Top nav ─────────────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Logo
                      Row(
                        children: const [
                          Icon(Icons.eco, color: Colors.white, size: 26),
                          SizedBox(width: 8),
                          Text(
                            'Goinus',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      // Nav buttons — fixed size, safe in Row
                      Row(
                        children: [
                          TextButton(
                            onPressed: () =>
                                Navigator.pushNamed(context, '/login'),
                            child: const Text(
                              'Login',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.white70),
                              foregroundColor: Colors.white,
                              minimumSize: const Size(0, 36), // ← safe
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                            ),
                            onPressed: () =>
                                Navigator.pushNamed(context, '/register'),
                            child: const Text('Sign up'),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),

                  // ── Hero card ──────────────────────────────────────────
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
                        const Text(
                          'Connect. Match. Grow.',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Find internships, build your profile, and '
                          'match with top companies in Cameroon.',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 20),
                        // ── CTA buttons — inside Row, NO double.infinity ──
                        Row(
                          children: [
                            ElevatedButton(
                              style: _rowBtnStyle.copyWith(
                                backgroundColor: const WidgetStatePropertyAll(
                                  AppColors.burgundy,
                                ),
                                foregroundColor: const WidgetStatePropertyAll(
                                  Colors.white,
                                ),
                              ),
                              onPressed: () =>
                                  Navigator.pushNamed(context, '/login'),
                              child: const Text('Login'),
                            ),
                            const SizedBox(width: 12),
                            OutlinedButton(
                              style: _rowOutlineStyle,
                              onPressed: () =>
                                  Navigator.pushNamed(context, '/register'),
                              child: const Text('Create Account'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ── Scrollable content ─────────────────────────────────
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.zero,
                      children: [
                        _sectionHeading('Who is Goinus for?'),
                        const SizedBox(height: 14),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _RoleCard(
                                title: 'Students',
                                sub:
                                    'Upload your profile, GPA, and '
                                    'documents to get matched.',
                                icon: Icons.school_outlined,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: _RoleCard(
                                title: 'Companies',
                                sub:
                                    'Post internships and find the '
                                    'best local talent.',
                                icon: Icons.business_outlined,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 22),
                        _sectionHeading('Key Features'),
                        const SizedBox(height: 12),
                        _FeatureRow(
                          Icons.upload_file_outlined,
                          'Upload CV, transcripts and motivation letter',
                        ),
                        const SizedBox(height: 10),
                        _FeatureRow(
                          Icons.auto_awesome_outlined,
                          'Smart matching based on GPA, skills, and field',
                        ),
                        const SizedBox(height: 10),
                        _FeatureRow(
                          Icons.notifications_active_outlined,
                          'Track your applications in real-time',
                        ),
                        const SizedBox(height: 24),

                        if (isLoggedIn)
                          _LoggedInBanner(name: auth.user.name)
                        else
                          _GuestBanner(
                            onContinue: () =>
                                Navigator.pushNamed(context, '/home'),
                            onLogin: () =>
                                Navigator.pushNamed(context, '/login'),
                            onRegister: () =>
                                Navigator.pushNamed(context, '/register'),
                          ),

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeading(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.bold,
      color: AppColors.green,
    ),
  );
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: AppColors.chipGreen,
            child: Icon(icon, color: AppColors.green),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            sub,
            style: const TextStyle(
              color: AppColors.textGrey,
              height: 1.4,
              fontSize: 13,
            ),
          ),
        ],
      ),
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
            backgroundColor: AppColors.green,
            radius: 18,
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

class _GuestBanner extends StatelessWidget {
  const _GuestBanner({
    required this.onContinue,
    required this.onLogin,
    required this.onRegister,
  });
  final VoidCallback onContinue, onLogin, onRegister;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Browsing as Guest',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'You can explore internships without an account. '
            'Login for personalised matches and to track applications.',
            style: TextStyle(
              color: AppColors.textGrey,
              height: 1.45,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          // Buttons stacked vertically — no Row → no infinite-width issue
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onLogin,
              child: const Text('Login'),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.green,
                side: const BorderSide(color: AppColors.green),
                minimumSize: const Size(double.infinity, 48),
              ),
              onPressed: onRegister,
              child: const Text('Create Account'),
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: onContinue,
            icon: const Icon(Icons.arrow_forward, size: 16),
            label: const Text('Continue as Guest'),
            style: TextButton.styleFrom(foregroundColor: AppColors.textGrey),
          ),
        ],
      ),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Welcome back, $name!',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Your dashboard is ready.',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 14),
          // Full-width button — safe because it's NOT inside a Row
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/home'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.green,
                minimumSize: const Size(double.infinity, 48),
              ),
              child: const Text('Go to Dashboard'),
            ),
          ),
        ],
      ),
    );
  }
}
