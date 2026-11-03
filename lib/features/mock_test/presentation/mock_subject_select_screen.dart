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
      const canonicalOrders = {
        'bengali': 1,
        'english': 2,
        'political_science': 3,
        'polscience': 3,
        'education': 4,
        'history': 5,
        'philosophy': 6,
        'sanskrit': 7,
        'geography': 8,
        'computer_application': 9,
        'computer': 9,
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
              color: widget.isPremiumMode
                  ? (isDark ? const Color(0xFF332005) : const Color(0xFFFEF3C7))
                  : (isDark ? const Color(0xFF0C2A4D) : const Color(0xFFE0F2FE)),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: widget.isPremiumMode
                    ? const Color(0xFFFCD34D)
                    : const Color(0xFFBAE6FD),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.isPremiumMode
                      ? Icons.workspace_premium_rounded
                      : Icons.verified_user_rounded,
                  size: 15,
                  color: widget.isPremiumMode
                      ? const Color(0xFFD97706)
                      : const Color(0xFF0070F3),
                ),
                const SizedBox(width: 5),
                Text(
                  widget.isPremiumMode ? 'PREMIUM' : 'FREE',
                  style: TextStyle(
                    color: widget.isPremiumMode
                        ? const Color(0xFFD97706)
                        : const Color(0xFF0070F3),
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
      body: _buildBody(isDark),
    );
  }

  Widget _buildBody(bool isDark) {
    if (_isLoading) {
      return _buildLoadingGrid(isDark);
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
        // Subtitle matching reference mockup
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: Text(
            widget.isPremiumMode
                ? 'প্রিমিয়াম মক টেস্ট দিতে আপনার বিষয়টি বেছে নিন'
                : 'মক টেস্ট দিতে আপনার বিষয়টি বেছে নিন',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
        ),

        // 2-column Modern Subject Cards Grid matching reference
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            physics: const BouncingScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.85,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: _subjects.length,
            itemBuilder: (context, index) {
              final subject = _subjects[index];
              return _buildSubjectCard(subject, isDark);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingGrid(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: Text(
            'মক টেস্ট দিতে আপনার বিষয়টি বেছে নিন',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.85,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: 6,
            itemBuilder: (context, index) {
              return AppShimmer(
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      width: 1.2,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
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

  String _getSubjectAsset(SubjectModel subject) {
    final id = subject.subjectId.toLowerCase();
    final name = subject.name.toLowerCase();
    final nameEn = subject.nameEn.toLowerCase();

    if (id.contains('bengali') || id.contains('bangla') || name.contains('বাংলা') || nameEn.contains('bengali')) {
      return 'assets/icons/subjects/ic_sub_bangla.png';
    } else if (id.contains('english') || name.contains('english') || name.contains('ইংরেজি') || name.contains('ইংরাজি') || nameEn.contains('english')) {
      return 'assets/icons/subjects/ic_sub_english.png';
    } else if (id.contains('pol') || name.contains('রাষ্ট্র') || nameEn.contains('pol')) {
      return 'assets/icons/subjects/ic_sub_polscience.png';
    } else if (id.contains('edu') || name.contains('শিক্ষা') || nameEn.contains('education')) {
      return 'assets/icons/subjects/ic_sub_education.png';
    } else if (id.contains('hist') || name.contains('ইতিহাস') || nameEn.contains('history')) {
      return 'assets/icons/subjects/ic_sub_history.png';
    } else if (id.contains('phil') || name.contains('দর্শন') || nameEn.contains('philosophy')) {
      return 'assets/icons/subjects/ic_sub_philosophy.png';
    } else if (id.contains('geo') || name.contains('ভূগোল') || nameEn.contains('geography')) {
      return 'assets/icons/subjects/ic_sub_geography.png';
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

  Widget _buildSubjectCard(SubjectModel subject, bool isDark) {
    final theme = _getSubjectTheme(subject);
    final displayName = _getCleanDisplayName(subject.name, subject.subjectId);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: widget.isPremiumMode
              ? const Color(0xFFFDE68A)
              : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          width: widget.isPremiumMode ? 1.4 : 1.2,
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
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 16, 12, 14),
              child: Column(
                children: [
                  // 1. Top Section: Large 3D Subject Icon directly on card
                  Expanded(
                    child: Center(
                      child: Image.asset(
                        _getSubjectAsset(subject),
                        width: 88,
                        height: 88,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Icon(
                          theme.icon,
                          size: 54,
                          color: theme.color,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // 2. Bottom Row: Subject Name on Left, Double Arrow Button on Right
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
