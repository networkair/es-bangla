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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Test Result',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        child: Column(
          children: [
            // 1. Prominent Large Lottie Animation
            Container(
              margin: const EdgeInsets.only(top: 0, bottom: 8),
              height: 280,
              width: double.infinity,
              alignment: Alignment.center,
              child: Lottie.asset(
                'assets/animations/quiz_success.json',
                fit: BoxFit.contain,
                repeat: true,
              ),
            ),

            // 2. Dynamic Encouraging Title & Subtitle
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _correctCount >= (questions.length * 0.8)
                      ? '🏆 Outstanding Champion!'
                      : (_correctCount >= (questions.length * 0.5)
                          ? '✨ Great Effort, Keep Going!'
                          : '📚 Try More Champion!'),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF2563EB),
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Here is your Result',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 16),

            // 3. Score Pill Box (Reference Design)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 46, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: const Color(0xFFBBF7D0), width: 1.5),
              ),
              child: AnimatedBuilder(
                animation: _scoreAnim,
                builder: (context, child) {
                  return Column(
                    children: [
                      Text(
                        '${_scoreAnim.value.toInt()}/${totalMarks.toInt()}',
                        style: const TextStyle(
                          fontSize: 38,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF16A34A),
                          letterSpacing: -0.5,
                        ),
                      ),
                      const Text(
                        'Marks',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF15803D),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 18),

            // 4. 3 Separate Individual Stat Cards (Reference Design)
            Row(
              children: [
                // Total Questions Card
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFBFDBFE), width: 1),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '${questions.length}',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Total Questions',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E40AF),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Correct Answers Card
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFBBF7D0), width: 1),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '$_correctCount',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF16A34A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Correct Answers',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF15803D),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Wrong Answers Card
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF1F2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFFECDD3), width: 1),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '$_wrongCount',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFE11D48),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Wrong Answers',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFBE123C),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 5. Action Buttons (Reference Design)
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                ),
                child: const Text(
                  'Start New Test',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_rounded, size: 18),
                label: const Text('Back to Topics', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF475569),
                  side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
            const SizedBox(height: 28),

            // 6. See Your Performance Section Header (Reference Design)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'See Your Performance',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF3B82F6),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Review every question and learn from mistakes.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 7. Question Review Cards (Reference Image 1 Clean Layout)
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
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0F172A).withOpacity(0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Question Title & 3-Dots Popup Menu
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              '${index + 1}. ${q.questionText}',
                              style: const TextStyle(
                                fontSize: 15.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                                height: 1.45,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF64748B), size: 20),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            onSelected: (val) async {
                              if (val == 'bookmark') {
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
                              } else if (val == 'report') {
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
                              }
                            },
                            itemBuilder: (ctx) => [
                              PopupMenuItem(
                                value: 'bookmark',
                                child: Row(
                                  children: [
                                    Icon(
                                      isSaved ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded,
                                      size: 18,
                                      color: isSaved ? AppColors.primary : const Color(0xFF64748B),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(isSaved ? 'Remove Bookmark' : 'Bookmark Question', style: const TextStyle(fontSize: 13)),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'report',
                                child: Row(
                                  children: [
                                    Icon(Icons.flag_outlined, size: 18, color: Color(0xFFE11D48)),
                                    SizedBox(width: 8),
                                    Text('Report Issue', style: TextStyle(fontSize: 13, color: Color(0xFFE11D48))),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      if (q.imageUrl.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            q.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                          ),
                        ),
                      ],

                      const Divider(height: 22, thickness: 1, color: Color(0xFFF1F5F9)),

                      // Answers Display (Exact Reference Design in Image 1)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: RichText(
                          text: TextSpan(
                            style: const TextStyle(fontSize: 14, fontFamily: 'Hind Siliguri'),
                            children: [
                              const TextSpan(
                                text: 'Your Answer : ',
                                style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                              ),
                              TextSpan(
                                text: userAns != null ? '($userAns) ${q.options[userAns] ?? ''}' : 'Not Answered',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: userAns == null
                                      ? const Color(0xFF94A3B8)
                                      : (isCorrect ? const Color(0xFF16A34A) : const Color(0xFFE11D48)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: RichText(
                          text: TextSpan(
                            style: const TextStyle(fontSize: 14, fontFamily: 'Hind Siliguri'),
                            children: [
                              const TextSpan(
                                text: 'Correct Answer : ',
                                style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                              ),
                              TextSpan(
                                text: '(${q.correctOption}) ${q.options[q.correctOption] ?? ''}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF16A34A),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Capsule Status Badge: [✔ Correct] or [✖ Wrong]
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: isCorrect ? const Color(0xFFDCFCE7) : const Color(0xFFFFE4E6),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isCorrect ? const Color(0xFF86EFAC) : const Color(0xFFFDA4AF),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                              size: 14,
                              color: isCorrect ? const Color(0xFF16A34A) : const Color(0xFFE11D48),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              isCorrect ? 'Correct' : (userAns == null ? 'Skipped' : 'Wrong'),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isCorrect ? const Color(0xFF16A34A) : const Color(0xFFE11D48),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Explanation block
                      if (q.explanation.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.lightbulb_outline_rounded, color: Color(0xFF3B82F6), size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Explanation: ${q.explanation}',
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    color: Color(0xFF475569),
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
}
