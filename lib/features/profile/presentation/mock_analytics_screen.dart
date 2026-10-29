import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/storage/local_storage_service.dart';
import '../../mock_test/presentation/mock_subject_select_screen.dart';

class MockAnalyticsScreen extends StatefulWidget {
  const MockAnalyticsScreen({super.key});

  @override
  State<MockAnalyticsScreen> createState() => _MockAnalyticsScreenState();
}

class _MockAnalyticsScreenState extends State<MockAnalyticsScreen> {
  String _timeframe = 'all'; // 'all', 'month', 'week'

  List<Map<String, dynamic>> _filterAttempts(List<Map<String, dynamic>> all) {
    if (_timeframe == 'all') return all;
    final now = DateTime.now();
    final cutoff = _timeframe == 'week'
        ? now.subtract(const Duration(days: 7))
        : now.subtract(const Duration(days: 30));

    return all.where((a) {
      final dateStr = a['date']?.toString();
      if (dateStr == null) return false;
      final dt = DateTime.tryParse(dateStr);
      if (dt == null) return false;
      return dt.isAfter(cutoff);
    }).toList();
  }

  Color _getSubjectColor(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('বাংলা') || lower.contains('bengali')) return const Color(0xFF2563EB);
    if (lower.contains('ইংরেজি') || lower.contains('english')) return const Color(0xFF7C3AED);
    if (lower.contains('ইতিহাস') || lower.contains('history')) return const Color(0xFFD97706);
    if (lower.contains('ভূগোল') || lower.contains('geography')) return const Color(0xFF059669);
    if (lower.contains('শিক্ষা') || lower.contains('education')) return const Color(0xFFE11D48);
    if (lower.contains('রাষ্ট্র') || lower.contains('pol')) return const Color(0xFF0891B2);
    if (lower.contains('দর্শন') || lower.contains('philosophy')) return const Color(0xFFEA580C);
    return const Color(0xFF4F46E5);
  }

  IconData _getSubjectIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('বাংলা') || lower.contains('bengali')) return Icons.menu_book_rounded;
    if (lower.contains('ইংরেজি') || lower.contains('english')) return Icons.translate_rounded;
    if (lower.contains('ইতিহাস') || lower.contains('history')) return Icons.account_balance_rounded;
    if (lower.contains('ভূগোল') || lower.contains('geography')) return Icons.public_rounded;
    if (lower.contains('শিক্ষা') || lower.contains('education')) return Icons.school_rounded;
    if (lower.contains('রাষ্ট্র') || lower.contains('pol')) return Icons.policy_rounded;
    if (lower.contains('দর্শন') || lower.contains('philosophy')) return Icons.psychology_rounded;
    return Icons.auto_stories_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allAttempts = LocalStorageService().getAttemptHistory();
    final attempts = _filterAttempts(allAttempts);

    if (allAttempts.isEmpty) {
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
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(28.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withOpacity(isDark ? 0.3 : 0.06),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.insights_rounded, size: 38, color: Color(0xFF2563EB)),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'এখনও কোনো মক টেস্ট দেওয়া হয়নি',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'মক টেস্ট সম্পন্ন করলে এখানে বিষয়ভিত্তিক পারফরম্যান্স, স্ট্রেন্থ ও ফোকাস টপিক দেখতে পাবেন।',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const MockSubjectSelectScreen(isPremiumMode: false)),
                      );
                    },
                    icon: const Icon(Icons.rocket_launch_rounded, size: 18),
                    label: const Text('মক টেস্ট শুরু করুন', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // 1. Calculations by Subject
    final Map<String, List<Map<String, dynamic>>> subjectMap = {};
    for (var a in attempts) {
      final sName = a['subject_name']?.toString().trim().isNotEmpty == true
          ? a['subject_name'].toString()
          : 'সাধারণ';
      subjectMap.putIfAbsent(sName, () => []).add(a);
    }

    // 2. Calculations by Topic
    final Map<String, List<Map<String, dynamic>>> topicMap = {};
    for (var a in attempts) {
      final tName = a['topic_name']?.toString().trim().isNotEmpty == true
          ? a['topic_name'].toString()
          : '';
      if (tName.isNotEmpty) {
        topicMap.putIfAbsent(tName, () => []).add(a);
      }
    }

    // Identify Strong Topics (>= 70%) and Weak Topics (< 60%)
    final List<Map<String, dynamic>> strongTopics = [];
    final List<Map<String, dynamic>> weakTopics = [];

    topicMap.forEach((tName, list) {
      double totalAcc = 0;
      int qCount = 0;
      String subjectName = '';
      for (var item in list) {
        totalAcc += (item['accuracy'] as num?)?.toDouble() ?? 0;
        qCount += (item['total_questions'] as num?)?.toInt() ?? 0;
        if (subjectName.isEmpty) subjectName = item['subject_name']?.toString() ?? '';
      }
      final avgAcc = totalAcc / list.length;
      final topicData = {
        'topic_name': tName,
        'subject_name': subjectName,
        'accuracy': avgAcc,
        'questions_count': qCount,
        'attempts_count': list.length,
      };

      if (avgAcc >= 70.0) {
        strongTopics.add(topicData);
      } else if (avgAcc < 60.0) {
        weakTopics.add(topicData);
      }
    });

    strongTopics.sort((a, b) => (b['accuracy'] as double).compareTo(a['accuracy'] as double));
    weakTopics.sort((a, b) => (a['accuracy'] as double).compareTo(b['accuracy'] as double));

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
            // Timeframe Filter Pills (3D, NO BORDER)
            Row(
              children: [
                _buildFilterPill('all', 'সব সময় (All Time)', isDark),
                const SizedBox(width: 8),
                _buildFilterPill('month', 'এই মাস (Month)', isDark),
                const SizedBox(width: 8),
                _buildFilterPill('week', 'গত ৭ দিন (7 Days)', isDark),
              ],
            ),
            const SizedBox(height: 20),

            // Section 1: Questions Solved by Subject (Horizontal 3D Cards, NO BORDER)
            _buildSectionHeader(
              icon: Icons.assignment_outlined,
              iconColor: const Color(0xFF2563EB),
              title: 'বিষয়ভিত্তিক সমাধান',
              isDark: isDark,
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 110,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: subjectMap.keys.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final subjectName = subjectMap.keys.elementAt(index);
                  final list = subjectMap[subjectName]!;
                  final color = _getSubjectColor(subjectName);
                  final icon = _getSubjectIcon(subjectName);

                  int totalQuestions = 0;
                  int correctQuestions = 0;
                  for (var item in list) {
                    totalQuestions += (item['total_questions'] as num?)?.toInt() ?? 0;
                    correctQuestions += (item['correct'] as num?)?.toInt() ?? 0;
                  }
                  final acc = totalQuestions > 0 ? (correctQuestions / totalQuestions) * 100 : 0.0;

                  return Container(
                    width: 160,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.08),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                        BoxShadow(
                          color: const Color(0xFF0F172A).withOpacity(isDark ? 0.2 : 0.02),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(icon, color: color, size: 18),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${acc.toInt()}%',
                                style: TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.bold, color: color),
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Text(
                          subjectName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14.5,
                            color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$totalQuestions টি সমাধান',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // Section 2: Priority Focus Areas / Weak Topics (Horizontal 3D Cards, NO BORDER)
            _buildSectionHeader(
              icon: Icons.trending_down_rounded,
              iconColor: const Color(0xFFE11D48),
              title: 'দুর্বল অধ্যায় ও ফোকাস টপিক',
              isDark: isDark,
            ),
            const SizedBox(height: 12),
            if (weakTopics.isEmpty)
              _buildEmptyStateCard(
                icon: Icons.verified_rounded,
                iconColor: const Color(0xFF16A34A),
                title: 'কোনো দুর্বল টপিক নেই, প্রস্তুতি চমৎকার!',
                isDark: isDark,
              )
            else
              SizedBox(
                height: 105,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: weakTopics.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final t = weakTopics[index];
                    final acc = (t['accuracy'] as double).toStringAsFixed(1);
                    return Container(
                      width: 185,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF3B1A22) : const Color(0xFFFFF1F2),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFE11D48).withOpacity(0.1),
                            blurRadius: 14,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t['topic_name'],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              color: Color(0xFFE11D48),
                            ),
                          ),
                          const Spacer(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '$acc%',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFFE11D48),
                                ),
                              ),
                              const Icon(Icons.arrow_downward_rounded,
                                  color: Color(0xFFE11D48), size: 18),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 24),

            // Section 3: Strength Topics (Horizontal 3D Cards, NO BORDER)
            _buildSectionHeader(
              icon: Icons.fitness_center_rounded,
              iconColor: const Color(0xFF16A34A),
              title: 'মাস্টারি স্ট্রেন্থ টপিক',
              isDark: isDark,
            ),
            const SizedBox(height: 12),
            if (strongTopics.isEmpty)
              _buildEmptyStateCard(
                icon: Icons.task_alt_rounded,
                iconColor: const Color(0xFF64748B),
                title: 'এখনও কোনো স্ট্রেন্থ টপিক রেকর্ড হয়নি',
                isDark: isDark,
              )
            else
              SizedBox(
                height: 105,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: strongTopics.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final t = strongTopics[index];
                    final acc = (t['accuracy'] as double).toStringAsFixed(1);
                    return Container(
                      width: 185,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF143324) : const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF16A34A).withOpacity(0.1),
                            blurRadius: 14,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t['topic_name'],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              color: Color(0xFF16A34A),
                            ),
                          ),
                          const Spacer(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '$acc%',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF16A34A),
                                ),
                              ),
                              const Icon(Icons.star_rounded,
                                  color: Color(0xFF16A34A), size: 20),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 24),

            // Section 4: Subject Accuracy Bar Chart (3D, NO BORDER)
            _buildSectionHeader(
              icon: Icons.bar_chart_rounded,
              iconColor: const Color(0xFF7C3AED),
              title: 'সার্বিক বিষয়ভিত্তিক তুলনা',
              isDark: isDark,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 20, 20, 14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withOpacity(isDark ? 0.3 : 0.05),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  SizedBox(
                    height: 190,
                    child: BarChart(
                      BarChartData(
                        maxY: 100,
                        barTouchData: BarTouchData(
                          touchTooltipData: BarTouchTooltipData(
                            getTooltipItem: (group, groupIndex, rod, rodIndex) {
                              final sName = subjectMap.keys.elementAt(groupIndex);
                              return BarTooltipItem(
                                '$sName\n${rod.toY.toStringAsFixed(1)}%',
                                const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12),
                              );
                            },
                          ),
                        ),
                        titlesData: FlTitlesData(
                          topTitles:
                              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles:
                              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              interval: 25,
                              reservedSize: 34,
                              getTitlesWidget: (val, _) => Text(
                                '${val.toInt()}%',
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  color: Color(0xFF94A3B8),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (index, _) {
                                final idx = index.toInt();
                                if (idx < 0 || idx >= subjectMap.keys.length) {
                                  return const SizedBox.shrink();
                                }
                                final sName = subjectMap.keys.elementAt(idx);
                                final shortName =
                                    sName.length > 7 ? '${sName.substring(0, 6)}..' : sName;
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    shortName,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: isDark
                                          ? const Color(0xFF94A3B8)
                                          : const Color(0xFF475569),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: 25,
                          getDrawingHorizontalLine: (val) => FlLine(
                            color: isDark
                                ? const Color(0xFF334155).withOpacity(0.5)
                                : const Color(0xFFF1F5F9),
                            strokeWidth: 1.2,
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        barGroups: subjectMap.entries.toList().asMap().entries.map((e) {
                          final idx = e.key;
                          final list = e.value.value;
                          final color = _getSubjectColor(e.value.key);

                          double totalAcc = 0;
                          for (var item in list) {
                            totalAcc += (item['accuracy'] as num?)?.toDouble() ?? 0;
                          }
                          final avg = list.isNotEmpty ? totalAcc / list.length : 0.0;

                          return BarChartGroupData(
                            x: idx,
                            barRods: [
                              BarChartRodData(
                                toY: avg,
                                gradient: LinearGradient(
                                  colors: [color.withOpacity(0.8), color],
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                ),
                                width: 22,
                                borderRadius:
                                    const BorderRadius.vertical(top: Radius.circular(8)),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Section 5: Smart Improvement Roadmap (Horizontal 3D Cards, NO BORDER)
            _buildSectionHeader(
              icon: Icons.lightbulb_rounded,
              iconColor: const Color(0xFFD97706),
              title: 'টার্গেটেড প্রস্তুতি ধাপ',
              isDark: isDark,
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 90,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildStepCard(
                    stepNum: '১',
                    title: 'মূল ধারণা রিভিশন',
                    color: const Color(0xFF2563EB),
                    isDark: isDark,
                  ),
                  const SizedBox(width: 12),
                  _buildStepCard(
                    stepNum: '২',
                    title: 'ফোকাসড টপিক ড্রিল',
                    color: const Color(0xFF7C3AED),
                    isDark: isDark,
                  ),
                  const SizedBox(width: 12),
                  _buildStepCard(
                    stepNum: '৩',
                    title: 'টাইমার মক প্র্যাকটিস',
                    color: const Color(0xFF059669),
                    isDark: isDark,
                  ),
                  const SizedBox(width: 12),
                  _buildStepCard(
                    stepNum: '৪',
                    title: 'সেভড প্রশ্ন রিভিশন',
                    color: const Color(0xFFEA580C),
                    isDark: isDark,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Primary Launch Mock Test Button
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

  // ==================== HELPER WIDGETS ====================
  Widget _buildFilterPill(String key, String label, bool isDark) {
    final isSelected = _timeframe == key;
    return InkWell(
      onTap: () => setState(() => _timeframe = key),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF2563EB)
              : (isDark ? const Color(0xFF1E293B) : Colors.white),
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF2563EB).withOpacity(0.24),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withOpacity(isDark ? 0.2 : 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.bold,
            color: isSelected
                ? Colors.white
                : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required Color iconColor,
    required String title,
    required bool isDark,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w800,
              color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyStateCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required bool isDark,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(isDark ? 0.25 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13.5,
                color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepCard({
    required String stepNum,
    required String title,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      width: 170,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(isDark ? 0.25 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'ধাপ $stepNum',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }
}
