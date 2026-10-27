import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/storage/local_storage_service.dart';
import 'mock_subject_select_screen.dart';

class MockTestLandingScreen extends StatelessWidget {
  const MockTestLandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentSem = LocalStorageService().semester;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mock Test'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Sem $currentSem',
              style: const TextStyle(
                color: AppColors.primaryDark,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'নিজেকে যাচাই করুন, আরও ভালো প্রস্তুতি নিন!',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),

            // Free Mock Test Card
            _buildTestTypeCard(
              context: context,
              title: 'ফ্রি মক টেস্ট',
              subtitle: 'বিভিন্ন বিষয়ের উপর ফ্রি মক টেস্ট দিয়ে নিজের প্রস্তুতি যাচাই করুন।',
              badge: 'FREE',
              badgeColor: AppColors.primary,
              features: ['সব বিষয়', 'সব অধ্যায়', 'সীমাহীন অনুশীলন'],
              buttonText: 'এখনই মক টেস্ট দিন',
              isPremium: false,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MockSubjectSelectScreen(isPremiumMode: false),
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            // Premium Mock Test Card
            _buildTestTypeCard(
              context: context,
              title: 'প্রিমিয়াম মক টেস্ট',
              subtitle: 'আরও বেশি প্রশ্ন, বিস্তারিত সমাধান এবং ১০০% অ্যাড-ফ্রি বিশেষ অভিজ্ঞতা।',
              badge: 'PREMIUM',
              badgeColor: AppColors.premiumGold,
              features: ['বিশেষ প্রশ্নপত্র', 'বিস্তারিত বিশ্লেষণ', 'পরীক্ষায় সর্বোচ্চ প্রস্তুতি'],
              buttonText: 'প্রিমিয়াম মক টেস্ট দেখুন',
              isPremium: true,
              onTap: () {
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

  Widget _buildTestTypeCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String badge,
    required Color badgeColor,
    required List<String> features,
    required String buttonText,
    required bool isPremium,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isPremium ? AppColors.premiumGold.withOpacity(0.3) : AppColors.border,
          width: isPremium ? 1.5 : 1,
        ),
        boxShadow: AppColors.softCardShadow,
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isPremium ? AppColors.premiumLight : AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    color: badgeColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Icon(
                isPremium ? Icons.workspace_premium_rounded : Icons.quiz_outlined,
                color: badgeColor,
                size: 26,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: features.map((f) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_rounded, size: 14, color: badgeColor),
                    const SizedBox(width: 6),
                    Text(
                      f,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: isPremium ? AppColors.premiumGold : AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    buttonText,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded, size: 18, color: Colors.white),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
