import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/storage/local_storage_service.dart';

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

    setState(() {
      _isRedeeming = true;
      _feedbackMessage = null;
    });

    final user = FirebaseAuth.instance.currentUser;
    final userEmail = LocalStorageService().userEmail;

    try {
      final keyDocRef = FirebaseFirestore.instance.collection('access_keys').doc(key);
      final userRef = FirebaseFirestore.instance.collection('users').doc(user?.uid ?? 'local_user');

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(keyDocRef);
        if (!snapshot.exists) {
          throw Exception('এই অ্যাক্সেস কী-টি অবৈধ বা খুঁজে পাওয়া যায়নি।');
        }

        final data = snapshot.data()!;
        final status = data['status'];
        final boundEmail = data['boundEmail'];

        if (status == 'used') {
          throw Exception('এই কী-টি ইতিমধ্যেই ব্যবহার করা হয়েছে।');
        }

        if (boundEmail != null && boundEmail.toString().isNotEmpty && boundEmail != userEmail) {
          throw Exception('এই কী-টি অন্য একটি অ্যাকাউন্টের জন্য ইস্যু করা হয়েছে।');
        }

        // Mark as used
        transaction.update(keyDocRef, {
          'status': 'used',
          'redeemedBy': userEmail,
          'redeemedAt': FieldValue.serverTimestamp(),
        });

        // Add entitlement
        final durationDays = data['durationDays'] ?? 365;
        final grants = List<String>.from(data['grants'] ?? [widget.grantType]);

        final entitlementRef = userRef.collection('entitlements').doc();
        transaction.set(entitlementRef, {
          'grants': grants,
          'startsAt': FieldValue.serverTimestamp(),
          'durationDays': durationDays,
          'status': 'active',
          'sourceKey': key,
        });

        // Cache locally
        final currentEntitlements = LocalStorageService().getEntitlements();
        for (var g in grants) {
          if (!currentEntitlements.contains(g)) currentEntitlements.add(g);
        }
        await LocalStorageService().setEntitlements(currentEntitlements);
      });

      setState(() {
        _isSuccess = true;
        _feedbackMessage = 'অভিনন্দন! আপনার অ্যাক্সেস সফলভাবে সক্রিয় হয়েছে।';
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
