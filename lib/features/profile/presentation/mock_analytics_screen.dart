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
  String _timeframe = 'Daily'; // 'Daily', 'Weekly', 'Monthly'

  List<Map<String, dynamic>> _filterAttempts(List<Map<String, dynamic>> all) {
    if (all.isEmpty) return [];
    final now = DateTime.now();

    // If Daily, attempts within last 36 hours (or fallback to recent)
    if (_timeframe == 'Daily') {
      final list = all.where((a) {
        final dt = DateTime.tryParse(a['date']?.toString() ?? '');
        if (dt == null) return true;
        return now.difference(dt).inHours <= 36;
      }).toList();
      return list.isNotEmpty ? list : all;
    } else if (_timeframe == 'Weekly') {
      final list = all.where((a) {
        final dt = DateTime.tryParse(a['date']?.toString() ?? '');
        if (dt == null) return true;
        return now.difference(dt).inDays <= 7;
      }).toList();
      return list.isNotEmpty ? list : all;
    } else {
      // Monthly
      final list = all.where((a) {
        final dt = DateTime.tryParse(a['date']?.toString() ?? '');
        if (dt == null) return true;
        return now.difference(dt).inDays <= 30;
      }).toList();
      return list.isNotEmpty ? list : all;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allAttempts = LocalStorageService().getAttemptHistory();
    final attempts = _filterAttempts(allAttempts);

    // Grouping by Subject
    final Map<String, List<Map<String, dynamic>>> subjectMap = {};
    for (var a in attempts) {
      final sName = a['subject_name']?.toString().trim().isNotEmpty == true
          ? a['subject_name'].toString().trim()
          : 'সাধারণ';
      subjectMap.putIfAbsent(sName, () => []).add(a);
    }

    // Identify Strong Topics (>= 70%) and Weak Topics (< 60%)
    final List<Map<String, dynamic>> strongTopics = [];
    final List<Map<String, dynamic>> weakTopics = [];

    subjectMap.forEach((sName, list) {
      int totalQ = 0;
      int correctQ = 0;
      for (var item in list) {
        totalQ += (item['total_questions'] as num?)?.toInt() ?? 0;
        correctQ += (item['correct'] as num?)?.toInt() ?? 0;
      }
      final double avgAccuracy = totalQ > 0 ? (correctQ / totalQ) * 100 : 0.0;

      final summary = {
        'subject_name': sName,
        'accuracy': avgAccuracy,
        'total_questions': totalQ,
        'correct_questions': correctQ,
        'attempts_count': list.length,
        'attempts': list,
      };

      if (avgAccuracy >= 70.0) {
        strongTopics.add(summary);
      } else {
        // Less than 60% or needs improvement
        weakTopics.add(summary);
      }
    });

    // Also check chapter/topic level
    final Map<String, List<Map<String, dynamic>>> topicMap = {};
    for (var a in attempts) {
      final tName = a['topic_name']?.toString().trim().isNotEmpty == true
          ? a['topic_name'].toString().trim()
          : (a['title']?.toString().trim() ?? '');
      if (tName.isNotEmpty) {
        topicMap.putIfAbsent(tName, () => []).add(a);
      }
    }

    topicMap.forEach((tName, list) {
      int totalQ = 0;
      int correctQ = 0;
      String sub = '';
      for (var item in list) {
        totalQ += (item['total_questions'] as num?)?.toInt() ?? 0;
        correctQ += (item['correct'] as num?)?.toInt() ?? 0;
        if (sub.isEmpty) sub = item['subject_name']?.toString() ?? '';
      }
      final double acc = totalQ > 0 ? (correctQ / totalQ) * 100 : 0.0;
      final topicSummary = {
        'topic_name': tName,
        'subject_name': sub.isNotEmpty ? sub : tName,
        'accuracy': acc,
        'total_questions': totalQ,
        'correct_questions': correctQ,
        'attempts_count': list.length,
        'attempts': list,
      };

      if (acc >= 70.0 && !strongTopics.any((s) => s['subject_name'] == sub || s['subject_name'] == tName)) {
        strongTopics.add(topicSummary);
      }
    });

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 19,
            color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 90),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Clean Title (No unnecessary subtitle per user instruction)
                Text(
                  'Mock Test Analytics',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                    color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 18),

                // Pill Filter Bar (Daily | Weekly | Monthly)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0).withOpacity(0.7),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    children: [
                      _buildPillTab('Daily', isDark),
                      _buildPillTab('Weekly', isDark),
                      _buildPillTab('Monthly', isDark),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 1. Total Solved Questions Section
                _buildHeader(
                  icon: Icons.menu_book_rounded,
                  iconColor: const Color(0xFF16A34A),
                  iconBg: const Color(0xFFDCFCE7),
                  title: 'Total Solved Questions',
                  isDark: isDark,
                ),
                const SizedBox(height: 14),

                if (subjectMap.isEmpty)
                  _buildEmptySectionCard('No questions solved yet.', isDark)
                else
                  SizedBox(
                    height: 136,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: subjectMap.keys.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 14),
                      itemBuilder: (context, idx) {
                        final sName = subjectMap.keys.elementAt(idx);
                        final sAttempts = subjectMap[sName]!;
                        int solvedCount = 0;
                        for (var item in sAttempts) {
                          solvedCount += (item['total_questions'] as num?)?.toInt() ?? 0;
                        }

                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => SubjectPerformanceDetailScreen(
                                  subjectName: sName,
                                  attempts: sAttempts,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            width: 125,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E293B) : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(isDark ? 0.3 : 0.04),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFDCFCE7),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.menu_book_rounded,
                                      size: 18,
                                      color: Color(0xFF16A34A),
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  sName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '$solvedCount',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                                  ),
                                ),
                                Text(
                                  'Questions',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w500,
                                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                const SizedBox(height: 26),

                // 2. Your Strength Topics Section
                _buildHeader(
                  icon: Icons.fitness_center_rounded,
                  iconColor: const Color(0xFFD97706),
                  iconBg: const Color(0xFFFEF3C7),
                  title: 'Your Strength Topics',
                  isDark: isDark,
                ),
                const SizedBox(height: 14),

                if (strongTopics.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.3 : 0.04),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Icon(
                              Icons.assignment_outlined,
                              size: 54,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF0F172A),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.cancel_rounded,
                                  size: 19,
                                  color: isDark ? const Color(0xFFEF4444) : const Color(0xFF0F172A),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'No Strength Topics Yet',
                          style: TextStyle(
                            fontSize: 16.5,
                            fontWeight: FontWeight.bold,
                            color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Solve more questions to discover your strongest subjects.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  SizedBox(
                    height: 146,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: strongTopics.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 14),
                      itemBuilder: (context, idx) {
                        final t = strongTopics[idx];
                        final sName = t['subject_name']?.toString() ?? '';
                        final sAttempts = (t['attempts'] as List?)?.cast<Map<String, dynamic>>() ?? [];

                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => SubjectPerformanceDetailScreen(
                                  subjectName: sName,
                                  attempts: sAttempts,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            width: 162,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF0FDF4),
                              borderRadius: BorderRadius.circular(22),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(isDark ? 0.3 : 0.04),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  sName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Correct Answers',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                  ),
                                ),
                                const Spacer(),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${(t['accuracy'] as double).toStringAsFixed(1)}%',
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFF16A34A),
                                      ),
                                    ),
                                    SizedBox(
                                      width: 44,
                                      height: 22,
                                      child: CustomPaint(
                                        painter: MiniSparklinePainter(
                                          color: const Color(0xFF16A34A),
                                          isUp: true,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                const SizedBox(height: 26),

                // 3. Your Weak Topics Section
                _buildHeader(
                  icon: Icons.trending_down_rounded,
                  iconColor: const Color(0xFFE11D48),
                  iconBg: const Color(0xFFFFE4E6),
                  title: 'Your Weak Topics',
                  isDark: isDark,
                ),
                const SizedBox(height: 14),

                if (weakTopics.isEmpty)
                  _buildEmptySectionCard('Great job! No weak topics detected.', isDark)
                else
                  SizedBox(
                    height: 146,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: weakTopics.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 14),
                      itemBuilder: (context, idx) {
                        final t = weakTopics[idx];
                        final sName = t['subject_name']?.toString() ?? '';
                        final sAttempts = (t['attempts'] as List?)?.cast<Map<String, dynamic>>() ?? [];

                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => SubjectPerformanceDetailScreen(
                                  subjectName: sName,
                                  attempts: sAttempts,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            width: 162,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFFFF1F2),
                              borderRadius: BorderRadius.circular(22),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(isDark ? 0.3 : 0.04),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  sName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Correct Answers',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                  ),
                                ),
                                const Spacer(),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${(t['accuracy'] as double).toStringAsFixed(1)}%',
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFFE11D48),
                                      ),
                                    ),
                                    SizedBox(
                                      width: 44,
                                      height: 22,
                                      child: CustomPaint(
                                        painter: MiniSparklinePainter(
                                          color: const Color(0xFFE11D48),
                                          isUp: false,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                const SizedBox(height: 26),

                // 4. Overall Performance Bar Chart
                _buildHeader(
                  icon: Icons.bar_chart_rounded,
                  iconColor: const Color(0xFF2563EB),
                  iconBg: const Color(0xFFDBEAFE),
                  title: 'Overall Performance',
                  isDark: isDark,
                ),
                const SizedBox(height: 14),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(14, 24, 18, 16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: subjectMap.isEmpty
                      ? SizedBox(
                          height: 180,
                          child: Center(
                            child: Text(
                              'Attempt tests to generate performance chart.',
                              style: TextStyle(
                                fontSize: 13.5,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              ),
                            ),
                          ),
                        )
                      : SizedBox(
                          height: 250,
                          child: BarChart(
                            BarChartData(
                              alignment: BarChartAlignment.spaceAround,
                              maxY: 100,
                              minY: 0,
                              barTouchData: BarTouchData(
                                enabled: true,
                                touchTooltipData: BarTouchTooltipData(
                                  getTooltipColor: (_) => const Color(0xFF0F172A),
                                  tooltipRoundedRadius: 8,
                                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                    final subject = subjectMap.keys.elementAt(group.x);
                                    return BarTooltipItem(
                                      '$subject\n${rod.toY.toStringAsFixed(1)}%',
                                      const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                    );
                                  },
                                ),
                              ),
                              gridData: FlGridData(
                                show: true,
                                drawVerticalLine: false,
                                horizontalInterval: 20,
                                getDrawingHorizontalLine: (val) => FlLine(
                                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                                  strokeWidth: 1,
                                ),
                              ),
                              borderData: FlBorderData(show: false),
                              titlesData: FlTitlesData(
                                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 32,
                                    interval: 20,
                                    getTitlesWidget: (val, meta) {
                                      if (val % 20 != 0) return const SizedBox.shrink();
                                      return Text(
                                        val.toInt().toString(),
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 30,
                                    getTitlesWidget: (val, meta) {
                                      final index = val.toInt();
                                      if (index < 0 || index >= subjectMap.keys.length) {
                                        return const SizedBox.shrink();
                                      }
                                      final subject = subjectMap.keys.elementAt(index);
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 8.0),
                                        child: Text(
                                          subject,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              barGroups: List.generate(subjectMap.keys.length, (i) {
                                final sName = subjectMap.keys.elementAt(i);
                                final sAttempts = subjectMap[sName]!;
                                int totalQ = 0;
                                int correctQ = 0;
                                for (var item in sAttempts) {
                                  totalQ += (item['total_questions'] as num?)?.toInt() ?? 0;
                                  correctQ += (item['correct'] as num?)?.toInt() ?? 0;
                                }
                                final double acc = totalQ > 0 ? (correctQ / totalQ) * 100 : 0.0;

                                // Bar color matching screenshot
                                Color barColor = const Color(0xFFEF4444);
                                if (acc >= 70) {
                                  barColor = const Color(0xFF10B981);
                                } else if (acc >= 50) {
                                  barColor = const Color(0xFFF59E0B);
                                }

                                return BarChartGroupData(
                                  x: i,
                                  showingTooltipIndicators: [0],
                                  barRods: [
                                    BarChartRodData(
                                      toY: acc,
                                      color: barColor,
                                      width: 46,
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                                    ),
                                  ],
                                );
                              }),
                            ),
                          ),
                        ),
                ),

                const SizedBox(height: 26),

                // 5. How to Improve Your Performance (Swipeable Action Steps)
                Row(
                  children: [
                    const Text('⭐', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Text(
                      'How to Improve Your Performance',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                SizedBox(
                  height: 140,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildStepCard('Step 1', 'Read the Chapter from Text Book', isDark),
                      const SizedBox(width: 14),
                      _buildStepCard('Step 2', 'Review Smart Notes & Summary in App', isDark),
                      const SizedBox(width: 14),
                      _buildStepCard('Step 3', 'Practice MCQs & Test Flashcards', isDark),
                      const SizedBox(width: 14),
                      _buildStepCard('Step 4', 'Analyze Solutions for Incorrect Answers', isDark),
                      const SizedBox(width: 14),
                      _buildStepCard('Step 5', 'Revise Weak Topics & Key Formulas', isDark),
                      const SizedBox(width: 14),
                      _buildStepCard('Step 6', 'Attempt Mock Test Again & Check Growth', isDark),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),

          // Floating Action Button at Bottom
          Positioned(
            left: 18,
            right: 18,
            bottom: 18,
            child: SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MockSubjectSelectScreen(isPremiumMode: false)),
                  );
                },
                icon: const Text('🚀', style: TextStyle(fontSize: 18)),
                label: const Text(
                  'Start New Mock Test',
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  elevation: 6,
                  shadowColor: const Color(0xFF2563EB).withOpacity(0.4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPillTab(String title, bool isDark) {
    final isSelected = _timeframe == title;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _timeframe = title),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF2563EB) : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              color: isSelected
                  ? Colors.white
                  : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF334155)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required bool isDark,
  }) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Center(child: Icon(icon, size: 18, color: iconColor)),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptySectionCard(String text, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 13,
          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
        ),
      ),
    );
  }

  Widget _buildStepCard(String stepTitle, String description, bool isDark) {
    return Container(
      width: 175,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            stepTitle,
            style: TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w900,
              color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 2. SUBJECT PERFORMANCE DETAIL SCREEN
// (Matches Images 4 & 7 from User Reference)
// ==========================================
class SubjectPerformanceDetailScreen extends StatelessWidget {
  final String subjectName;
  final List<Map<String, dynamic>> attempts;

  const SubjectPerformanceDetailScreen({
    super.key,
    required this.subjectName,
    required this.attempts,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final int totalAttempts = attempts.length;
    int totalQ = 0;
    int correctQ = 0;
    for (var a in attempts) {
      totalQ += (a['total_questions'] as num?)?.toInt() ?? 0;
      correctQ += (a['correct'] as num?)?.toInt() ?? 0;
    }
    final double avgPercentage = totalQ > 0 ? (correctQ / totalQ) * 100 : 0.0;

    String overallPerformance = 'Needs Improvement';
    if (avgPercentage >= 85) {
      overallPerformance = 'Mastery';
    } else if (avgPercentage >= 70) {
      overallPerformance = 'Good';
    } else if (avgPercentage >= 50) {
      overallPerformance = 'Average';
    }

    // Group chapters / topics
    final Map<String, List<Map<String, dynamic>>> chapterMap = {};
    for (var a in attempts) {
      final cName = a['topic_name']?.toString().trim().isNotEmpty == true
          ? a['topic_name'].toString().trim()
          : (a['title']?.toString().trim() ?? 'General Topic');
      chapterMap.putIfAbsent(cName, () => []).add(a);
    }

    final List<Map<String, dynamic>> bestChapters = [];
    final List<Map<String, dynamic>> weakChapters = [];

    chapterMap.forEach((cName, list) {
      int cTotalQ = 0;
      int cCorrectQ = 0;
      for (var item in list) {
        cTotalQ += (item['total_questions'] as num?)?.toInt() ?? 0;
        cCorrectQ += (item['correct'] as num?)?.toInt() ?? 0;
      }
      final double cAcc = cTotalQ > 0 ? (cCorrectQ / cTotalQ) * 100 : 0.0;
      final data = {
        'chapter_name': cName,
        'accuracy': cAcc,
      };

      if (cAcc >= 70) {
        bestChapters.add(data);
      } else {
        weakChapters.add(data);
      }
    });

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          subjectName,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18.5,
            color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
          ),
        ),
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
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
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 90),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Performance for this subject',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.2,
                    color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 20),

                // 2x2 Grid of 4 Stat Cards
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 1.35,
                  children: [
                    _buildMetricCard(
                      label: 'Overall Performance',
                      value: overallPerformance,
                      isDark: isDark,
                      valueColor: avgPercentage < 50
                          ? const Color(0xFFE11D48)
                          : const Color(0xFF16A34A),
                    ),
                    _buildMetricCard(
                      label: 'Average Percentage',
                      value: '${avgPercentage.toStringAsFixed(0)}%',
                      isDark: isDark,
                    ),
                    _buildMetricCard(
                      label: 'Total Test Attempted',
                      value: '$totalAttempts',
                      isDark: isDark,
                    ),
                    _buildMetricCard(
                      label: 'Correct Questions',
                      value: '$correctQ/$totalQ',
                      isDark: isDark,
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // Best Chapters
                Text(
                  'Best Chapters',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 12),

                if (bestChapters.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Center(
                      child: Text(
                        'No strong chapters yet.',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  )
                else
                  ...bestChapters.map((c) => _buildChapterCard(
                        title: c['chapter_name'],
                        score: '${(c['accuracy'] as double).toStringAsFixed(1)}%',
                        isDark: isDark,
                        isStrong: true,
                      )),

                const SizedBox(height: 24),

                // Weak Chapters
                Text(
                  'Weak Chapters',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 12),

                if (weakChapters.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Center(
                      child: Text(
                        'No weak chapters identified.',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  )
                else
                  ...weakChapters.map((c) => _buildChapterCard(
                        title: c['chapter_name'],
                        score: '${(c['accuracy'] as double).toStringAsFixed(1)}%',
                        isDark: isDark,
                        isStrong: false,
                      )),
              ],
            ),
          ),

          // Sticky Button
          Positioned(
            left: 18,
            right: 18,
            bottom: 18,
            child: SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MockSubjectSelectScreen(isPremiumMode: false)),
                  );
                },
                icon: const Text('🚀', style: TextStyle(fontSize: 18)),
                label: const Text(
                  'Start New Mock Test',
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  elevation: 6,
                  shadowColor: const Color(0xFF2563EB).withOpacity(0.4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String label,
    required String value,
    required bool isDark,
    Color? valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: valueColor ?? (isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChapterCard({
    required String title,
    required String score,
    required bool isDark,
    required bool isStrong,
  }) {
    final bgColor = isStrong
        ? (isDark ? const Color(0xFF1E293B) : const Color(0xFFF0FDF4))
        : (isDark ? const Color(0xFF1E293B) : const Color(0xFFFFF1F2));

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          RichText(
            text: TextSpan(
              text: score,
              style: TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.w900,
                color: isStrong ? const Color(0xFF16A34A) : const Color(0xFFE11D48),
              ),
              children: [
                TextSpan(
                  text: ' (overall score)',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.normal,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Mini Sparkline Painter for cute wavy lines
class MiniSparklinePainter extends CustomPainter {
  final Color color;
  final bool isUp;

  MiniSparklinePainter({required this.color, this.isUp = false});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    final w = size.width;
    final h = size.height;

    if (isUp) {
      path.moveTo(0, h * 0.85);
      path.lineTo(w * 0.25, h * 0.65);
      path.lineTo(w * 0.50, h * 0.75);
      path.lineTo(w * 0.75, h * 0.35);
      path.lineTo(w, h * 0.15);
    } else {
      path.moveTo(0, h * 0.40);
      path.lineTo(w * 0.22, h * 0.20);
      path.lineTo(w * 0.44, h * 0.65);
      path.lineTo(w * 0.66, h * 0.35);
      path.lineTo(w * 0.88, h * 0.85);
      path.lineTo(w, h * 0.60);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
