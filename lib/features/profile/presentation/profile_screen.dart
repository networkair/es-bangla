import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:in_app_review/in_app_review.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/storage/local_storage_service.dart';
import 'mock_analytics_screen.dart';
import 'saved_questions_screen.dart';
import '../../reminder/presentation/reminder_history_screen.dart';
import '../../auth/presentation/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback onSemesterChanged;

  const ProfileScreen({super.key, required this.onSemesterChanged});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final LocalStorageService _storage = LocalStorageService();
  late bool _notificationsEnabled;
  late int _currentSemester;

  @override
  void initState() {
    super.initState();
    _notificationsEnabled = _storage.notificationsEnabled;
    _currentSemester = _storage.semester;
  }

  void _changeSemester() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('সেমিস্টার পরিবর্তন করুন'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Semester 3 (সেমিস্টার ৩)'),
              leading: Radio<int>(
                value: 3,
                groupValue: _currentSemester,
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _currentSemester = val);
                    _storage.semester = val;
                    widget.onSemesterChanged();
                    Navigator.pop(ctx);
                  }
                },
              ),
            ),
            ListTile(
              title: const Text('Semester 4 (সেমিস্টার ৪)'),
              leading: Radio<int>(
                value: 4,
                groupValue: _currentSemester,
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _currentSemester = val);
                    _storage.semester = val;
                    widget.onSemesterChanged();
                    Navigator.pop(ctx);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('লগ আউট করবেন?'),
        content: const Text('আপনি কি নিশ্চিত যে আপনার অ্যাকাউন্ট থেকে লগ আউট করতে চান?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('না')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.wrongRed),
            child: const Text('লগ আউট', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = _storage.userName.isNotEmpty ? _storage.userName : (user?.displayName ?? 'Student');
    final email = _storage.userEmail.isNotEmpty ? _storage.userEmail : (user?.email ?? 'student@esbangla.app');
    final entitlements = _storage.getEntitlements();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('আমার প্রোফাইল'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // User Header Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.Border.all(color: AppColors.border),
                boxShadow: AppColors.softCardShadow,
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: AppColors.primaryLight,
                    child: Text(
                      displayName.isNotEmpty ? displayName[0].toUpperCase() : 'S',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          email,
                          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Class 12 • Semester $_currentSemester',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
                    tooltip: 'সেমিস্টার পরিবর্তন',
                    onPressed: _changeSemester,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Study & Content Section
            _buildSectionCard(
              title: 'পড়াশোনা ও অগ্রগতি',
              items: [
                _buildTile(
                  icon: Icons.analytics_outlined,
                  title: 'মক টেস্ট পারফরম্যান্স অ্যানালিটিক্স',
                  subtitle: 'নির্ভুলতা, স্কোর ও উন্নতির ট্রেন্ড',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MockAnalyticsScreen())),
                ),
                _buildTile(
                  icon: Icons.bookmark_border_rounded,
                  title: 'সংরক্ষিত প্রশ্নাবলি (Saved Questions)',
                  subtitle: 'আপনার বুকমার্ক করা প্রশ্ন তালিকা',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SavedQuestionsScreen())),
                ),
                _buildTile(
                  icon: Icons.history_rounded,
                  title: 'রিমাইন্ডার ইতিহাস',
                  subtitle: 'সম্পন্ন ও মিসড স্টাডি টাস্ক',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReminderHistoryScreen())),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Subscription / Access Keys Section
            _buildSectionCard(
              title: 'সাবস্ক্রিপশন ও কী (My Access)',
              items: [
                _buildTile(
                  icon: Icons.vpn_key_outlined,
                  title: 'আমার অ্যাক্সেস (My Access)',
                  subtitle: entitlements.isEmpty
                      ? 'কোনো সক্রিয় প্রিমিয়াম কী নেই'
                      : '${entitlements.length} টি সক্রিয় পারমিশন রয়েছে',
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: entitlements.isEmpty ? AppColors.surfaceMuted : AppColors.correctLight,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      entitlements.isEmpty ? 'ফ্রি প্ল্যান' : 'সক্রিয়',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: entitlements.isEmpty ? AppColors.textSecondary : AppColors.correctGreen,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Settings & Support
            _buildSectionCard(
              title: 'সেটিংস ও সহায়তা',
              items: [
                SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  title: const Text('নোটিফিকেশন ও অ্যালার্ট', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: const Text('স্টাডি রিমাইন্ডার ও মালিকের ঘোষণা', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  value: _notificationsEnabled,
                  activeColor: AppColors.primary,
                  onChanged: (val) {
                    setState(() => _notificationsEnabled = val);
                    _storage.notificationsEnabled = val;
                  },
                ),
                _buildTile(
                  icon: Icons.star_border_rounded,
                  title: 'অ্যাপে রেটিং দিন (Rate App)',
                  onTap: () async {
                    final inAppReview = InAppReview.instance;
                    if (await inAppReview.isAvailable()) {
                      inAppReview.requestReview();
                    }
                  },
                ),
                _buildTile(
                  icon: Icons.privacy_tip_outlined,
                  title: 'গোপনীয়তা নীতি (Privacy Policy)',
                ),
                _buildTile(
                  icon: Icons.logout_rounded,
                  title: 'লগ আউট (Logout)',
                  titleColor: AppColors.wrongRed,
                  onTap: _logout,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({required String title, required List<Widget> items}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.Border.all(color: AppColors.border),
        boxShadow: AppColors.softCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Text(
              title,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textMuted),
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          ...items,
        ],
      ),
    );
  }

  Widget _buildTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Color? titleColor,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: titleColor ?? AppColors.primary, size: 22),
      title: Text(
        title,
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: titleColor ?? AppColors.textPrimary),
      ),
      subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)) : null,
      trailing: trailing ?? const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMuted),
      onTap: onTap,
    );
  }
}
