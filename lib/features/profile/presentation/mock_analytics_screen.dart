import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/storage/local_storage_service.dart';

class MockAnalyticsScreen extends StatelessWidget {
  const MockAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final attempts = LocalStorageService().getAttemptHistory();

    if (attempts.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('পারফরম্যান্স অ্যানালিটিক্স')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.analytics_outlined, size: 36, color: AppColors.primary),
                ),
                const SizedBox(height: 16),
                const Text(
                  'এখনো কোনো মক টেস্ট দেওয়া হয়নি!',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 8),
                const Text(
                  'মক টেস্ট দেওয়া শুরু করুন। আপনার প্রতিটি পরীক্ষার নির্ভুলতা ও শক্তির জায়গাগুলো এখানে গ্রাফের মাধ্যমে ফুটে উঠবে।',
                  style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.4),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Calculations
    final totalTests = attempts.length;
    double totalAcc = 0;
    double totalScore = 0;
    for (var a in attempts) {
      totalAcc += (a['accuracy'] as num?)?.toDouble() ?? 0;
      totalScore += (a['score'] as num?)?.toDouble() ?? 0;
    }
    final avgAcc = (totalAcc / totalTests).toStringAsFixed(1);
    final avgScore = (totalScore / totalTests).toStringAsFixed(1);

    // Subject breakdown
    final Map<String, List<double>> subjectScores = {};
    for (var a in attempts) {
      final sName = a['subject_name']?.toString() ?? 'অন্যান্য';
      final acc = (a['accuracy'] as num?)?.toDouble() ?? 0;
      subjectScores.putIfAbsent(sName, () => []).add(acc);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('পারফরম্যান্স অ্যানালিটিক্স')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Overall Stats Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.Border.all(color: AppColors.border),
                boxShadow: AppColors.softCardShadow,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem('মোট পরীক্ষা', '$totalTests টি', AppColors.primary),
                  _buildStatItem('গড় নির্ভুলতা', '$avgAcc%', AppColors.correctGreen),
                  _buildStatItem('গড় স্কোর', avgScore, AppColors.primaryDark),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Accuracy Trend Chart
            const Text(
              'অগ্রগতি ও নির্ভুলতার ট্রেন্ড (%)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 12),
            Container(
              height: 200,
              padding: const EdgeInsets.fromLTRB(16, 20, 20, 10),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.Border.all(color: AppColors.border),
              ),
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  minY: 0,
                  maxY: 100,
                  lineBarsData: [
                    LineBarData(
                      spots: attempts.asMap().entries.map((e) {
                        final val = (e.value['accuracy'] as num?)?.toDouble() ?? 0;
                        return FlSpot(e.key.toDouble(), val);
                      }).toList(),
                      isCurved: true,
                      color: AppColors.primary,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppColors.primaryLight.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Subject-wise performance
            const Text(
              'বিষয়ভিত্তিক পারফরম্যান্স',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 12),
            ...subjectScores.entries.map((entry) {
              final avg = entry.value.reduce((a, b) => a + b) / entry.value.length;
              final isStrong = avg >= 75;
              final isWeak = avg < 50;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          entry.key,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isStrong
                                ? AppColors.correctLight
                                : (isWeak ? AppColors.wrongLight : AppColors.primaryLight),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isStrong ? 'শক্তিশালী দিক' : (isWeak ? 'উন্নতি প্রয়োজন' : 'সন্তোষজনক'),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isStrong
                                  ? AppColors.correctGreen
                                  : (isWeak ? AppColors.wrongRed : AppColors.primaryDark),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: avg / 100,
                        minHeight: 8,
                        backgroundColor: AppColors.surfaceMuted,
                        valueColor: AlwaysStoppedAnimation(
                          isStrong ? AppColors.correctGreen : (isWeak ? AppColors.wrongRed : AppColors.primary),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'গড় নির্ভুলতা: ${avg.toStringAsFixed(1)}%',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }
}
