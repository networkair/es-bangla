import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/storage/local_storage_service.dart';
import '../../../core/widgets/app_shimmer.dart';
import '../../../core/notifications/app_notification_service.dart';
import '../../../core/utils/security_manager.dart';

class NotificationInboxScreen extends StatefulWidget {
  const NotificationInboxScreen({super.key});

  @override
  State<NotificationInboxScreen> createState() => _NotificationInboxScreenState();
}

class _NotificationInboxScreenState extends State<NotificationInboxScreen> {
  @override
  void initState() {
    super.initState();
    // Mark announcements as read to clear the top-bar notification badge
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppNotificationService().markAllAsRead();
    });
  }

  @override
  Widget build(BuildContext context) {
    final sem = LocalStorageService().semester;
    final semKey1 = 'c12_sem$sem';
    final semKey2 = 'sem$sem';
    final semKey3 = sem.toString();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('বিজ্ঞপ্তি ইনবক্স (Announcements)'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('notifications').snapshots(),
        builder: (context, snapshot) {
          // Shimmer loading placeholder while fetching real-time data
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return _buildShimmerLoading();
          }

          final allDocs = snapshot.data?.docs ?? [];
          final List<Map<String, dynamic>> notifications = [];

          for (final doc in allDocs) {
            final data = doc.data() as Map<String, dynamic>? ?? {};
            final bool isActive = data['isActive'] ?? true;
            if (!isActive) continue;

            final audience = (data['audience'] ?? 'all').toString().trim().toLowerCase();
            final bool isTarget = audience == 'all' ||
                audience == semKey1 ||
                audience == semKey2 ||
                audience == semKey3 ||
                audience == '0';

            if (!isTarget) continue;

            final title = (data['title'] ?? 'বিজ্ঞপ্তি').toString().trim();
            final body = (data['body'] ?? data['message'] ?? '').toString().trim();
            final imageUrl = (data['imageUrl'] ?? data['image'] ?? '').toString().trim();
            final actionUrl = (data['actionUrl'] ?? data['link'] ?? data['redirectUrl'] ?? '').toString().trim();
            final createdAt = (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();

            notifications.add({
              'id': doc.id,
              'title': title,
              'body': body,
              'imageUrl': imageUrl,
              'actionUrl': actionUrl,
              'createdAt': createdAt,
            });
          }

          // Sort by newest first
          notifications.sort((a, b) => (b['createdAt'] as DateTime).compareTo(a['createdAt'] as DateTime));

          if (notifications.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 76,
                      height: 76,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryLight,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.notifications_none_rounded, size: 40, color: AppColors.primary),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'কোনো নতুন বিজ্ঞপ্তি নেই',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'গুরুত্বপূর্ণ নোটিশ, রুটিন ও ক্লাসের আপডেট এখানে রিয়েল-টাইমে দেখতে পাবেন।',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13.5, color: AppColors.textSecondary, height: 1.4),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final item = notifications[index];
              final title = item['title'] as String;
              final body = item['body'] as String;
              final imageUrl = item['imageUrl'] as String;
              final actionUrl = item['actionUrl'] as String;
              final timestamp = item['createdAt'] as DateTime;
              final bool hasLink = actionUrl.isNotEmpty;

              return Card(
                margin: const EdgeInsets.only(bottom: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: AppColors.border, width: 1.2),
                ),
                elevation: 1,
                shadowColor: Colors.black.withOpacity(0.04),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    if (hasLink) {
                      SecurityManager.openExternalUrl(actionUrl);
                    } else {
                      // Navigate back to HomeScreen if no external link provided
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top Header: Tag & Timestamp
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDC2626), // RED TAG
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'ANNOUNCEMENT',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            Text(
                              DateFormat('dd MMM, hh:mm a').format(timestamp),
                              style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Title
                        Text(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15.5,
                            color: AppColors.textPrimary,
                            height: 1.3,
                          ),
                        ),

                        if (body.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            body,
                            style: const TextStyle(fontSize: 13.5, color: AppColors.textSecondary, height: 1.45),
                          ),
                        ],

                        // Image Banner Preview (if provided)
                        if (imageUrl.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: AspectRatio(
                              aspectRatio: 16 / 9,
                              child: CachedNetworkImage(
                                imageUrl: imageUrl,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => AppShimmer.banner16x9(borderRadius: 6),
                                errorWidget: (context, url, error) => Container(
                                  color: AppColors.surfaceMuted,
                                  child: const Center(
                                    child: Icon(Icons.broken_image_rounded, color: AppColors.textMuted, size: 30),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(height: 12),

                        // Bottom Action Link or Home Action
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (hasLink)
                              ElevatedButton.icon(
                                onPressed: () => SecurityManager.openExternalUrl(actionUrl),
                                icon: const Icon(Icons.open_in_new_rounded, size: 14),
                                label: const Text('লিঙ্ক খুলুন', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                              )
                            else
                              TextButton.icon(
                                onPressed: () {
                                  Navigator.of(context).popUntil((route) => route.isFirst);
                                },
                                icon: const Icon(Icons.home_rounded, size: 15, color: AppColors.primary),
                                label: const Text(
                                  'হোম পেজে যান',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                                ),
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 4,
      itemBuilder: (context, index) {
        return AppShimmer(
          child: Container(
            margin: const EdgeInsets.only(bottom: 14),
            height: 140,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
          ),
        );
      },
    );
  }
}
