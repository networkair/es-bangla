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
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFFAF8F5),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFFAF8F5),
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 20,
        title: Column(
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
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F1E36),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const TextSpan(
                    text: 'Bangla',
                    style: TextStyle(
                      fontFamily: 'AppTitleFont',
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0070F3), // Vibrant Royal Blue
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            // Golden brushstroke accent below 'Bangla' matching mockup
            Container(
              margin: const EdgeInsets.only(left: 38, top: 1),
              width: 44,
              height: 3,
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B),
                borderRadius: BorderRadius.circular(2),
              ),
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
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0).withOpacity(0.6),
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
            // 1. Hero News Slider (3D Peeking Carousel with Blue Dots)
            _buildNewsSlider(currentSem, isDark),

            // Content Area with Clean, Balanced Spacing & Matching Canvas
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 2. Study Reminder 3D Pill Card
                  _buildStudyReminderTile(),
                  const SizedBox(height: 18),

                  // 3. Semester 3 & Semester 4 Cards (Side by Side in a Row)
                  Row(
                    children: [
                      Expanded(
                        child: _buildSemesterTile(
                          title: 'SEMESTER 3',
                          semester: 3,
                          iconAsset: 'assets/icons/ic_sem3.png',
                          blobColor: const Color(0xFFE0F2FE),
                          accentLineColor: const Color(0xFF38BDF8),
                          buttonBgColor: const Color(0xFFE0F2FE),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _buildSemesterTile(
                          title: 'SEMESTER 4',
                          semester: 4,
                          iconAsset: 'assets/icons/ic_sem4.png',
                          blobColor: const Color(0xFFFEF3C7),
                          accentLineColor: const Color(0xFFF59E0B),
                          buttonBgColor: const Color(0xFFFFEDD5),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // 4. Previous Year Questions (PYQ) 3D Card
                  _buildActionTile(
                    title: 'PREVIOUS YEARS\nQUESTIONS',
                    iconAsset: 'assets/icons/ic_pyq.png',
                    blobColor: const Color(0xFFE0F7FA),
                    accentLineColor: const Color(0xFF0D9488),
                    buttonBgColor: const Color(0xFFE0F2FE),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PyqScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 18),

                  // 5. Premium Store 3D Card
                  _buildActionTile(
                    title: 'PREMIUM STORE',
                    iconAsset: 'assets/icons/ic_store.png',
                    blobColor: const Color(0xFFFFF1F2),
                    accentLineColor: const Color(0xFFF87171),
                    buttonBgColor: const Color(0xFFFEE2E2),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const BookNotesScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 18),

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

                // Indicator Dots (Centered Royal Blue Dots Below Slider matching mockup)
                if (newsList.length > 1) ...[
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(newsList.length, (idx) {
                      final isSelected = safeSlideIndex == idx;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut,
                        width: isSelected ? 8 : 6,
                        height: isSelected ? 8 : 6,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected
                              ? const Color(0xFF0070F3) // Vibrant Royal Blue
                              : (isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1)),
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
            color: (isDark ? Colors.black : const Color(0xFF0F172A)).withOpacity(isDark ? 0.25 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
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
    final imageUrl = (item['imageUrl'] ?? '').toString().trim();

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
              size: 105,
              color: Colors.white.withOpacity(0.08),
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
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
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
                      'বিস্তারিত জানতে ট্যাপ করুন',
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
          ),
        ],
      ),
    );
  }

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 62,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? const [Color(0xFF1E3A8A), Color(0xFF0F172A)]
              : const [Color(0xFF0080FF), Color(0xFF0052D4)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(31),
        boxShadow: [
          // 3D downward drop shadow matching mockup
          BoxShadow(
            color: (isDark ? Colors.black : const Color(0xFF0052D4)).withOpacity(isDark ? 0.40 : 0.28),
            offset: const Offset(0, 8),
            blurRadius: 16,
            spreadRadius: -2,
          ),
          BoxShadow(
            color: (isDark ? Colors.black : const Color(0xFF0052D4)).withOpacity(isDark ? 0.20 : 0.12),
            offset: const Offset(0, 3),
            blurRadius: 6,
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(31),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ReminderScreen()),
              );
            },
            child: Stack(
              children: [
                // Organic wave/bubble on the left matching mockup
                Positioned(
                  left: -15,
                  top: -20,
                  bottom: -20,
                  child: Container(
                    width: 85,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF38BDF8).withOpacity(0.35),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    children: [
                      // White circular badge with golden ringing bell
                      Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.notifications_active_rounded,
                            color: Color(0xFFF59E0B), // Golden amber bell
                            size: 24,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Title
                      const Expanded(
                        child: Text(
                          'SET STUDY REMINDER',
                          style: TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                            color: Colors.white,
                          ),
                        ),
                      ),

                      // Right circular chevron forward button
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 14,
                            color: Colors.white,
                          ),
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

  // ==================== 3. SEMESTER 3 & 4 CARDS (SIDE BY SIDE) ====================
  Widget _buildSemesterTile({
    required String title,
    required int semester,
    required String iconAsset,
    required Color blobColor,
    required Color accentLineColor,
    required Color buttonBgColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1.0,
        ),
        boxShadow: [
          // 3D downward drop shadow matching user reference mockup
          BoxShadow(
            color: (isDark ? Colors.black : const Color(0xFF1E293B)).withOpacity(isDark ? 0.35 : 0.07),
            offset: const Offset(0, 8),
            blurRadius: 16,
            spreadRadius: -2,
          ),
          BoxShadow(
            color: (isDark ? Colors.black : const Color(0xFF1E293B)).withOpacity(isDark ? 0.18 : 0.03),
            offset: const Offset(0, 3),
            blurRadius: 6,
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => NotesSubjectsScreen(semester: semester)),
              );
            },
            child: Stack(
              children: [
                // Top-left organic backdrop blob
                Positioned(
                  left: -15,
                  top: -15,
                  child: Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark ? blobColor.withOpacity(0.12) : blobColor.withOpacity(0.65),
                    ),
                  ),
                ),
                // Bottom-right corner subtle wave
                Positioned(
                  right: -20,
                  bottom: -20,
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark ? blobColor.withOpacity(0.08) : blobColor.withOpacity(0.40),
                    ),
                  ),
                ),

                // Main card content
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Large 3D Icon matching mockup
                          Image.asset(
                            iconAsset,
                            width: 78,
                            height: 78,
                            fit: BoxFit.contain,
                          ),
                          // Top-right action arrow pill
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF334155) : buttonBgColor,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 13,
                                color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F1E36),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.3,
                          color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F1E36),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Container(
                        width: 28,
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

  // ==================== 4 & 5. ACTION CARDS (PYQ & BOOK NOTES) ====================
  Widget _buildActionTile({
    required String title,
    required String iconAsset,
    required Color blobColor,
    required Color accentLineColor,
    required Color buttonBgColor,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1.0,
        ),
        boxShadow: [
          // 3D downward drop shadow matching user reference mockup
          BoxShadow(
            color: (isDark ? Colors.black : const Color(0xFF1E293B)).withOpacity(isDark ? 0.35 : 0.07),
            offset: const Offset(0, 8),
            blurRadius: 16,
            spreadRadius: -2,
          ),
          BoxShadow(
            color: (isDark ? Colors.black : const Color(0xFF1E293B)).withOpacity(isDark ? 0.18 : 0.03),
            offset: const Offset(0, 3),
            blurRadius: 6,
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Stack(
              children: [
                // Left organic backdrop blob
                Positioned(
                  left: -20,
                  top: -20,
                  bottom: -20,
                  child: Container(
                    width: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark ? blobColor.withOpacity(0.12) : blobColor.withOpacity(0.65),
                    ),
                  ),
                ),
                // Bottom-right corner subtle wave
                Positioned(
                  right: -25,
                  bottom: -25,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark ? blobColor.withOpacity(0.08) : blobColor.withOpacity(0.40),
                    ),
                  ),
                ),

                // Main card content
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      // Large 3D Icon matching mockup
                      Image.asset(
                        iconAsset,
                        width: 84,
                        height: 84,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(width: 16),

                      // Title & Accent Underline
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.3,
                                height: 1.25,
                                color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F1E36),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              width: 32,
                              height: 3.5,
                              decoration: BoxDecoration(
                                color: accentLineColor,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Right Action Arrow Circle
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF334155) : buttonBgColor,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 15,
                            color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F1E36),
                          ),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1.0,
        ),
        boxShadow: [
          // 3D downward drop shadow matching user reference image
          BoxShadow(
            color: (isDark ? Colors.black : const Color(0xFF1E293B)).withOpacity(isDark ? 0.38 : 0.08),
            offset: const Offset(0, 8),
            blurRadius: 16,
            spreadRadius: -2,
          ),
          BoxShadow(
            color: (isDark ? Colors.black : const Color(0xFF1E293B)).withOpacity(isDark ? 0.20 : 0.04),
            offset: const Offset(0, 3),
            blurRadius: 6,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFEDF4FF),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    Icons.share_rounded,
                    size: 18,
                    color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'JOIN OUR COMMUNITY',
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                    color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 4 Social Channels in a Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSocialButton('assets/icons/ic_youtube.png', 'YouTube', ApiConstants.youtubeChannelUrl, isDark),
              _buildSocialButton('assets/icons/ic_facebook.png', 'Facebook', ApiConstants.facebookPageUrl, isDark),
              _buildSocialButton('assets/icons/ic_telegram.png', 'Telegram', ApiConstants.telegramChannelUrl, isDark),
              _buildSocialButton('assets/icons/ic_whatsapp.png', 'WhatsApp', ApiConstants.whatsappUrl, isDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSocialButton(String iconAsset, String label, String url, bool isDark) {
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
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFEDF4FF), // Soft light blue
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Image.asset(iconAsset, width: 38, height: 38, fit: BoxFit.contain),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
