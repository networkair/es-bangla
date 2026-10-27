import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/storage/local_storage_service.dart';
import '../data/mock_test_repository.dart';
import '../domain/mock_test_models.dart';
import 'report_bottom_sheet.dart';
import 'result_screen.dart';

class QuizScreen extends StatefulWidget {
  final String subjectId;
  final String subjectName;
  final String topicId;
  final String topicName;
  final String setFile;
  final String version;

  const QuizScreen({
    super.key,
    required this.subjectId,
    required this.subjectName,
    required this.topicId,
    required this.topicName,
    required this.setFile,
    required this.version,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final MockTestRepository _repository = MockTestRepository();
  TestPaperModel? _testPaper;
  bool _isLoading = true;
  String? _error;

  int _currentIndex = 0;
  // Map of question index -> selected option ('A', 'B', 'C', 'D' or null)
  final Map<int, String> _userAnswers = {};

  @override
  void initState() {
    super.initState();
    _loadPaper();
  }

  Future<void> _loadPaper() async {
    final sem = LocalStorageService().semester;
    try {
      final paper = await _repository.getTestPaper(
        sem,
        widget.subjectId,
        widget.setFile,
        version: widget.version,
      );
      if (mounted) {
        setState(() {
          _testPaper = paper;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'প্রশ্নপত্র লোড করা সম্ভব হয়নি। ইন্টারনেট সংযোগ চেক করুন।';
          _isLoading = false;
        });
      }
    }
  }

  void _selectOption(String optionKey) {
    if (_userAnswers.containsKey(_currentIndex)) return; // Locked once answered
    setState(() {
      _userAnswers[_currentIndex] = optionKey;
    });
  }

  void _onNext() {
    if (_testPaper == null) return;
    if (_currentIndex < _testPaper!.questions.length - 1) {
      setState(() {
        _currentIndex++;
      });
    } else {
      _finishQuiz();
    }
  }

  void _finishQuiz() {
    if (_testPaper == null) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ResultScreen(
          testPaper: _testPaper!,
          userAnswers: _userAnswers,
        ),
      ),
    );
  }

  Future<bool> _onWillPop() async {
    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('পরীক্ষা বাতিল করবেন?'),
        content: const Text('এখন পরীক্ষা থেকে বেরিয়ে গেলে আপনার অগ্রগতি সংরক্ষিত হবে না। আপনি কি নিশ্চিত?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('না, পরীক্ষা দেব'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.wrongRed),
            child: const Text('বেরিয়ে যান', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    return shouldLeave ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final shouldLeave = await _onWillPop();
        if (shouldLeave && context.mounted) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(_testPaper?.metadata.title ?? widget.topicName),
          actions: [
            IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: () async {
                final shouldLeave = await _onWillPop();
                if (shouldLeave && context.mounted) {
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(AppColors.primary)),
      );
    }

    if (_error != null || _testPaper == null || _testPaper!.questions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.wrongRed),
              const SizedBox(height: 16),
              Text(_error ?? 'প্রশ্ন পাওয়া যায়নি', style: const TextStyle(fontSize: 15, color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() => _isLoading = true);
                  _loadPaper();
                },
                child: const Text('আবার চেষ্টা করুন'),
              ),
            ],
          ),
        ),
      );
    }

    final questions = _testPaper!.questions;
    final currentQ = questions[_currentIndex];
    final selectedOpt = _userAnswers[_currentIndex];
    final isAnswered = selectedOpt != null;
    final isLast = _currentIndex == questions.length - 1;
    final progress = (_currentIndex + 1) / questions.length;

    return Column(
      children: [
        // Progress Bar & Question Counter
        Container(
          color: AppColors.surface,
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'প্রশ্ন ${_currentIndex + 1} / ${questions.length}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primaryDark),
                  ),
                  Text(
                    '${(progress * 100).toInt()}% সম্পন্ন',
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: AppColors.surfaceMuted,
                  valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                ),
              ),
            ],
          ),
        ),

        // Scrollable Question Content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Question Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.Border.all(color: AppColors.border),
                    boxShadow: AppColors.softCardShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentQ.questionText,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                          height: 1.45,
                        ),
                      ),
                      if (currentQ.imageUrl.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            currentQ.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Options List A-D
                ...currentQ.options.entries.map((entry) {
                  final key = entry.key; // 'A', 'B', 'C', 'D'
                  final text = entry.value;

                  Color optionBg = AppColors.surface;
                  Color borderColor = AppColors.border;
                  Color textColor = AppColors.textPrimary;
                  Widget? statusIcon;

                  if (isAnswered) {
                    if (key == currentQ.correctOption) {
                      optionBg = AppColors.correctLight;
                      borderColor = AppColors.correctGreen;
                      textColor = AppColors.correctGreen;
                      statusIcon = const Icon(Icons.check_circle_rounded, color: AppColors.correctGreen, size: 20);
                    } else if (key == selectedOpt) {
                      optionBg = AppColors.wrongLight;
                      borderColor = AppColors.wrongRed;
                      textColor = AppColors.wrongRed;
                      statusIcon = const Icon(Icons.cancel_rounded, color: AppColors.wrongRed, size: 20);
                    }
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      onTap: () => _selectOption(key),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: optionBg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.Border.all(color: borderColor, width: isAnswered && (key == currentQ.correctOption || key == selectedOpt) ? 1.5 : 1),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: isAnswered && key == currentQ.correctOption
                                    ? AppColors.correctGreen.withOpacity(0.15)
                                    : AppColors.primaryLight,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  key,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: isAnswered && key == currentQ.correctOption
                                        ? AppColors.correctGreen
                                        : AppColors.primaryDark,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                text,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: textColor,
                                ),
                              ),
                            ),
                            if (statusIcon != null) statusIcon,
                          ],
                        ),
                      ),
                    ),
                  );
                }),

                // Explanation Block (if answered and present)
                if (isAnswered && currentQ.explanation.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.Border.all(color: AppColors.primary.withOpacity(0.2)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'ব্যাখ্যা: ${currentQ.explanation}',
                            style: const TextStyle(fontSize: 13, color: AppColors.primaryDark, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        // Bottom Actions: Report Question & Next Question
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: const Border(top: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    builder: (_) => ReportBottomSheet(
                      question: currentQ,
                      metadata: _testPaper!.metadata,
                      questionIndex: _currentIndex,
                      selectedOption: selectedOpt,
                    ),
                  );
                },
                icon: const Icon(Icons.flag_outlined, size: 18),
                label: const Text('রিপোর্ট'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(100, 48),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _onNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isLast ? AppColors.correctGreen : AppColors.primary,
                  ),
                  child: Text(
                    isLast ? 'পরীক্ষা সম্পন্ন করুন' : (isAnswered ? 'পরবর্তী প্রশ্ন' : 'পরবর্তী (স্কিপ)'),
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
