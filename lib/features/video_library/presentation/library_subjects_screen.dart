import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/storage/local_storage_service.dart';
import '../../../core/services/entitlement_service.dart';
import 'library_topics_screen.dart';
import 'course_subscription_screen.dart';

class LibrarySubjectItem {
  final String id;
  final String name;
  final String thumbnailAsset;

  const LibrarySubjectItem({
    required this.id,
    required this.name,
    required this.thumbnailAsset,
  });
}

class LibrarySubjectsScreen extends StatelessWidget {
  final int semester;

  const LibrarySubjectsScreen({super.key, required this.semester});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Pre-configured static subjects for Semester 3
    final List<LibrarySubjectItem> subjects = semester == 3
        ? [
            const LibrarySubjectItem(
              id: 'bengali',
              name: 'বাংলা',
              thumbnailAsset: 'assets/images/lib_sub_bengali_sem3.png',
            ),
            const LibrarySubjectItem(
              id: 'english',
              name: 'English',
              thumbnailAsset: 'assets/images/lib_sub_english_sem3.png',
            ),
          ]
        : [];

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Navigation Bar (Only Back Button, completely clean)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.arrow_back_rounded,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Subjects List (16:9 Cards with subtle bottom shadow)
            Expanded(
              child: subjects.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.hourglass_top_rounded,
                                size: 40,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 18),
                            Text(
                              'Coming Soon',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'সেমিস্টার $semester-এর বিষয়ভিত্তিক ভিডিও ক্লাস শীঘ্রই যুক্ত করা হবে।',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('app_settings')
                          .doc('subject_locks')
                          .snapshots(),
                      builder: (context, lockSnapshot) {
                        final lockData = lockSnapshot.data?.data() as Map<String, dynamic>? ?? {};

                        return StreamBuilder<List<String>>(
                          stream: EntitlementService.liveUserEntitlementsStream(),
                          initialData: EntitlementService.currentEntitlements,
                          builder: (context, entSnapshot) {
                            final entitlements = entSnapshot.data ?? [];
                            final hasSemesterVip = entitlements.contains('video_library_sem$semester') ||
                                entitlements.contains('video_library_all') ||
                                entitlements.contains('combo_sem$semester') ||
                                entitlements.contains('combo_all');

                            return ListView.builder(
                              physics: const BouncingScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                              itemCount: subjects.length,
                              itemBuilder: (context, index) {
                                final subject = subjects[index];
                                final isLocked = lockData['sem${semester}_${subject.id}_locked'] == true;
                                final hasSubjectVip = hasSemesterVip || entitlements.contains('subject_${subject.id}');
                                final showLocked = isLocked && !hasSubjectVip;

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: _buildSubjectCard(
                                    context: context,
                                    subject: subject,
                                    isDark: isDark,
                                    isLocked: showLocked,
                                    onSubjectTap: () {
                                      if (showLocked) {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => CourseSubscriptionScreen(
                                              semester: semester,
                                              subjectName: subject.name,
                                              subjectId: subject.id,
                                            ),
                                          ),
                                        );
                                      } else {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => LibraryTopicsScreen(
                                              semester: semester,
                                              subjectId: subject.id,
                                              subjectName: subject.name,
                                              subjectThumbnailUrl: subject.thumbnailAsset,
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectCard({
    required BuildContext context,
    required LibrarySubjectItem subject,
    required bool isDark,
    required bool isLocked,
    required VoidCallback onSubjectTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : const Color(0xFF000000)).withOpacity(isDark ? 0.30 : 0.08),
            blurRadius: 10,
            spreadRadius: 0.5,
            offset: const Offset(0, 4), // Subtle bottom shadow
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onSubjectTap,
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.asset(
                    subject.thumbnailAsset,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: AppColors.primaryLight,
                        child: Center(
                          child: Text(
                            subject.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              if (isLocked)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.75),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.amber.withOpacity(0.6), width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.4),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock_rounded, color: Colors.amber, size: 13),
                        SizedBox(width: 4),
                        Text(
                          'লকড (PRO)',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
