import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/storage/local_storage_service.dart';
import '../../../core/services/quiz_audio_service.dart';
import '../data/mock_test_repository.dart';
import '../domain/mock_test_models.dart';
import 'report_bottom_sheet.dart';
import 'result_screen.dart';
import '../../../core/widgets/app_shimmer.dart';

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
  // Map of question index -> selected option ('A', 'B', 'C', 'D')
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
          _error = 'Failed to load question paper. Please check internet connection.';
          _isLoading = false;
        });
      }
    }
  }

  void _selectOption(String optionKey) {
    if (_userAnswers.containsKey(_currentIndex)) return; // Locked once answered

    final currentQ = _testPaper!.questions[_currentIndex];
    final isCorrect = optionKey == currentQ.correctOption;

    // Play native buzzer sound effect immediately on tap (zero latency)
    if (isCorrect) {
      QuizAudioService.playCorrectSound();
    } else {
      QuizAudioService.playWrongSound();
    }

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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Exit Mock Test?',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: const Text(
          'Are you sure you want to exit? Your current test progress will be lost.',
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Stay', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.wrongRed,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Exit Test', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
        body: SafeArea(
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            AppShimmer.box(width: double.infinity, height: 48, borderRadius: 12),
            const SizedBox(height: 16),
            AppShimmer.box(width: double.infinity, height: 120, borderRadius: 16),
            const SizedBox(height: 20),
            ...List.generate(
              4,
              (index) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AppShimmer.box(width: double.infinity, height: 56, borderRadius: 12),
              ),
            ),
          ],
        ),
      );
    }

    if (_error != null || _testPaper == null || _testPaper!.questions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off_rounded, size: 52, color: AppColors.wrongRed),
              const SizedBox(height: 16),
              Text(
                _error ?? 'No questions found.',
                style: const TextStyle(fontSize: 15, color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() => _isLoading = true);
                  _loadPaper();
                },
                child: const Text('Try Again'),
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

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      builder: (context, animVal, child) {
        return Opacity(
          opacity: animVal,
          child: Transform.translate(
            offset: Offset(0, 16 * (1 - animVal)),
            child: child,
          ),
        );
      },
      child: Column(
        children: [
          // 1. Clean Top Header: Only sleek Back Button at top-left (no title, no cross, no percentage text)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
            child: Row(
              children: [
                InkWell(
                  onTap: () async {
                    final shouldLeave = await _onWillPop();
                    if (shouldLeave && context.mounted) {
                      Navigator.pop(context);
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                      boxShadow: AppColors.softCardShadow,
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 16,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. Animated Smooth Linear Progress Bar (Smoothly animates forward as user progresses)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.0, end: progress),
                duration: const Duration(milliseconds: 380),
                curve: Curves.easeInOutCubic,
                builder: (context, val, _) {
                  return LinearProgressIndicator(
                    value: val,
                    minHeight: 6,
                    backgroundColor: AppColors.border.withOpacity(0.5),
                    valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                  );
                },
              ),
            ),
          ),

          const SizedBox(height: 8),

          // 3. Question & Options Content with Smooth Advanced Transitions
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (Widget child, Animation<double> animation) {
                final slideAnimation = Tween<Offset>(
                  begin: const Offset(0.12, 0.0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));

                return FadeTransition(
                  opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
                  child: SlideTransition(
                    position: slideAnimation,
                    child: child,
                  ),
                );
              },
            child: SingleChildScrollView(
              key: ValueKey<int>(_currentIndex),
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Modern Question Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: AppColors.border.withOpacity(0.8)),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0F172A).withOpacity(0.04),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentQ.questionText,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                            height: 1.45,
                            letterSpacing: -0.2,
                          ),
                        ),
                        if (currentQ.imageUrl.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
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

                  const SizedBox(height: 18),

                  // Options A, B, C, D
                  ...currentQ.options.entries.map((entry) {
                    final key = entry.key; // 'A', 'B', 'C', 'D'
                    final text = entry.value;

                    Color optionBg = AppColors.surface;
                    Color borderColor = AppColors.border.withOpacity(0.8);
                    Color textColor = AppColors.textPrimary;
                    Widget? statusIcon;

                    if (isAnswered) {
                      if (key == currentQ.correctOption) {
                        optionBg = AppColors.correctLight;
                        borderColor = AppColors.correctGreen;
                        textColor = const Color(0xFF047857);
                        statusIcon = const Icon(Icons.check_circle_rounded, color: AppColors.correctGreen, size: 22);
                      } else if (key == selectedOpt) {
                        optionBg = AppColors.wrongLight;
                        borderColor = AppColors.wrongRed;
                        textColor = AppColors.wrongRed;
                        statusIcon = const Icon(Icons.cancel_rounded, color: AppColors.wrongRed, size: 22);
                      }
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        onTap: () => _selectOption(key),
                        borderRadius: BorderRadius.circular(16),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: optionBg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: borderColor,
                              width: isAnswered && (key == currentQ.correctOption || key == selectedOpt) ? 1.8 : 1.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0F172A).withOpacity(0.02),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: isAnswered && key == currentQ.correctOption
                                      ? AppColors.correctGreen.withOpacity(0.18)
                                      : (isAnswered && key == selectedOpt
                                          ? AppColors.wrongRed.withOpacity(0.18)
                                          : AppColors.primaryLight),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    key,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: isAnswered && key == currentQ.correctOption
                                          ? const Color(0xFF047857)
                                          : (isAnswered && key == selectedOpt
                                              ? AppColors.wrongRed
                                              : AppColors.primaryDark),
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
                                    fontWeight: FontWeight.w600,
                                    color: textColor,
                                    height: 1.3,
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

                  // Explanation (English label)
                  if (isAnswered && currentQ.explanation.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Explanation: ${currentQ.explanation}',
                              style: const TextStyle(
                                fontSize: 13.5,
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
            ),
          ),
        ),

        // 4. Bottom Action Bar: Report Button & Next Button (Disabled until an option is selected!)
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.border.withOpacity(0.7))),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Report Button in English
              OutlinedButton.icon(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                label: const Text('Report', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(100, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  side: BorderSide(color: AppColors.border),
                ),
              ),
              const SizedBox(width: 12),

              // Next Button in English (Disabled until answered!)
              Expanded(
                child: ElevatedButton(
                  onPressed: isAnswered ? _onNext : null,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                    backgroundColor: isLast ? AppColors.correctGreen : AppColors.primary,
                    disabledBackgroundColor: AppColors.border,
                    disabledForegroundColor: AppColors.textMuted,
                    elevation: isAnswered ? 2 : 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    isLast ? 'Submit Test' : 'Next',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isAnswered ? Colors.white : AppColors.textMuted,
                    ),
                  ),
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
