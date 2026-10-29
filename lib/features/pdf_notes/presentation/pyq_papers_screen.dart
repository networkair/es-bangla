import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class PyqPaperItem {
  final String subjectName;
  final String thumbnailAsset;

  const PyqPaperItem({
    required this.subjectName,
    required this.thumbnailAsset,
  });
}

class PyqPapersScreen extends StatelessWidget {
  final int semester;
  final String year;

  const PyqPapersScreen({
    super.key,
    required this.semester,
    required this.year,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Pre-configured subjects for Semester 3
    final List<PyqPaperItem> papers = semester == 3
        ? [
            const PyqPaperItem(
              subjectName: 'Class 12 Bengali',
              thumbnailAsset: 'assets/images/pyq_bengali_sem3.png',
            ),
            const PyqPaperItem(
              subjectName: 'Class 12 English',
              thumbnailAsset: 'assets/images/pyq_english_sem3.png',
            ),
          ]
        : [];

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Semester $semester - $year',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: papers.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.hourglass_empty_rounded,
                          size: 40,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Coming Soon',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'সেমিস্টার $semester-এর প্রশ্নপত্রগুলো শীঘ্রই যুক্ত করা হবে।',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : ListView.builder(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                itemCount: papers.length,
                itemBuilder: (context, index) {
                  final paper = papers[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _buildPaperCard(
                      context: context,
                      paper: paper,
                      isDark: isDark,
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildPaperCard({
    required BuildContext context,
    required PyqPaperItem paper,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : const Color(0xFF000000)).withOpacity(isDark ? 0.30 : 0.08),
            blurRadius: 10,
            spreadRadius: 0.5,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showComingSoonModal(context, paper.subjectName, isDark),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                // Thumbnail on Left
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: 130,
                    height: 74,
                    child: Image.asset(
                      paper.thumbnailAsset,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Subject Name in single line on Right
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        paper.subjectName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF0C4A6E).withOpacity(0.4)
                              : const Color(0xFFE0F2FE),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Question Paper',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Arrow icon
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                ),
                const SizedBox(width: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showComingSoonModal(BuildContext context, String subjectName, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.hourglass_top_rounded,
                  color: AppColors.primary,
                  size: 30,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Coming Soon!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$subjectName ($year) প্রশ্নপত্রটি শীঘ্রই যুক্ত করা হবে।',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'ঠিক আছে',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
