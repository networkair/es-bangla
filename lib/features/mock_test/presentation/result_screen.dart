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
      duration: const Duration(milliseconds: 1000),
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

  Future<void> _toggleBookmark({
    required TestMetadataModel meta,
    required QuestionModel q,
    required bool wasSaved,
  }) async {
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
    if (mounted) {
      setState(() {});
      _showCuteSaveToast(isSaved: !wasSaved);
    }
  }

  void _showCuteSaveToast({required bool isSaved}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        backgroundColor: Colors.transparent,
        padding: EdgeInsets.zero,
        margin: const EdgeInsets.only(bottom: 24, left: 24, right: 24),
        duration: const Duration(milliseconds: 2000),
        content: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: Colors.white.withOpacity(0.14),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.28),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Official Es Bangla App Logo Badge
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.asset(
                    'assets/icons/app_logo.png',
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 10),
                // Feedback Text
                Text(
                  isSaved ? 'সেভ সাকসেসফুল' : 'বুকমার্ক সরানো হয়েছে',
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  isSaved ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                  color: isSaved ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final meta = widget.testPaper.metadata;
    final questions = widget.testPaper.questions;
    final totalMarks = meta.totalMarks > 0 ? meta.totalMarks : questions.length.toDouble();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Performance Scorecard',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0F172A)),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE2E8F0), height: 1),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Compact Lottie Celebration Illustration (Reduced from 280 down to 125)
            Center(
              child: SizedBox(
                height: 125,
                child: Lottie.asset(
                  'assets/animations/quiz_success.json',
                  fit: BoxFit.contain,
                  repeat: true,
                ),
              ),
            ),
            const SizedBox(height: 6),

            // 2. Encouraging Title & Subtitle
            Center(
              child: Column(
                children: [
                  Text(
                    _correctCount >= (questions.length * 0.8)
                        ? '🎯 Outstanding Performance!'
                        : (_correctCount >= (questions.length * 0.5)
                            ? '⚡ Impressive Effort, Keep Going!'
                            : '📚 Practice Makes Perfect!'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF2563EB),
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Performance Summary & Overview',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 3. Modern 3D Score & Metric Overview Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE2E8F0), width: 1.4),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF94A3B8).withOpacity(0.22),
                    offset: const Offset(0, 3.5),
                    blurRadius: 0,
                  ),
                  BoxShadow(
                    color: const Color(0xFF0F172A).withOpacity(0.04),
                    offset: const Offset(0, 1),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Score Pill
                  AnimatedBuilder(
                    animation: _scoreAnim,
                    builder: (context, _) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0FDF4),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFF86EFAC), width: 1.2),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.stars_rounded, color: Color(0xFF16A34A), size: 20),
                                const SizedBox(width: 6),
                                Text(
                                  'Score: ${_scoreAnim.value.toInt()}/${totalMarks.toInt()}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF15803D),
                                    letterSpacing: -0.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 12),

                  // 3 Stat Chips in Row
                  Row(
                    children: [
                      // Total Questions
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFBFDBFE), width: 1),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF93C5FD).withOpacity(0.35),
                                offset: const Offset(0, 2),
                                blurRadius: 0,
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Text(
                                '${questions.length}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF2563EB),
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'All Questions',
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
                      const SizedBox(width: 8),

                      // Correct
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFBBF7D0), width: 1),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF86EFAC).withOpacity(0.35),
                                offset: const Offset(0, 2),
                                blurRadius: 0,
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Text(
                                '$_correctCount',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF16A34A),
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Right Answers',
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
                      const SizedBox(width: 8),

                      // Incorrect
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF1F2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFFECDD3), width: 1),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFDA4AF).withOpacity(0.35),
                                offset: const Offset(0, 2),
                                blurRadius: 0,
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Text(
                                '$_wrongCount',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFFE11D48),
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Incorrect',
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
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 4. Compact 3D Action Buttons Side-by-Side
            Row(
              children: [
                // Retake Button
                Expanded(
                  child: InkWell(
                    onTap: () {
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
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      height: 46,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0xFF1D4ED8),
                            offset: Offset(0, 3),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.refresh_rounded, size: 18, color: Colors.white),
                          SizedBox(width: 6),
                          Text(
                            'Retake Test',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Return to Topics Button
                Expanded(
                  child: InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      height: 46,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFCBD5E1), width: 1.2),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF94A3B8).withOpacity(0.35),
                            offset: const Offset(0, 2.5),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.arrow_back_rounded, size: 18, color: Color(0xFF475569)),
                          SizedBox(width: 6),
                          Text(
                            'Return Topics',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF475569),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 5. Answer Breakdown Section Header (Now immediately visible on viewport!)
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: const Icon(Icons.fact_check_rounded, color: Color(0xFF2563EB), size: 18),
                ),
                const SizedBox(width: 10),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Answer Sheet & Solutions',
                      style: TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.2,
                      ),
                    ),
                    Text(
                      'Review correct answers and step-by-step solutions below.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 6. Question Review Cards with 3D Design
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
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFCBD5E1).withOpacity(0.5),
                        blurRadius: 0,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Question Number, Status Capsule & 3-Dots Menu
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Status Capsule Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isCorrect
                                  ? const Color(0xFFDCFCE7)
                                  : (userAns == null ? const Color(0xFFF1F5F9) : const Color(0xFFFFE4E6)),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isCorrect
                                    ? const Color(0xFF86EFAC)
                                    : (userAns == null ? const Color(0xFFCBD5E1) : const Color(0xFFFDA4AF)),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isCorrect
                                      ? Icons.check_circle_rounded
                                      : (userAns == null ? Icons.help_outline_rounded : Icons.cancel_rounded),
                                  size: 13,
                                  color: isCorrect
                                      ? const Color(0xFF16A34A)
                                      : (userAns == null ? const Color(0xFF64748B) : const Color(0xFFE11D48)),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isCorrect ? 'Correct' : (userAns == null ? 'Skipped' : 'Incorrect'),
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                    color: isCorrect
                                        ? const Color(0xFF16A34A)
                                        : (userAns == null ? const Color(0xFF64748B) : const Color(0xFFE11D48)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),

                          // Quick 1-Tap Bookmark Action Button
                          GestureDetector(
                            onTap: () => _toggleBookmark(
                              meta: meta,
                              q: q,
                              wasSaved: isSaved,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              child: Icon(
                                isSaved ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded,
                                size: 22,
                                color: isSaved ? AppColors.primary : const Color(0xFF94A3B8),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),

                          // 3-Dots Menu (Bookmark & Report)
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF64748B), size: 20),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            onSelected: (val) async {
                              if (val == 'bookmark') {
                                await _toggleBookmark(
                                  meta: meta,
                                  q: q,
                                  wasSaved: isSaved,
                                );
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
                      const SizedBox(height: 8),

                      // Question Text
                      Text(
                        '${index + 1}. ${q.questionText}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                          height: 1.4,
                        ),
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

                      const Divider(height: 20, thickness: 1, color: Color(0xFFF1F5F9)),

                      // Answers Display
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Your response
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Your Answer: ',
                                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                                ),
                                Expanded(
                                  child: Text(
                                    userAns != null ? '($userAns) ${q.options[userAns] ?? ''}' : 'Not Answered',
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.bold,
                                      color: userAns == null
                                          ? const Color(0xFF94A3B8)
                                          : (isCorrect ? const Color(0xFF16A34A) : const Color(0xFFE11D48)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),

                            // Correct answer
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Correct Answer: ',
                                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                                ),
                                Expanded(
                                  child: Text(
                                    '(${q.correctOption}) ${q.options[q.correctOption] ?? ''}',
                                    style: const TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF16A34A),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Explanation block
                      if (q.explanation.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFBFDBFE)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.lightbulb_outline_rounded, color: Color(0xFF2563EB), size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Explanation: ${q.explanation}',
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    color: Color(0xFF1E40AF),
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

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
