import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/storage/local_storage_service.dart';
import '../domain/mock_test_models.dart';
import 'report_bottom_sheet.dart';
import 'quiz_screen.dart';

class ResultScreen extends StatefulWidget {
  final TestPaperModel testPaper;
  final Map<int, String> userAnswers;

  const ResultScreen({
    super.key,
    required this.testPaper,
    required this.userAnswers,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scoreAnim;

  int _correctCount = 0;
  int _wrongCount = 0;
  int _unansweredCount = 0;
  double _finalScore = 0.0;

  @override
  void initState() {
    super.initState();
    _calculateResults();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _scoreAnim = Tween<double>(begin: 0, end: _finalScore).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );

    _animController.forward();
    _saveAttemptToHistory();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _calculateResults() {
    final questions = widget.testPaper.questions;
    final meta = widget.testPaper.metadata;

    for (int i = 0; i < questions.length; i++) {
      final answer = widget.userAnswers[i];
      if (answer == null) {
        _unansweredCount++;
      } else if (answer == questions[i].correctOption) {
        _correctCount++;
      } else {
        _wrongCount++;
      }
    }

    // No negative marking! Wrong answers do NOT deduct marks.
    final markPerQ = meta.positiveMark > 0 ? meta.positiveMark : 1.0;
    _finalScore = _correctCount * markPerQ;
  }

  Future<void> _saveAttemptToHistory() async {
    final meta = widget.testPaper.metadata;
    final totalMarks = meta.totalMarks > 0 ? meta.totalMarks : widget.testPaper.questions.length.toDouble();
    final record = {
      'test_id': meta.testId,
      'subject_id': meta.subjectId,
      'subject_name': meta.subjectName,
      'topic_id': meta.topicId,
      'topic_name': meta.topicName,
      'set_file': meta.setFile,
      'title': meta.title,
      'date': DateTime.now().toIso8601String(),
      'total_questions': widget.testPaper.questions.length,
      'correct': _correctCount,
      'wrong': _wrongCount,
      'unanswered': _unansweredCount,
      'score': _finalScore,
      'total_marks': totalMarks,
      'accuracy': widget.testPaper.questions.isNotEmpty
          ? (_correctCount / widget.testPaper.questions.length) * 100
          : 0.0,
    };
    await LocalStorageService().recordAttempt(record);
  }

  @override
  Widget build(BuildContext context) {
    final meta = widget.testPaper.metadata;
    final questions = widget.testPaper.questions;
    final totalMarks = meta.totalMarks > 0 ? meta.totalMarks : questions.length.toDouble();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Test Result',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        child: Column(
          children: [
            // 1. Prominent Lottie Animation at Top
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              height: 220,
              width: double.infinity,
              child: Lottie.asset(
                'assets/animations/quiz_success.json',
                fit: BoxFit.contain,
                repeat: true,
              ),
            ),

            // 2. Score Summary Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppColors.border),
                boxShadow: AppColors.softCardShadow,
              ),
              child: Column(
                children: [
                  Text(
                    meta.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  AnimatedBuilder(
                    animation: _scoreAnim,
                    builder: (context, child) {
                      return Column(
                        children: [
                          Text(
                            '${_scoreAnim.value.toInt()} / ${totalMarks.toInt()}',
                            style: const TextStyle(
                              fontSize: 44,
                              fontWeight: FontWeight.w900,
                              color: AppColors.primary,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Total Marks Obtained',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 20),

                  // 3 Clean Metrics in English: Total Questions, Correct, Incorrect
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border.withOpacity(0.5)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildMetricItem('Total Questions', '${questions.length}', AppColors.textPrimary),
                        Container(width: 1, height: 32, color: AppColors.border),
                        _buildMetricItem('Correct', '$_correctCount', AppColors.correctGreen),
                        Container(width: 1, height: 32, color: AppColors.border),
                        _buildMetricItem('Incorrect', '$_wrongCount', AppColors.wrongRed),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 3. Action Buttons: Retake Test & Back to Topics
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => QuizScreen(
                            subjectId: meta.subjectId,
                            subjectName: meta.subjectName,
                            topicId: meta.topicId,
                            topicName: meta.topicName,
                            setFile: meta.setFile,
                            version: meta.version,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.replay_rounded, size: 20),
                    label: const Text(
                      'Retake Test',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      side: const BorderSide(color: AppColors.border, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_rounded, size: 20),
                    label: const Text(
                      'Back to Topics',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 2,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // 4. Questions Review Header
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Question Review & Solutions',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
            ),
            const SizedBox(height: 14),

            // 5. Questions Review List
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: questions.length,
              itemBuilder: (context, index) {
                final q = questions[index];
                final userAns = widget.userAnswers[index];
                final isCorrect = userAns != null && userAns == q.correctOption;
                final isSaved = LocalStorageService().isQuestionSaved(meta.testId, q.qId);

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: userAns == null
                          ? AppColors.border
                          : (isCorrect
                              ? AppColors.correctGreen.withOpacity(0.35)
                              : AppColors.wrongRed.withOpacity(0.35)),
                      width: 1.2,
                    ),
                    boxShadow: AppColors.softCardShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Row: Status Chip & Action Icons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: userAns == null
                                  ? AppColors.surfaceMuted
                                  : (isCorrect ? AppColors.correctLight : AppColors.wrongLight),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  userAns == null
                                      ? Icons.help_outline_rounded
                                      : (isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded),
                                  size: 14,
                                  color: userAns == null
                                      ? AppColors.textSecondary
                                      : (isCorrect ? AppColors.correctGreen : AppColors.wrongRed),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  'Question ${index + 1} • ${userAns == null ? 'Skipped' : (isCorrect ? 'Correct' : 'Incorrect')}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: userAns == null
                                        ? AppColors.textSecondary
                                        : (isCorrect ? AppColors.correctGreen : AppColors.wrongRed),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              // Save Bookmark Button
                              IconButton(
                                constraints: const BoxConstraints(),
                                padding: const EdgeInsets.symmetric(horizontal: 6),
                                icon: Icon(
                                  isSaved ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded,
                                  color: isSaved ? AppColors.primary : AppColors.textMuted,
                                  size: 20,
                                ),
                                onPressed: () async {
                                  final qData = {
                                    'test_id': meta.testId,
                                    'q_id': q.qId,
                                    'question_text': q.questionText,
                                    'image_url': q.imageUrl,
                                    'options': q.options,
                                    'correct_option': q.correctOption,
                                    'explanation': q.explanation,
                                    'subject_id': meta.subjectId,
                                    'subject_name': meta.subjectName,
                                    'topic_name': meta.topicName,
                                    'set_title': meta.title,
                                    'saved_at': DateTime.now().toIso8601String(),
                                  };
                                  await LocalStorageService().toggleSaveQuestion(qData);
                                  setState(() {});
                                },
                              ),
                              // Report Button
                              IconButton(
                                constraints: const BoxConstraints(),
                                padding: const EdgeInsets.symmetric(horizontal: 6),
                                icon: const Icon(Icons.flag_outlined, size: 20, color: AppColors.textMuted),
                                onPressed: () {
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                                    ),
                                    builder: (_) => ReportBottomSheet(
                                      question: q,
                                      metadata: meta,
                                      questionIndex: index,
                                      selectedOption: userAns,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Question Text
                      Text(
                        q.questionText,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Answers Review Box
                      if (isCorrect) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.correctLight.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.correctGreen.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle_rounded, color: AppColors.correctGreen, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Your Answer (Correct): $userAns) ${q.options[userAns] ?? ''}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.correctGreen,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        if (userAns != null) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppColors.wrongLight.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.wrongRed.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.cancel_rounded, color: AppColors.wrongRed, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Your Answer: $userAns) ${q.options[userAns] ?? ''}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.wrongRed,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                        ] else ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceMuted,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.remove_circle_outline_rounded, color: AppColors.textSecondary, size: 18),
                                SizedBox(width: 8),
                                Text(
                                  'Not Answered',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                        ],
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.correctLight.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.correctGreen.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle_rounded, color: AppColors.correctGreen, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Correct Answer: ${q.correctOption}) ${q.options[q.correctOption] ?? ''}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.correctGreen,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Explanation Box
                      if (q.explanation.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.lightbulb_outline_rounded, color: AppColors.primary, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Explanation: ${q.explanation}',
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    color: AppColors.primaryDark,
                                    height: 1.45,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
