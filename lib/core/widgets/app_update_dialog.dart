import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AppUpdateDialog extends StatelessWidget {
  final String title;
  final String message;
  final String version;
  final String updateUrl;
  final bool isForce;
  final List<String>? releaseNotes;

  const AppUpdateDialog({
    super.key,
    required this.title,
    required this.message,
    required this.version,
    required this.updateUrl,
    this.isForce = false,
    this.releaseNotes,
  });

  static Future<void> show(
    BuildContext context, {
    required String title,
    required String message,
    required String version,
    required String updateUrl,
    bool isForce = false,
    List<String>? releaseNotes,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: !isForce,
      barrierColor: Colors.black.withOpacity(0.65),
      builder: (ctx) => AppUpdateDialog(
        title: title,
        message: message,
        version: version,
        updateUrl: updateUrl,
        isForce: isForce,
        releaseNotes: releaseNotes,
      ),
    );
  }

  Future<void> _openUpdateUrl(BuildContext context) async {
    try {
      final uri = Uri.parse(updateUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Error launching update URL: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textPrimary = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return PopScope(
      canPop: !isForce,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          elevation: 0,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Main Card Container
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.45 : 0.15),
                      blurRadius: 28,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 1. User's Animated Surprise Gift Icon
                    Container(
                      height: 155,
                      width: double.infinity,
                      alignment: Alignment.center,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.asset(
                          'assets/images/update_surprise.gif',
                          height: 150,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.card_giftcard_rounded,
                            size: 90,
                            color: Color(0xFF0070F3),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Version Tag Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0070F3).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'NEW VERSION $version',
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0070F3),
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // 2. Creative Title
                    Text(
                      title.isNotEmpty
                          ? title
                          : 'A Brand New Update is Waiting! 🎁',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: textPrimary,
                        letterSpacing: -0.3,
                        height: 1.25,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // 3. Message / Description
                    Text(
                      message.isNotEmpty
                          ? message
                          : 'Exciting new features, 60FPS faster speed, and latest exam notes are ready for you. Update now to enjoy the best learning experience!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: textSecondary,
                        height: 1.4,
                      ),
                    ),

                    const SizedBox(height: 14),

                    // 4. Highlighted Feature Highlights Container
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFeatureRow(
                            Icons.bolt_rounded,
                            const Color(0xFFF59E0B),
                            'Superfast 60 FPS UI & instant question loading',
                            textPrimary,
                          ),
                          const SizedBox(height: 6),
                          _buildFeatureRow(
                            Icons.auto_stories_rounded,
                            const Color(0xFF0070F3),
                            'Latest chapter study notes & exam syllabus',
                            textPrimary,
                          ),
                          const SizedBox(height: 6),
                          _buildFeatureRow(
                            Icons.quiz_rounded,
                            const Color(0xFF10B981),
                            'Real-time answer keys & score analytics',
                            textPrimary,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // 5. Primary UPDATE NOW Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0070F3), Color(0xFF1D4ED8)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0070F3).withOpacity(0.35),
                              blurRadius: 14,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: () => _openUpdateUrl(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.system_update_alt_rounded, color: Colors.white, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'UPDATE NOW',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // 6. Dismiss/Later button (Only if not force update)
                    if (!isForce) ...[
                      const SizedBox(height: 6),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          foregroundColor: textSecondary,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        child: Text(
                          'Maybe Later • পরে করব',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Close 'X' Button on Top Right (Only if not force update)
              if (!isForce)
                Positioned(
                  top: 12,
                  right: 12,
                  child: InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, Color color, String text, Color textColor) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.14),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 13),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: textColor.withOpacity(0.85),
            ),
          ),
        ),
      ],
    );
  }
}
