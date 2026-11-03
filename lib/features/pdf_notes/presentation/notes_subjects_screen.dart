import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../data/content_manifest_repository.dart';
import 'notes_topics_screen.dart';

class NotesSubjectsScreen extends StatefulWidget {
  final int semester;

  const NotesSubjectsScreen({super.key, required this.semester});

  @override
  State<NotesSubjectsScreen> createState() => _NotesSubjectsScreenState();
}

class _NotesSubjectsScreenState extends State<NotesSubjectsScreen> {
  final ContentManifestRepository _repo = ContentManifestRepository();
  List<NoteSubject> _subjects = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    final list = await _repo.getNotesForSemester(widget.semester);
    const canonicalOrders = {
      'bengali': 1,
      'english': 2,
      'polscience': 3,
      'political_science': 3,
      'education': 4,
      'history': 5,
      'philosophy': 6,
      'sanskrit': 7,
      'geography': 8,
      'computer': 9,
      'computer_application': 9,
    };
    list.sort((a, b) {
      final orderA = canonicalOrders[a.subjectId.toLowerCase()] ?? 99;
      final orderB = canonicalOrders[b.subjectId.toLowerCase()] ?? 99;
      return orderA.compareTo(orderB);
    });
    if (mounted) {
      setState(() {
        _subjects = list;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFFCF8F4),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFFCF8F4),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F1E36),
            size: 24,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 1.2,
              height: 22,
              margin: const EdgeInsets.only(right: 12),
              color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Choose Subject',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F1E36),
                    letterSpacing: -0.3,
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  width: 42,
                  height: 3.5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B), // Golden Yellow Accent Underline
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE0F2FE),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFBAE6FD),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.school_rounded,
                  size: 15,
                  color: Color(0xFF0070F3),
                ),
                const SizedBox(width: 5),
                Text(
                  'SEM ${widget.semester}',
                  style: const TextStyle(
                    color: Color(0xFF0070F3),
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Subtitle matching reference mockup
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Text(
                widget.semester == 3
                    ? 'সেমিস্টার ৩-এর হ্যান্ডনোটস পড়তে আপনার বিষয়টি বেছে নিন'
                    : 'সেমিস্টার ${widget.semester}-এর হ্যান্ডনোটস পড়তে বিষয়টি বেছে নিন',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
            ),

            // Subject Cards Grid
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation(AppColors.primary),
                      ),
                    )
                  : _subjects.isEmpty
                      ? _buildComingSoonState()
                      : GridView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          physics: const BouncingScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 0.85,
                          ),
                          itemCount: _subjects.length,
                          itemBuilder: (context, index) {
                            final subject = _subjects[index];
                            return _buildSubjectCard(subject, isDark);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  String _getCleanDisplayName(String rawName, String id) {
    final lowerId = id.toLowerCase();
    final lowerName = rawName.toLowerCase();

    if (lowerId.contains('bengali') || lowerId.contains('bangla') || lowerName.contains('বাংলা')) {
      return 'বাংলা';
    } else if (lowerId.contains('english') || lowerName.contains('english') || lowerName.contains('ইংরেজি')) {
      return 'English';
    } else if (lowerId.contains('pol') || lowerName.contains('রাষ্ট্র')) {
      return 'রাষ্ট্রবিজ্ঞান';
    } else if (lowerId.contains('edu') || lowerName.contains('শিক্ষা')) {
      return 'শিক্ষাবিজ্ঞান';
    } else if (lowerId.contains('hist') || lowerName.contains('ইতিহাস')) {
      return 'ইতিহাস';
    } else if (lowerId.contains('phil') || lowerName.contains('দর্শন')) {
      return 'দর্শন';
    } else if (lowerId.contains('san') || lowerName.contains('সংস্কৃত')) {
      return 'সংস্কৃত';
    } else if (lowerId.contains('geo') || lowerName.contains('ভূগোল')) {
      return 'ভূগোল';
    } else if (lowerId.contains('comp') || lowerName.contains('কম্পিউটার')) {
      return 'কম্পিউটার';
    }
    return rawName;
  }

  String _getSubjectAsset(String id, String name, String nameEn) {
    final lowerId = id.toLowerCase();
    final lowerName = name.toLowerCase();
    final lowerEn = nameEn.toLowerCase();

    if (lowerId.contains('bengali') || lowerId.contains('bangla') || lowerName.contains('বাংলা') || lowerEn.contains('bengali')) {
      return 'assets/icons/subjects/ic_sub_bangla.png';
    } else if (lowerId.contains('english') || lowerName.contains('english') || lowerName.contains('ইংরেজি') || lowerName.contains('ইংরাজি') || lowerEn.contains('english')) {
      return 'assets/icons/subjects/ic_sub_english.png';
    } else if (lowerId.contains('hist') || lowerName.contains('ইতিহাস') || lowerEn.contains('history')) {
      return 'assets/icons/subjects/ic_sub_history.png';
    } else if (lowerId.contains('geo') || lowerName.contains('ভূগোল') || lowerEn.contains('geography')) {
      return 'assets/icons/subjects/ic_sub_geography.png';
    } else if (lowerId.contains('pol') || lowerName.contains('রাষ্ট্র') || lowerEn.contains('pol')) {
      return 'assets/icons/subjects/ic_sub_polscience.png';
    } else if (lowerId.contains('edu') || lowerName.contains('শিক্ষা') || lowerEn.contains('education')) {
      return 'assets/icons/subjects/ic_sub_education.png';
    } else if (lowerId.contains('phil') || lowerName.contains('দর্শন') || lowerEn.contains('philosophy')) {
      return 'assets/icons/subjects/ic_sub_philosophy.png';
    } else if (lowerId.contains('san') || lowerName.contains('সংস্কৃত') || lowerEn.contains('sanskrit')) {
      return 'assets/icons/subjects/ic_sub_sanskrit.png';
    } else if (lowerId.contains('comp') || lowerName.contains('কম্পিউটার') || lowerEn.contains('computer')) {
      return 'assets/icons/subjects/ic_sub_computer.png';
    }
    return 'assets/icons/subjects/ic_sub_bangla.png';
  }

  Widget _buildSubjectCard(NoteSubject subject, bool isDark) {
    final displayName = _getCleanDisplayName(subject.subjectName, subject.subjectId);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : const Color(0xFF0F1E36)).withOpacity(isDark ? 0.35 : 0.05),
            offset: const Offset(0, 8),
            blurRadius: 18,
            spreadRadius: -2,
          ),
          BoxShadow(
            color: (isDark ? Colors.black : const Color(0xFF0F1E36)).withOpacity(isDark ? 0.15 : 0.02),
            offset: const Offset(0, 2),
            blurRadius: 4,
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => NotesTopicsScreen(
                    subject: subject,
                    semester: widget.semester,
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 16, 12, 14),
              child: Column(
                children: [
                  // 1. Large 3D Subject Icon sitting directly on the card
                  Expanded(
                    child: Center(
                      child: _buildSubjectEmblem(subject),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // 2. Bottom Row: Subject Title on Left, Double Arrow Button on Right
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          displayName,
                          style: TextStyle(
                            fontSize: displayName.length > 8 ? 16.0 : 17.5,
                            fontWeight: FontWeight.bold,
                            color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F1E36),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFE0F2FE),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Icon(
                            Icons.keyboard_double_arrow_right_rounded,
                            size: 20,
                            color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0070F3),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubjectEmblem(NoteSubject subject) {
    String assetPath = (subject.iconAsset != null && subject.iconAsset!.isNotEmpty)
        ? subject.iconAsset!
        : _getSubjectAsset(subject.subjectId, subject.subjectName, subject.subjectNameEn);

    return Image.asset(
      assetPath,
      width: 88,
      height: 88,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => _buildFallbackEmblem(subject),
    );
  }

  Widget _buildFallbackEmblem(NoteSubject subject) {

    // Default clean semantic emblems for subjects
    final nameLower = subject.subjectName.toLowerCase();
    final nameEnLower = subject.subjectNameEn.toLowerCase();

    if (nameLower.contains('বাংলা') || nameEnLower.contains('bengali')) {
      return const Text(
        'অ',
        style: TextStyle(
          color: AppColors.primaryDark,
          fontWeight: FontWeight.bold,
          fontSize: 48,
        ),
      );
    } else if (nameLower.contains('english') || nameEnLower.contains('english')) {
      return const Text(
        'Aa',
        style: TextStyle(
          color: AppColors.primaryDark,
          fontWeight: FontWeight.bold,
          fontSize: 40,
        ),
      );
    } else if (nameLower.contains('ইতিহাস') || nameEnLower.contains('history')) {
      return const Icon(Icons.account_balance_rounded, color: AppColors.primary, size: 56);
    } else if (nameLower.contains('ভূগোল') || nameEnLower.contains('geography')) {
      return const Icon(Icons.public_rounded, color: AppColors.primary, size: 56);
    } else if (nameLower.contains('রাষ্ট্র') || nameEnLower.contains('political') || nameEnLower.contains('polscience')) {
      return const Icon(Icons.gavel_rounded, color: AppColors.primary, size: 56);
    } else if (nameLower.contains('শিক্ষা') || nameEnLower.contains('education')) {
      return const Icon(Icons.school_rounded, color: AppColors.primary, size: 56);
    } else if (nameLower.contains('সংস্কৃত') || nameEnLower.contains('sanskrit')) {
      return const Text(
        'ॐ',
        style: TextStyle(
          color: AppColors.primaryDark,
          fontWeight: FontWeight.bold,
          fontSize: 48,
        ),
      );
    } else if (nameLower.contains('দর্শন') || nameEnLower.contains('philosophy')) {
      return const Icon(Icons.psychology_rounded, color: AppColors.primary, size: 56);
    } else if (nameLower.contains('সমাজ') || nameEnLower.contains('sociology')) {
      return const Icon(Icons.groups_rounded, color: AppColors.primary, size: 56);
    } else if (nameLower.contains('পরিবেশ') || nameEnLower.contains('evs')) {
      return const Icon(Icons.eco_rounded, color: AppColors.primary, size: 56);
    }

    return const Icon(Icons.menu_book_rounded, color: AppColors.primary, size: 56);
  }

  Widget _buildComingSoonState() {
    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary.withOpacity(0.18), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: AppColors.primary,
                size: 38,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primary.withOpacity(0.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'কামিং সুন • COMING SOON',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryDark,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'সেমিস্টার ${widget.semester}-এর নোটস শীঘ্রই আসছে',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                letterSpacing: -0.3,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              'এই সেমিস্টারের অধ্যায়ভিত্তিক হ্যান্ডনোটস ও সাজেশনস তৈরির কাজ চলছে। খুব শীঘ্রই অ্যাপে সমস্ত বিষয়ের নোটস যুক্ত করা হবে।',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            if (widget.semester == 4) ...[
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const NotesSubjectsScreen(semester: 3),
                    ),
                  );
                },
                icon: const Icon(Icons.arrow_back_rounded, size: 18, color: AppColors.primary),
                label: const Text(
                  'সেমিস্টার ৩-এর নোটস দেখুন',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.primary, width: 1.2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  backgroundColor: AppColors.surface,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
