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

class _MockAnalyticsScreenState extends State<MockAnalyticsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _timeframe = 'all'; // 'all', 'month', 'week'
  DateTime _calendarMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

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
    final allAttempts = LocalStorageService().getAttemptHistory();

    if (allAttempts.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: const Text('Performance Analytics', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          backgroundColor: Colors.white,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(28.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2563EB).withOpacity(0.14),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.insights_rounded, size: 44, color: Color(0xFF2563EB)),
                ),
                const SizedBox(height: 22),
                const Text(
                  'No Test Attempts Yet',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Complete your first mock test to unlock chapterwise scorecards, weak topic detection, and daily study activity charts.',
                  style: TextStyle(fontSize: 13.5, color: Color(0xFF64748B), height: 1.45),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const MockSubjectSelectScreen(isPremiumMode: false)),
                  ),
                  icon: const Icon(Icons.play_arrow_rounded, size: 20),
                  label: const Text('Start First Mock Test', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 3,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final filteredAttempts = _filterAttempts(allAttempts);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Performance Analytics',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(14),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withOpacity(0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: const Color(0xFF2563EB),
              unselectedLabelColor: const Color(0xFF64748B),
              labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              tabs: const [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.bar_chart_rounded, size: 17),
                      SizedBox(width: 6),
                      Text('Subject Mastery'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.calendar_month_rounded, size: 17),
                      SizedBox(width: 6),
                      Text('Activity & Streak'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // TAB 1: Subject Mastery & Progress
          _buildSubjectMasteryTab(filteredAttempts, allAttempts),

          // TAB 2: Activity Streak Calendar
          _buildActivityCalendarTab(allAttempts),
        ],
      ),
    );
  }

  // ==================== TAB 1: SUBJECT MASTERY & PROGRESS ====================
  Widget _buildSubjectMasteryTab(List<Map<String, dynamic>> attempts, List<Map<String, dynamic>> allAttempts) {
    // 1. Calculations by Subject
    final Map<String, List<Map<String, dynamic>>> subjectMap = {};
    for (var a in attempts) {
      final sName = a['subject_name']?.toString().trim().isNotEmpty == true
          ? a['subject_name'].toString()
          : 'General';
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

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeframe Filter Pills: [Daily/Weekly/Monthly/All Time]
          Row(
            children: [
              _buildFilterPill('all', 'All Time'),
              const SizedBox(width: 8),
              _buildFilterPill('month', 'This Month'),
              const SizedBox(width: 8),
              _buildFilterPill('week', 'Last 7 Days'),
            ],
          ),
          const SizedBox(height: 20),

          // Section 1: Questions Solved by Subject (Horizontal 3D Cards)
          _buildSectionHeader(
            icon: Icons.assignment_outlined,
            iconColor: const Color(0xFF2563EB),
            title: 'Total Solved Questions',
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

                return InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SubjectAnalyticsDetailScreen(
                          subjectName: subjectName,
                          subjectColor: color,
                          subjectIcon: icon,
                          attempts: list,
                        ),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 155,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.08),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                        BoxShadow(
                          color: const Color(0xFF0F172A).withOpacity(0.02),
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
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${acc.toInt()}%',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Text(
                          subjectName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: Color(0xFF0F172A)),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),

          // Section 2: Priority Focus Areas / Weak Topics
          _buildSectionHeader(
            icon: Icons.trending_down_rounded,
            iconColor: const Color(0xFFE11D48),
            title: 'Priority Focus Areas',
          ),
          const SizedBox(height: 12),
          if (weakTopics.isEmpty)
            _buildEmptyStateCard(
              icon: Icons.verified_rounded,
              iconColor: const Color(0xFF16A34A),
              title: 'No Critical Weak Topics!',
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
                    width: 180,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF1F2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFFECDD3), width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFE11D48).withOpacity(0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
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
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF9F1239)),
                        ),
                        const Spacer(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '$acc%',
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFFE11D48)),
                            ),
                            const Icon(Icons.arrow_downward_rounded, color: Color(0xFFE11D48), size: 18),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 24),

          // Section 3: Strength Topics
          _buildSectionHeader(
            icon: Icons.fitness_center_rounded,
            iconColor: const Color(0xFF16A34A),
            title: 'Mastery Strength Topics',
          ),
          const SizedBox(height: 12),
          if (strongTopics.isEmpty)
            _buildEmptyStateCard(
              icon: Icons.task_alt_rounded,
              iconColor: const Color(0xFF64748B),
              title: 'No Strength Topics Recorded Yet',
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
                    width: 180,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFBBF7D0), width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF16A34A).withOpacity(0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
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
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF14532D)),
                        ),
                        const Spacer(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '$acc%',
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF16A34A)),
                            ),
                            const Icon(Icons.star_rounded, color: Color(0xFF16A34A), size: 20),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 24),

          // Section 4: Subject Accuracy Bar Chart
          _buildSectionHeader(
            icon: Icons.bar_chart_rounded,
            iconColor: const Color(0xFF7C3AED),
            title: 'Overall Subject Comparison',
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 20, 20, 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F172A).withOpacity(0.04),
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
                              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                            );
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 25,
                            reservedSize: 34,
                            getTitlesWidget: (val, _) => Text(
                              '${val.toInt()}%',
                              style: const TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (index, _) {
                              final idx = index.toInt();
                              if (idx < 0 || idx >= subjectMap.keys.length) return const SizedBox.shrink();
                              final sName = subjectMap.keys.elementAt(idx);
                              final shortName = sName.length > 7 ? '${sName.substring(0, 6)}..' : sName;
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  shortName,
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
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
                          color: const Color(0xFFF1F5F9),
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
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
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

          // Section 5: Smart Improvement Roadmap
          _buildSectionHeader(
            icon: Icons.lightbulb_rounded,
            iconColor: const Color(0xFFD97706),
            title: 'Targeted Improvement Steps',
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 90,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildStepCard(
                  stepNum: '1',
                  title: 'Core Concept Revision',
                  color: const Color(0xFF2563EB),
                ),
                const SizedBox(width: 12),
                _buildStepCard(
                  stepNum: '2',
                  title: 'Focused Topic Drills',
                  color: const Color(0xFF7C3AED),
                ),
                const SizedBox(width: 12),
                _buildStepCard(
                  stepNum: '3',
                  title: 'Timed Mock Practice',
                  color: const Color(0xFF059669),
                ),
                const SizedBox(width: 12),
                _buildStepCard(
                  stepNum: '4',
                  title: 'Review Saved Vault',
                  color: const Color(0xFFEA580C),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Primary Launch Mock Test Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MockSubjectSelectScreen(isPremiumMode: false)),
                );
              },
              icon: const Icon(Icons.rocket_launch_rounded, size: 20),
              label: const Text(
                'Start New Mock Test',
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
    );
  }

  // ==================== TAB 2: ACTIVITY STREAK & CALENDAR ====================
  Widget _buildActivityCalendarTab(List<Map<String, dynamic>> allAttempts) {
    // Map dates to number of tests attempted
    final Map<String, int> activeDays = {};
    for (var a in allAttempts) {
      final dateStr = a['date']?.toString();
      if (dateStr != null) {
        final dt = DateTime.tryParse(dateStr);
        if (dt != null) {
          final key = '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
          activeDays[key] = (activeDays[key] ?? 0) + 1;
        }
      }
    }

    // Days in selected calendar month
    final year = _calendarMonth.year;
    final month = _calendarMonth.month;
    final firstDayOfMonth = DateTime(year, month, 1);
    final daysInMonth = DateUtils.getDaysInMonth(year, month);
    final startWeekday = firstDayOfMonth.weekday % 7; // Sunday = 0

    final monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    final currentMonthTitle = '${monthNames[month - 1]} $year';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 3D Month Navigator Box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F172A).withOpacity(0.04),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_rounded, size: 18, color: Color(0xFF475569)),
                  onPressed: () {
                    setState(() {
                      _calendarMonth = DateTime(_calendarMonth.year, _calendarMonth.month - 1, 1);
                    });
                  },
                ),
                Text(
                  currentMonthTitle,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios_rounded, size: 18, color: Color(0xFF475569)),
                  onPressed: () {
                    setState(() {
                      _calendarMonth = DateTime(_calendarMonth.year, _calendarMonth.month + 1, 1);
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 3D Calendar Grid Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F172A).withOpacity(0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                // Day of week headers
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: const [
                    _WeekdayHeader('Sun'),
                    _WeekdayHeader('Mon'),
                    _WeekdayHeader('Tue'),
                    _WeekdayHeader('Wed'),
                    _WeekdayHeader('Thu'),
                    _WeekdayHeader('Fri'),
                    _WeekdayHeader('Sat'),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 12),

                // Days Grid
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
                    final dayKey = '$year-${month.toString().padLeft(2, '0')}-${dayNum.toString().padLeft(2, '0')}';
                    final hasActivity = activeDays.containsKey(dayKey);
                    final testCount = activeDays[dayKey] ?? 0;

                    final now = DateTime.now();
                    final isToday = now.year == year && now.month == month && now.day == dayNum;

                    return Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: hasActivity
                            ? const Color(0xFF059669)
                            : (isToday ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC)),
                        border: Border.all(
                          color: isToday
                              ? const Color(0xFF2563EB)
                              : (hasActivity ? const Color(0xFF059669) : const Color(0xFFE2E8F0)),
                          width: isToday ? 2 : 1,
                        ),
                        boxShadow: hasActivity
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF059669).withOpacity(0.35),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ]
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$dayNum',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: hasActivity
                              ? Colors.white
                              : (isToday ? const Color(0xFF2563EB) : const Color(0xFF475569)),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Streak & Activity Overview Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F172A).withOpacity(0.2),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStreakMetric(
                  icon: Icons.local_fire_department_rounded,
                  iconColor: const Color(0xFFF97316),
                  value: '${activeDays.length}',
                  label: 'Active Days',
                ),
                Container(width: 1, height: 40, color: Colors.white.withOpacity(0.15)),
                _buildStreakMetric(
                  icon: Icons.check_circle_outline_rounded,
                  iconColor: const Color(0xFF10B981),
                  value: '${allAttempts.length}',
                  label: 'Total Tests',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakMetric({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 6),
            Text(
              value,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.7), fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  // ==================== COMMON HELPERS ====================
  Widget _buildFilterPill(String key, String label) {
    final isSelected = _timeframe == key;
    return InkWell(
      onTap: () => setState(() => _timeframe = key),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2563EB) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0)),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF2563EB).withOpacity(0.24),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required Color iconColor,
    required String title,
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
            style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyStateCard({
    required IconData icon,
    required Color iconColor,
    required String title,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Color(0xFF0F172A)),
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
  }) {
    return Container(
      width: 170,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.04),
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
              'Step $stepNum',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
          ),
        ],
      ),
    );
  }
}

class _WeekdayHeader extends StatelessWidget {
  final String label;
  const _WeekdayHeader(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8)),
    );
  }
}

/// Dedicated Screen showing full chapter-level mastery for a single subject
class SubjectAnalyticsDetailScreen extends StatelessWidget {
  final String subjectName;
  final Color subjectColor;
  final IconData subjectIcon;
  final List<Map<String, dynamic>> attempts;

  const SubjectAnalyticsDetailScreen({
    super.key,
    required this.subjectName,
    required this.subjectColor,
    required this.subjectIcon,
    required this.attempts,
  });

  @override
  Widget build(BuildContext context) {
    int totalQuestions = 0;
    int correctQuestions = 0;
    double totalAcc = 0;
    for (var a in attempts) {
      totalQuestions += (a['total_questions'] as num?)?.toInt() ?? 0;
      correctQuestions += (a['correct'] as num?)?.toInt() ?? 0;
      totalAcc += (a['accuracy'] as num?)?.toDouble() ?? 0;
    }
    final avgAcc = attempts.isNotEmpty ? totalAcc / attempts.length : 0.0;

    String proficiency;
    Color profColor;
    if (avgAcc >= 75) {
      proficiency = 'Mastered';
      profColor = const Color(0xFF16A34A);
    } else if (avgAcc >= 50) {
      proficiency = 'Good Progress';
      profColor = const Color(0xFF2563EB);
    } else {
      proficiency = 'Needs Practice';
      profColor = const Color(0xFFE11D48);
    }

    // Group by topic
    final Map<String, List<double>> topicScores = {};
    for (var a in attempts) {
      final t = a['topic_name']?.toString() ?? 'General';
      final acc = (a['accuracy'] as num?)?.toDouble() ?? 0;
      topicScores.putIfAbsent(t, () => []).add(acc);
    }

    final bestTopics = <MapEntry<String, double>>[];
    final weakTopics = <MapEntry<String, double>>[];

    topicScores.forEach((t, list) {
      final avg = list.reduce((a, b) => a + b) / list.length;
      if (avg >= 70) {
        bestTopics.add(MapEntry(t, avg));
      } else {
        weakTopics.add(MapEntry(t, avg));
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(subjectName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Subject Mastery Overview',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), letterSpacing: -0.2),
            ),
            const SizedBox(height: 16),

            // 4 3D Metric Cards Grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.45,
              children: [
                _buildMetricBox('Proficiency Level', proficiency, profColor),
                _buildMetricBox('Average Accuracy', '${avgAcc.toStringAsFixed(0)}%', const Color(0xFF2563EB)),
                _buildMetricBox('Tests Attempted', '${attempts.length}', const Color(0xFF7C3AED)),
                _buildMetricBox('Correct Questions', '$correctQuestions / $totalQuestions', const Color(0xFF059669)),
              ],
            ),
            const SizedBox(height: 24),

            // Best Chapters Section
            const Text(
              'High Performing Chapters',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 10),
            if (bestTopics.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Text(
                  'No mastered chapters yet. Keep practicing this subject!',
                  style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                ),
              )
            else
              ...bestTopics.map((entry) => _buildChapterRow(entry.key, entry.value, const Color(0xFF16A34A))),

            const SizedBox(height: 20),

            // Weak Chapters Section
            const Text(
              'Chapters Needing Focus',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 10),
            if (weakTopics.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Text(
                  'All tested chapters are performing strongly!',
                  style: TextStyle(fontSize: 12.5, color: Color(0xFF16A34A), fontWeight: FontWeight.w500),
                ),
              )
            else
              ...weakTopics.map((entry) => _buildChapterRow(entry.key, entry.value, const Color(0xFFE11D48))),

            const SizedBox(height: 28),

            // Start Mock Test for this Subject
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MockSubjectSelectScreen(isPremiumMode: false)),
                  );
                },
                icon: const Icon(Icons.rocket_launch_rounded, size: 20),
                label: const Text('Practice Mock Tests', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: subjectColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricBox(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color)),
        ],
      ),
    );
  }

  Widget _buildChapterRow(String chapter, double acc, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              chapter,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${acc.toStringAsFixed(1)}%',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: color),
            ),
          ),
        ],
      ),
    );
  }
}
