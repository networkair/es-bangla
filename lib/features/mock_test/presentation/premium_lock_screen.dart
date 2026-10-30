import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/storage/local_storage_service.dart';
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
  final TextEditingController _keyController = TextEditingController();
  bool _isRedeeming = false;
  String? _feedbackMessage;
  bool _isSuccess = false;

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  Future<void> _redeemKey() async {
    final key = _keyController.text.trim();
    if (key.isEmpty) return;

    if (FirebaseAuth.instance.currentUser == null) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      if (FirebaseAuth.instance.currentUser == null) {
        setState(() {
          _feedbackMessage = 'কী রিডিম করতে অনুগ্রহ করে লগইন করুন।';
          _isSuccess = false;
        });
        return;
      }
    }

    setState(() {
      _isRedeeming = true;
      _feedbackMessage = null;
    });

    try {
      final result = await EntitlementService.redeemOrRestoreKey(
        inputCode: key,
        semester: LocalStorageService().semester,
        fallbackGrants: [widget.grantType],
      );

      setState(() {
        _isSuccess = true;
        _feedbackMessage = result.message;
        _isRedeeming = false;
      });
    } catch (e) {
      setState(() {
        _isSuccess = false;
        _feedbackMessage = e.toString().replaceAll('Exception:', '').trim();
        _isRedeeming = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('প্রিমিয়াম অ্যাক্সেস'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.premiumGold.withOpacity(0.3)),
                boxShadow: AppColors.softCardShadow,
              ),
              child: Column(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppColors.premiumLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.workspace_premium_rounded, size: 36, color: AppColors.premiumGold),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.title,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'এই কনটেন্টটি প্রিমিয়াম শিক্ষার্থীদের জন্য সংরক্ষিত। আনলক করতে আপনার অ্যাক্সেস কী প্রবেশ করান।',
                    style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.4),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  const Divider(color: AppColors.border),
                  const SizedBox(height: 16),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('অ্যাক্সেস কী আছে? এখানে লিখুন:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _keyController,
                    decoration: const InputDecoration(
                      hintText: 'উদা: ES-PREM-2026-XXXX',
                      prefixIcon: Icon(Icons.vpn_key_rounded, color: AppColors.primary),
                    ),
                  ),
                  if (_feedbackMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _feedbackMessage!,
                      style: TextStyle(
                        color: _isSuccess ? AppColors.correctGreen : AppColors.wrongRed,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isRedeeming ? null : _redeemKey,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isRedeeming
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('আনলক করুন (Redeem)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'কীভাবে অ্যাক্সেস কী পাবেন?',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'WhatsApp-এ অ্যাডমিনের সাথে যোগাযোগ করে QR কোডে পেমেন্ট সম্পন্ন করলে তৎক্ষণাৎ আপনার অ্যাকাউন্টের জন্য অ্যাক্সেস কী সরবরাহ করা হবে।',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () {
                      // Opens WhatsApp contact
                    },
                    icon: const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.primary),
                    label: const Text('WhatsApp-এ কী সংগ্রহ করুন'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
