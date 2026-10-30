import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/storage/local_storage_service.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/services/entitlement_service.dart';
import '../../auth/presentation/login_screen.dart';
import '../data/youtube_helper.dart';
import 'video_player_screen.dart';
import 'native_video_helper.dart';

class CourseSubscriptionScreen extends StatefulWidget {
  final int semester;
  final String subjectName;
  final String subjectId;

  const CourseSubscriptionScreen({
    super.key,
    required this.semester,
    required this.subjectName,
    required this.subjectId,
  });

  @override
  State<CourseSubscriptionScreen> createState() => _CourseSubscriptionScreenState();
}

class _CourseSubscriptionScreenState extends State<CourseSubscriptionScreen> {
  bool _isChecking = false;
  StreamSubscription<List<String>>? _entitlementSub;

  @override
  void initState() {
    super.initState();
    // Auto-listen to live Firestore updates: auto-celebrate if admin grants VIP
    _entitlementSub = EntitlementService.liveUserEntitlementsStream().listen((grants) {
      if (EntitlementService.hasVideoAccess(
        widget.semester,
        subjectId: widget.subjectId,
        subjectName: widget.subjectName,
      )) {
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
        content: Text(
          'আপনার সেমিস্টার ${widget.semester}-এর কোর্স সফলভাবে সক্রিয় হয়েছে! এখন আপনি সমস্ত ভিডিও লেকচার সরাসরি দেখতে পারবেন।',
          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.4),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx); // Close dialog
              Navigator.pop(context, true); // Close subscription screen and trigger refresh in topics
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('ভিডিও দেখুন'),
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
      await EntitlementService.syncUserEntitlements();
      final hasAccess = EntitlementService.hasVideoAccess(
        widget.semester,
        subjectId: widget.subjectId,
        subjectName: widget.subjectName,
      );

      if (!mounted) return;
      setState(() => _isChecking = false);

      if (hasAccess) {
        _showCelebrationDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('আপনার অ্যাকাউন্টে এখনো ভিডিও কোর্স সক্রিয় হয়নি। হোয়াটসঅ্যাপে মেসেজ পাঠিয়ে থাকলে অনুগ্রহ করে কিছুক্ষণ অপেক্ষা করুন।'),
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

  Future<void> _openWhatsAppContact() async {
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
    final course = widget.subjectName.isNotEmpty ? widget.subjectName : 'সেমিস্টার ${widget.semester} ভিডিও কোর্স';

    final String message = '''
হ্যালো Es Bangla টিম!
আমি দ্বাদশ শ্রেণির সেমিস্টার ${widget.semester} এর ভিডিও লাইব্রেরি VIP কোর্স নিতে চাই।

📌 কোর্স: $course
👤 শিক্ষার্থী: $name
📧 ইমেইল: $email
🔑 ইউজার আইডি (UID): $uid

অনুগ্রহ করে আমাকে কোর্স ফি ও পেমেন্ট কিউআর কোড (QR Code) পাঠান। ধন্যবাদ!
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
      body: SafeArea(
        child: Column(
          children: [
            // Top Navigation Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
              ),
              child: Row(
                children: [
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
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'কোর্স অ্যাক্সেস ও সাবস্ক্রিপশন',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'সম্পূর্ণ ভিডিও কোর্স আনলক করুন',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Hero Banner
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: AppColors.primary.withOpacity(0.2), width: 1.2),
                        boxShadow: AppColors.softCardShadow,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.premiumGold,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.workspace_premium_rounded, size: 14, color: Colors.white),
                                    SizedBox(width: 4),
                                    Text(
                                      'PREMIUM COURSE',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Spacer(),
                              Text(
                                'Semester ${widget.semester}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Text(
                            widget.subjectName.isNotEmpty
                                ? '${widget.subjectName} সম্পূর্ণ ভিডিও কোর্স'
                                : 'সেমিস্টার ${widget.semester} সম্পূর্ণ ভিডিও লেকচার',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'অধ্যায়ভিত্তিক প্রতিটি টপিকের স্পষ্ট ও গোছানো ভিডিও ক্লাস, পরীক্ষার স্পেশাল সাজেশনস ও প্রশ্নোত্তর গাইড।',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                              height: 1.45,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Highlights checklist
                          _buildBenefitItem(Icons.play_circle_fill_rounded, 'প্রতিটি বিষয়ের অধ্যায়ভিত্তিক বিস্তারিত ভিডিও ক্লাস'),
                          const SizedBox(height: 8),
                          _buildBenefitItem(Icons.verified_rounded, 'উচ্চ মাধ্যমিকের নতুন প্রশ্ন প্যাটার্ন অনুযায়ী প্রস্তুতি'),
                          const SizedBox(height: 8),
                          _buildBenefitItem(Icons.all_inclusive_rounded, 'সম্পূর্ণ পরীক্ষা পর্যন্ত যতবার খুশি দেখার সুযোগ'),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Student Account Info Card (For Admin Direct Grant Linking)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.badge_outlined, size: 18, color: AppColors.primary),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'আপনার শিক্ষার্থী অ্যাকাউন্ট তথ্য',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13.5,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const Spacer(),
                              InkWell(
                                onTap: () {
                                  Clipboard.setData(ClipboardData(text: uid));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('ইউজার আইডি (UID) কপি করা হয়েছে!'),
                                      behavior: SnackBarBehavior.floating,
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: const Color(0xFFCBD5E1)),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.copy_rounded, size: 12, color: AppColors.primary),
                                      SizedBox(width: 4),
                                      Text(
                                        'UID কপি',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildAccountInfoRow('নাম:', name),
                          const SizedBox(height: 4),
                          _buildAccountInfoRow('ইমেইল:', email),
                          const SizedBox(height: 4),
                          _buildAccountInfoRow('ইউজার আইডি:', uid),
                        ],
                      ),
                    ),

                    const SizedBox(height: 22),

                    // Free Demo Videos Section
                    const Text(
                      'ফ্রি ডেমো ভিডিও লেকচার (Demo Classes)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'কোর্সে জয়েন করার পূর্বে আমাদের ফ্রি ডেমো ক্লাসগুলো দেখে মান যাচাই করে নিন:',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 12),

                    // Demo Video Cards
                    Row(
                      children: [
                        Expanded(
                          child: _buildDemoCard(
                            title: 'ডেমো ক্লাস ১',
                            subtitle: 'পাঠ পরিচিতি ও কনসেপ্ট',
                            youtubeId: 'dQw4w9WgXcQ',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildDemoCard(
                            title: 'ডেমো ক্লাস ২',
                            subtitle: 'গুরুত্বপূর্ণ প্রশ্নের বিশ্লেষণ',
                            youtubeId: 'dQw4w9WgXcQ',
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Step-by-Step Enrollment Guide Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'কীভাবে ভিডিও কোর্সটি আনলক করবেন?',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          _buildStepItem('১', 'হোয়াটসঅ্যাপে যোগাযোগ করুন', 'নিচের বাটনে ট্যাপ করে সরাসরি আমাদের অফিশিয়াল হোয়াটসঅ্যাপে মেসেজ পাঠান।'),
                          const SizedBox(height: 10),
                          _buildStepItem('২', 'পেমেন্ট সম্পন্ন করুন', 'আমরা হোয়াটসঅ্যাপে আপনাকে অফিশিয়াল কিউআর কোড (QR Code) পাঠাবো।'),
                          const SizedBox(height: 10),
                          _buildStepItem('৩', 'সরাসরি সাবস্ক্রিপশন সক্রিয়করণ', 'পেমেন্ট সম্পন্ন হলে আমাদের টিম সরাসরি আপনার অ্যাকাউন্টে সাবস্ক্রিপশন চালু করে দেবে। কোনো কোডের প্রয়োজন নেই।'),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Primary WhatsApp Contact Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _openWhatsAppContact,
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

                    // Secondary Refresh / Check Status Button
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
            ),
          ],
        ),
      ),
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

  Widget _buildBenefitItem(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.3),
          ),
        ),
      ],
    );
  }

  Widget _buildDemoCard({
    required String title,
    required String subtitle,
    required String youtubeId,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            final videoId = YoutubeHelper.extractVideoId(youtubeId);
            NativeVideoHelper.playVideo(
              title: '$title ($subtitle)',
              videoId: videoId,
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      height: 70,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Icon(Icons.ondemand_video_rounded, color: AppColors.primary, size: 28),
                      ),
                    ),
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 4),
                        ],
                      ),
                      child: const Icon(Icons.play_arrow_rounded, color: AppColors.primary, size: 22),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepItem(String number, String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.primary.withOpacity(0.3)),
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryDark,
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
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.3),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
