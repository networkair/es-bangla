import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class BookNotesScreen extends StatelessWidget {
  const BookNotesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header with Back button
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 20, 16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: const Border(bottom: BorderSide(color: AppColors.border, width: 1)),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.border),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary, size: 20),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Book Notes',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'বইয়ের নোটস ও স্পেশাল হ্যান্ডনোটস',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Coming Soon Body
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 88,
                        height: 88,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.primary.withOpacity(0.2), width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.1),
                              blurRadius: 18,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Image.asset(
                          'assets/icons/ic_book_notes.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 22),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'কামিং সুন • COMING SOON',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryDark,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'বইয়ের নোটস শীঘ্রই আসছে',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.3,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'সম্পূর্ণ নতুন সিস্টেমে প্রতিটি পাঠ্যবইয়ের বিশেষ গাইড, অধ্যায়ভিত্তিক হ্যান্ডনোটস ও সাজেশনস তৈরির কাজ চলছে। খুব শীঘ্রই এই সেকশনটি চালু করা হবে।',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
