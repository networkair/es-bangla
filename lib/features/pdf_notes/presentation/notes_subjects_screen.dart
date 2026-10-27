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
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.folder_open_rounded, size: 56, color: AppColors.textMuted.withOpacity(0.5)),
                              const SizedBox(height: 12),
                              Text(
                                'সেমিস্টার ${widget.semester}-এর কোনো বিষয় পাওয়া যায়নি',
                                style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                          physics: const BouncingScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                            childAspectRatio: 1.15,
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

  Widget _buildSubjectCard(NoteSubject subject) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border, width: 1.2),
        boxShadow: AppColors.softCardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
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
          child: Stack(
            children: [
              // Subtle background floating bubble effect (matching reference image)
              Positioned(
                top: 8,
                right: 12,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primary.withOpacity(0.08), width: 2),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Top: Subject Icon & Title
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Subject Icon Container
                        Container(
                          width: 48,
                          height: 48,
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.primary.withOpacity(0.12)),
                          ),
                          child: Center(
                            child: _buildSubjectEmblem(subject),
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Subject Title & Semester
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                subject.subjectName,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                  height: 1.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Semester ${widget.semester}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // Bottom Row: Topic count on left, Arrow Button on right
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${subject.topics.length} টি অধ্যায়',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        // Circular Arrow Button
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.35),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubjectEmblem(NoteSubject subject) {
    if (subject.iconAsset != null && subject.iconAsset!.isNotEmpty) {
      return Image.asset(
        subject.iconAsset!,
        width: 28,
        height: 28,
        fit: BoxFit.contain,
      );
    }

    // Default clean semantic emblems for subjects
    final nameLower = subject.subjectName.toLowerCase();
    final nameEnLower = subject.subjectNameEn.toLowerCase();

    if (nameLower.contains('বাংলা') || nameEnLower.contains('bengali')) {
      return const Text(
        'অ',
        style: TextStyle(
          color: AppColors.primaryDark,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      );
    } else if (nameLower.contains('english') || nameEnLower.contains('english')) {
      return const Text(
        'Aa',
        style: TextStyle(
          color: AppColors.primaryDark,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      );
    } else if (nameLower.contains('ইতিহাস') || nameEnLower.contains('history')) {
      return const Icon(Icons.account_balance_rounded, color: AppColors.primaryDark, size: 22);
    } else if (nameLower.contains('ভূগোল') || nameEnLower.contains('geography')) {
      return const Icon(Icons.public_rounded, color: AppColors.primaryDark, size: 22);
    } else if (nameLower.contains('রাষ্ট্র') || nameEnLower.contains('political') || nameEnLower.contains('polscience')) {
      return const Icon(Icons.gavel_rounded, color: AppColors.primaryDark, size: 22);
    } else if (nameLower.contains('শিক্ষা') || nameEnLower.contains('education')) {
      return const Icon(Icons.school_rounded, color: AppColors.primaryDark, size: 22);
    } else if (nameLower.contains('সংস্কৃত') || nameEnLower.contains('sanskrit')) {
      return const Text(
        'ॐ',
        style: TextStyle(
          color: AppColors.primaryDark,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      );
    } else if (nameLower.contains('দর্শন') || nameEnLower.contains('philosophy')) {
      return const Icon(Icons.psychology_rounded, color: AppColors.primaryDark, size: 22);
    } else if (nameLower.contains('সমাজ') || nameEnLower.contains('sociology')) {
      return const Icon(Icons.groups_rounded, color: AppColors.primaryDark, size: 22);
    } else if (nameLower.contains('পরিবেশ') || nameEnLower.contains('evs')) {
      return const Icon(Icons.eco_rounded, color: AppColors.primaryDark, size: 22);
    }

    return const Icon(Icons.menu_book_rounded, color: AppColors.primaryDark, size: 22);
  }
}
