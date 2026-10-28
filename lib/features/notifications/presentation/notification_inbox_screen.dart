import 'package:flutter/material.dart';
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
  final LocalStorageService _storage = LocalStorageService();

  @override
  void initState() {
    super.initState();
    // Mark announcements as read to clear the top-bar notification badge
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppNotificationService().markAllAsRead();
    });
  }

  Future<void> _confirmClearAll() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'বিজ্ঞপ্তি মুছে ফেলতে চান?',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: const Text(
          'আপনার ডিভাইসে সংরক্ষিত সমস্ত বিজ্ঞপ্তি মুছে ফেলা হবে।',
          style: TextStyle(fontSize: 14, color: Color(0xFF64748B), height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('বাতিল', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE11D48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('মুছে ফেলুন', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _storage.clearAllLocalNotifications();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('সমস্ত বিজ্ঞপ্তি মুছে ফেলা হয়েছে'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'বিজ্ঞপ্তি ইনবক্স (Announcements)',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
          ),
        ),
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          ValueListenableBuilder<List<Map<String, dynamic>>>(
            valueListenable: _storage.localNotificationsNotifier,
            builder: (context, notifications, _) {
              if (notifications.isEmpty) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.delete_sweep_outlined, color: Color(0xFFE11D48)),
                tooltip: 'সব মুছে ফেলুন',
                onPressed: _confirmClearAll,
              );
            },
          ),
        ],
      ),
      body: ValueListenableBuilder<List<Map<String, dynamic>>>(
        valueListenable: _storage.localNotificationsNotifier,
        builder: (context, notifications, _) {
          if (notifications.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.notifications_none_rounded,
                        size: 42,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'কোনো সংরক্ষিত বিজ্ঞপ্তি নেই',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'অ্যাডমিন থেকে পাঠানো সমস্ত নোটিফিকেশন আপনার ডিভাইসের লোকাল স্টোরেজে সংরক্ষিত থাকবে।',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13.5,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final item = notifications[index];
              final id = item['id']?.toString() ?? '';
              final title = (item['title'] ?? 'বিজ্ঞপ্তি').toString().trim();
              final body = (item['body'] ?? '').toString().trim();
              final imageUrl = (item['imageUrl'] ?? '').toString().trim();
              final actionUrl = (item['actionUrl'] ?? '').toString().trim();
              final bool hasLink = actionUrl.isNotEmpty &&
                  (actionUrl.startsWith('http://') || actionUrl.startsWith('https://'));

              DateTime timestamp = DateTime.now();
              final tsRaw = item['timestamp'];
              if (tsRaw is num) {
                timestamp = DateTime.fromMillisecondsSinceEpoch(tsRaw.toInt());
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (isDark ? Colors.black : const Color(0xFF0F172A))
                          .withOpacity(isDark ? 0.25 : 0.04),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: hasLink
                        ? () => SecurityManager.openExternalUrl(actionUrl)
                        : null,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header: Date & Delete icon
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.access_time_rounded,
                                    size: 13,
                                    color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    DateFormat('dd MMM yyyy, hh:mm a').format(timestamp),
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w500,
                                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                              InkWell(
                                onTap: () => _storage.deleteLocalNotification(id),
                                borderRadius: BorderRadius.circular(20),
                                child: Padding(
                                  padding: const EdgeInsets.all(4.0),
                                  child: Icon(
                                    Icons.close_rounded,
                                    size: 16,
                                    color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Title
                          Text(
                            title,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15.5,
                              color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                              height: 1.3,
                            ),
                          ),

                          if (body.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              body,
                              style: TextStyle(
                                fontSize: 13.5,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                                height: 1.45,
                              ),
                            ),
                          ],

                          // Image Banner Preview
                          if (imageUrl.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: AspectRatio(
                                aspectRatio: 16 / 9,
                                child: CachedNetworkImage(
                                  imageUrl: imageUrl,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => AppShimmer.banner16x9(borderRadius: 10),
                                  errorWidget: (context, url, error) => Container(
                                    color: isDark ? const Color(0xFF0F172A) : AppColors.surfaceMuted,
                                    child: const Center(
                                      child: Icon(Icons.broken_image_rounded, color: AppColors.textMuted, size: 28),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],

                          // Action Link Button
                          if (hasLink) ...[
                            const SizedBox(height: 14),
                            Align(
                              alignment: Alignment.centerRight,
                              child: ElevatedButton.icon(
                                onPressed: () => SecurityManager.openExternalUrl(actionUrl),
                                icon: const Icon(Icons.open_in_new_rounded, size: 14),
                                label: const Text('লিঙ্ক খুলুন', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2563EB),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
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
}
