import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/storage/local_storage_service.dart';
import 'video_player_screen.dart';
import '../../mock_test/presentation/premium_lock_screen.dart';

class LibraryTopicsScreen extends StatelessWidget {
  final String subjectName;
  final String subjectId;
  final bool isSubjectLocked;
  final List<Map<String, dynamic>> topics;

  const LibraryTopicsScreen({
    super.key,
    required this.subjectName,
    required this.subjectId,
    required this.isSubjectLocked,
    required this.topics,
  });

  @override
  Widget build(BuildContext context) {
    final entitlements = LocalStorageService().getEntitlements();
    final sem = LocalStorageService().semester;
    final hasSubjectEntitlement = entitlements.contains('subject_$subjectId') ||
        entitlements.contains('combo_sem$sem');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(subjectName),
      ),
      body: topics.isEmpty
          ? const Center(child: Text('শীঘ্রই এই বিষয়ের ভিডিও সংযুক্ত করা হবে'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: topics.length,
              itemBuilder: (context, index) {
                final topic = topics[index];
                final topicTitle = topic['title'] ?? 'ভিডিও লেকচার ${index + 1}';
                final youtubeId = topic['youtubeId'] ?? 'dQw4w9WgXcQ';
                final isFreePreview = topic['access'] == 'free';
                final isLocked = isSubjectLocked && !hasSubjectEntitlement && !isFreePreview;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isLocked ? AppColors.surfaceMuted : AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isLocked ? Icons.lock_outline_rounded : Icons.play_arrow_rounded,
                        color: isLocked ? AppColors.textMuted : AppColors.primary,
                        size: 26,
                      ),
                    ),
                    title: Text(
                      topicTitle,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
                    ),
                    subtitle: Text(
                      isLocked ? 'লক করা (সাবস্ক্রিপশন প্রয়োজন)' : (isFreePreview ? 'ফ্রি প্রিভিউ' : 'ভিডিও দেখুন'),
                      style: TextStyle(
                        fontSize: 12,
                        color: isLocked ? AppColors.premiumGold : AppColors.textSecondary,
                        fontWeight: isFreePreview ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMuted),
                    onTap: () {
                      if (isLocked) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PremiumLockScreen(
                              title: '$subjectName ভিডিও কোর্স',
                              grantType: 'subject_$subjectId',
                            ),
                          ),
                        );
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => VideoPlayerScreen(
                              title: topicTitle,
                              youtubeVideoId: youtubeId,
                            ),
                          ),
                        );
                      }
                    },
                  ),
                );
              },
            ),
    );
  }
}
