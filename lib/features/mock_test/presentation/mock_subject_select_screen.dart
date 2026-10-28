import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/storage/local_storage_service.dart';
import '../../../core/widgets/app_shimmer.dart';
import '../data/mock_test_repository.dart';
import '../domain/mock_test_models.dart';
import 'mock_topics_sets_screen.dart';

class MockSubjectSelectScreen extends StatefulWidget {
  final bool isPremiumMode;

  const MockSubjectSelectScreen({super.key, required this.isPremiumMode});

  @override
  State<MockSubjectSelectScreen> createState() => _MockSubjectSelectScreenState();
}

class _MockSubjectSelectScreenState extends State<MockSubjectSelectScreen> {
  final MockTestRepository _repository = MockTestRepository();
  List<SubjectModel> _subjects = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSubjects();
  }

  Future<void> _loadSubjects() async {
    final sem = LocalStorageService().semester;
    try {
      final list = await _repository.getSubjects(sem);
      if (mounted) {
        setState(() {
          _subjects = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'বিষয়সমূহ লোড করা যায়নি। ইন্টারনেট সংযোগ চেক করুন।';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        title: const Text(
          'Choose Subject',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
            letterSpacing: -0.4,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: widget.isPremiumMode ? AppColors.premiumLight : AppColors.primaryLight,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: widget.isPremiumMode
                    ? AppColors.premiumGold.withOpacity(0.4)
                    : AppColors.primary.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.isPremiumMode
                      ? Icons.workspace_premium_rounded
                      : Icons.verified_outlined,
                  size: 14,
                  color: widget.isPremiumMode ? AppColors.premiumGold : AppColors.primaryDark,
                ),
                const SizedBox(width: 4),
                Text(
                  widget.isPremiumMode ? 'PREMIUM' : 'FREE',
                  style: TextStyle(
                    color: widget.isPremiumMode ? AppColors.premiumGold : AppColors.primaryDark,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return _buildLoadingGrid();
    }

    if (_error != null && _subjects.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.wrongRed),
              const SizedBox(height: 16),
              Text(
                _error!,
                style: const TextStyle(fontSize: 15, color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() => _isLoading = true);
                  _loadSubjects();
                },
                child: const Text('আবার চেষ্টা করুন'),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Clean, elegant 1-line subtitle
        const Padding(
          padding: EdgeInsets.fromLTRB(18, 4, 18, 14),
          child: Text(
            'মক টেস্ট দিতে আপনার বিষয়টি বেছে নিন',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ),

        // 2-column Modern Subject Cards Grid
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.68,
              crossAxisSpacing: 16,
              mainAxisSpacing: 18,
            ),
            itemCount: _subjects.length,
            itemBuilder: (context, index) {
              final subject = _subjects[index];
              return _buildSubjectCard(subject);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(18, 4, 18, 14),
          child: Text(
            'মক টেস্ট দিতে আপনার বিষয়টি বেছে নিন',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.68,
              crossAxisSpacing: 16,
              mainAxisSpacing: 18,
            ),
            itemCount: 6,
            itemBuilder: (context, index) {
              return AppShimmer(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: AppColors.border, width: 1.5),
                  ),
                  padding: const EdgeInsets.fromLTRB(14, 20, 14, 16),
                  child: Column(
                    children: [
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        width: 95,
                        height: 18,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const Spacer(),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _getSubjectAsset(SubjectModel subject) {
    final id = subject.subjectId.toLowerCase();
    final name = subject.name.toLowerCase();
    final nameEn = subject.nameEn.toLowerCase();

    if (id.contains('bengali') || id.contains('bangla') || name.contains('বাংলা') || nameEn.contains('bengali')) {
      return 'assets/icons/subjects/ic_sub_bangla.png';
    } else if (id.contains('english') || name.contains('english') || name.contains('ইংরেজি') || name.contains('ইংরাজি') || nameEn.contains('english')) {
      return 'assets/icons/subjects/ic_sub_english.png';
    } else if (id.contains('hist') || name.contains('ইতিহাস') || nameEn.contains('history')) {
      return 'assets/icons/subjects/ic_sub_history.png';
    } else if (id.contains('geo') || name.contains('ভূগোল') || nameEn.contains('geography')) {
      return 'assets/icons/subjects/ic_sub_geography.png';
    } else if (id.contains('pol') || name.contains('রাষ্ট্র') || nameEn.contains('pol')) {
      return 'assets/icons/subjects/ic_sub_polscience.png';
    } else if (id.contains('edu') || name.contains('শিক্ষা') || nameEn.contains('education')) {
      return 'assets/icons/subjects/ic_sub_education.png';
    } else if (id.contains('phil') || name.contains('দর্শন') || nameEn.contains('philosophy')) {
      return 'assets/icons/subjects/ic_sub_philosophy.png';
    } else if (id.contains('san') || name.contains('সংস্কৃত') || nameEn.contains('sanskrit')) {
      return 'assets/icons/subjects/ic_sub_sanskrit.png';
    } else if (id.contains('comp') || name.contains('কম্পিউটার') || nameEn.contains('computer')) {
      return 'assets/icons/subjects/ic_sub_computer.png';
    }

    if (subject.iconUrl.isNotEmpty && subject.iconUrl.startsWith('assets/')) {
      return subject.iconUrl;
    }
    return 'assets/icons/subjects/ic_sub_bangla.png';
  }

  Widget _buildSubjectCard(SubjectModel subject) {
    final theme = _getSubjectTheme(subject);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: widget.isPremiumMode
              ? AppColors.premiumGold.withOpacity(0.35)
              : const Color(0xFFE2E8F0).withOpacity(0.8),
          width: widget.isPremiumMode ? 1.4 : 1.0,
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
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MockTopicsSetsScreen(
                  subject: subject,
                  isPremiumMode: widget.isPremiumMode,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(26),
          splashColor: theme.color.withOpacity(0.08),
          highlightColor: theme.color.withOpacity(0.04),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Top Section: Large 3D Subject Icon directly on card (NO background)
                Expanded(
                  child: Center(
                    child: Image.asset(
                      _getSubjectAsset(subject),
                      width: 95,
                      height: 95,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Icon(
                        theme.icon,
                        size: 54,
                        color: theme.color,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // 2. Subject Name
                Text(
                  subject.name,
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

  _SubjectTheme _getSubjectTheme(SubjectModel subject) {
    final id = subject.subjectId.toLowerCase();
    final name = subject.name.toLowerCase();

    if (id.contains('bengali') || id.contains('bangla') || name.contains('বাংলা')) {
      return const _SubjectTheme(
        color: Color(0xFF2563EB), // Royal Blue
        icon: Icons.auto_stories_rounded,
      );
    } else if (id.contains('english') || name.contains('english') || name.contains('ইংরেজি')) {
      return const _SubjectTheme(
        color: Color(0xFF0284C7), // Sky / Ocean Blue
        icon: Icons.translate_rounded,
      );
    } else if (id.contains('hist') || name.contains('ইতিহাস')) {
      return const _SubjectTheme(
        color: Color(0xFFD97706), // Amber / Heritage Gold
        icon: Icons.history_edu_rounded,
      );
    } else if (id.contains('geo') || name.contains('ভূগোল')) {
      return const _SubjectTheme(
        color: Color(0xFF059669), // Emerald Earth
        icon: Icons.public_rounded,
      );
    } else if (id.contains('pol') || name.contains('রাষ্ট্র')) {
      return const _SubjectTheme(
        color: Color(0xFF7C3AED), // Violet Justice
        icon: Icons.balance_rounded,
      );
    } else if (id.contains('edu') || name.contains('শিক্ষা')) {
      return const _SubjectTheme(
        color: Color(0xFFE11D48), // Rose Academy
        icon: Icons.school_rounded,
      );
    } else if (id.contains('phil') || name.contains('দর্শন')) {
      return const _SubjectTheme(
        color: Color(0xFF0D9488), // Teal Wisdom
        icon: Icons.psychology_rounded,
      );
    } else if (id.contains('san') || name.contains('সংস্কৃত')) {
      return const _SubjectTheme(
        color: Color(0xFFEA580C), // Saffron Heritage
        icon: Icons.import_contacts_rounded,
      );
    } else if (id.contains('comp') || name.contains('কম্পিউটার')) {
      return const _SubjectTheme(
        color: Color(0xFF4F46E5), // Indigo Tech
        icon: Icons.terminal_rounded,
      );
    }

    return const _SubjectTheme(
      color: AppColors.primary,
      icon: Icons.menu_book_rounded,
    );
  }
}

class _SubjectTheme {
  final Color color;
  final IconData icon;

  const _SubjectTheme({required this.color, required this.icon});
}
