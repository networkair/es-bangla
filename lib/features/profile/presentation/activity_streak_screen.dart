import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/storage/local_storage_service.dart';
import '../../mock_test/presentation/mock_subject_select_screen.dart';

class ActivityStreakScreen extends StatefulWidget {
  const ActivityStreakScreen({super.key});

  @override
  State<ActivityStreakScreen> createState() => _ActivityStreakScreenState();
}

class _ActivityStreakScreenState extends State<ActivityStreakScreen> {
  DateTime _calendarMonth = DateTime.now();

  int _calculateStreak(Map<String, int> activeDays) {
    if (activeDays.isEmpty) return 0;
    final now = DateTime.now();
    int streak = 0;
    DateTime checkDate = DateTime(now.year, now.month, now.day);

    final todayKey =
        '${checkDate.year}-${checkDate.month.toString().padLeft(2, '0')}-${checkDate.day.toString().padLeft(2, '0')}';
    if (!activeDays.containsKey(todayKey)) {
      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    while (true) {
      final key =
          '${checkDate.year}-${checkDate.month.toString().padLeft(2, '0')}-${checkDate.day.toString().padLeft(2, '0')}';
      if (activeDays.containsKey(key)) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allAttempts = LocalStorageService().getAttemptHistory();

    final Map<String, int> activeDays = {};
    for (var a in allAttempts) {
      final dateStr = a['date']?.toString();
      if (dateStr != null) {
        final dt = DateTime.tryParse(dateStr);
        if (dt != null) {
          final key =
              '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
          activeDays[key] = (activeDays[key] ?? 0) + 1;
        }
      }
    }

    final int streak = _calculateStreak(activeDays);

    final year = _calendarMonth.year;
    final month = _calendarMonth.month;
    final firstDayOfMonth = DateTime(year, month, 1);
    final daysInMonth = DateUtils.getDaysInMonth(year, month);
    final startWeekday = firstDayOfMonth.weekday % 7; // Sunday = 0

    const monthNames = [
      'জানুয়ারি', 'ফেব্রুয়ারি', 'মার্চ', 'এপ্রিল', 'মে', 'জুন',
      'জুলাই', 'আগস্ট', 'সেপ্টেম্বর', 'অক্টোবর', 'নভেম্বর', 'ডিসেম্বর'
    ];
    final currentMonthTitle = '${monthNames[month - 1]} $year';
    const weekdayHeaders = ['রবি', 'সোম', 'মঙ্গল', 'বুধ', 'বৃহ', 'শুক্র', 'শনি'];

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Consistency Stats 3D Card (NO BORDER)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withOpacity(isDark ? 0.3 : 0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatColumn('সক্রিয় দিন', '${activeDays.length}', const Color(0xFF059669),
                      Icons.event_available_rounded, isDark),
                  Container(
                      width: 1,
                      height: 44,
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
                  _buildStatColumn('স্ট্রিক', '$streak দিন', const Color(0xFFEA580C),
                      Icons.local_fire_department_rounded, isDark),
                  Container(
                      width: 1,
                      height: 44,
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
                  _buildStatColumn('মোট টেস্ট', '${allAttempts.length}', const Color(0xFF2563EB),
                      Icons.check_circle_outline_rounded, isDark),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 2. Study Calendar 3D Card (NO BORDER)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withOpacity(isDark ? 0.3 : 0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Month switcher
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.arrow_back_ios_rounded,
                          size: 18,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                        ),
                        onPressed: () {
                          setState(() {
                            _calendarMonth =
                                DateTime(_calendarMonth.year, _calendarMonth.month - 1, 1);
                          });
                        },
                      ),
                      Text(
                        currentMonthTitle,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 18,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                        ),
                        onPressed: () {
                          setState(() {
                            _calendarMonth =
                                DateTime(_calendarMonth.year, _calendarMonth.month + 1, 1);
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Weekday headers
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: weekdayHeaders
                        .map((day) => Expanded(
                              child: Center(
                                child: Text(
                                  day,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                                  ),
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 14),

                  // Days Grid (NO HARSH BORDER)
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: startWeekday + daysInMonth,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 10,
                    ),
                    itemBuilder: (context, index) {
                      if (index < startWeekday) {
                        return const SizedBox.shrink();
                      }
                      final dayNum = index - startWeekday + 1;
                      final dayKey =
                          '$year-${month.toString().padLeft(2, '0')}-${dayNum.toString().padLeft(2, '0')}';
                      final hasActivity = activeDays.containsKey(dayKey);

                      final now = DateTime.now();
                      final isToday = now.year == year && now.month == month && now.day == dayNum;

                      Color circleColor;
                      Color textColor;
                      List<BoxShadow>? shadows;

                      if (hasActivity) {
                        circleColor = const Color(0xFF059669);
                        textColor = Colors.white;
                        shadows = [
                          BoxShadow(
                            color: const Color(0xFF059669).withOpacity(0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ];
                      } else if (isToday) {
                        circleColor = const Color(0xFF2563EB);
                        textColor = Colors.white;
                        shadows = [
                          BoxShadow(
                            color: const Color(0xFF2563EB).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ];
                      } else {
                        circleColor = isDark
                            ? const Color(0xFF0F172A).withOpacity(0.4)
                            : const Color(0xFFF8FAFC);
                        textColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);
                        shadows = null;
                      }

                      return Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: circleColor,
                          boxShadow: shadows,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '$dayNum',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),

                  // Calendar Legend
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildLegendItem(const Color(0xFF059669), 'মক টেস্ট সম্পন্ন', isDark),
                      const SizedBox(width: 24),
                      _buildLegendItem(const Color(0xFF2563EB), 'আজকের দিন', isDark),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 3. Action Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const MockSubjectSelectScreen(isPremiumMode: false)),
                  );
                },
                icon: const Icon(Icons.rocket_launch_rounded, size: 20),
                label: const Text(
                  'মক টেস্ট শুরু করুন',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 3,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(
      String label, String value, Color color, IconData icon, bool isDark) {
    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }
}
