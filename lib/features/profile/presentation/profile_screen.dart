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
  late bool _isDarkMode;
  late String _userAvatar;

  static const List<String> _availableAvatars = [
    'assets/avatars/avatar_1.jpg',
    'assets/avatars/avatar_2.jpg',
    'assets/avatars/avatar_3.jpg',
    'assets/avatars/avatar_4.jpg',
    'assets/avatars/avatar_5.jpg',
    'assets/avatars/avatar_6.jpg',
    'assets/avatars/avatar_7.jpg',
    'assets/avatars/avatar_8.jpg',
    'assets/avatars/avatar_9.jpg',
    'assets/avatars/avatar_10.jpg',
  ];

  @override
  void initState() {
    super.initState();
    _notificationsEnabled = _storage.notificationsEnabled;
    _currentSemester = _storage.semester;
    _isDarkMode = _storage.isDarkMode;
    _userAvatar = _storage.userAvatar;
  }

  void _showAvatarPicker() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            return Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle Bar
                  Container(
                    width: 42,
                    height: 4.5,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  // Title Row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.face_rounded, color: Color(0xFF2563EB), size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Choose Your Avatar',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Select an avatar for your profile',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_userAvatar.isNotEmpty)
                        TextButton(
                          onPressed: () {
                            setState(() => _userAvatar = '');
                            _storage.userAvatar = '';
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Default initial avatar restored'),
                                duration: Duration(seconds: 2),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          child: const Text(
                            'Reset',
                            style: TextStyle(color: Color(0xFFE11D48), fontWeight: FontWeight.w700),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Grid of 10 avatars
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _availableAvatars.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 5,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 14,
                      childAspectRatio: 1.0,
                    ),
                    itemBuilder: (context, index) {
                      final avatarPath = _availableAvatars[index];
                      final isSelected = _userAvatar == avatarPath;

                      return GestureDetector(
                        onTap: () {
                          setState(() => _userAvatar = avatarPath);
                          _storage.userAvatar = avatarPath;
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Avatar updated successfully!'),
                              duration: Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF2563EB)
                                  : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                              width: isSelected ? 3 : 1.5,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFF2563EB).withOpacity(0.4),
                                      blurRadius: 10,
                                      spreadRadius: 1,
                                    ),
                                  ]
                                : null,
                          ),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              ClipOval(
                                child: Container(
                                  color: isDark ? const Color(0xFF0F172A) : Colors.white,
                                  child: Transform.scale(
                                    scale: 1.12,
                                    child: Image.asset(
                                      avatarPath,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ),
                              if (isSelected)
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    width: 18,
                                    height: 18,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF2563EB),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.check_rounded,
                                      size: 13,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            );
          },
        );
      },
    );
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

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'My Profile',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 19,
            color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
          ),
        ),
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
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
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isDark ? Colors.black : const Color(0xFF0F172A)).withOpacity(isDark ? 0.25 : 0.05),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: (isDark ? Colors.black : const Color(0xFF0F172A)).withOpacity(isDark ? 0.15 : 0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: _showAvatarPicker,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 66,
                              height: 66,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: _userAvatar.isEmpty
                                    ? const LinearGradient(
                                        colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      )
                                    : null,
                                color: _userAvatar.isNotEmpty
                                    ? (isDark ? const Color(0xFF1E293B) : Colors.white)
                                    : null,
                                border: Border.all(
                                  color: isDark ? const Color(0xFF3B82F6) : const Color(0xFF93C5FD),
                                  width: 2.2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF2563EB).withOpacity(0.28),
                                    blurRadius: 14,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: _userAvatar.isNotEmpty
                                    ? Transform.scale(
                                        scale: 1.12,
                                        child: Image.asset(
                                          _userAvatar,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => Center(
                                            child: Text(
                                              displayName.isNotEmpty ? displayName[0].toUpperCase() : 'S',
                                              style: const TextStyle(
                                                fontSize: 26,
                                                fontWeight: FontWeight.w900,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                      )
                                    : Center(
                                        child: Text(
                                          displayName.isNotEmpty ? displayName[0].toUpperCase() : 'S',
                                          style: const TextStyle(
                                            fontSize: 26,
                                            fontWeight: FontWeight.w900,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                              ),
                            ),
                            Positioned(
                              bottom: -2,
                              right: -2,
                              child: Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2563EB),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                                    width: 2.2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.22),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.add_rounded,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              email,
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: _changeSemester,
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF1E3A8A).withOpacity(0.4) : const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isDark ? const Color(0xFF3B82F6).withOpacity(0.5) : const Color(0xFFBFDBFE),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.school_rounded, size: 13, color: Color(0xFF38BDF8)),
                                    const SizedBox(width: 5),
                                    Text(
                                      'Class 12 • Sem $_currentSemester',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1E40AF),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.edit_rounded, size: 12, color: Color(0xFF38BDF8)),
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
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                      ),
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
                        Container(width: 1, height: 32, color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                        _buildMetricPill(
                          label: 'Bookmarks',
                          value: '${savedQuestions.length}',
                          color: const Color(0xFFD97706),
                          icon: Icons.bookmark_rounded,
                        ),
                        Container(width: 1, height: 32, color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
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

            // 4. Preferences & System 3D Section
            _build3DSection(
              title: 'Preferences & System',
              items: [
                SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                  secondary: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.notifications_active_outlined, color: Color(0xFF2563EB), size: 20),
                  ),
                  title: Text(
                    'Study Alerts & Reminders',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                    ),
                  ),
                  subtitle: Text(
                    'Get periodic mock test prompts & updates',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                  value: _notificationsEnabled,
                  activeColor: const Color(0xFF2563EB),
                  onChanged: (val) {
                    setState(() => _notificationsEnabled = val);
                    _storage.notificationsEnabled = val;
                  },
                ),
                _buildDivider(),
                SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                  secondary: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.dark_mode_outlined,
                      color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF334155),
                      size: 20,
                    ),
                  ),
                  title: Text(
                    'Dark Theme (ডার্ক মোড)',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                    ),
                  ),
                  subtitle: Text(
                    'Enable dark appearance across the app',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                  value: _isDarkMode,
                  activeColor: const Color(0xFF2563EB),
                  onChanged: (val) {
                    setState(() => _isDarkMode = val);
                    _storage.isDarkMode = val;
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _build3DSection({required String title, required List<Widget> items}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : const Color(0xFF0F172A)).withOpacity(isDark ? 0.25 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: (isDark ? Colors.black : const Color(0xFF0F172A)).withOpacity(isDark ? 0.15 : 0.02),
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
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                letterSpacing: 0.6,
              ),
            ),
          ),
          Divider(height: 1, color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
          ...items,
        ],
      ),
    );
  }

  Widget _buildDivider() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Divider(
      height: 1,
      indent: 64,
      endIndent: 16,
      color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
    );
  }

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF334155) : iconBg,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: iconColor, size: 21),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14.5,
          fontWeight: FontWeight.w700,
          color: titleColor ?? (isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A)),
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                height: 1.3,
              ),
            )
          : null,
      trailing: trailing ??
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (badge != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E3A8A) : const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark ? const Color(0xFF3B82F6) : const Color(0xFFBFDBFE),
                    ),
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF2563EB),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 13,
                color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
              ),
            ],
          ),
      onTap: onTap,
    );
  }
}
