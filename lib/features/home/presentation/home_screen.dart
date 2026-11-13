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
      viewportFraction: 1.0,
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
                  // 2. Quick Action Cards (Notepad + Study Reminder)
                  _buildQuickActionCardsRow(isDark),
                  const SizedBox(height: 12),

                  // 3. Semester 3 Card (Wide Horizontal Card)
                  _buildSemesterTile(
                    title: 'SEMESTER 3',
                    semester: 3,
                    iconAsset: 'assets/icons/ic_sem3.png',
                    buttonBgColor: const Color(0xFFE0F2FE),
                    buttonIconColor: const Color(0xFF0070F3),
                  ),
                  const SizedBox(height: 13),

                  // 4. Semester 4 Card (Wide Horizontal Card)
                  _buildSemesterTile(
                    title: 'SEMESTER 4',
                    semester: 4,
                    iconAsset: 'assets/icons/ic_sem4.png',
                    buttonBgColor: const Color(0xFFFFEDD5),
                    buttonIconColor: const Color(0xFFD97706),
                  ),
                  const SizedBox(height: 13),

                  // 4. Previous Year Questions (PYQ) Horizontal Card
                  _buildActionTile(
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
                  const SizedBox(height: 13),

                  // 5. Premium Store Horizontal Card
                  _buildActionTile(
                    title: 'PREMIUM STORE',
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
                  const SizedBox(height: 13),

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
          return LayoutBuilder(
            builder: (context, constraints) {
              final sliderHeight = constraints.maxWidth * (9.0 / 16.0);
              return AppShimmer.box(
                width: double.infinity,
                height: sliderHeight,
                borderRadius: 0,
              );
            },
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
            // Exact 16:9 widescreen aspect ratio flush to screen edges
            final sliderHeight = constraints.maxWidth * (9.0 / 16.0);

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: double.infinity,
                  height: sliderHeight,
                  child: newsList.length == 1
                      ? _buildBannerCard(newsList[0], isDark)
                      : PageView.builder(
                          controller: _sliderController,
                          onPageChanged: (idx) {
                            final actualIndex = ((idx % newsList.length) + newsList.length) % newsList.length;
                            if (_currentSlide != actualIndex) {
                              setState(() => _currentSlide = actualIndex);
                            }
                          },
                          itemBuilder: (context, virtualIndex) {
                            final index = ((virtualIndex % newsList.length) + newsList.length) % newsList.length;
                            final item = newsList[index];
                            return _buildBannerCard(item, isDark);
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
                              : (isDark ? const Color(0xFF475569) : const Color(0xFFBAE6FD)),
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
      width: double.infinity,
      height: double.infinity,
      margin: EdgeInsets.zero,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.zero,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showNewsDetailsModal(item),
          child: _buildBannerImage(item, isDark),
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

  // ==================== PREMIUM CARD BOTTOM SHADOW (HTML DEMO SPEC) ====================
  List<BoxShadow> _buildPremiumCardShadow(bool isDark) {
    if (isDark) {
      return [
        BoxShadow(
          color: Colors.black.withOpacity(0.35),
          offset: const Offset(0, 2),
          blurRadius: 4,
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.30),
          offset: const Offset(0, 7),
          blurRadius: 12,
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.25),
          offset: const Offset(0, 15),
          blurRadius: 22,
        ),
      ];
    }
    return [
      BoxShadow(
        color: const Color(0xFF18273D).withOpacity(0.045),
        offset: const Offset(0, 2),
        blurRadius: 4,
      ),
      BoxShadow(
        color: const Color(0xFF18273D).withOpacity(0.055),
        offset: const Offset(0, 7),
        blurRadius: 12,
      ),
      BoxShadow(
        color: const Color(0xFF18273D).withOpacity(0.045),
        offset: const Offset(0, 15),
        blurRadius: 22,
      ),
      BoxShadow(
        color: const Color(0xFF233650).withOpacity(0.035),
        offset: const Offset(0, 20),
        blurRadius: 26,
        spreadRadius: -4,
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

        // Right: Set Study Reminder Card
        Expanded(
          child: _buildQuickActionCard(
            titleLine1: 'SET STUDY',
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
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
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE8EDF4),
          width: 1.0,
        ),
        boxShadow: _buildPremiumCardShadow(isDark),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
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
                  // Left: Circular Logo Wrap
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
                  const SizedBox(width: 12),

                  // Right: Action Arrow Circle
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
                        size: 14,
                        color: buttonIconColor,
                      ),
                    ),
                  ),
                ],
              ),
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
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE8EDF4),
          width: 1.0,
        ),
        boxShadow: _buildPremiumCardShadow(isDark),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
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
                  const SizedBox(width: 12),

                  // Right: Action Arrow Circle matching demo
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
                        size: 14,
                        color: buttonIconColor,
                      ),
                    ),
                  ),
                ],
              ),
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
        // 1. WhatsApp VIP Updates Banner (Top Hero Card with JOIN NOW button)
        _buildWhatsappHeroCard(isDark),
        const SizedBox(height: 14),

        // 2. Stylish Section Divider
        Row(
          children: [
            Expanded(
              child: Divider(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                thickness: 1.0,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'FOLLOW US ON',
                style: TextStyle(
                  fontFamily: 'sans-serif',
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
            ),
            Expanded(
              child: Divider(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                thickness: 1.0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // 3. Row of 3 Official Social Channels (YouTube, Telegram, Instagram)
        Row(
          children: [
            // YouTube Card
            Expanded(
              child: _buildSocialChannelCard(
                iconAsset: 'assets/icons/ic_youtube.png',
                name: 'YouTube',
                desc: 'ভিডিও ক্লাস',
                bgColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFFEF2F2),
                borderColor: isDark ? const Color(0xFF334155) : const Color(0xFFFECACA),
                url: ApiConstants.youtubeChannelUrl,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 10),

            // Telegram Card
            Expanded(
              child: _buildSocialChannelCard(
                iconAsset: 'assets/icons/ic_telegram.png',
                name: 'Telegram',
                desc: 'ফ্রি PDF নোটস',
                bgColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF0F9FF),
                borderColor: isDark ? const Color(0xFF334155) : const Color(0xFFBAE6FD),
                url: ApiConstants.telegramChannelUrl,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 10),

            // Instagram Card
            Expanded(
              child: _buildSocialChannelCard(
                iconAsset: 'assets/icons/ic_instagram.png',
                name: 'Instagram',
                desc: 'টিপস ও রিলস',
                bgColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFFDF2F8),
                borderColor: isDark ? const Color(0xFF334155) : const Color(0xFFFBCFE8),
                url: ApiConstants.instagramUrl,
                isDark: isDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // 4. Trust & Security Badge Card
        _buildTrustBadgeCard(isDark),
      ],
    );
  }

  Widget _buildWhatsappHeroCard(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF064E3B).withOpacity(0.35) : const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? const Color(0xFF065F46) : const Color(0xFFBBF7D0),
          width: 1.0,
        ),
        boxShadow: _buildPremiumCardShadow(isDark),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => SecurityManager.openExternalUrl(ApiConstants.whatsappUrl),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: Row(
                children: [
                  // WhatsApp 3D icon container
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF16A34A).withOpacity(0.18),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Image.asset(
                        'assets/icons/ic_whatsapp.png',
                        width: 32,
                        height: 32,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Middle text: Header & Subtitle
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'WHATSAPP COMMUNITY',
                          style: TextStyle(
                            fontFamily: 'sans-serif',
                            fontSize: 13.0,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.3,
                            color: isDark ? const Color(0xFFF0FDF4) : const Color(0xFF064E3B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'সবার আগে সব গুরুত্বপূর্ণ আপডেট পান',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: isDark ? const Color(0xFF86EFAC) : const Color(0xFF15803D),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Action Button: Green Pill 'JOIN NOW'
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF16A34A), Color(0xFF15803D)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF16A34A).withOpacity(0.35),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'JOIN NOW',
                          style: TextStyle(
                            fontFamily: 'sans-serif',
                            fontSize: 11.0,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.4,
                            color: Colors.white,
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
      ),
    );
  }

  Widget _buildSocialChannelCard({
    required String iconAsset,
    required String name,
    required String desc,
    required Color bgColor,
    required Color borderColor,
    required String url,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: borderColor,
          width: 1.0,
        ),
        boxShadow: _buildPremiumCardShadow(isDark),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => SecurityManager.openExternalUrl(url),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon container
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF334155) : Colors.white,
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
                        width: 26,
                        height: 26,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 7),

                  // Channel Name
                  Text(
                    name,
                    style: TextStyle(
                      fontFamily: 'sans-serif',
                      fontSize: 12.0,
                      fontWeight: FontWeight.w800,
                      color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),

                  // Purpose description
                  Text(
                    desc,
                    style: TextStyle(
                      fontSize: 10.0,
                      fontWeight: FontWeight.w600,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTrustBadgeCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF0F7FF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF1E3A8A).withOpacity(0.5) : const Color(0xFFBAE6FD),
          width: 1.0,
        ),
        boxShadow: _buildPremiumCardShadow(isDark),
      ),
      child: Row(
        children: [
          // Blue Shield Icon
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0070F3).withOpacity(0.15),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.verified_user_rounded,
                color: Color(0xFF0070F3),
                size: 21,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Trust Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Trusted Educational Platform',
                  style: TextStyle(
                    fontFamily: 'sans-serif',
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  'পশ্চিমবঙ্গের ৫০,০০০+ ছাত্র-ছাত্রীদের ভরসা',
                  style: TextStyle(
                    fontSize: 13.0,
                    fontWeight: FontWeight.w900,
                    color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF0070F3),
                  ),
                ),
              ],
            ),
          ),

          // Star Rating Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFF59E0B).withOpacity(0.4),
                width: 1.0,
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.star_rounded,
                  color: Color(0xFFF59E0B),
                  size: 14,
                ),
                SizedBox(width: 3),
                Text(
                  '4.9',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFD97706),
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
