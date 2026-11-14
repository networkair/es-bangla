import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/storage/local_storage_service.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/utils/security_manager.dart';
import '../../pdf_notes/presentation/notes_subjects_screen.dart';
import '../../pdf_notes/presentation/pyq_screen.dart';
import '../../reminder/presentation/reminder_screen.dart';
import '../../notepad/presentation/notepad_screen.dart';
import '../../notifications/presentation/notification_inbox_screen.dart';
import '../../book_notes/presentation/book_notes_screen.dart';
import '../../../core/widgets/app_shimmer.dart';
import '../../../core/widgets/academic_selection_modal.dart';
import '../../../core/notifications/app_notification_service.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback onSemesterChanged;

  const HomeScreen({super.key, required this.onSemesterChanged});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final LocalStorageService _storage = LocalStorageService();

  @override
  Widget build(BuildContext context) {
    final currentSem = _storage.semester;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 20,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.35 : 0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.asset(
                'assets/icons/app_logo.png',
                fit: BoxFit.cover,
                cacheWidth: 100,
                cacheHeight: 100,
              ),
            ),
            Container(
              width: 1.2,
              height: 22,
              margin: const EdgeInsets.symmetric(horizontal: 10),
              color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'Es ',
                        style: TextStyle(
                          fontFamily: 'AppTitleFont',
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                          color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F1E36),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const TextSpan(
                        text: 'Bangla',
                        style: TextStyle(
                          fontFamily: 'AppTitleFont',
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0070F3), // Vibrant Royal Blue
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                // Golden brushstroke accent below 'Bangla'
                Container(
                  margin: const EdgeInsets.only(left: 36, top: 1),
                  width: 38,
                  height: 3,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationInboxScreen()),
              );
            },
            icon: ValueListenableBuilder<int>(
              valueListenable: AppNotificationService().unreadCountNotifier,
              builder: (context, unreadCount, _) {
                return Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE0F2FE),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.notifications_none_rounded,
                        color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F1E36),
                        size: 22,
                      ),
                    ),
                    if (unreadCount > 0)
                      Positioned(
                        right: 4,
                        top: 4,
                        child: Container(
                          width: 9,
                          height: 9,
                          decoration: const BoxDecoration(
                            color: Color(0xFFDC2626),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(width: 14),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Hero News Slider (Smooth, Isolated, Thin Black Stroke Border)
            _HomeNewsSlider(
              currentSem: currentSem,
              isDark: isDark,
              onNewsTap: _showNewsDetailsModal,
            ),

            // Content Area with Clean, Balanced Spacing & Matching Canvas
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 2. Quick Action Cards (Notepad + Study Reminder)
                  RepaintBoundary(
                    child: _buildQuickActionCardsRow(isDark),
                  ),
                  const SizedBox(height: 12),

                  // 3. Active Semester Card (Shows only the selected semester)
                  RepaintBoundary(
                    child: currentSem == 3
                        ? _buildSemesterTile(
                            title: 'SEMESTER 3',
                            semester: 3,
                            iconAsset: 'assets/icons/ic_sem3.png',
                            buttonBgColor: const Color(0xFFE0F2FE),
                            buttonIconColor: const Color(0xFF0070F3),
                          )
                        : _buildSemesterTile(
                            title: 'SEMESTER 4',
                            semester: 4,
                            iconAsset: 'assets/icons/ic_sem4.png',
                            buttonBgColor: const Color(0xFFFFEDD5),
                            buttonIconColor: const Color(0xFFD97706),
                          ),
                  ),
                  const SizedBox(height: 13),

                  // 4. Previous Year Questions (PYQ) Horizontal Card
                  RepaintBoundary(
                    child: _buildActionTile(
                      title: 'PREVIOUS YEARS\nQUESTIONS',
                      iconAsset: 'assets/icons/ic_pyq.png',
                      accentLineColor: const Color(0xFF0070F3),
                      buttonBgColor: const Color(0xFFE0F2FE),
                      buttonIconColor: const Color(0xFF0070F3),
                      isTwoLineTitle: true,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const PyqScreen()),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 13),

                  // 5. Es Store Horizontal Card
                  RepaintBoundary(
                    child: _buildActionTile(
                      title: 'Es Store',
                      iconAsset: 'assets/icons/ic_store.png',
                      accentLineColor: const Color(0xFFF59E0B),
                      buttonBgColor: const Color(0xFFFFEDD5),
                      buttonIconColor: const Color(0xFFD97706),
                      isTwoLineTitle: false,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const BookNotesScreen()),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 13),

                  // 6. Authentic Es Bangla Social Media Hub
                  RepaintBoundary(
                    child: _buildSocialMediaSection(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== 1. NEWS DETAILS MODAL ====================


  void _showNewsDetailsModal(Map<String, dynamic> item) {
    final title = item['title'] ?? '';
    final subtitle = item['subtitle'] ?? '';
    final tag = item['tag'] ?? 'ES BANGLA';
    final redirectUrl = (item['redirectUrl'] ?? '').toString().trim();
    final imageUrl = (item['imageUrl'] ?? '').toString().trim();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isModalDark = Theme.of(ctx).brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            color: isModalDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 28,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isModalDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              if (imageUrl.isNotEmpty) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      memCacheWidth: 800,
                      memCacheHeight: 450,
                      placeholder: (context, url) => AppShimmer.banner16x9(borderRadius: 12),
                      errorWidget: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              Text(
                title,
                style: TextStyle(
                  fontSize: 17.5,
                  fontWeight: FontWeight.bold,
                  color: isModalDark ? Colors.white : const Color(0xFF0F172A),
                  height: 1.3,
                ),
              ),

              if (subtitle.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13.5,
                    color: isModalDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                    height: 1.5,
                  ),
                ),
              ],

              if (redirectUrl.isNotEmpty) ...[
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          SecurityManager.openExternalUrl(redirectUrl);
                        },
                        icon: const Icon(Icons.open_in_new_rounded, size: 18),
                        label: const Text('লিঙ্ক খুলুন', style: TextStyle(fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: redirectUrl));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('লিঙ্ক ক্লিপবোর্ডে কপি করা হয়েছে!'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy_rounded, color: AppColors.textSecondary),
                      tooltip: 'লিঙ্ক কপি করুন',
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  // ==================== PREMIUM CARD BOTTOM SHADOW (HARDWARE-ACCELERATED) ====================
  List<BoxShadow> _buildPremiumCardShadow(bool isDark) {
    if (isDark) {
      return [
        BoxShadow(
          color: Colors.black.withOpacity(0.28),
          offset: const Offset(0, 4),
          blurRadius: 8,
        ),
      ];
    }
    return [
      BoxShadow(
        color: const Color(0xFF18273D).withOpacity(0.06),
        offset: const Offset(0, 4),
        blurRadius: 8,
      ),
    ];
  }

  // ==================== 2. QUICK ACTION CARDS (NOTEPAD & STUDY REMINDER) ====================
  Widget _buildQuickActionCardsRow(bool isDark) {
    return Row(
      children: [
        // Left: Study Notepad Card
        Expanded(
          child: _buildQuickActionCard(
            titleLine1: 'STUDY',
            titleLine2: 'NOTEPAD',
            iconAsset: 'assets/icons/ic_notepad.png',
            iconBgColor: isDark ? const Color(0xFF334155) : Colors.white,
            cardBgColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
            borderColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            arrowColor: const Color(0xFF0070F3),
            arrowBgColor: isDark ? const Color(0xFF334155) : Colors.white,
            isDark: isDark,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotepadScreen()),
              );
            },
          ),
        ),
        const SizedBox(width: 12),

        // Right: Study Reminder Card
        Expanded(
          child: _buildQuickActionCard(
            titleLine1: 'STUDY',
            titleLine2: 'REMINDER',
            iconAsset: 'assets/icons/ic_reminder_goal.png',
            iconBgColor: isDark ? const Color(0xFF334155) : Colors.white,
            cardBgColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFFFFBEB),
            borderColor: isDark ? const Color(0xFF334155) : const Color(0xFFFDE68A).withOpacity(0.7),
            arrowColor: const Color(0xFFD97706),
            arrowBgColor: isDark ? const Color(0xFF334155) : Colors.white,
            isDark: isDark,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ReminderScreen()),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionCard({
    required String titleLine1,
    required String titleLine2,
    required String iconAsset,
    required Color iconBgColor,
    required Color cardBgColor,
    required Color borderColor,
    required Color arrowColor,
    required Color arrowBgColor,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: borderColor,
          width: 1.0,
        ),
        boxShadow: _buildPremiumCardShadow(isDark),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            child: Row(
              children: [
                // Icon Circle with 3D Image Asset
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 4,
                        offset: const Offset(0, 1.5),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Image.asset(
                      iconAsset,
                      width: 25,
                      height: 25,
                      fit: BoxFit.contain,
                      cacheWidth: 80,
                      cacheHeight: 80,
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Title (2 lines)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        titleLine1,
                        style: TextStyle(
                          fontFamily: 'sans-serif',
                          fontSize: 12.0,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                          height: 1.15,
                          color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F1E36),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        titleLine2,
                        style: TextStyle(
                          fontFamily: 'sans-serif',
                          fontSize: 12.0,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                          height: 1.15,
                          color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F1E36),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),

                // Small chevron arrow button
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: arrowBgColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 10,
                      color: arrowColor,
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

  // ==================== 3. SEMESTER CARDS (WIDE HORIZONTAL) ====================
  Widget _buildSemesterTile({
    required String title,
    required int semester,
    required String iconAsset,
    required Color buttonBgColor,
    required Color buttonIconColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: _buildPremiumCardShadow(isDark),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(30),
        child: InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => NotesSubjectsScreen(semester: semester)),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
            child: Row(
              children: [
                // Left: 3D Semester Book Icon (uses icon's own circular badge, no duplicate background)
                SizedBox(
                  width: 76,
                  height: 76,
                  child: Center(
                    child: Image.asset(
                      iconAsset,
                      width: 76,
                      height: 76,
                      fit: BoxFit.contain,
                      cacheWidth: 200,
                      cacheHeight: 200,
                    ),
                  ),
                ),
                  const SizedBox(width: 16),

                  // Center/Right: Title, Accent Underline & '99% Common' Badge
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontFamily: 'sans-serif',
                            fontSize: 17.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.3,
                            color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F1E36),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: 36,
                          height: 3.5,
                          decoration: BoxDecoration(
                            color: buttonIconColor,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Builder(
                          builder: (context) {
                            final badgeBgColor = isDark
                                ? const Color(0xFF1E293B)
                                : const Color(0xFFEFF6FF);
                            final badgeBorderColor = isDark
                                ? const Color(0xFF334155)
                                : const Color(0xFFBFDBFE);
                            final badgeTextColor = isDark
                                ? const Color(0xFFF8FAFC)
                                : const Color(0xFF000000);

                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                              decoration: BoxDecoration(
                                color: badgeBgColor,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: badgeBorderColor,
                                  width: 1.0,
                                ),
                              ),
                              child: Text(
                                '99% Common',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.3,
                                  color: badgeTextColor,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
  }

  // ==================== 4 & 5. ACTION CARDS (PYQ & PREMIUM STORE) ====================
  Widget _buildActionTile({
    required String title,
    required String iconAsset,
    required Color accentLineColor,
    required Color buttonBgColor,
    required Color buttonIconColor,
    required VoidCallback onTap,
    bool isTwoLineTitle = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: _buildPremiumCardShadow(isDark),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(30),
        child: InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
            child: Row(
              children: [
                // Left: Circular icon wrap matching HTML demo
                Container(
                  width: 78,
                  height: 78,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF334155) : buttonBgColor,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Image.asset(
                      iconAsset,
                      width: 54,
                      height: 54,
                      fit: BoxFit.contain,
                      cacheWidth: 160,
                      cacheHeight: 160,
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Center: Title & Accent Underline matching demo
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontFamily: 'sans-serif',
                          fontSize: isTwoLineTitle ? 15.5 : 17.0,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.2,
                          height: 1.22,
                          color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F1E36),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: 36,
                        height: 3.5,
                        decoration: BoxDecoration(
                          color: accentLineColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==================== 6. AUTHENTIC ES BANGLA SOCIAL HUB ====================
  Widget _buildSocialMediaSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Clean Section Header
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 12),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE0F2FE),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.public_rounded,
                    size: 16,
                    color: Color(0xFF0070F3),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'OFFICIAL SOCIAL MEDIA',
                style: TextStyle(
                  fontFamily: 'sans-serif',
                  fontSize: 13.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.4,
                  color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F1E36),
                ),
              ),
            ],
          ),
        ),

        // 1. Prominent Highlighted WhatsApp VIP Card
        _buildHighlightedWhatsAppCard(isDark),
        const SizedBox(height: 12),

        // 2. Row: YouTube (Left) & Telegram (Right)
        Row(
          children: [
            Expanded(
              child: _buildSocialPillCard(
                name: 'YouTube',
                iconAsset: 'assets/icons/ic_youtube.png',
                iconBgColor: isDark ? const Color(0xFF7F1D1D).withOpacity(0.4) : const Color(0xFFFEE2E2),
                arrowColor: const Color(0xFFDC2626),
                arrowBgColor: isDark ? const Color(0xFF7F1D1D).withOpacity(0.3) : const Color(0xFFFEE2E2),
                url: ApiConstants.youtubeChannelUrl,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSocialPillCard(
                name: 'Telegram',
                iconAsset: 'assets/icons/ic_telegram.png',
                iconBgColor: isDark ? const Color(0xFF0C4A6E).withOpacity(0.4) : const Color(0xFFE0F2FE),
                arrowColor: const Color(0xFF0284C7),
                arrowBgColor: isDark ? const Color(0xFF0C4A6E).withOpacity(0.3) : const Color(0xFFE0F2FE),
                url: ApiConstants.telegramChannelUrl,
                isDark: isDark,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHighlightedWhatsAppCard(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? const Color(0xFF059669).withOpacity(0.45) : const Color(0xFF86EFAC),
          width: 1.2,
        ),
        boxShadow: _buildPremiumCardShadow(isDark),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => SecurityManager.openExternalUrl(ApiConstants.whatsappUrl),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            child: Row(
              children: [
                // WhatsApp 3D Icon wrap with subtle green glow
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF064E3B).withOpacity(0.5) : const Color(0xFFDCFCE7),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Image.asset(
                      'assets/icons/ic_whatsapp.png',
                      width: 32,
                      height: 32,
                      fit: BoxFit.contain,
                      cacheWidth: 100,
                      cacheHeight: 100,
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Texts: Title + Subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              'WhatsApp Channel',
                              style: TextStyle(
                                fontFamily: 'sans-serif',
                                fontSize: 15.0,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.2,
                                color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F1E36),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF16A34A),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'OFFICIAL',
                              style: TextStyle(
                                fontSize: 8.5,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Suggestions, Notes & Study Updates',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),

                // Highlighted Action Button (Green Pill)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16A34A),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF16A34A).withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text(
                        'Join',
                        style: TextStyle(
                          fontSize: 12.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 13,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialPillCard({
    required String name,
    required String iconAsset,
    required Color iconBgColor,
    required Color arrowColor,
    required Color arrowBgColor,
    required String url,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE8EDF4),
          width: 1.0,
        ),
        boxShadow: _buildPremiumCardShadow(isDark),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () => SecurityManager.openExternalUrl(url),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                // Icon container with comfortable pastel tint
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Image.asset(
                      iconAsset,
                      width: 25,
                      height: 25,
                      fit: BoxFit.contain,
                      cacheWidth: 80,
                      cacheHeight: 80,
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Channel Name (Clean, single bold line, strictly NO subtitles)
                Expanded(
                  child: Text(
                    name,
                    style: TextStyle(
                      fontFamily: 'sans-serif',
                      fontSize: 13.0,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                      color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F1E36),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),

                // Small right circular arrow button
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: arrowBgColor,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 10,
                      color: arrowColor,
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

// ==================== 1. ISOLATED HIGH-PERFORMANCE NEWS SLIDER ====================
class _HomeNewsSlider extends StatefulWidget {
  final int currentSem;
  final bool isDark;
  final void Function(Map<String, dynamic> item) onNewsTap;

  const _HomeNewsSlider({
    required this.currentSem,
    required this.isDark,
    required this.onNewsTap,
  });

  @override
  State<_HomeNewsSlider> createState() => _HomeNewsSliderState();
}

class _HomeNewsSliderState extends State<_HomeNewsSlider> {
  late final Stream<QuerySnapshot> _newsStream;
  late final PageController _pageController;
  final ValueNotifier<int> _currentSlideNotifier = ValueNotifier<int>(0);
  Timer? _sliderTimer;
  int _itemCount = 0;

  static const List<Map<String, dynamic>> _fallbackSlides = [
    {
      'title': 'উচ্চ মাধ্যমিক বাংলা ও ইংরেজি সহায়িকা',
      'subtitle': 'সেমিস্টার ৩ ও ৪-এর সম্পূর্ণ সিলেবাস, সাজেশন ও অধ্যায়ভিত্তিক নোটস',
      'tag': 'ES BANGLA',
      'redirectUrl': '',
      'gradientColors': [Color(0xFF1E3A8A), Color(0xFF0F172A)],
      'icon': Icons.menu_book_rounded,
      'order': 1,
    },
    {
      'title': 'অনলাইন অধ্যায়ভিত্তিক মক টেস্ট',
      'subtitle': 'প্রতিটি সেটে অংশগ্রহণ করে নিজের প্রস্তুতি তাৎক্ষণিক যাচাই করুন',
      'tag': 'MOCK TEST',
      'redirectUrl': '',
      'gradientColors': [Color(0xFF065F46), Color(0xFF064E3B)],
      'icon': Icons.timer_outlined,
      'order': 2,
    },
    {
      'title': 'বিগত বছরের প্রশ্নপত্র ও সমাধান (PYQ)',
      'subtitle': 'পরীক্ষায় সর্বোচ্চ নম্বর পেতে প্রিভিয়াস ইয়ার কোশ্চেন অনুশীলন করুন',
      'tag': 'PYQ ARCHIVE',
      'redirectUrl': '',
      'gradientColors': [Color(0xFF4C1D95), Color(0xFF2E1065)],
      'icon': Icons.quiz_outlined,
      'order': 3,
    },
  ];

  @override
  void initState() {
    super.initState();
    _newsStream = FirebaseFirestore.instance.collection('news').snapshots();
    _pageController = PageController(viewportFraction: 1.0, initialPage: 1200);
    _startTimer(3);
  }

  void _startTimer(int count) {
    _sliderTimer?.cancel();
    _itemCount = count;
    if (count > 1) {
      _sliderTimer = Timer.periodic(const Duration(milliseconds: 3800), (_) {
        if (_pageController.hasClients && mounted) {
          _pageController.nextPage(
            duration: const Duration(milliseconds: 650),
            curve: Curves.easeInOutCubic,
          );
        }
      });
    }
  }

  void _resetTimer() {
    _startTimer(_itemCount);
  }

  @override
  void dispose() {
    _sliderTimer?.cancel();
    _pageController.dispose();
    _currentSlideNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: StreamBuilder<QuerySnapshot>(
        stream: _newsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: widget.isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFF0F172A).withOpacity(0.18),
                    width: 1.0,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: AppShimmer.box(
                    width: double.infinity,
                    height: double.infinity,
                    borderRadius: 0,
                  ),
                ),
              ),
            );
          }

          List<Map<String, dynamic>> newsList = [];

          if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
            for (final doc in snapshot.data!.docs) {
              final data = doc.data() as Map<String, dynamic>? ?? {};
              final bool isActive = data['isActive'] ?? true;
              if (!isActive) continue;

              final targetSem = data['targetSemester'];
              if (targetSem != null &&
                  targetSem != 0 &&
                  targetSem != '0' &&
                  targetSem != 'all' &&
                  targetSem != widget.currentSem) {
                continue;
              }

              final title = (data['title'] ?? '').toString().trim();
              if (title.isEmpty) continue;

              newsList.add({
                'id': doc.id,
                'title': title,
                'subtitle': (data['subtitle'] ?? data['description'] ?? '').toString().trim(),
                'tag': (data['tag'] ?? 'LATEST NEWS').toString().toUpperCase().trim(),
                'redirectUrl': (data['redirectUrl'] ?? data['link'] ?? data['url'] ?? '').toString().trim(),
                'imageUrl': (data['imageUrl'] ?? data['image'] ?? '').toString().trim(),
                'imageAsset': (data['imageAsset'] ?? '').toString().trim(),
                'order': data['order'] is num ? (data['order'] as num).toInt() : 0,
              });
            }

            newsList.sort((a, b) => (a['order'] as int).compareTo(b['order'] as int));
          }

          if (newsList.isEmpty) {
            newsList = _fallbackSlides;
          }

          if (_itemCount != newsList.length || _sliderTimer == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _startTimer(newsList.length);
            });
          }

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: Container(
                  decoration: BoxDecoration(
                    color: widget.isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: widget.isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFF0F172A).withOpacity(0.18), // Crisp, thin black stroke
                      width: 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(widget.isDark ? 0.35 : 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: newsList.length == 1
                        ? _buildBannerCard(newsList[0], widget.isDark)
                        : PageView.builder(
                            controller: _pageController,
                            physics: const PageScrollPhysics(parent: ClampingScrollPhysics()),
                            onPageChanged: (idx) {
                              final actualIndex = ((idx % newsList.length) + newsList.length) % newsList.length;
                              if (_currentSlideNotifier.value != actualIndex) {
                                _currentSlideNotifier.value = actualIndex;
                              }
                              _resetTimer();
                            },
                            itemBuilder: (context, virtualIndex) {
                              final index = ((virtualIndex % newsList.length) + newsList.length) % newsList.length;
                              return _buildBannerCard(newsList[index], widget.isDark);
                            },
                          ),
                  ),
                ),
              ),

              // Animated Indicator Dots (Smooth, isolated rebuilds only)
              if (newsList.length > 1) ...[
                const SizedBox(height: 10),
                ValueListenableBuilder<int>(
                  valueListenable: _currentSlideNotifier,
                  builder: (context, activeIndex, _) {
                    final safeIndex = activeIndex >= newsList.length ? 0 : activeIndex;
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(newsList.length, (idx) {
                        final isSelected = safeIndex == idx;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOut,
                          width: isSelected ? 16 : 6,
                          height: 6,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(3),
                            color: isSelected
                                ? const Color(0xFF0070F3) // Royal Blue
                                : (widget.isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1)),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFF0070F3).withOpacity(0.35),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1),
                                    ),
                                  ]
                                : null,
                          ),
                        );
                      }),
                    );
                  },
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildBannerCard(Map<String, dynamic> item, bool isDark) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => widget.onNewsTap(item),
        child: _buildBannerContent(item, isDark),
      ),
    );
  }

  Widget _buildBannerContent(Map<String, dynamic> item, bool isDark) {
    final imageUrl = (item['imageUrl'] ?? '').toString().trim();

    if (imageUrl.isNotEmpty) {
      if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
        return CachedNetworkImage(
          imageUrl: imageUrl,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          memCacheWidth: 800,
          memCacheHeight: 450,
          fadeInDuration: const Duration(milliseconds: 200),
          placeholder: (context, url) => AppShimmer.box(
            width: double.infinity,
            height: double.infinity,
            borderRadius: 0,
          ),
          errorWidget: (context, url, error) => _buildBannerFallback(item, isDark),
        );
      } else {
        return Image.asset(
          imageUrl,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          cacheWidth: 800,
          errorBuilder: (_, __, ___) => _buildBannerFallback(item, isDark),
        );
      }
    }

    return _buildBannerFallback(item, isDark);
  }

  Widget _buildBannerFallback(Map<String, dynamic> item, bool isDark) {
    final title = item['title'] ?? '';
    final subtitle = item['subtitle'] ?? '';
    final tag = (item['tag'] ?? 'ES BANGLA').toString().toUpperCase();
    final List<Color> gradientColors = item['gradientColors'] is List<Color>
        ? (item['gradientColors'] as List<Color>)
        : const [Color(0xFF1E3A8A), Color(0xFF0F172A)];
    final IconData iconData = item['icon'] is IconData
        ? (item['icon'] as IconData)
        : Icons.school_rounded;

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          // Decorative Subtle Watermark Icon
          Positioned(
            right: -8,
            bottom: -12,
            child: Icon(
              iconData,
              size: 110,
              color: Colors.white.withOpacity(0.07),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B),
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFF59E0B).withOpacity(0.35),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Text(
                        tag,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.25,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                          height: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.22),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.12), width: 0.8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text(
                        'বিস্তারিত জানতে ট্যাপ করুন',
                        style: TextStyle(
                          fontSize: 10.5,
                          color: Color(0xFFFCD34D),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward_rounded, size: 11, color: Color(0xFFFCD34D)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
