import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/storage/local_storage_service.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/services/entitlement_service.dart';
import '../../auth/presentation/login_screen.dart';

class PremiumLockScreen extends StatefulWidget {
  final String title;
  final String grantType; // e.g. 'premium_mock_sem3', 'subject_bengali'

  const PremiumLockScreen({
    super.key,
    required this.title,
    required this.grantType,
  });

  @override
  State<PremiumLockScreen> createState() => _PremiumLockScreenState();
}

class _PremiumLockScreenState extends State<PremiumLockScreen> {
  bool _isChecking = false;
  StreamSubscription<List<String>>? _entitlementSub;

  @override
  void initState() {
    super.initState();
    // Auto-listen to live Firestore updates
    _entitlementSub = EntitlementService.liveUserEntitlementsStream().listen((grants) {
      final sem = LocalStorageService().semester;
      if (EntitlementService.hasMockAccess(sem)) {
        if (mounted) {
          _showCelebrationDialog();
        }
      }
    });
  }

  @override
  void dispose() {
    _entitlementSub?.cancel();
    super.dispose();
  }

  void _showCelebrationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Row(
          children: const [
            Icon(Icons.check_circle_rounded, color: AppColors.correctGreen, size: 28),
            SizedBox(width: 10),
            Text('অভিনন্দন!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: const Text(
          'আপনার অ্যাকাউন্টে প্রিমিয়াম মক টেস্ট সাবস্ক্রিপশন সফলভাবে সক্রিয় হয়েছে! এখন আপনি সমস্ত প্রিমিয়াম টেস্ট সেট আনলক অবস্থায় উপভোগ করতে পারবেন।',
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.4),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx); // Close dialog
              Navigator.pop(context, true); // Pop lock screen with success
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('টেস্ট শুরু করুন'),
          ),
        ],
      ),
    );
  }

  Future<void> _checkSubscriptionStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      if (FirebaseAuth.instance.currentUser == null) return;
    }

    setState(() => _isChecking = true);

    try {
      final synced = await EntitlementService.syncUserEntitlements();
      final sem = LocalStorageService().semester;
      final hasAccess = EntitlementService.hasMockAccess(sem);

      if (!mounted) return;
      setState(() => _isChecking = false);

      if (hasAccess) {
        _showCelebrationDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('আপনার অ্যাকাউন্টে এখনো সাবস্ক্রিপশন সক্রিয় হয়নি। হোয়াটসঅ্যাপে মেসেজ পাঠিয়ে থাকলে অনুগ্রহ করে কিছুক্ষণ অপেক্ষা করুন।'),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isChecking = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('যাচাই করতে সমস্যা হয়েছে: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _openWhatsApp() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      if (FirebaseAuth.instance.currentUser == null) return;
    }

    final currentUser = FirebaseAuth.instance.currentUser;
    final name = currentUser?.displayName?.isNotEmpty == true
        ? currentUser!.displayName!
        : LocalStorageService().userName;
    final email = currentUser?.email ?? LocalStorageService().userEmail;
    final uid = currentUser?.uid ?? 'অজ্ঞাত';
    final sem = LocalStorageService().semester;

    final String message = '''
হ্যালো Es Bangla টিম!
আমি সেমিস্টার $sem এর প্রিমিয়াম মক টেস্ট VIP সাবস্ক্রিপশন নিতে চাই।

📌 কোর্স: ${widget.title}
👤 শিক্ষার্থী: $name
📧 ইমেইল: $email
🔑 ইউজার আইডি (UID): $uid

অনুগ্রহ করে আমাকে সাবস্ক্রিপশন ফি ও পেমেন্ট কিউআর কোড (QR Code) পাঠান। ধন্যবাদ!
'''.trim();

    Clipboard.setData(ClipboardData(text: 'UID: $uid\nEmail: $email'));

    final phone = ApiConstants.defaultWhatsappNumber.replaceAll('+', '').replaceAll(' ', '');
    final uri = Uri.parse('https://wa.me/$phone?text=${Uri.encodeComponent(message)}');

    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('হোয়াটসঅ্যাপ ওপেন করা সম্ভব হয়নি। নম্বর: ${ApiConstants.defaultWhatsappNumber} (আপনার UID ও তথ্য কপি করা হয়েছে)'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final name = user?.displayName?.isNotEmpty == true
        ? user!.displayName!
        : LocalStorageService().userName;
    final email = user?.email?.isNotEmpty == true
        ? user!.email!
        : (LocalStorageService().userEmail.isNotEmpty ? LocalStorageService().userEmail : 'লগইন করা নেই');
    final uid = user?.uid ?? 'লগইন করার পর তৈরি হবে';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        title: const Text(
          'প্রিমিয়াম ভিআইপি মক টেস্ট',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 32),
        child: Column(
          children: [
            // 1. Premium Header Banner Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFFDE68A), width: 1.4),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF59E0B).withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFFCD34D), width: 1.2),
                    ),
                    child: const Icon(
                      Icons.workspace_premium_rounded,
                      size: 38,
                      color: Color(0xFFB45309),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF78350F),
                      letterSpacing: -0.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'এই টেস্ট সেটটি প্রিমিয়াম ভিআইপি শিক্ষার্থীদের জন্য সংরক্ষিত। উচ্চমানের সাজেস্টিভ প্রশ্ন ও বিস্তারিত ব্যাখ্যা আনলক করতে ভিআইপি সাবস্ক্রিপশন গ্রহণ করুন।',
                    style: TextStyle(
                      fontSize: 13.5,
                      color: Color(0xFF78716C),
                      height: 1.45,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  const Divider(color: Color(0xFFF1F5F9)),
                  const SizedBox(height: 16),

                  // Feature Checklist
                  _buildFeatureRow(Icons.check_circle_rounded, 'সকল অধ্যায়ের প্রিমিয়াম ও আনলিমিটেড মক টেস্ট'),
                  const SizedBox(height: 10),
                  _buildFeatureRow(Icons.check_circle_rounded, 'অভিজ্ঞ শিক্ষকদের বিশেষ সাজেস্টিভ প্রশ্ন সেট'),
                  const SizedBox(height: 10),
                  _buildFeatureRow(Icons.check_circle_rounded, 'প্রতিটি প্রশ্নের বিস্তারিত ব্যাখ্যা ও টাইমার বিশ্লেষণ'),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // 2. Student Account Information Box
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withOpacity(0.03),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.badge_outlined, size: 20, color: AppColors.primary),
                      SizedBox(width: 8),
                      Text(
                        'আপনার শিক্ষার্থী অ্যাকাউন্ট তথ্য:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildAccountInfoRow('নাম:', name),
                  const SizedBox(height: 6),
                  _buildAccountInfoRow('ইমেইল:', email),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Text(
                        'ইউজার আইডি (UID): ',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      Expanded(
                        child: Text(
                          uid,
                          style: const TextStyle(
                            fontSize: 11,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy_rounded, size: 16, color: AppColors.primary),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: 'UID কপি করুন',
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: uid));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('ইউজার আইডি (UID) কপি করা হয়েছে!'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Icon(Icons.info_outline_rounded, size: 15, color: Color(0xFF64748B)),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'হোয়াটসঅ্যাপে যোগাযোগ করার সময় এই ইউজার আইডি স্বয়ংক্রিয়ভাবে মেসেজে যুক্ত হয়ে যাবে।',
                            style: TextStyle(fontSize: 11, color: Color(0xFF64748B), height: 1.3),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // 3. How to Activate Guide Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'কীভাবে ভিআইপি সাবস্ক্রিপশন সক্রিয় করবেন?',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14.5,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _buildStep('১', 'হোয়াটসঅ্যাপে যোগাযোগ করুন', 'নিচের বাটনে ট্যাপ করে সরাসরি আমাদের অফিশিয়াল হোয়াটসঅ্যাপে মেসেজ পাঠান।'),
                  const SizedBox(height: 10),
                  _buildStep('২', 'পেমেন্ট সম্পন্ন করুন', 'আমরা হোয়াটসঅ্যাপে আপনাকে অফিশিয়াল কিউআর কোড (QR Code) পাঠাবো।'),
                  const SizedBox(height: 10),
                  _buildStep('৩', 'সরাসরি সাবস্ক্রিপশন চালু', 'পেমেন্ট সম্পন্ন হলে আমাদের টিম সরাসরি আপনার অ্যাকাউন্টে সাবস্ক্রিপশন সক্রিয় করে দেবে। কোনো কোডের প্রয়োজন নেই।'),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 4. Primary WhatsApp Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _openWhatsApp,
                icon: const Icon(Icons.chat_bubble_rounded, size: 20),
                label: const Text(
                  'হোয়াটসঅ্যাপে যোগাযোগ করুন',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366), // WhatsApp Green
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // 5. Secondary Check / Refresh Status Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: _isChecking ? null : _checkSubscriptionStatus,
                icon: _isChecking
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                      )
                    : const Icon(Icons.refresh_rounded, size: 20, color: AppColors.primary),
                label: Text(
                  _isChecking ? 'সার্ভার যাচাই হচ্ছে...' : 'সাবস্ক্রিপশন স্ট্যাটাস রিফ্রেশ করুন',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.primary, width: 1.2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: const Color(0xFFD97706)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAccountInfoRow(String label, String value) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildStep(String number, String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: const Color(0xFFFEF3C7),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFFCD34D)),
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFF92400E),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary, height: 1.3),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
