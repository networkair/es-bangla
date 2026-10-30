import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/storage/local_storage_service.dart';
import '../../../core/services/entitlement_service.dart';
import '../../auth/presentation/login_screen.dart';
import '../data/youtube_helper.dart';
import 'video_player_screen.dart';
import 'course_subscription_screen.dart';
import 'native_video_helper.dart';

class LibraryTopicsScreen extends StatefulWidget {
  final int semester;
  final String subjectId;
  final String subjectName;
  final String subjectThumbnailUrl;

  const LibraryTopicsScreen({
    super.key,
    required this.semester,
    required this.subjectId,
    required this.subjectName,
    required this.subjectThumbnailUrl,
  });

  @override
  State<LibraryTopicsScreen> createState() => _LibraryTopicsScreenState();
}

class _LibraryTopicsScreenState extends State<LibraryTopicsScreen> {
  @override
  void initState() {
    super.initState();
    if (FirebaseAuth.instance.currentUser != null) {
      EntitlementService.syncUserEntitlements().then((_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header Bar (Clean Minimalist Back Button Only)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
              ),
              child: Row(
                children: [
                  // Circular Back Button
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
                ],
              ),
            ),

            // Real-Time Video Grid Stream with Live Entitlement Sync
            Expanded(
              child: StreamBuilder<List<String>>(
                stream: EntitlementService.liveUserEntitlementsStream(),
                initialData: EntitlementService.currentEntitlements,
                builder: (context, entSnapshot) {
                  return StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('library_videos')
                        .where('semester', isEqualTo: widget.semester)
                        .snapshots(),
                    builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation(AppColors.primary),
                      ),
                    );
                  }

                  final docs = snapshot.data?.docs ?? [];
                  List<Map<String, dynamic>> videos = [];

                  for (final doc in docs) {
                    final data = doc.data() as Map<String, dynamic>? ?? {};
                    final bool isActive = data['isActive'] ?? true;
                    if (!isActive) continue;

                    // Match by subjectId or subjectName
                    final docSubjId = (data['subjectId'] ?? '').toString().trim().toLowerCase();
                    final docSubjName = (data['subjectName'] ?? data['subject'] ?? '').toString().trim().toLowerCase();
                    final targetId = widget.subjectId.toLowerCase();
                    final targetName = widget.subjectName.toLowerCase();

                    final bool isBengali = targetId == 'bengali' || targetName.contains('বাংলা');
                    final bool isEnglish = targetId == 'english' || targetName.contains('english');

                    final bool matches = (docSubjId.isNotEmpty && (
                        docSubjId == targetId ||
                        (isBengali && (docSubjId == 'bangla' || docSubjId.contains('বাংলা'))) ||
                        (isEnglish && (docSubjId == 'eng' || docSubjId.contains('ইংরেজি')))
                      )) ||
                      (docSubjName.isNotEmpty && (
                        docSubjName == targetName ||
                        (isBengali && (docSubjName.contains('বাংলা') || docSubjName.contains('bangla') || docSubjName.contains('bengali'))) ||
                        (isEnglish && (docSubjName.contains('english') || docSubjName.contains('ইংরেজি') || docSubjName.contains('eng')))
                      ));

                    if (!matches) continue;

                    final title = (data['title'] ?? data['topicName'] ?? '').toString().trim();

                    videos.add({
                      'id': doc.id,
                      'title': title,
                      'thumbnailUrl': (data['thumbnailUrl'] ?? data['imageUrl'] ?? data['image'] ?? '').toString().trim(),
                      'youtubeInput': (data['youtubeUrl'] ?? data['youtubeVideoId'] ?? data['videoUrl'] ?? data['embedCode'] ?? '').toString().trim(),
                      'isFree': data['isFree'] ?? true,
                      'order': data['order'] is num ? (data['order'] as num).toInt() : 0,
                    });
                  }

                  // Sort by order ascending
                  videos.sort((a, b) => (a['order'] as int).compareTo(b['order'] as int));

                  if (videos.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: _buildEmptyState(),
                    );
                  }

                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        childAspectRatio: 1.32,
                      ),
                      itemCount: videos.length,
                      itemBuilder: (context, index) {
                        final video = videos[index];
                        return _buildVideoCard(video);
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),

            // Fixed Bottom Trust Banner (3D Card Design, Docked at Bottom)
            _buildFixedBottomBanner(),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoCard(Map<String, dynamic> video) {
    final String thumbnailUrl = video['thumbnailUrl'] ?? '';
    final String title = video['title'] ?? '';
    final String youtubeInput = video['youtubeInput'] ?? '';
    final bool isFree = video['isFree'] ?? true;

    final bool hasAccess = isFree ||
        EntitlementService.hasVideoAccess(
          widget.semester,
          subjectId: widget.subjectId,
          subjectName: widget.subjectName,
        );

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: hasAccess ? AppColors.border : AppColors.primary.withOpacity(0.3),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
          BoxShadow(
            color: hasAccess ? AppColors.primary.withOpacity(0.04) : AppColors.wrongRed.withOpacity(0.04),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            if (FirebaseAuth.instance.currentUser == null) {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
              if (FirebaseAuth.instance.currentUser == null) return;
              await EntitlementService.syncUserEntitlements();
              if (mounted) setState(() {});
            }

            await EntitlementService.syncUserEntitlements();
            final bool updatedAccess = isFree ||
                EntitlementService.hasVideoAccess(
                  widget.semester,
                  subjectId: widget.subjectId,
                  subjectName: widget.subjectName,
                );

            if (!updatedAccess) {
              final bool? unlocked = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => CourseSubscriptionScreen(
                    semester: widget.semester,
                    subjectName: widget.subjectName,
                    subjectId: widget.subjectId,
                  ),
                ),
              );
              if (unlocked == true && mounted) {
                setState(() {});
              }
              return;
            }

            final String videoId = YoutubeHelper.extractVideoId(youtubeInput);
            if (videoId.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('এই ভিডিওটির লিঙ্ক শীঘ্রই যুক্ত করা হবে।'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
              return;
            }

            NativeVideoHelper.playVideo(
              title: title.isNotEmpty ? title : widget.subjectName,
              videoId: videoId,
            );
          },
          borderRadius: BorderRadius.circular(18),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Background Thumbnail Image
                if (thumbnailUrl.isNotEmpty)
                  CachedNetworkImage(
                    imageUrl: thumbnailUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: AppColors.primaryLight.withOpacity(0.3),
                      child: const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(AppColors.primary)),
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => _buildFallbackTopicCard(title),
                  )
                else
                  _buildFallbackTopicCard(title),

                // Subtle dark overlay if locked
                if (!hasAccess)
                  Container(
                    color: Colors.black.withOpacity(0.35),
                  ),

                // Top-Right 3D Badge (FREE / UNLOCKED / LOCKED)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: hasAccess
                            ? (isFree ? AppColors.correctGreen : AppColors.primary)
                            : AppColors.wrongRed,
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.14),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!hasAccess) ...[
                          const Icon(Icons.lock_rounded, size: 10, color: AppColors.wrongRed),
                          const SizedBox(width: 3),
                        ],
                        Text(
                          hasAccess ? (isFree ? 'FREE' : 'UNLOCKED') : 'LOCKED',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                            color: hasAccess
                                ? (isFree ? AppColors.correctGreen : AppColors.primary)
                                : AppColors.wrongRed,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Bottom-Right 3D Circular Button (Play or Lock)
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: hasAccess ? Colors.white : AppColors.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.24),
                          blurRadius: 6,
                          offset: const Offset(0, 2.5),
                        ),
                        BoxShadow(
                          color: (hasAccess ? AppColors.primary : Colors.black).withOpacity(0.1),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        hasAccess ? Icons.play_arrow_rounded : Icons.lock_rounded,
                        color: hasAccess ? AppColors.primary : Colors.white,
                        size: hasAccess ? 22 : 16,
                      ),
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

  Widget _buildFallbackTopicCard(String title) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryLight.withOpacity(0.7),
            AppColors.surfaceMuted,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title.isNotEmpty ? title : 'ভিডিও লেকচার',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              height: 1.2,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildFixedBottomBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(top: BorderSide(color: AppColors.border, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.primary.withOpacity(0.18), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary.withOpacity(0.2)),
              ),
              child: const Icon(Icons.group_rounded, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'হাজারো শিক্ষার্থী ইতিমধ্যে Es Bangla-র সাথে নিয়মিত প্রস্তুতি নিচ্ছেন।',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.ondemand_video_rounded, size: 32, color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          Text(
            'শীঘ্রই ${widget.subjectName}-এর ক্লাস যুক্ত করা হবে',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          const Text(
            'আমাদের শিক্ষকবৃন্দ এই বিষয়ের প্রতিটি অধ্যায়ের ভিডিও ক্লাস প্রস্তুত করছেন, খুব শীঘ্রই এগুলো এখানে যুক্ত করা হবে।',
            style: TextStyle(
              fontSize: 12.5,
              color: AppColors.textSecondary,
              height: 1.45,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
