import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  final TextEditingController _codeController = TextEditingController();
  bool _isRedeeming = false;
  String? _errorMessage;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<String?> _redeemCode(String inputCode) async {
    try {
      final result = await EntitlementService.redeemOrRestoreKey(
        inputCode: inputCode,
        semester: widget.semester,
        expectedCategory: 'video_library',
        fallbackGrants: [
          'video_library_sem${widget.semester}',
        ],
      );

      if (result.success) {
        return null;
      }
      return result.message;
    } catch (e) {
      return e.toString().replaceAll('Exception:', '').trim();
    }
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
          'আপনার সেমিস্টার ${widget.semester}-এর কোর্স সফলভাবে সক্রিয় হয়েছে। এখন আপনি সমস্ত ভিডিও লেকচার সরাসরি দেখতে পারবেন।',
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

  void _showRedeemBottomSheet() {
    setState(() => _errorMessage = null);
    _codeController.clear();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'ইনভাইট কোড দিয়ে আনলক করুন',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'হোয়াটসঅ্যাপে পেমেন্ট করার পর আপনাকে যে বিশেষ ইনভাইট কোডটি দেওয়া হয়েছে, সেটি এখানে লিখুন:',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                  ),
                  const SizedBox(height: 18),

                  TextField(
                    controller: _codeController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      hintText: 'যেমন: SEM3-VIP-9988',
                      labelText: 'ইনভাইট / অ্যাক্টিভেশন কোড',
                      prefixIcon: const Icon(Icons.vpn_key_rounded, color: AppColors.primary),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                      ),
                    ),
                  ),

                  if (_errorMessage != null) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.error_outline_rounded, color: AppColors.wrongRed, size: 16),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: AppColors.wrongRed, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isRedeeming
                          ? null
                          : () async {
                              final code = _codeController.text.trim().toUpperCase();
                              if (code.isEmpty) {
                                setModalState(() => _errorMessage = 'দয়া করে ইনভাইট কোডটি লিখুন');
                                return;
                              }

                              if (FirebaseAuth.instance.currentUser == null) {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                                );
                                if (FirebaseAuth.instance.currentUser == null) {
                                  if (modalCtx.mounted) {
                                    setModalState(() {
                                      _errorMessage = 'অ্যাক্টিভেশন কোড রিডিম করতে প্রথমে লগইন করুন';
                                    });
                                  }
                                  return;
                                }
                              }

                              setModalState(() {
                                _isRedeeming = true;
                                _errorMessage = null;
                              });

                              final error = await _redeemCode(code);
                              if (error != null) {
                                if (modalCtx.mounted) {
                                  setModalState(() {
                                    _isRedeeming = false;
                                    _errorMessage = error;
                                  });
                                }
                              } else {
                                if (modalCtx.mounted) {
                                  Navigator.pop(modalCtx); // Close sheet first
                                }
                                if (mounted) {
                                  setState(() => _isRedeeming = false);
                                  _showCelebrationDialog();
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: _isRedeeming
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)),
                            )
                          : const Text(
                              'কোড সক্রিয় করুন (Activate Now)',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _openWhatsAppContact() {
    final String message = Uri.encodeComponent(
      'হ্যালো Es Bangla! আমি দ্বাদশ শ্রেণির সেমিস্টার ${widget.semester}-এর ${widget.subjectName.isNotEmpty ? widget.subjectName : "ভিডিও কোর্স"} নিতে আগ্রহী। দয়া করে পেমেন্ট কিউআর কোড (QR Code) ও ইনভাইট কোড পাওয়ার নিয়ম জানান।',
    );
    final String url = '${ApiConstants.whatsappUrl}?text=$message';

    Clipboard.setData(ClipboardData(text: ApiConstants.defaultWhatsappNumber));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('হোয়াটসঅ্যাপ নম্বর (${ApiConstants.defaultWhatsappNumber}) কপি করা হয়েছে! যোগাযোগ করুন: $url'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'কপি লিংক',
          textColor: Colors.white,
          onPressed: () {
            Clipboard.setData(ClipboardData(text: url));
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top Navigation Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: const Border(bottom: BorderSide(color: AppColors.border, width: 1)),
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
                          'কোর্স অ্যাক্সেস ও জয়েন',
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

                    const SizedBox(height: 22),

                    // Free Demo Videos Section (User Requirement: ডেমো ভিডিও সাজানো থাকবে)
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
                          _buildStepItem('1', 'হোয়াটসঅ্যাপে মেসেজ পাঠান', 'নিচের বাটনে ট্যাপ করে আমাদের হোয়াটসঅ্যাপে যোগাযোগ করুন।'),
                          const SizedBox(height: 10),
                          _buildStepItem('2', 'পেমেন্ট সম্পন্ন করুন', 'আমরা হোয়াটসঅ্যাপে আপনাকে অফিশিয়াল কিউআর কোড (QR Code) পাঠাবো।'),
                          const SizedBox(height: 10),
                          _buildStepItem('3', 'ইনভাইট কোড নিয়ে জয়েন করুন', 'পেমেন্টের পর আপনাকে একটি ইউনিক ইনভাইট কোড দেওয়া হবে যা দিয়ে সাথে সাথে কোর্স আনলক হবে।'),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // WhatsApp Contact Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _openWhatsAppContact,
                        icon: const Icon(Icons.chat_bubble_rounded, size: 20),
                        label: const Text(
                          'হোয়াটসঅ্যাপে যোগাযোগ ও পেমেন্ট কিউআর কোড',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF25D366), // WhatsApp Green
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Join with Invite Code Button (Primary Action)
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _showRedeemBottomSheet,
                        icon: const Icon(Icons.vpn_key_rounded, size: 20),
                        label: const Text(
                          'ইনভাইট কোড দিয়ে আনলক করুন (Join with Code)',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
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
