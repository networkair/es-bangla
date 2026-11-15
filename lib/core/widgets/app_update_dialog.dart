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
      barrierColor: Colors.black.withOpacity(0.60),
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
    final textPrimary = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF1E293B);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    // Formatted clean title
    final displayTitle = title.isNotEmpty
        ? title
        : 'Exciting Update\nReady For You 🚀 !';

    return PopScope(
      canPop: !isForce,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          elevation: 0,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Main Card Container
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(26, 26, 26, 26),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.40 : 0.12),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 1. User's Surprise Gift Box Image
                    Container(
                      height: 175,
                      width: double.infinity,
                      alignment: Alignment.center,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.asset(
                          'assets/images/update_box.png',
                          height: 170,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.card_giftcard_rounded,
                            size: 90,
                            color: Color(0xFF4F7BF7),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // 2. Simple, Standard & Comfortable Headline
                    Text(
                      displayTitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: textPrimary,
                        height: 1.32,
                        letterSpacing: -0.2,
                      ),
                    ),

                    // Optional clean short subtitle (if passed from remote config and different from title)
                    if (message.isNotEmpty && message.trim() != displayTitle.trim()) ...[
                      const SizedBox(height: 8),
                      Text(
                        message,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ],

                    const SizedBox(height: 22),

                    // 3. Comfortable, Premium UPDATE NOW Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF5A81FA), Color(0xFF4168E8)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF4F7BF7).withOpacity(0.32),
                              blurRadius: 14,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: () => _openUpdateUrl(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          child: const Text(
                            'UPDATE NOW',
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Close 'X' Button on Top Right (Only if not force update)
              if (!isForce)
                Positioned(
                  top: 14,
                  right: 14,
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
                        color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF64748B),
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
}
