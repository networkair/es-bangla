import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../storage/local_storage_service.dart';

class AcademicSelectionModal extends StatefulWidget {
  final bool isDismissible;
  final ValueChanged<int>? onSaved;

  const AcademicSelectionModal({
    super.key,
    this.isDismissible = true,
    this.onSaved,
  });

  static Future<int?> show(
    BuildContext context, {
    bool isDismissible = true,
    ValueChanged<int>? onSaved,
  }) {
    return showModalBottomSheet<int>(
      context: context,
      isDismissible: isDismissible,
      enableDrag: isDismissible,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AcademicSelectionModal(
        isDismissible: isDismissible,
        onSaved: onSaved,
      ),
    );
  }

  @override
  State<AcademicSelectionModal> createState() => _AcademicSelectionModalState();
}

class _AcademicSelectionModalState extends State<AcademicSelectionModal> {
  late int _selectedSemester;
  final String _selectedClass = '12';

  @override
  void initState() {
    super.initState();
    _selectedSemester = LocalStorageService().semester;
    if (_selectedSemester != 3 && _selectedSemester != 4) {
      _selectedSemester = 3;
    }
  }

  void _saveAndProceed() {
    final storage = LocalStorageService();
    storage.userClass = _selectedClass;
    storage.semester = _selectedSemester;
    storage.hasSelectedAcademicInfo = true;

    // Sync to Firestore if user is authenticated
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'class': _selectedClass,
          'semester': _selectedSemester,
        }).catchError((_) {});
      }
    } catch (_) {}

    widget.onSaved?.call(_selectedSemester);
    Navigator.of(context).pop(_selectedSemester);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final primaryTextColor = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F1E36);
    final secondaryTextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return WillPopScope(
      onWillPop: () async => widget.isDismissible,
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.4 : 0.15),
              blurRadius: 24,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 14,
          bottom: MediaQuery.of(context).viewInsets.bottom + 28,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Drag Handle
            Center(
              child: Container(
                width: 44,
                height: 4.5,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF475569) : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header Row: Icon + Title + Close (if dismissible)
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0C4A6E) : const Color(0xFFEFF6FF),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.school_rounded,
                      color: Color(0xFF0070F3),
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ক্লাস ও সেমিস্টার নির্বাচন করুন',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: primaryTextColor,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'আপনার একাডেমিক সেশন সিলেক্ট করুন',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.isDismissible)
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.close_rounded,
                      color: secondaryTextColor,
                      size: 22,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Section 1: Class (Class 12)
            Text(
              'শ্রেণি (CLASS)',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: secondaryTextColor,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 8),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: const Color(0xFF0070F3),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE0F2FE),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.menu_book_rounded,
                        color: Color(0xFF0070F3),
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Class 12 (দ্বাদশ শ্রেণি)',
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.bold,
                            color: primaryTextColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'WBCHSE Higher Secondary Education',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF0070F3),
                    size: 22,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Section 2: Semester Selection
            Text(
              'সেমিস্টার নির্বাচন করুন (SEMESTER)',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: secondaryTextColor,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 8),

            // Semester 3 Option
            _buildSemesterSelectCard(
              semester: 3,
              title: 'Semester 3',
              subtitle: 'নোটস, লাইব্রেরি ক্লাস ও মক টেস্ট',
              iconAsset: 'assets/icons/ic_sem3.png',
              accentColor: const Color(0xFF0070F3),
              isSelected: _selectedSemester == 3,
              isDark: isDark,
              onTap: () => setState(() => _selectedSemester = 3),
            ),
            const SizedBox(height: 10),

            // Semester 4 Option
            _buildSemesterSelectCard(
              semester: 4,
              title: 'Semester 4',
              subtitle: 'নোটস, লাইব্রেরি ক্লাস ও মক টেস্ট',
              iconAsset: 'assets/icons/ic_sem4.png',
              accentColor: const Color(0xFFD97706),
              isSelected: _selectedSemester == 4,
              isDark: isDark,
              onTap: () => setState(() => _selectedSemester = 4),
            ),
            const SizedBox(height: 22),

            // Confirm Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _saveAndProceed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0070F3),
                  elevation: 2,
                  shadowColor: const Color(0xFF0070F3).withOpacity(0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text(
                      'নির্বাচন নিশ্চিত করুন',
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 18,
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

  Widget _buildSemesterSelectCard({
    required int semester,
    required String title,
    required String subtitle,
    required String iconAsset,
    required Color accentColor,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    final primaryTextColor = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F1E36);
    final secondaryTextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    final cardBg = isSelected
        ? (isDark ? accentColor.withOpacity(0.12) : accentColor.withOpacity(0.06))
        : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC));

    final borderColor = isSelected
        ? accentColor
        : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0));

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: borderColor,
            width: isSelected ? 2.0 : 1.2,
          ),
        ),
        child: Row(
          children: [
            // Book Icon
            SizedBox(
              width: 44,
              height: 44,
              child: Center(
                child: Image.asset(
                  iconAsset,
                  width: 44,
                  height: 44,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Title & Subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: primaryTextColor,
                        ),
                      ),
                      if (isSelected) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: accentColor,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'ACTIVE',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: secondaryTextColor,
                    ),
                  ),
                ],
              ),
            ),

            // Radio Indicator
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? accentColor : (isDark ? const Color(0xFF64748B) : const Color(0xFFCBD5E1)),
                  width: isSelected ? 6.5 : 2.0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
