import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import 'library_subjects_screen.dart';

class LibraryMainScreen extends StatelessWidget {
  const LibraryMainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Library 📚'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Top Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primary.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'ভিডিও লাইব্রেরি',
                          style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'শিখুন, দেখুন নিজেকে এগিয়ে নিন',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'দ্বাদশ শ্রেণির সমস্ত বিষয়ের শিক্ষামূলক ভিডিও এক জায়গায় সাজানো রয়েছে।',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Semester 3 Card
            _buildSemesterCard(
              context: context,
              title: 'Semester 3',
              subtitle: 'দ্বাদশ শ্রেণি সেমিস্টার ৩-এর সমস্ত বিষয়ের ভিডিও লেকচার',
              semester: 3,
            ),
            const SizedBox(height: 16),

            // Semester 4 Card
            _buildSemesterCard(
              context: context,
              title: 'Semester 4',
              subtitle: 'দ্বাদশ শ্রেণি সেমিস্টার ৪-এর সমস্ত বিষয়ের ভিডিও লেকচার',
              semester: 4,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSemesterCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required int semester,
  }) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => LibrarySubjectsScreen(semester: semester),
            ),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.school_rounded, color: AppColors.primary, size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.3),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: const [
                        Text(
                          'এখানে দেখুন',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward_rounded, size: 14, color: AppColors.primary),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
