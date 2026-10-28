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
      backgroundColor: AppColors.background,
      appBar: AppBar(
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Academic Selector Pill (Class 12 Semester Indicator)
            _buildAcademicHeaderPill(currentSem),
            const SizedBox(height: 14),

            // 2. News Slider (16:9 Banner)
            _buildNewsSlider(currentSem),
            const SizedBox(height: 14),

            // 3. Study Reminder Banner (Warm Soft-Amber 3D Card)
            _buildStudyReminderTile(),
            const SizedBox(height: 14),

            // 4. Primary Academic Action Cards (Cohesive Full-Width 3D Cards)
            _buildModernFeatureCard(
              tag: 'SEMESTER 3',
              title: 'Semester 3',
              subtitle: 'অধ্যায়ভিত্তিক সাজেশন, হ্যান্ডনোটস ও প্র্যাকটিস',
              iconAsset: 'assets/icons/ic_sem3.png',
              emblemBgColor: const Color(0xFFEFF6FF),
              emblemBorderColor: const Color(0xFFBFDBFE),
              tagColor: const Color(0xFF0369A1),
              trailingBadge: _buildPillBadge('WBCHSE', const Color(0xFF0284C7), const Color(0xFFE0F2FE)),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NotesSubjectsScreen(semester: 3)),
                );
              },
            ),

            _buildModernFeatureCard(
              tag: 'SEMESTER 4',
              title: 'Semester 4',
              subtitle: 'অধ্যায়ভিত্তিক সাজেশন, হ্যান্ডনোটস ও প্র্যাকটিস',
              iconAsset: 'assets/icons/ic_sem4.png',
              emblemBgColor: const Color(0xFFFAF5FF),
              emblemBorderColor: const Color(0xFFDDD6FE),
              tagColor: const Color(0xFF6D28D9),
              trailingBadge: _buildPillBadge('WBCHSE', const Color(0xFF7C3AED), const Color(0xFFEDE9FE)),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NotesSubjectsScreen(semester: 4)),
                );
              },
            ),

            _buildModernFeatureCard(
              tag: 'PREVIOUS YEARS QUESTIONS',
              title: 'PYQ',
              subtitle: 'উচ্চ মাধ্যমিক বিগত বছরের প্রশ্নপত্র ও সমাধান',
              iconAsset: 'assets/icons/ic_pyq.png',
              emblemBgColor: const Color(0xFFFFF7ED),
              emblemBorderColor: const Color(0xFFFED7AA),
              tagColor: const Color(0xFFC2410C),
              trailingBadge: _buildPillBadge('SOLVED', const Color(0xFFEA580C), const Color(0xFFFFEDD5)),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PyqScreen()),
                );
              },
            ),

            _buildModernFeatureCard(
              tag: 'BOOK NOTES (বইয়ের নোটস)',
              title: 'Book Notes',
              subtitle: 'গুরুত্বপূর্ণ অধ্যায়ভিত্তিক হ্যান্ডনোটস ও সাজেশন',
              iconAsset: 'assets/icons/ic_book_notes.png',
              emblemBgColor: const Color(0xFFECFDF5),
              emblemBorderColor: const Color(0xFFA7F3D0),
              tagColor: const Color(0xFF047857),
              trailingBadge: _buildPillBadge('PDF', const Color(0xFF059669), const Color(0xFFD1FAE5)),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BookNotesScreen()),
                );
              },
            ),
            const SizedBox(height: 6),

            // 5. WhatsApp Community Hero Banner
            _buildWhatsAppCommunityBanner(),

            // 6. Social Media Channels
            _buildSocialChannelsSection(),

            // 7. Trust Badge Footer
            _buildTrustBadge(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildNewsSlider(int currentSem) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('news').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return AppShimmer.banner16x9(borderRadius: 16);
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

          // Sort by order ascending
          newsList.sort((a, b) => (a['order'] as int).compareTo(b['order'] as int));
        }

        // Fallback default slides if collection is empty or offline
        if (newsList.isEmpty) {
          newsList = _fallbackSlides;
        }

        // Sync slider timer smoothly with current item count
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _syncSliderTimer(newsList.length);
        });

        final safeSlideIndex = _currentSlide >= newsList.length ? 0 : _currentSlide;

        return AspectRatio(
          aspectRatio: 16 / 9,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
              children: [
                // Background subtle graphic icon (for cards without image)
                Positioned(
                  top: -15,
                  right: -15,
                  child: Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primaryLight.withOpacity(0.4),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.campaign_rounded,
                        size: 48,
                        color: AppColors.primary.withOpacity(0.2),
                      ),
                    ),
                  ),
                ),

                // PageView with real-time news cards
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
                          borderRadius: BorderRadius.circular(16),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              // Background 16:9 Banner Image (100% Bright, Crisp & Clear - No Dark Overlay)
                              CachedNetworkImage(
                                imageUrl: imageUrl,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => AppShimmer.banner16x9(borderRadius: 16),
                                errorWidget: (context, url, error) => Container(
                                  color: AppColors.surfaceMuted,
                                  child: const Center(
                                    child: Icon(Icons.broken_image_rounded, color: AppColors.textMuted, size: 32),
                                  ),
                                ),
                              ),

                              // Top-Left: Red Tag Badge & Live Indicator
                              Positioned(
                                top: 10,
                                left: 10,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFDC2626), // RED TAG
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
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.55),
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

                    // Fallback when news has no image
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _showNewsDetailsModal(item),
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Top Tag & Live Indicator
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFDC2626), // RED TAG
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      tag,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: AppColors.correctGreen,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Text(
                                    'LIVE',
                                    style: TextStyle(
                                      color: AppColors.correctGreen,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),

                              // Title & Subtitle
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
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
                                        color: AppColors.textSecondary,
                                        height: 1.25,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ],
                              ),

                              // Bottom action hint
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Text(
                                    'বিস্তারিত দেখতে ট্যাপ করুন',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFFDC2626),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(width: 3),
                                  Icon(Icons.arrow_forward_rounded, size: 12, color: Color(0xFFDC2626)),
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
                        color: Colors.black.withOpacity(0.52),
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
            color: AppColors.surface,
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
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              if (imageUrl.isNotEmpty) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => AppShimmer.banner16x9(borderRadius: 6),
                      errorWidget: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Category Tag
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFDC2626), // RED TAG
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

              // Title
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  height: 1.3,
                ),
              ),

              if (subtitle.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
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
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAcademicHeaderPill(int currentSem) {
    return Center(
      child: InkWell(
        onTap: () => _showSemesterSelectionSheet(currentSem),
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.border, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.school_rounded, size: 14, color: AppColors.primary),
              ),
              const SizedBox(width: 8),
              Text(
                'CLASS 12 (Semester $currentSem)',
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }

  void _showSemesterSelectionSheet(int currentSem) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'সেমিস্টার নির্বাচন করুন',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'আপনার প্রয়োজনীয় সেমিস্টার বেছে নিন',
                style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              _buildSemesterChoiceTile(
                semester: 3,
                title: 'Semester 3 (সেমিস্টার ৩)',
                subtitle: 'উচ্চ মাধ্যমিক প্রথম পর্ব',
                isSelected: currentSem == 3,
                onTap: () {
                  _storage.semester = 3;
                  setState(() {});
                  widget.onSemesterChanged();
                  Navigator.pop(ctx);
                },
              ),
              const SizedBox(height: 10),
              _buildSemesterChoiceTile(
                semester: 4,
                title: 'Semester 4 (সেমিস্টার ৪)',
                subtitle: 'উচ্চ মাধ্যমিক দ্বিতীয় পর্ব',
                isSelected: currentSem == 4,
                onTap: () {
                  _storage.semester = 4;
                  setState(() {});
                  widget.onSemesterChanged();
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSemesterChoiceTile({
    required int semester,
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primaryLight.withOpacity(0.4) : AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected ? AppColors.primary : AppColors.border,
          width: isSelected ? 1.6 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$semester',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isSelected ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? AppColors.primaryDark : AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPillBadge(String label, Color textColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
          color: textColor,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  Widget _buildStudyReminderTile() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFDE68A), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD97706).withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
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
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // 3D Reminder Bell Icon Emblem
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFFDE68A), width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFD97706).withOpacity(0.08),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Image.asset(
                      'assets/icons/ic_reminder.png',
                      width: 34,
                      height: 34,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // Text Column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'SET STUDY REMINDER',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13.5,
                          color: Color(0xFF78350F),
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'দৈনিক পড়ার রুটিন ও অ্যালার্ম সেট করুন',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF92400E),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Forward chevron circle
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: const Center(
                    child: Icon(Icons.arrow_forward_ios_rounded, size: 11.5, color: Color(0xFF92400E)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernFeatureCard({
    required String tag,
    required String title,
    required String subtitle,
    required String iconAsset,
    required Color emblemBgColor,
    required Color emblemBorderColor,
    required Color tagColor,
    required VoidCallback onTap,
    Widget? trailingBadge,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.035),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // 3D Circular Emblem
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: emblemBgColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: emblemBorderColor, width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Image.asset(
                      iconAsset,
                      width: 44,
                      height: 44,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Title, Tag & Subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            tag,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: tagColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                          if (trailingBadge != null) ...[
                            const SizedBox(width: 8),
                            trailingBadge,
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Chevron Action Circle
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 11.5,
                      color: AppColors.textSecondary,
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

  Widget _buildWhatsAppCommunityBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFBBF7D0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF16A34A).withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            SecurityManager.openExternalUrl(ApiConstants.whatsappUrl);
          },
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // WhatsApp 3D Emblem
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF86EFAC), width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF16A34A).withOpacity(0.08),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Image.asset(
                      'assets/icons/ic_whatsapp.png',
                      width: 36,
                      height: 36,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Text Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'GET ALL LATEST UPDATES',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: Color(0xFF14532D),
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'যুক্ত হন আমাদের অফিসিয়াল হোয়াটসঅ্যাপে',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF166534),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 10),

                // Join Now Button
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF22C55E),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF22C55E).withOpacity(0.35),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Text(
                    'JOIN NOW',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                      letterSpacing: 0.5,
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

  Widget _buildSocialChannelsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Icon(Icons.public_rounded, size: 16, color: AppColors.textSecondary),
            SizedBox(width: 6),
            Text(
              'আমাদের সাথে যুক্ত থাকুন',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            // YouTube Card
            Expanded(
              child: _buildSocialPillCard(
                title: 'YouTube',
                subtitle: 'ফ্রি ক্লাস ও টিপস',
                iconAsset: 'assets/icons/ic_youtube.png',
                bgColor: const Color(0xFFFEF2F2),
                borderColor: const Color(0xFFFECACA),
                titleColor: const Color(0xFFB91C1C),
                url: ApiConstants.youtubeChannelUrl,
              ),
            ),
            const SizedBox(width: 10),
            // Telegram Card
            Expanded(
              child: _buildSocialPillCard(
                title: 'Telegram',
                subtitle: 'নোটস ও পিডিএফ',
                iconAsset: 'assets/icons/ic_telegram.png',
                bgColor: const Color(0xFFF0F9FF),
                borderColor: const Color(0xFFBAE6FD),
                titleColor: const Color(0xFF0369A1),
                url: ApiConstants.telegramChannelUrl,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Facebook Card
        _buildFacebookBannerCard(),
      ],
    );
  }

  Widget _buildSocialPillCard({
    required String title,
    required String subtitle,
    required String iconAsset,
    required Color bgColor,
    required Color borderColor,
    required Color titleColor,
    required String url,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => SecurityManager.openExternalUrl(url),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Image.asset(iconAsset, width: 24, height: 24, fit: BoxFit.contain),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: titleColor,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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

  Widget _buildFacebookBannerCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDBEAFE), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => SecurityManager.openExternalUrl(ApiConstants.facebookPageUrl),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Image.asset(
                      'assets/icons/ic_facebook.png',
                      width: 24,
                      height: 24,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Facebook Page',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1D4ED8),
                        ),
                      ),
                      Text(
                        'আমাদের অফিশিয়াল পেজে যুক্ত হয়ে আপডেট থাকুন',
                        style: TextStyle(fontSize: 10.5, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Color(0xFF1D4ED8)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTrustBadge() {
    return Container(
      margin: const EdgeInsets.only(top: 14, bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F9FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBAE6FD), width: 1.2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.verified_rounded, size: 20, color: Color(0xFF0284C7)),
          SizedBox(width: 8),
          Flexible(
            child: Text(
              'Trusted by over 10,000+ Class 12 Students',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0369A1),
                letterSpacing: 0.3,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
