import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/storage/local_storage_service.dart';
import '../../../core/services/entitlement_service.dart';
import '../../auth/presentation/login_screen.dart';
import 'mock_subject_select_screen.dart';
import 'premium_lock_screen.dart';

class MockTestLandingScreen extends StatelessWidget {
  const MockTestLandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: LocalStorageService().semesterNotifier,
      builder: (context, currentSem, _) {
        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            title: const Text(
              'Mock Test',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            centerTitle: false,
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFBFDBFE), width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.school_rounded, size: 14, color: Color(0xFF2563EB)),
                    const SizedBox(width: 5),
                    Text(
                      'Semester $currentSem',
                      style: const TextStyle(
                        color: Color(0xFF2563EB),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          body: const SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(18, 12, 18, 32),
            physics: ClampingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Title & Subtitle in 100% clean English
                Text(
                  'Mock Test Portal',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.4,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Test your knowledge, evaluate accuracy, and accelerate exam preparation.',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                    height: 1.4,
                  ),
                ),
                SizedBox(height: 20),

                // 1. Free Mock Test Card with Lottie Student Animation
                _FreeMockCard(),

                SizedBox(height: 22),

                // 2. Premium Mock Test Card with Lottie Gold Medal Badge
                _PremiumMockCard(),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// 1. Free Mock Test Card (Isolated in RepaintBoundary for 60/120 FPS Scrolling)
class _FreeMockCard extends StatelessWidget {
  const _FreeMockCard();

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color(0xFFE2E8F0),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2563EB).withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFBFDBFE), width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.verified_outlined, size: 14, color: Color(0xFF2563EB)),
                  SizedBox(width: 5),
                  Text(
                    'FREE',
                    style: TextStyle(
                      color: Color(0xFF2563EB),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Content Row: Title + Subtitle on Left, Lottie Animation on Right
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Free Mock Test',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.3,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Assess your preparation with chapter-wise free mock test sets and timed quizzes.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF64748B),
                          height: 1.45,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                RepaintBoundary(
                  child: SizedBox(
                    width: 115,
                    height: 115,
                    child: Lottie.asset(
                      'assets/animations/mock_free_student.json',
                      fit: BoxFit.contain,
                      repeat: true,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 3 Feature Icon Pills Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: const [
                _FeatureItemPill(
                  icon: Icons.auto_stories_rounded,
                  iconColor: Color(0xFF059669),
                  bgColor: Color(0xFFECFDF5),
                  label: 'All Subjects',
                ),
                _FeatureItemPill(
                  icon: Icons.layers_rounded,
                  iconColor: Color(0xFF7C3AED),
                  bgColor: Color(0xFFF5F3FF),
                  label: 'All Chapters',
                ),
                _FeatureItemPill(
                  icon: Icons.all_inclusive_rounded,
                  iconColor: Color(0xFFE11D48),
                  bgColor: Color(0xFFFFF1F2),
                  label: 'Unlimited',
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Action Button
            _MockActionButton(
              text: 'Take Free Mock Test',
              buttonColor: const Color(0xFF2563EB),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MockSubjectSelectScreen(isPremiumMode: false),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// 2. Premium Mock Test Card (Isolated in RepaintBoundary for 60/120 FPS Scrolling)
class _PremiumMockCard extends StatelessWidget {
  const _PremiumMockCard();

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color(0xFFFDE68A),
            width: 1.4,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFF59E0B).withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFFCD34D), width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.workspace_premium_rounded, size: 15, color: Color(0xFFB45309)),
                  SizedBox(width: 5),
                  Text(
                    'PREMIUM',
                    style: TextStyle(
                      color: Color(0xFFB45309),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Content Row: Title + Subtitle on Left, Lottie Animation on Right
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Premium Mock Test',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF78350F),
                          letterSpacing: -0.3,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Exclusive question banks, in-depth solution reviews, and a 100% ad-free experience.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF78716C),
                          height: 1.45,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                RepaintBoundary(
                  child: SizedBox(
                    width: 110,
                    height: 110,
                    child: Lottie.asset(
                      'assets/animations/mock_premium_badge.json',
                      fit: BoxFit.contain,
                      repeat: true,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 3 Feature Icon Pills Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: const [
                _FeatureItemPill(
                  icon: Icons.assignment_turned_in_rounded,
                  iconColor: Color(0xFFE11D48),
                  bgColor: Color(0xFFFFF1F2),
                  label: 'Exclusive Sets',
                ),
                _FeatureItemPill(
                  icon: Icons.bar_chart_rounded,
                  iconColor: Color(0xFF2563EB),
                  bgColor: Color(0xFFEFF6FF),
                  label: 'Full Analytics',
                ),
                _FeatureItemPill(
                  icon: Icons.verified_user_rounded,
                  iconColor: Color(0xFF059669),
                  bgColor: Color(0xFFECFDF5),
                  label: '100% Ad-Free',
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Action Button
            _MockActionButton(
              text: 'Explore Premium Mock Tests',
              buttonColor: const Color(0xFFF59E0B),
              onTap: () async {
                if (FirebaseAuth.instance.currentUser == null) {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                  if (FirebaseAuth.instance.currentUser == null) return;
                }

                final sem = LocalStorageService().semester;
                await EntitlementService.syncUserEntitlements();
                final hasAccess = EntitlementService.hasMockAccess(sem);

                if (!context.mounted) return;

                if (!hasAccess) {
                  final unlocked = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PremiumLockScreen(
                        title: 'সেমিস্টার $sem প্রিমিয়াম মক টেস্ট',
                        grantType: 'premium_mock_sem$sem',
                      ),
                    ),
                  );
                  if (unlocked != true) return;
                }

                if (!context.mounted) return;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MockSubjectSelectScreen(isPremiumMode: true),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Feature Item Pill (Icon on top, Label on bottom)
class _FeatureItemPill extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final String label;

  const _FeatureItemPill({
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: iconColor.withOpacity(0.20), width: 1.0),
          ),
          child: Center(
            child: Icon(icon, color: iconColor, size: 22),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xFF334155),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// Action Button with Right Circle Icon
class _MockActionButton extends StatelessWidget {
  final String text;
  final Color buttonColor;
  final VoidCallback onTap;

  const _MockActionButton({
    required this.text,
    required this.buttonColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        color: buttonColor,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: buttonColor.withOpacity(0.28),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(25),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                const SizedBox(width: 32),
                Expanded(
                  child: Text(
                    text,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.24),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
