// lib/widgets/shared_widgets.dart
import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../models/internship.dart';

// ──────────────────────────────────────────────────────────────────────────────
// GRADIENT BANNER
// ──────────────────────────────────────────────────────────────────────────────

class GradientBanner extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? chip;

  const GradientBanner({
    super.key,
    required this.title,
    required this.subtitle,
    this.chip,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
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
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(subtitle, style: const TextStyle(color: Colors.white70)),
          if (chip != null) ...[const SizedBox(height: 14), chip!],
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// SECTION TITLE
// ──────────────────────────────────────────────────────────────────────────────

class SectionTitle extends StatelessWidget {
  final String text;
  final Widget? trailing;

  const SectionTitle(this.text, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          text,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// GO CARD
// ──────────────────────────────────────────────────────────────────────────────

class GoCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final VoidCallback? onTap;

  const GoCard({super.key, required this.child, this.padding, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: padding ?? const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// STATUS BADGE
// ──────────────────────────────────────────────────────────────────────────────

class StatusBadge extends StatelessWidget {
  final String status;
  final bool large;

  const StatusBadge(this.status, {super.key, this.large = false});

  @override
  Widget build(BuildContext context) {
    final colors = {
      'accepted': (Colors.green[100]!, Colors.green[800]!),
      'rejected': (Colors.red[100]!, Colors.red[800]!),
      'pending': (Colors.orange[50]!, Colors.orange[800]!),
    };
    final pair = colors[status] ?? (Colors.grey[100]!, Colors.grey[800]!);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: large ? 16 : 10,
        vertical: large ? 8 : 4,
      ),
      decoration: BoxDecoration(
        color: pair.$1,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: pair.$2,
          fontSize: large ? 14 : 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// INTERNSHIP CARD
// ──────────────────────────────────────────────────────────────────────────────

class InternshipCard extends StatelessWidget {
  final Internship internship;
  final String actionLabel;
  final VoidCallback onAction;
  final bool showScore;
  final bool isApplying;

  const InternshipCard({
    super.key,
    required this.internship,
    required this.actionLabel,
    required this.onAction,
    this.showScore = false,
    this.isApplying = false,
  });

  @override
  Widget build(BuildContext context) {
    return GoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                    fontSize: 16,
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
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      internship.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
              _DeadlineChip(internship: internship),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            internship.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textGrey,
              height: 1.4,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _InfoChip(
                internship.location,
                Icons.location_on_outlined,
                AppColors.chipGreen,
              ),
              _InfoChip(
                internship.field,
                Icons.work_outline,
                AppColors.chipRed,
              ),
              if (showScore && internship.matchScore != null)
                _InfoChip(
                  '${internship.matchScore}% match',
                  Icons.favorite_outline,
                  const Color(0xFFE8F4FD),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (internship.isExpired)
                const Text(
                  'Expired',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                )
              else
                ElevatedButton(
                  onPressed: isApplying ? null : onAction,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(100, 40),
                  ),
                  child: Text(actionLabel),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// DEADLINE CHIP (Private)
// ──────────────────────────────────────────────────────────────────────────────

class _DeadlineChip extends StatelessWidget {
  final Internship internship;

  const _DeadlineChip({required this.internship});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: internship.isExpired
            ? Colors.red.withOpacity(0.1)
            : AppColors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        internship.deadlineLabel,
        style: TextStyle(
          color: internship.isExpired ? Colors.red[700] : AppColors.green,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// INFO CHIP (Private)
// ──────────────────────────────────────────────────────────────────────────────

class _InfoChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _InfoChip(this.label, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.textGrey),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppColors.textDark),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// EMPTY STATE
// ──────────────────────────────────────────────────────────────────────────────

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? sub;

  const EmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.sub,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 60, color: Colors.grey.shade300),
          const SizedBox(height: 14),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
          if (sub != null) ...[
            const SizedBox(height: 6),
            Text(
              sub!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ],
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// LOADING OVERLAY
// ──────────────────────────────────────────────────────────────────────────────

class LoadingOverlay extends StatelessWidget {
  const LoadingOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.green),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// GO TEXT FIELD
// ──────────────────────────────────────────────────────────────────────────────

class GoTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? hint;
  final bool obscure;
  final int maxLines;
  final TextInputType? keyboardType;
  final IconData? prefixIcon;
  final ValueChanged<String>? onChanged;

  const GoTextField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.obscure = false,
    this.maxLines = 1,
    this.keyboardType,
    this.prefixIcon,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      maxLines: maxLines,
      keyboardType: keyboardType,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// BOTTOM NAVIGATION BAR - FIXED
// ──────────────────────────────────────────────────────────────────────────────

class GoBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const GoBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // FIXED: Ensure currentIndex is within valid range (0-3)
    final validIndex = currentIndex.clamp(0, 3);

    return NavigationBar(
      backgroundColor: Colors.white,
      indicatorColor: AppColors.green.withOpacity(0.12),
      selectedIndex: validIndex,
      onDestinationSelected: onTap,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home, color: AppColors.green),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.favorite_outline),
          selectedIcon: Icon(Icons.favorite, color: AppColors.green),
          label: 'Matches',
        ),
        NavigationDestination(
          icon: Icon(Icons.description_outlined),
          selectedIcon: Icon(Icons.description, color: AppColors.green),
          label: 'Applications',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person, color: AppColors.green),
          label: 'Profile',
        ),
      ],
    );
  }
}
