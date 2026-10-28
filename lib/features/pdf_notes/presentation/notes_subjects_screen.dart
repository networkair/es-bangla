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
    if (mounted) {
      setState(() {
        _subjects = list;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top Modern Header matching reference layout
            _buildHeader(context),

            // Subject Cards Grid (Dynamic, renders whatever subjects are in manifest)
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
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                          physics: const BouncingScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 16,
                            childAspectRatio: 0.68,
                          ),
                          itemCount: _subjects.length,
                          itemBuilder: (context, index) {
                            final subject = _subjects[index];
                            return _buildSubjectCard(subject);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 20, 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(bottom: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Row(
        children: [
          // Circular White Back Button with soft shadow
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary, size: 20),
            ),
          ),
          const SizedBox(width: 16),

          // Title & Subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Semester ${widget.semester}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Class 12',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Right Illustration Badge
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.primary.withOpacity(0.15)),
            ),
            child: const Icon(
              Icons.school_rounded,
              color: AppColors.primary,
              size: 26,
            ),
          ),
        ],
      ),
    );
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

  Widget _buildSubjectCard(NoteSubject subject) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: const Color(0xFFE2E8F0).withOpacity(0.8),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(26),
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
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Large 3D Subject Icon sitting directly on the card with NO background
                Expanded(
                  child: Center(
                    child: _buildSubjectEmblem(subject),
                  ),
                ),

                const SizedBox(height: 12),

                // 2. Subject Title
                Text(
                  subject.subjectName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.3,
                    height: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 6),

                // 3. Double Arrow (») matching reference image
                const Align(
                  alignment: Alignment.bottomRight,
                  child: Icon(
                    Icons.keyboard_double_arrow_right_rounded,
                    size: 30,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
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
      width: 95,
      height: 95,
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
