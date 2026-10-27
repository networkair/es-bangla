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
            icon: Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.notifications_none_rounded, color: AppColors.textPrimary, size: 22),
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.wrongRed,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
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
            // 1. News Slider
            _buildNewsSlider(currentSem),
            const SizedBox(height: 18),

            // 2. Study Reminder Tile
            _buildStudyReminderTile(),
            const SizedBox(height: 16),

            // 3. Semester 3 & Semester 4 Tiles
            Row(
              children: [
                Expanded(
                  child: _buildSemesterTile(
                    title: 'Semester 3',
                    semester: 3,
                    iconAsset: 'assets/icons/ic_sem3.png',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSemesterTile(
                    title: 'Semester 4',
                    semester: 4,
                    iconAsset: 'assets/icons/ic_sem4.png',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 4. Previous Year Questions Tile
            _buildActionTile(
              title: 'Previous Year Questions',
              subtitle: 'গত বছরের প্রশ্নপত্র ও সমাধান',
              iconAsset: 'assets/icons/ic_pyq.png',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PyqScreen()),
                );
              },
            ),
            const SizedBox(height: 14),

            // 5. Book Notes / Buy Notes Tile
            _buildActionTile(
              title: 'Book Notes (বইয়ের নোটস)',
              subtitle: 'গুরুত্বপূর্ণ অধ্যায়ভিত্তিক হ্যান্ডনোটস',
              iconAsset: 'assets/icons/ic_book_notes.png',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BookNotesScreen()),
                );
              },
            ),
            const SizedBox(height: 20),

            // 6. Social Media Tile
            _buildSocialMediaSection(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildNewsSlider(int currentSem) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('news').snapshots(),
      builder: (context, snapshot) {
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

        return Container(
          height: 168,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.primary.withOpacity(0.18), width: 1.2),
            boxShadow: AppColors.softCardShadow,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
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
                          borderRadius: BorderRadius.circular(22),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              // Background Image (Auto-adjusted)
                              CachedNetworkImage(
                                imageUrl: imageUrl,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  color: AppColors.surfaceMuted,
                                  child: const Center(
                                    child: SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(AppColors.primary)),
                                    ),
                                  ),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  color: AppColors.primaryDark,
                                  child: const Center(child: Icon(Icons.broken_image_rounded, color: Colors.white38, size: 30)),
                                ),
                              ),

                              // Dark Gradient Overlay for Maximum Readability
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.black.withOpacity(0.28),
                                      Colors.black.withOpacity(0.85),
                                    ],
                                  ),
                                ),
                              ),

                              // Text content over image
                              Padding(
                                padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    // Top Tag & Live Indicator
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary,
                                            borderRadius: BorderRadius.circular(10),
                                            boxShadow: [
                                              BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 4),
                                            ],
                                          ),
                                          child: Text(
                                            tag,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 0.4,
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
                                            fontSize: 15.5,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            height: 1.25,
                                            shadows: [
                                              Shadow(color: Colors.black87, blurRadius: 4, offset: Offset(0, 1)),
                                            ],
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (subtitle.isNotEmpty) ...[
                                          const SizedBox(height: 3),
                                          Text(
                                            subtitle,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.white.withOpacity(0.9),
                                              height: 1.25,
                                              shadows: const [
                                                Shadow(color: Colors.black87, blurRadius: 3),
                                              ],
                                            ),
                                            maxLines: 1,
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
                                            color: Colors.amberAccent,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        SizedBox(width: 4),
                                        Icon(Icons.arrow_forward_rounded, size: 12, color: Colors.amberAccent),
                                      ],
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
                        borderRadius: BorderRadius.circular(22),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Top Tag & Live Indicator
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      tag,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.4,
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
                                    const SizedBox(height: 3),
                                    Text(
                                      subtitle,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                        height: 1.25,
                                      ),
                                      maxLines: 1,
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
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(width: 3),
                                  Icon(Icons.arrow_forward_rounded, size: 12, color: AppColors.primary),
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
                    bottom: 14,
                    right: 18,
                    child: Row(
                      children: List.generate(newsList.length, (idx) {
                        final isSelected = safeSlideIndex == idx;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          width: isSelected ? 16 : 6,
                          height: 6,
                          margin: const EdgeInsets.only(left: 4),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primary : AppColors.textMuted.withOpacity(0.35),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        );
                      }),
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
                  borderRadius: BorderRadius.circular(16),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: AppColors.surfaceMuted,
                        child: const Center(child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(AppColors.primary))),
                      ),
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
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
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

  Widget _buildStudyReminderTile() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ReminderScreen()),
          );
        },
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Image.asset(
                  'assets/icons/ic_reminder.png',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Study Reminder',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'আজকের পড়াশোনা শেষ হয়েছে? রুটিন দেখুন',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSemesterTile({
    required String title,
    required int semester,
    required String iconAsset,
  }) {
    return Card(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(
          color: AppColors.border,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => NotesSubjectsScreen(semester: semester)),
          );
        },
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight.withOpacity(0.45),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.primary.withOpacity(0.12)),
                    ),
                    child: Center(
                      child: Image.asset(
                        iconAsset,
                        width: 62,
                        height: 62,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.border.withOpacity(0.8)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(Icons.arrow_forward_ios_rounded, size: 11, color: AppColors.primary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required String title,
    required String subtitle,
    required String iconAsset,
    required VoidCallback onTap,
  }) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Image.asset(iconAsset, fit: BoxFit.contain),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSocialMediaSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.softCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.share_rounded, size: 20, color: AppColors.primary),
              SizedBox(width: 8),
              Text(
                'আমাদের সাথে যুক্ত থাকুন',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'সকল নতুন আপডেট, সাজেশন ও ক্লাস সবার আগে পেতে যুক্ত হোন',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
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
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.border),
          ),
          child: Image.asset(iconAsset, fit: BoxFit.contain),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
      ],
    );
  }
}
