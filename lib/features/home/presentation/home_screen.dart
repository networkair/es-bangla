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
import '../../notifications/presentation/notification_inbox_screen.dart';
import '../../book_notes/presentation/book_notes_screen.dart';
import '../../../core/widgets/app_shimmer.dart';
import '../../../core/notifications/app_notification_service.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback onSemesterChanged;

  const HomeScreen({super.key, required this.onSemesterChanged});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final LocalStorageService _storage = LocalStorageService();
  final PageController _sliderController = PageController();
  int _currentSlide = 0;
  Timer? _sliderTimer;
  int _sliderItemCount = 0;

  final List<Map<String, dynamic>> _fallbackSlides = [
    {
      'title': 'উচ্চ মাধ্যমিকের নতুন নির্দেশিকা প্রকাশ!',
      'subtitle': 'পরীক্ষা, রুটিন, সিলেবাস ও অন্যান্য সকল আপডেট জানুন',
      'tag': 'LATEST NEWS',
      'redirectUrl': '',
      'imageUrl': '',
      'order': 1,
    },
    {
      'title': 'সেমিস্টার ৩ ও ৪-এর মক টেস্ট শুরু!',
      'subtitle': 'অধ্যায়ভিত্তিক প্রতিটি সেটে অংশ নিয়ে প্রস্তুতি যাচাই করুন',
      'tag': 'MOCK TEST',
      'redirectUrl': '',
      'imageUrl': '',
      'order': 2,
    },
  ];

  @override
  void initState() {
    super.initState();
  }

  void _syncSliderTimer(int count) {
    if (_sliderItemCount == count) return;
    _sliderItemCount = count;
    _sliderTimer?.cancel();
    if (count > 1) {
      _sliderTimer = Timer.periodic(const Duration(seconds: 4), (_) {
        if (_sliderController.hasClients && mounted) {
          final nextPage = (_currentSlide + 1) % count;
          _sliderController.animateToPage(
            nextPage,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _sliderTimer?.cancel();
    _sliderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentSem = _storage.semester;
    final userName = _storage.userName.isNotEmpty ? _storage.userName : 'Student';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 20,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'হ্যালো, $userName 👋',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
              ],
            ),
            const Text(
              'আজ নতুন কিছু শিক্ষার দিন!',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.normal),
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
                      decoration: const BoxDecoration(
                        color: AppColors.surfaceMuted,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.notifications_none_rounded, color: AppColors.textPrimary, size: 22),
                    ),
                    if (unreadCount > 0)
                      Positioned(
                        right: 6,
                        top: 6,
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
          const SizedBox(width: 12),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Hero News Slider (Edge-to-Edge Flush 16:9, Sharp Corners, Crystal Clear)
            _buildNewsSlider(currentSem),

            // Content Area with Clean, Balanced Spacing & Matching Canvas
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 2. Study Reminder 3D Pill Card
                  _buildStudyReminderTile(),
                  const SizedBox(height: 10),

                  // 3. Semester 3 & Semester 4 Cards (Side by Side in a Row)
                  Row(
                    children: [
                      Expanded(
                        child: _buildSemesterTile(
                          title: 'SEMESTER 3',
                          semester: 3,
                          iconAsset: 'assets/icons/ic_sem3.png',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildSemesterTile(
                          title: 'SEMESTER 4',
                          semester: 4,
                          iconAsset: 'assets/icons/ic_sem4.png',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // 4. Previous Year Questions (PYQ) 3D Card
                  _buildActionTile(
                    title: 'PREVIOUS YEARS QUESTIONS',
                    iconAsset: 'assets/icons/ic_pyq.png',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PyqScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 10),

                  // 5. Book Notes / Handnotes 3D Card
                  _buildActionTile(
                    title: 'BOOK NOTES & HANDNOTES',
                    iconAsset: 'assets/icons/ic_book_notes.png',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const BookNotesScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 10),

                  // 6. Authentic Es Bangla Social Media Hub
                  _buildSocialMediaSection(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== 1. NEWS SLIDER ====================
  Widget _buildNewsSlider(int currentSem) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('news').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return AppShimmer.banner16x9(borderRadius: 0);
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
                targetSem != currentSem) {
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
              'order': data['order'] is num ? (data['order'] as num).toInt() : 0,
            });
          }

          newsList.sort((a, b) => (a['order'] as int).compareTo(b['order'] as int));
        }

        if (newsList.isEmpty) {
          newsList = _fallbackSlides;
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _syncSliderTimer(newsList.length);
        });

        final safeSlideIndex = _currentSlide >= newsList.length ? 0 : _currentSlide;

        return AspectRatio(
          aspectRatio: 16 / 9,
          child: Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.zero,
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                PageView.builder(
                  controller: _sliderController,
                  onPageChanged: (idx) => setState(() => _currentSlide = idx),
                  itemCount: newsList.length,
                  itemBuilder: (context, index) {
                    final item = newsList[index];
                    final tag = (item['tag'] ?? 'LATEST NEWS').toString();
                    final title = item['title'] ?? '';
                    final subtitle = item['subtitle'] ?? '';
                    final imageUrl = (item['imageUrl'] ?? '').toString().trim();
                    final hasImage = imageUrl.isNotEmpty;

                    if (hasImage) {
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _showNewsDetailsModal(item),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              // 100% Bright, Crisp & Clear Image (No Dark Overlay)
                              CachedNetworkImage(
                                imageUrl: imageUrl,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => AppShimmer.banner16x9(borderRadius: 0),
                                errorWidget: (context, url, error) => Container(
                                  color: const Color(0xFF1E293B),
                                  child: const Center(
                                    child: Icon(Icons.broken_image_rounded, color: Colors.white54, size: 36),
                                  ),
                                ),
                              ),

                              // Top-Left: Category Tag & Live Indicator
                              Positioned(
                                top: 12,
                                left: 12,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFDC2626),
                                        borderRadius: BorderRadius.circular(4),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.35),
                                            blurRadius: 4,
                                            offset: const Offset(0, 1),
                                          ),
                                        ],
                                      ),
                                      child: Text(
                                        tag,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3.5),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.6),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 6,
                                            height: 6,
                                            decoration: const BoxDecoration(
                                              color: Color(0xFF22C55E),
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          const Text(
                                            'LIVE',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    // Fallback for News without Image
                    return Material(
                      color: const Color(0xFF0F172A),
                      child: InkWell(
                        onTap: () => _showNewsDetailsModal(item),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFDC2626),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      tag,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF22C55E),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Text(
                                    'LIVE',
                                    style: TextStyle(
                                      color: Color(0xFF22C55E),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
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
                                        height: 1.25,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ],
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Text(
                                    'বিস্তারিত দেখতে ট্যাপ করুন',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFFF87171),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(width: 4),
                                  Icon(Icons.arrow_forward_rounded, size: 12, color: Color(0xFFF87171)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),

                // Slide Indicator Dots (Bottom Right)
                if (newsList.length > 1)
                  Positioned(
                    bottom: 10,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.55),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(newsList.length, (idx) {
                          final isSelected = safeSlideIndex == idx;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            width: isSelected ? 14 : 5,
                            height: 5,
                            margin: const EdgeInsets.symmetric(horizontal: 2.5),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFFDC2626) : Colors.white.withOpacity(0.65),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showNewsDetailsModal(Map<String, dynamic> item) {
    final title = item['title'] ?? '';
    final subtitle = item['subtitle'] ?? '';
    final tag = item['tag'] ?? 'LATEST NEWS';
    final redirectUrl = (item['redirectUrl'] ?? '').toString().trim();
    final imageUrl = (item['imageUrl'] ?? '').toString().trim();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              if (imageUrl.isNotEmpty) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => AppShimmer.banner16x9(borderRadius: 8),
                      errorWidget: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFDC2626),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  tag,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              Text(
                title,
                style: const TextStyle(
                  fontSize: 17.5,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                  height: 1.3,
                ),
              ),

              if (subtitle.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: Color(0xFF475569),
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

  // ==================== 2. STUDY REMINDER CARD ====================
  Widget _buildStudyReminderTile() {
    return Container(
      height: 58,
      decoration: BoxDecoration(
        color: const Color(0xFFFFEEDD), // Warm modern peach cream matching white background
        borderRadius: BorderRadius.circular(29),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000), // Smooth 3D elevation
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ReminderScreen()),
            );
          },
          borderRadius: BorderRadius.circular(29),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'SET STUDY REMINDER',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(width: 8),
                Image.asset(
                  'assets/icons/ic_reminder.png',
                  width: 30,
                  height: 30,
                  fit: BoxFit.contain,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==================== 3. SEMESTER 3 & 4 CARDS (SIDE BY SIDE) ====================
  Widget _buildSemesterTile({
    required String title,
    required int semester,
    required String iconAsset,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white, // Crisp White 3D Card
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => NotesSubjectsScreen(semester: semester)),
            );
          },
          borderRadius: BorderRadius.circular(28),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Uniform Borderless Light Blue Icon Container
                    Container(
                      width: 58,
                      height: 58,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEDF4FF), // Soft light blue
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Image.asset(
                          iconAsset,
                          width: 48,
                          height: 48,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),

                    // Circular Chevron Button
                    Container(
                      width: 34,
                      height: 34,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEAF2FF),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 13,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.3,
                    color: Color(0xFF0F172A), // Crisp Black
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==================== 4 & 5. ACTION CARDS (PYQ & BOOK NOTES) ====================
  Widget _buildActionTile({
    required String title,
    required String iconAsset,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white, // Crisp White 3D Card
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(28),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // Uniform Borderless Light Blue Icon Container
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEDF4FF), // Soft light blue
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Image.asset(
                      iconAsset,
                      width: 52,
                      height: 52,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.3,
                      color: Color(0xFF0F172A), // Crisp Black
                    ),
                  ),
                ),

                // Circular Chevron Button
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEAF2FF),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 15,
                      color: Color(0xFF0F172A),
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

  // ==================== 6. AUTHENTIC ES BANGLA SOCIAL HUB ====================
  Widget _buildSocialMediaSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, // Crisp White 3D Card
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: const BoxDecoration(
                  color: Color(0xFFEDF4FF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.share_rounded, size: 18, color: Color(0xFF0F172A)),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'JOIN OUR COMMUNITY',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                    color: Color(0xFF0F172A), // Crisp Black
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 4 Social Channels in a Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSocialButton('assets/icons/ic_youtube.png', 'YouTube', ApiConstants.youtubeChannelUrl),
              _buildSocialButton('assets/icons/ic_facebook.png', 'Facebook', ApiConstants.facebookPageUrl),
              _buildSocialButton('assets/icons/ic_telegram.png', 'Telegram', ApiConstants.telegramChannelUrl),
              _buildSocialButton('assets/icons/ic_whatsapp.png', 'WhatsApp', ApiConstants.whatsappUrl),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSocialButton(String iconAsset, String label, String url) {
    return InkWell(
      onTap: () {
        SecurityManager.openExternalUrl(url);
      },
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Column(
          children: [
            // Uniform Borderless Light Blue Container
            Container(
              width: 52,
              height: 52,
              decoration: const BoxDecoration(
                color: Color(0xFFEDF4FF), // Soft light blue
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Image.asset(iconAsset, width: 38, height: 38, fit: BoxFit.contain),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A), // Crisp Black
              ),
            ),
          ],
        ),
      ),
    );
  }
}
