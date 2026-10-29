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
  late final PageController _sliderController;
  int _currentSlide = 0;
  Timer? _sliderTimer;
  int _sliderItemCount = 0;

  final List<Map<String, dynamic>> _fallbackSlides = [
    {
      'title': 'Active স্কলারশিপ',
      'subtitle': 'বিভিন্ন স্কলারশিপের আপডেট ও আবেদন লিঙ্ক',
      'tag': 'SCHOLARSHIP',
      'redirectUrl': '',
      'imageAsset': 'assets/images/banner_scholarship.png',
      'order': 1,
    },
    {
      'title': 'Ongoing সরকারি চাকরি ফর্ম ফিলাপ',
      'subtitle': 'সর্বশেষ সরকারি চাকরির বিজ্ঞপ্তি ও তথ্য',
      'tag': 'JOB EXAM',
      'redirectUrl': '',
      'imageAsset': 'assets/images/banner_job_exam.png',
      'order': 2,
    },
    {
      'title': 'UpSkill with AI',
      'subtitle': 'কম্পিউটার ও AI স্কিল শিখুন এবং ক্যারিয়ারে এগিয়ে থাকুন',
      'tag': 'UPSKILL',
      'redirectUrl': '',
      'imageAsset': 'assets/images/banner_upskill_ai.png',
      'order': 3,
    },
    {
      'title': 'Special Offer 10% Discount - Edutips Store',
      'subtitle': 'store.edutips.in - বই ও স্টাডি মেটেরিয়াল কিনুন ছাড়ে',
      'tag': 'EDUTIPS STORE',
      'redirectUrl': 'https://store.edutips.in',
      'imageAsset': 'assets/images/banner_edutips_store.png',
      'order': 4,
    },
  ];

  @override
  void initState() {
    super.initState();
    _sliderController = PageController(
      viewportFraction: 0.86,
      initialPage: 1200,
    );
  }

  void _syncSliderTimer(int count) {
    if (_sliderItemCount == count) return;
    _sliderItemCount = count;
    _sliderTimer?.cancel();
    if (count > 1) {
      _sliderTimer = Timer.periodic(const Duration(seconds: 4), (_) {
        if (_sliderController.hasClients && mounted) {
          _sliderController.nextPage(
            duration: const Duration(milliseconds: 550),
            curve: Curves.easeInOutCubic,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 20,
        title: Text(
          'Es Bangla',
          style: TextStyle(
            fontFamily: 'AppTitleFont',
            fontSize: 27,
            fontWeight: FontWeight.bold,
            color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
            letterSpacing: 0.5,
          ),
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
                        color: isDark ? const Color(0xFF1E293B) : AppColors.surfaceMuted,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.notifications_none_rounded,
                        color: isDark ? const Color(0xFFF8FAFC) : AppColors.textPrimary,
                        size: 22,
                      ),
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
            // 1. Hero News Slider (3D Peeking Carousel with Golden Dots)
            _buildNewsSlider(currentSem, isDark),

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

                  // 5. Premium Store 3D Card
                  _buildActionTile(
                    title: 'PREMIUM STORE',
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
  Widget _buildNewsSlider(int currentSem, bool isDark) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('news').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: AppShimmer.box(
              width: double.infinity,
              height: 160,
              borderRadius: 18,
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
              'imageAsset': (data['imageAsset'] ?? '').toString().trim(),
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

        return LayoutBuilder(
          builder: (context, constraints) {
            // Responsive slider height matching ~2.15:1 aspect ratio of the banner cards
            final cardWidth = constraints.maxWidth * 0.86;
            final sliderHeight = (cardWidth / 2.1).clamp(142.0, 185.0);

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                SizedBox(
                  height: sliderHeight,
                  child: newsList.length == 1
                      ? Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          child: _buildBannerCard(newsList[0], isDark),
                        )
                      : PageView.builder(
                          controller: _sliderController,
                          clipBehavior: Clip.none,
                          onPageChanged: (idx) {
                            final actualIndex = ((idx % newsList.length) + newsList.length) % newsList.length;
                            if (_currentSlide != actualIndex) {
                              setState(() => _currentSlide = actualIndex);
                            }
                          },
                          itemBuilder: (context, virtualIndex) {
                            final index = ((virtualIndex % newsList.length) + newsList.length) % newsList.length;
                            final item = newsList[index];

                            return AnimatedBuilder(
                              animation: _sliderController,
                              builder: (context, child) {
                                double diff = 0.0;
                                if (_sliderController.position.haveDimensions) {
                                  final page = _sliderController.page ?? _sliderController.initialPage.toDouble();
                                  diff = (page - virtualIndex).abs();
                                } else {
                                  diff = (virtualIndex == _sliderController.initialPage) ? 0.0 : 1.0;
                                }
                                final scale = (1.0 - (diff * 0.07)).clamp(0.93, 1.0);
                                return Transform.scale(
                                  scale: scale,
                                  child: child,
                                );
                              },
                              child: _buildBannerCard(item, isDark),
                            );
                          },
                        ),
                ),

                // Indicator Dots (Centered Golden Dots Below Slider)
                if (newsList.length > 1) ...[
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(newsList.length, (idx) {
                      final isSelected = safeSlideIndex == idx;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut,
                        width: isSelected ? 18 : 6,
                        height: 6,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFF59E0B) // Golden Amber
                              : (isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1)),
                          borderRadius: BorderRadius.circular(3),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFFF59E0B).withOpacity(0.4),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ]
                              : null,
                        ),
                      );
                    }),
                  ),
                ],
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildBannerCard(Map<String, dynamic> item, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.35) : const Color(0x140F172A),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(17),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showNewsDetailsModal(item),
            child: _buildBannerImage(item, isDark),
          ),
        ),
      ),
    );
  }

  Widget _buildBannerImage(Map<String, dynamic> item, bool isDark) {
    final imageAsset = (item['imageAsset'] ?? '').toString().trim();
    final imageUrl = (item['imageUrl'] ?? '').toString().trim();

    if (imageAsset.isNotEmpty) {
      return Image.asset(
        imageAsset,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) => _buildBannerFallback(item, isDark),
      );
    }

    if (imageUrl.isNotEmpty) {
      if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
        return CachedNetworkImage(
          imageUrl: imageUrl,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          placeholder: (context, url) => AppShimmer.box(
            width: double.infinity,
            height: double.infinity,
            borderRadius: 17,
          ),
          errorWidget: (context, url, error) => _buildBannerFallback(item, isDark),
        );
      } else {
        return Image.asset(
          imageUrl,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (_, __, ___) => _buildBannerFallback(item, isDark),
        );
      }
    }

    return _buildBannerFallback(item, isDark);
  }

  Widget _buildBannerFallback(Map<String, dynamic> item, bool isDark) {
    final title = item['title'] ?? '';
    final subtitle = item['subtitle'] ?? '';
    final tag = (item['tag'] ?? 'LATEST NEWS').toString().toUpperCase();

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF0F172A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B),
                  borderRadius: BorderRadius.circular(6),
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
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1.25,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (subtitle.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: Colors.white70,
                    height: 1.2,
                  ),
                  maxLines: 1,
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
                  color: Color(0xFFFCD34D),
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(width: 4),
              Icon(Icons.arrow_forward_rounded, size: 12, color: Color(0xFFFCD34D)),
            ],
          ),
        ],
      ),
    );
  }

  void _showNewsDetailsModal(Map<String, dynamic> item) {
    final title = item['title'] ?? '';
    final subtitle = item['subtitle'] ?? '';
    final tag = item['tag'] ?? 'LATEST NEWS';
    final redirectUrl = (item['redirectUrl'] ?? '').toString().trim();
    final imageUrl = (item['imageUrl'] ?? '').toString().trim();
    final imageAsset = (item['imageAsset'] ?? '').toString().trim();

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

              if (imageAsset.isNotEmpty) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Image.asset(imageAsset, fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(height: 16),
              ] else if (imageUrl.isNotEmpty) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
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

  // ==================== 2. STUDY REMINDER CARD ====================
  Widget _buildStudyReminderTile() {
    return Container(
      height: 58,
      decoration: BoxDecoration(
        color: const Color(0xFFFFEEDD), // Warm modern peach cream matching white background
        borderRadius: BorderRadius.circular(29),
        boxShadow: const [
          BoxShadow(
            color: Color(0x20000000), // Rich prominent bottom shadow
            blurRadius: 18,
            spreadRadius: 0.5,
            offset: Offset(0, 9),
          ),
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 6,
            offset: Offset(0, 3),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white, // Crisp White / Dark Slate 3D Card
        borderRadius: BorderRadius.circular(28),
        border: isDark ? Border.all(color: const Color(0xFF334155)) : null,
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : const Color(0xFF000000)).withOpacity(isDark ? 0.3 : 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: (isDark ? Colors.black : const Color(0xFF000000)).withOpacity(isDark ? 0.15 : 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
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
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFEDF4FF), // Soft light blue
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Image.asset(
                          iconAsset,
                          width: 54,
                          height: 54,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),

                    // Circular Chevron Button
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFEAF2FF),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 13,
                          color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.3,
                    color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white, // Crisp White / Dark Slate 3D Card
        borderRadius: BorderRadius.circular(28),
        border: isDark ? Border.all(color: const Color(0xFF334155)) : null,
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : const Color(0xFF000000)).withOpacity(isDark ? 0.35 : 0.13),
            blurRadius: 22,
            spreadRadius: 1,
            offset: const Offset(0, 11),
          ),
          BoxShadow(
            color: (isDark ? Colors.black : const Color(0xFF000000)).withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
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
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFEDF4FF),
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
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.3,
                      color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                    ),
                  ),
                ),

                // Circular Chevron Button
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFEAF2FF),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 15,
                      color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
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
            color: Color(0x22000000), // Prominent bottom drop shadow
            blurRadius: 22,
            spreadRadius: 1,
            offset: Offset(0, 11),
          ),
          BoxShadow(
            color: Color(0x0C000000),
            blurRadius: 6,
            offset: Offset(0, 3),
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
