import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import 'library_subjects_screen.dart';

class LibraryMainScreen extends StatelessWidget {
  const LibraryMainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Top Banner
              _buildTopBanner(context, isDark),
              const SizedBox(height: 18),

              // 2. Semester 3 3D Card (Ice Blue Theme)
              _buildSemesterCard(
                context: context,
                semesterTitle: 'Semester 3',
                subtitle: 'All Subjects Video Lectures & Classes',
                semester: 3,
                isDark: isDark,
              ),
              const SizedBox(height: 16),

              // 3. Semester 4 3D Card (Warm Peach/Amber Theme)
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
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFBAE6FD).withOpacity(0.6),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : const Color(0xFF0284C7)).withOpacity(isDark ? 0.35 : 0.12),
            blurRadius: 18,
            spreadRadius: 1,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(21),
        child: AspectRatio(
          aspectRatio: 1672 / 941,
          child: Image.asset(
            'assets/images/library_banner.png',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
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
                  child: Icon(
                    Icons.image_outlined,
                    size: 36,
                    color: AppColors.primary.withOpacity(0.6),
                  ),
                ),
              );
            },
          ),
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
    final isSem3 = semester == 3;

    // Background gradient matched to each semester's 3D icon
    final cardGradient = isDark
        ? (isSem3
            ? const LinearGradient(
                colors: [Color(0xFF1E293B), Color(0xFF0F2644)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : const LinearGradient(
                colors: [Color(0xFF1E293B), Color(0xFF332014)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ))
        : (isSem3
            ? const LinearGradient(
                colors: [Color(0xFFF8FCFE), Color(0xFFEAF5FC)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : const LinearGradient(
                colors: [Color(0xFFFFFDF9), Color(0xFFFFF3E6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ));

    // Border color matching the icon color scheme
    final borderColor = isDark
        ? (isSem3
            ? const Color(0xFF0284C7).withOpacity(0.4)
            : const Color(0xFFF97316).withOpacity(0.4))
        : (isSem3
            ? const Color(0xFFBAE6FD).withOpacity(0.85)
            : const Color(0xFFFED7AA).withOpacity(0.85));

    // 3D Shadow with soft color tint
    final shadowColor = isDark
        ? Colors.black
        : (isSem3 ? const Color(0xFF0284C7) : const Color(0xFFEA580C));

    // Badge styling
    final badgeBg = isDark
        ? (isSem3 ? const Color(0xFF0C4A6E).withOpacity(0.5) : const Color(0xFF7C2D12).withOpacity(0.5))
        : (isSem3 ? const Color(0xFFE0F2FE) : const Color(0xFFFFEDD5));

    final badgeBorder = isDark
        ? (isSem3 ? const Color(0xFF0284C7) : const Color(0xFFF97316))
        : (isSem3 ? const Color(0xFFBAE6FD) : const Color(0xFFFED7AA));

    final badgeTextColor = isDark
        ? (isSem3 ? const Color(0xFF38BDF8) : const Color(0xFFFB923C))
        : (isSem3 ? const Color(0xFF0284C7) : const Color(0xFFC2410C));

    final assetPath = isSem3
        ? 'assets/images/library_sem3_3d.png'
        : 'assets/images/library_sem4_3d.png';

    return Container(
      decoration: BoxDecoration(
        gradient: cardGradient,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: shadowColor.withOpacity(isDark ? 0.38 : 0.12),
            blurRadius: 20,
            spreadRadius: 1,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
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
            padding: const EdgeInsets.fromLTRB(18, 16, 12, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Left Column: Details & Action Button
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Pill Badge: Class 12
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                        decoration: BoxDecoration(
                          color: badgeBg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: badgeBorder, width: 1),
                        ),
                        child: Text(
                          'Class 12',
                          style: TextStyle(
                            color: badgeTextColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Semester Title
                      Text(
                        semesterTitle,
                        style: TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 5),

                      // Subtitle in English
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                          height: 1.35,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Action Button with Blue Circle Arrow
                      Container(
                        padding: const EdgeInsets.only(left: 14, right: 6, top: 5, bottom: 5),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0F172A) : Colors.white,
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

                // Right: 3D Illustration
                SizedBox(
                  width: 125,
                  height: 125,
                  child: Image.asset(
                    assetPath,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const SizedBox(width: 125, height: 125);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
