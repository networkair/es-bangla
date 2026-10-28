import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:in_app_review/in_app_review.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/storage/local_storage_service.dart';
import 'mock_analytics_screen.dart';
import 'saved_questions_screen.dart';
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Select Academic Semester',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Semester 3 (Higher Secondary)', style: TextStyle(fontWeight: FontWeight.w600)),
              leading: Radio<int>(
                value: 3,
                groupValue: _currentSemester,
                activeColor: const Color(0xFF2563EB),
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
              title: const Text('Semester 4 (Board Preparation)', style: TextStyle(fontWeight: FontWeight.w600)),
              leading: Radio<int>(
                value: 4,
                groupValue: _currentSemester,
                activeColor: const Color(0xFF2563EB),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Sign Out of Account?',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: const Text(
          'Are you sure you want to log out? You can sign back in anytime to access your study materials and tests.',
          style: TextStyle(fontSize: 14, color: Color(0xFF64748B), height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE11D48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Sign Out', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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

    final attempts = _storage.getAttemptHistory();
    final savedQuestions = _storage.getSavedQuestions();

    double totalAcc = 0;
    for (var a in attempts) {
      totalAcc += (a['accuracy'] as num?)?.toDouble() ?? 0;
    }
    final avgAccuracy = attempts.isNotEmpty ? (totalAcc / attempts.length).toStringAsFixed(0) : '0';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'My Profile',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 19),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Column(
          children: [
            // 1. User Header 3D Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withOpacity(0.05),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: const Color(0xFF0F172A).withOpacity(0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 62,
                        height: 62,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF2563EB).withOpacity(0.28),
                              blurRadius: 14,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          displayName.isNotEmpty ? displayName[0].toUpperCase() : 'S',
                          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              email,
                              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: _changeSemester,
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: const Color(0xFFBFDBFE), width: 1),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.school_rounded, size: 13, color: Color(0xFF2563EB)),
                                    const SizedBox(width: 5),
                                    Text(
                                      'Class 12 • Sem $_currentSemester',
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1E40AF),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.edit_rounded, size: 12, color: Color(0xFF2563EB)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 3D Quick Metrics Row
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFF1F5F9)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildMetricPill(
                          label: 'Tests Taken',
                          value: '${attempts.length}',
                          color: const Color(0xFF2563EB),
                          icon: Icons.assignment_turned_in_rounded,
                        ),
                        Container(width: 1, height: 32, color: const Color(0xFFE2E8F0)),
                        _buildMetricPill(
                          label: 'Bookmarks',
                          value: '${savedQuestions.length}',
                          color: const Color(0xFFD97706),
                          icon: Icons.bookmark_rounded,
                        ),
                        Container(width: 1, height: 32, color: const Color(0xFFE2E8F0)),
                        _buildMetricPill(
                          label: 'Avg. Accuracy',
                          value: '$avgAccuracy%',
                          color: const Color(0xFF16A34A),
                          icon: Icons.trending_up_rounded,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 2. Study & Performance 3D Section
            _build3DSection(
              title: 'Study & Performance',
              items: [
                _buildActionTile(
                  icon: Icons.insights_rounded,
                  iconColor: const Color(0xFF2563EB),
                  iconBg: const Color(0xFFEFF6FF),
                  title: 'Mock Test Analytics',
                  subtitle: 'Strengths, weak topics, and mastery insights',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MockAnalyticsScreen()),
                  ).then((_) => setState(() {})),
                ),
                _buildDivider(),
                _buildActionTile(
                  icon: Icons.collections_bookmark_rounded,
                  iconColor: const Color(0xFFD97706),
                  iconBg: const Color(0xFFFFFBEB),
                  title: 'Saved Question Vault',
                  subtitle: 'Review bookmarked exam questions by subject',
                  badge: savedQuestions.isNotEmpty ? '${savedQuestions.length}' : null,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SavedQuestionsScreen()),
                  ).then((_) => setState(() {})),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 3. Plan & Access 3D Section
            _build3DSection(
              title: 'Plan & Membership',
              items: [
                _buildActionTile(
                  icon: Icons.verified_user_rounded,
                  iconColor: const Color(0xFF7C3AED),
                  iconBg: const Color(0xFFF5F3FF),
                  title: 'Subscription Status',
                  subtitle: entitlements.isEmpty
                      ? 'Free Standard Plan'
                      : '${entitlements.length} Active Pro Access Permissions',
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: entitlements.isEmpty ? const Color(0xFFF1F5F9) : const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: entitlements.isEmpty ? const Color(0xFFE2E8F0) : const Color(0xFF86EFAC),
                      ),
                    ),
                    child: Text(
                      entitlements.isEmpty ? 'Free Plan' : 'Active Pro',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: entitlements.isEmpty ? const Color(0xFF64748B) : const Color(0xFF16A34A),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 4. Preferences & Support 3D Section
            _build3DSection(
              title: 'Preferences & System',
              items: [
                SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                  secondary: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.notifications_active_outlined, color: Color(0xFF2563EB), size: 20),
                  ),
                  title: const Text(
                    'Study Alerts & Reminders',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF0F172A)),
                  ),
                  subtitle: const Text(
                    'Get periodic mock test prompts & updates',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                  value: _notificationsEnabled,
                  activeColor: const Color(0xFF2563EB),
                  onChanged: (val) {
                    setState(() => _notificationsEnabled = val);
                    _storage.notificationsEnabled = val;
                  },
                ),
                _buildDivider(),
                _buildActionTile(
                  icon: Icons.star_outline_rounded,
                  iconColor: const Color(0xFFEA580C),
                  iconBg: const Color(0xFFFFF7ED),
                  title: 'Rate App on Play Store',
                  subtitle: 'Share your feedback with fellow students',
                  onTap: () async {
                    final inAppReview = InAppReview.instance;
                    if (await inAppReview.isAvailable()) {
                      inAppReview.requestReview();
                    }
                  },
                ),
                _buildDivider(),
                _buildActionTile(
                  icon: Icons.logout_rounded,
                  iconColor: const Color(0xFFE11D48),
                  iconBg: const Color(0xFFFFF1F2),
                  title: 'Sign Out',
                  titleColor: const Color(0xFFE11D48),
                  subtitle: 'Log out of this device',
                  onTap: _logout,
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricPill({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: color),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
        ),
      ],
    );
  }

  Widget _build3DSection({required String title, required List<Widget> items}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.02),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
            child: Text(
              title.toUpperCase(),
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: Color(0xFF64748B),
                letterSpacing: 0.6,
              ),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          ...items,
        ],
      ),
    );
  }

  Widget _buildDivider() => const Divider(height: 1, indent: 64, endIndent: 16, color: Color(0xFFF1F5F9));

  Widget _buildActionTile({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    String? subtitle,
    Color? titleColor,
    String? badge,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: iconBg,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: iconColor, size: 21),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14.5,
          fontWeight: FontWeight.w700,
          color: titleColor ?? const Color(0xFF0F172A),
        ),
      ),
      subtitle: subtitle != null
          ? Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.3))
          : null,
      trailing: trailing ??
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (badge != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                  ),
                ),
                const SizedBox(width: 6),
              ],
              const Icon(Icons.arrow_forward_ios_rounded, size: 13, color: Color(0xFF94A3B8)),
            ],
          ),
      onTap: onTap,
    );
  }
}
