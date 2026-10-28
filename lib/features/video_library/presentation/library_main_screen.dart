import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import 'library_subjects_screen.dart';

class LibraryMainScreen extends StatelessWidget {
  const LibraryMainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Banner Area (reserved placeholder ready for banner image)
              _buildTopBanner(context, isDark),
              const SizedBox(height: 20),

              // Semester 3 3D Card
              _buildSemesterCard(
                context: context,
                semesterTitle: 'Semester 3',
                subtitle: 'All Subjects Video Lectures & Classes',
                semester: 3,
                isDark: isDark,
              ),
              const SizedBox(height: 18),

              // Semester 4 3D Card
              _buildSemesterCard(
                context: context,
                semesterTitle: 'Semester 4',
                subtitle: 'All Subjects Video Lectures & Classes',
                semester: 4,
                isDark: isDark,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBanner(BuildContext context, bool isDark) {
    return Container(
      width: double.infinity,
      height: 165,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : const Color(0xFF000000)).withOpacity(isDark ? 0.35 : 0.10),
            blurRadius: 20,
            spreadRadius: 1,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: (isDark ? Colors.black : const Color(0xFF000000)).withOpacity(isDark ? 0.18 : 0.03),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(21),
        child: Image.asset(
          'assets/images/library_banner.png',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            // Clean placeholder ready for banner image
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                      : [const Color(0xFFF0F9FF), const Color(0xFFE0F2FE)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.image_outlined,
                        size: 32,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Banner Area',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF0284C7),
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSemesterCard({
    required BuildContext context,
    required String semesterTitle,
    required String subtitle,
    required int semester,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : const Color(0xFF000000)).withOpacity(isDark ? 0.35 : 0.12),
            blurRadius: 22,
            spreadRadius: 1,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: (isDark ? Colors.black : const Color(0xFF000000)).withOpacity(isDark ? 0.18 : 0.04),
            blurRadius: 6,
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
              MaterialPageRoute(
                builder: (_) => LibrarySubjectsScreen(semester: semester),
              ),
            );
          },
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Badge: Class 12
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0C4A6E).withOpacity(0.4) : const Color(0xFFE0F2FE),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isDark ? const Color(0xFF0284C7) : const Color(0xFFBAE6FD),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          'Class 12',
                          style: TextStyle(
                            color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Semester Title
                      Text(
                        semesterTitle,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Subtitle in English
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          height: 1.35,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Pill Button with Blue Circle Arrow
                      Container(
                        padding: const EdgeInsets.only(left: 14, right: 6, top: 5, bottom: 5),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Watch Videos',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 28,
                              height: 28,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFF0284C7),
                              ),
                              child: const Icon(
                                Icons.arrow_forward_rounded,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Right side illustration (reserved clean space until user provides 3D graphics)
                _buildCardIllustration(semester),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardIllustration(int semester) {
    final assetName = semester == 3
        ? 'assets/images/library_sem3_3d.png'
        : 'assets/images/library_sem4_3d.png';

    return SizedBox(
      width: 105,
      height: 115,
      child: Image.asset(
        assetName,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          // Space kept clean and empty as requested until user provides the 3D graphics
          return const SizedBox(width: 105, height: 115);
        },
      ),
    );
  }
}
