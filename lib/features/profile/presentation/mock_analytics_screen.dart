import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/storage/local_storage_service.dart';
import '../../mock_test/presentation/mock_subject_select_screen.dart';

class MockAnalyticsScreen extends StatefulWidget {
  const MockAnalyticsScreen({super.key});

  @override
  State<MockAnalyticsScreen> createState() => _MockAnalyticsScreenState();
}

class _MockAnalyticsScreenState extends State<MockAnalyticsScreen> {
  String _timeframe = 'Weekly'; // Default to Weekly for a rich, immediate activity view
  int? _selectedSubjectIndex;

  List<Map<String, dynamic>> _filterAttempts(List<Map<String, dynamic>> all) {
    if (all.isEmpty) return [];
    final now = DateTime.now();

    if (_timeframe == 'Daily') {
      final todayStart = DateTime(now.year, now.month, now.day);
      return all.where((a) {
        final dt = DateTime.tryParse(a['date']?.toString() ?? '');
        if (dt == null) return false;
        return dt.isAfter(todayStart);
      }).toList();
    } else if (_timeframe == 'Weekly') {
      final weekAgo = now.subtract(const Duration(days: 7));
      return all.where((a) {
        final dt = DateTime.tryParse(a['date']?.toString() ?? '');
        if (dt == null) return false;
        return dt.isAfter(weekAgo);
      }).toList();
    } else {
      // Monthly (last 30 days)
      final monthAgo = now.subtract(const Duration(days: 30));
      return all.where((a) {
        final dt = DateTime.tryParse(a['date']?.toString() ?? '');
        if (dt == null) return false;
        return dt.isAfter(monthAgo);
      }).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allAttempts = LocalStorageService().getAttemptHistory();
    final attempts = _filterAttempts(allAttempts);

    // Grouping strictly by canonical Subject Name
    final Map<String, List<Map<String, dynamic>>> subjectMap = {};
    for (var a in attempts) {
      final sName = a['subject_name']?.toString().trim().isNotEmpty == true
          ? a['subject_name'].toString().trim()
          : 'সাধারণ';
      subjectMap.putIfAbsent(sName, () => []).add(a);
    }

    // Identify Strong Subjects (>= 70%) and Weak Subjects (< 70%)
    // MUTUALLY EXCLUSIVE: A subject will NEVER appear in both Mastered and Revision!
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
        weakTopics.add(summary);
      }
    });

    // Sort strong topics descending (highest score first)
    strongTopics.sort((a, b) => (b['accuracy'] as double).compareTo(a['accuracy'] as double));
    // Sort weak topics ascending (lowest score first so student knows what needs revision most)
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
            size: 19,
            color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
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

            // Modern Segmented Timeframe Switcher (Daily | Weekly | Monthly)
            Row(
              children: [
                _buildTimeframeTab(
                  title: 'Daily',
                  icon: Icons.bolt_rounded,
                  isDark: isDark,
                ),
                const SizedBox(width: 8),
                _buildTimeframeTab(
                  title: 'Weekly',
                  icon: Icons.calendar_view_week_rounded,
                  isDark: isDark,
                ),
                const SizedBox(width: 8),
                _buildTimeframeTab(
                  title: 'Monthly',
                  icon: Icons.calendar_month_rounded,
                  isDark: isDark,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 1. Solved Questions Overview Section
            _buildHeader(
              icon: Icons.menu_book_rounded,
              iconColor: const Color(0xFF16A34A),
              iconBg: const Color(0xFFDCFCE7),
              title: 'Solved Questions Overview',
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

            // 2. Mastered Topics & Subjects Section
            _buildHeader(
              icon: Icons.fitness_center_rounded,
              iconColor: const Color(0xFFD97706),
              iconBg: const Color(0xFFFEF3C7),
              title: 'Mastered Topics & Subjects',
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

            // 3. Topics Needing Revision Section
            _buildHeader(
              icon: Icons.trending_down_rounded,
              iconColor: const Color(0xFFE11D48),
              iconBg: const Color(0xFFFFE4E6),
              title: 'Topics Needing Revision',
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

            // 4. Overall Accuracy & Progress Bar Chart
            _buildHeader(
              icon: Icons.bar_chart_rounded,
              iconColor: const Color(0xFF2563EB),
              iconBg: const Color(0xFFDBEAFE),
              title: 'Overall Accuracy & Progress',
              isDark: isDark,
            ),
            const SizedBox(height: 14),

            _buildAdvancedPerformanceBarChart(
              subjectMap: subjectMap,
              isDark: isDark,
            ),

            const SizedBox(height: 26),

            // 5. Smart Preparation Roadmap (Tailored Action Steps)
            _buildHeader(
              icon: Icons.auto_awesome_rounded,
              iconColor: const Color(0xFFD97706),
              iconBg: const Color(0xFFFEF3C7),
              title: 'Smart Preparation Roadmap',
              isDark: isDark,
            ),
            const SizedBox(height: 14),

            SizedBox(
              height: 154,
              child: ListView(
                clipBehavior: Clip.none,
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(vertical: 4),
                children: [
                  _buildStepCard('Step 1', 'Core Concept Clarity', 'Read textbook chapters attentively to build solid conceptual foundation.', isDark),
                  const SizedBox(width: 14),
                  _buildStepCard('Step 2', 'Smart Study Notes', 'Explore curated suggestions and key topic notes in Es Bangla app.', isDark),
                  const SizedBox(width: 14),
                  _buildStepCard('Step 3', 'Topic-wise Practice', 'Attempt topic quizzes to evaluate understanding and accuracy.', isDark),
                  const SizedBox(width: 14),
                  _buildStepCard('Step 4', 'Analyze & Learn', 'Review solution explanations carefully to identify and fix mistakes.', isDark),
                  const SizedBox(width: 14),
                  _buildStepCard('Step 5', 'Targeted Mock Revision', 'Revisit weak chapters and retake full mock tests for guaranteed mastery.', isDark),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Action Button - In Scrollable flow (No longer frozen over content!)
            SizedBox(
              width: double.infinity,
              height: 54,
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
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  elevation: 4,
                  shadowColor: const Color(0xFF2563EB).withOpacity(0.35),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeframeTab({
    required String title,
    required IconData icon,
    required bool isDark,
  }) {
    final isSelected = _timeframe == title;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _timeframe = title),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
                    colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isSelected
                ? null
                : (isDark ? const Color(0xFF1E293B) : Colors.white),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF3B82F6)
                  : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              width: 1.2,
            ),
            boxShadow: [
              if (isSelected)
                BoxShadow(
                  color: const Color(0xFF2563EB).withOpacity(0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                )
              else
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color: isSelected
                    ? Colors.white
                    : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
              ),
              const SizedBox(width: 6),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected
                      ? Colors.white
                      : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569)),
                  letterSpacing: 0.2,
                ),
              ),
            ],
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

  Widget _buildAdvancedPerformanceBarChart({
    required Map<String, List<Map<String, dynamic>>> subjectMap,
    required bool isDark,
  }) {
    if (subjectMap.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
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
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.insert_chart_outlined_rounded,
                size: 46,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
              const SizedBox(height: 12),
              Text(
                'Attempt tests to generate performance chart.',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final List<Map<String, dynamic>> subjectStats = [];
    subjectMap.forEach((sName, list) {
      int totalQ = 0;
      int correctQ = 0;
      for (var item in list) {
        totalQ += (item['total_questions'] as num?)?.toInt() ?? 0;
        correctQ += (item['correct'] as num?)?.toInt() ?? 0;
      }
      final double acc = totalQ > 0 ? (correctQ / totalQ) * 100 : 0.0;
      subjectStats.add({
        'name': sName,
        'accuracy': acc,
        'totalQ': totalQ,
        'correctQ': correctQ,
        'attempts': list,
      });
    });

    final selectedIdx = (_selectedSubjectIndex != null &&
            _selectedSubjectIndex! < subjectStats.length)
        ? _selectedSubjectIndex!
        : 0;
    final selectedSubject = subjectStats[selectedIdx];
    final selectedAcc = selectedSubject['accuracy'] as double;
    final selectedColor = selectedAcc >= 70
        ? const Color(0xFF10B981)
        : (selectedAcc >= 50 ? const Color(0xFFF59E0B) : const Color(0xFFEF4444));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 18, 14, 16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Legend Row
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _buildChartLegendDot(const Color(0xFF10B981), '≥70% High', isDark),
              const SizedBox(width: 10),
              _buildChartLegendDot(const Color(0xFFF59E0B), '50-69% Avg', isDark),
              const SizedBox(width: 10),
              _buildChartLegendDot(const Color(0xFFEF4444), '<50% Focus', isDark),
            ],
          ),
          const SizedBox(height: 14),

          // 2. Main Chart: Sticky Left Y-Axis + Horizontally Scrollable Bar Canvas
          SizedBox(
            height: 250,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Fixed Left Y-Axis
                SizedBox(
                  width: 30,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildYAxisLabel('100', isDark),
                      _buildYAxisLabel('80', isDark),
                      _buildYAxisLabel('60', isDark),
                      _buildYAxisLabel('40', isDark),
                      _buildYAxisLabel('20', isDark),
                      _buildYAxisLabel('0', isDark),
                      const SizedBox(height: 44),
                    ],
                  ),
                ),

                const SizedBox(width: 6),

                // Vertical Divider Line
                Container(
                  width: 1,
                  height: 195,
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),

                // Horizontally Scrollable Bars
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final availableWidth = constraints.maxWidth;
                      final double colWidth = math.max(
                        74.0,
                        availableWidth / math.max(1, subjectStats.length),
                      );

                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Stack(
                          children: [
                            // Background horizontal grid lines
                            Positioned.fill(
                              bottom: 44,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: List.generate(
                                  6,
                                  (_) => Container(
                                    width: colWidth * subjectStats.length,
                                    height: 1,
                                    color: isDark
                                        ? const Color(0xFF334155).withOpacity(0.4)
                                        : const Color(0xFFE2E8F0).withOpacity(0.7),
                                  ),
                                ),
                              ),
                            ),

                            // Row of Bar Columns
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: List.generate(subjectStats.length, (idx) {
                                final s = subjectStats[idx];
                                final acc = s['accuracy'] as double;
                                final isSelected = idx == selectedIdx;

                                Color barColor = const Color(0xFFEF4444);
                                if (acc >= 70) {
                                  barColor = const Color(0xFF10B981);
                                } else if (acc >= 50) {
                                  barColor = const Color(0xFFF59E0B);
                                }

                                const double maxBarHeight = 160.0;
                                final double filledHeight =
                                    (maxBarHeight * (acc / 100)).clamp(4.0, maxBarHeight);

                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedSubjectIndex = idx;
                                    });
                                  },
                                  child: Container(
                                    width: colWidth,
                                    color: Colors.transparent,
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        // Accuracy Percentage Value
                                        Text(
                                          '${acc.toStringAsFixed(1)}%',
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold,
                                            color: barColor,
                                          ),
                                        ),
                                        const SizedBox(height: 6),

                                        // Bar with Rounded Track
                                        Container(
                                          width: 36,
                                          height: maxBarHeight,
                                          decoration: BoxDecoration(
                                            color: isDark
                                                ? const Color(0xFF334155).withOpacity(0.3)
                                                : const Color(0xFFF1F5F9),
                                            borderRadius:
                                                const BorderRadius.vertical(top: Radius.circular(8)),
                                          ),
                                          alignment: Alignment.bottomCenter,
                                          child: AnimatedContainer(
                                            duration: const Duration(milliseconds: 350),
                                            curve: Curves.easeOutCubic,
                                            width: 36,
                                            height: filledHeight,
                                            decoration: BoxDecoration(
                                              color: barColor,
                                              borderRadius:
                                                  const BorderRadius.vertical(top: Radius.circular(8)),
                                              boxShadow: isSelected
                                                  ? [
                                                      BoxShadow(
                                                        color: barColor.withOpacity(0.45),
                                                        blurRadius: 8,
                                                        offset: const Offset(0, 2),
                                                      ),
                                                    ]
                                                  : null,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 8),

                                        // Dedicated Subject Label (Never Overlaps!)
                                        SizedBox(
                                          height: 36,
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 4),
                                            child: Text(
                                              s['name'],
                                              maxLines: 2,
                                              textAlign: TextAlign.center,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                                color: isSelected
                                                    ? (isDark ? Colors.white : const Color(0xFF0F172A))
                                                    : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569)),
                                                height: 1.25,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          if (subjectStats.length > 4) ...[
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.swap_horiz_rounded,
                  size: 15,
                  color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                ),
                const SizedBox(width: 4),
                Text(
                  'ডানে-বামে স্ক্রোল করে সব বিষয় দেখুন (Swipe to view all)',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 12),

          // 3. Interactive Subject Focus Card (MarkerView for active bar)
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SubjectPerformanceDetailScreen(
                    subjectName: selectedSubject['name'],
                    attempts: (selectedSubject['attempts'] as List).cast<Map<String, dynamic>>(),
                  ),
                ),
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: selectedColor.withOpacity(0.35),
                  width: 1.2,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: selectedColor.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${selectedAcc.toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w900,
                          color: selectedColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          selectedSubject['name'],
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${selectedSubject['correctQ']} / ${selectedSubject['totalQ']} প্রশ্ন সঠিক (${(selectedSubject['attempts'] as List).length} টি টেস্ট)',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: selectedColor,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYAxisLabel(String text, bool isDark) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 10.5,
        fontWeight: FontWeight.w600,
        color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
      ),
    );
  }

  Widget _buildChartLegendDot(Color color, String text, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          text,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildStepCard(String stepTitle, String subtitle, String description, bool isDark) {
    return Container(
      width: 190,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0).withOpacity(0.8),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : const Color(0xFF0F172A)).withOpacity(isDark ? 0.35 : 0.08),
            blurRadius: 18,
            spreadRadius: -2,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: (isDark ? Colors.black : const Color(0xFF0F172A)).withOpacity(isDark ? 0.15 : 0.03),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB).withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              stepTitle,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: Color(0xFF2563EB),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.bold,
              color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            description,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Subject Performance Breakdown',
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
                  label: 'Overall Status',
                  value: overallPerformance,
                  isDark: isDark,
                  valueColor: avgPercentage < 50
                      ? const Color(0xFFE11D48)
                      : const Color(0xFF16A34A),
                ),
                _buildMetricCard(
                  label: 'Average Score',
                  value: '${avgPercentage.toStringAsFixed(0)}%',
                  isDark: isDark,
                ),
                _buildMetricCard(
                  label: 'Tests Completed',
                  value: '$totalAttempts',
                  isDark: isDark,
                ),
                _buildMetricCard(
                  label: 'Correct Answers',
                  value: '$correctQ/$totalQ',
                  isDark: isDark,
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Best Chapters
            Text(
              'Mastered Chapters',
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
              'Chapters for Revision',
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

            const SizedBox(height: 28),

            // Action Button - In Scrollable flow (No longer frozen over content!)
            SizedBox(
              width: double.infinity,
              height: 54,
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
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  elevation: 4,
                  shadowColor: const Color(0xFF2563EB).withOpacity(0.35),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
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
