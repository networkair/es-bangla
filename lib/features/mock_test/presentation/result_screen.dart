import 'package:flutter/material.dart';
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
  double _accuracy = 0.0;

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

    _finalScore = (_correctCount * meta.positiveMark) - (_wrongCount * meta.negativeMark);
    if (_finalScore < 0) _finalScore = 0.0;

    _accuracy = questions.isNotEmpty ? (_correctCount / questions.length) * 100 : 0.0;
  }

  Future<void> _saveAttemptToHistory() async {
    final meta = widget.testPaper.metadata;
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
      'total_marks': meta.totalMarks,
      'accuracy': _accuracy,
    };
    await LocalStorageService().recordAttempt(record);
  }

  @override
  Widget build(BuildContext context) {
    final meta = widget.testPaper.metadata;
    final questions = widget.testPaper.questions;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('পরীক্ষার ফলাফল'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Score Summary Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
                boxShadow: AppColors.softCardShadow,
              ),
              child: Column(
                children: [
                  Text(
                    meta.title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  AnimatedBuilder(
                    animation: _scoreAnim,
                    builder: (context, child) {
                      return Column(
                        children: [
                          Text(
                            _scoreAnim.value.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.w900,
                              color: AppColors.primary,
                            ),
                          ),
                          Text(
                            'মোট নম্বর: ${meta.totalMarks.toInt()}',
                            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildMetricItem('সঠিক', '$_correctCount', AppColors.correctGreen),
                      _buildMetricItem('ভুল', '$_wrongCount', AppColors.wrongRed),
                      _buildMetricItem('স্কিপ', '$_unansweredCount', AppColors.textMuted),
                      _buildMetricItem('নির্ভুলতা', '${_accuracy.toInt()}%', AppColors.primaryDark),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Action Buttons: Retry & Back
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
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('আবার পরীক্ষা দিন'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_rounded),
                    label: const Text('তালিকায় ফিরুন'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Question Review Header
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'প্রশ্নোত্তর পর্যালোচনা ও বিশ্লেষণ',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
            ),
            const SizedBox(height: 14),

            // Questions Review List
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: questions.length,
              itemBuilder: (context, index) {
                final q = questions[index];
                final userAns = widget.userAnswers[index];
                final isCorrect = userAns == q.correctOption;
                final isSaved = LocalStorageService().isQuestionSaved(meta.testId, q.qId);

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: userAns == null
                          ? AppColors.border
                          : (isCorrect ? AppColors.correctGreen.withOpacity(0.4) : AppColors.wrongRed.withOpacity(0.4)),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: userAns == null
                                  ? AppColors.surfaceMuted
                                  : (isCorrect ? AppColors.correctLight : AppColors.wrongLight),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'প্রশ্ন ${index + 1}: ${userAns == null ? 'স্কিপ' : (isCorrect ? 'সঠিক' : 'ভুল')}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: userAns == null
                                    ? AppColors.textSecondary
                                    : (isCorrect ? AppColors.correctGreen : AppColors.wrongRed),
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              // Save Bookmark Button
                              IconButton(
                                constraints: const BoxConstraints(),
                                padding: const EdgeInsets.symmetric(horizontal: 8),
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
                                padding: const EdgeInsets.symmetric(horizontal: 8),
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
                      const SizedBox(height: 10),
                      Text(
                        q.questionText,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'আপনার উত্তর: ${userAns != null ? '$userAns (${q.options[userAns] ?? ''})' : 'উত্তর দেননি'}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isCorrect ? AppColors.correctGreen : AppColors.wrongRed,
                        ),
                      ),
                      Text(
                        'সঠিক উত্তর: ${q.correctOption} (${q.options[q.correctOption] ?? ''})',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.correctGreen,
                        ),
                      ),
                      if (q.explanation.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          'ব্যাখ্যা: ${q.explanation}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
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
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
