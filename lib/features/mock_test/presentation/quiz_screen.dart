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

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      builder: (context, animVal, child) {
        return Opacity(
          opacity: animVal,
          child: Transform.translate(
            offset: Offset(0, 12 * (1 - animVal)),
            child: child,
          ),
        );
      },
      child: Column(
        children: [
          // 1. Sleek Top Header: Back button + Question counter badge
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0F172A).withOpacity(0.04),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 16,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFBFDBFE), width: 1),
                  ),
                  child: Text(
                    'Question ${_currentIndex + 1} of ${questions.length}',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2563EB),
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. Segmented Capsule Progress Bar ("কাটা কাটা লোডিং বার")
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: List.generate(questions.length, (idx) {
                final userAns = _userAnswers[idx];
                final isAnswered = userAns != null;
                final isCurrent = idx == _currentIndex;

                Color capsuleColor;
                List<BoxShadow>? capsuleShadow;

                if (isAnswered) {
                  final isCorrect = userAns == questions[idx].correctOption;
                  if (isCorrect) {
                    capsuleColor = const Color(0xFF10B981); // Emerald green for correct
                    capsuleShadow = [
                      BoxShadow(
                        color: const Color(0xFF10B981).withOpacity(0.4),
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ];
                  } else {
                    capsuleColor = const Color(0xFFEF4444); // Red for incorrect
                    capsuleShadow = [
                      BoxShadow(
                        color: const Color(0xFFEF4444).withOpacity(0.4),
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ];
                  }
                } else if (isCurrent) {
                  capsuleColor = AppColors.primary;
                  capsuleShadow = [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.4),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ];
                } else {
                  capsuleColor = const Color(0xFFE2E8F0);
                  capsuleShadow = null;
                }

                return Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeOutCubic,
                    height: 5.5,
                    margin: EdgeInsets.only(right: idx == questions.length - 1 ? 0 : 3.5),
                    decoration: BoxDecoration(
                      color: capsuleColor,
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: capsuleShadow,
                    ),
                  ),
                );
              }),
            ),
          ),

          const SizedBox(height: 6),

          // 3. Question & Options Content with Dynamic In & Out Animation
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 320),
              reverseDuration: const Duration(milliseconds: 240),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              layoutBuilder: (currentChild, previousChildren) {
                return Stack(
                  alignment: Alignment.topCenter,
                  children: <Widget>[
                    ...previousChildren,
                    if (currentChild != null) currentChild,
                  ],
                );
              },
              transitionBuilder: (Widget child, Animation<double> animation) {
                // Determine whether child is entering (in) or leaving (out)
                final isIncoming = (child.key as ValueKey<int>?)?.value == _currentIndex;

                if (isIncoming) {
                  // IN-ANIMATION: Glides gracefully up from slightly below (Y: 0.08) with smooth Fade & Scale
                  final inSlide = Tween<Offset>(
                    begin: const Offset(0.0, 0.08),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ));

                  final inScale = Tween<double>(
                    begin: 0.96,
                    end: 1.0,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ));

                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: inSlide,
                      child: ScaleTransition(
                        scale: inScale,
                        child: child,
                      ),
                    ),
                  );
                } else {
                  // OUT-ANIMATION: Gracefully floats upward (Y: -0.06) while fading out
                  final outSlide = Tween<Offset>(
                    begin: const Offset(0.0, -0.06),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeInCubic,
                  ));

                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: outSlide,
                      child: child,
                    ),
                  );
                }
              },
              child: SingleChildScrollView(
                key: ValueKey<int>(_currentIndex),
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Modern 3D Question Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.4),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF94A3B8).withOpacity(0.25),
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentQ.questionText,
                            style: const TextStyle(
                              fontSize: 17.5,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                              height: 1.45,
                              letterSpacing: -0.2,
                            ),
                          ),
                          if (currentQ.imageUrl.isNotEmpty) ...[
                            const SizedBox(height: 14),
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

                    const SizedBox(height: 16),

                    // Modern 3D Option Cards (A, B, C, D)
                    ...currentQ.options.entries.map((entry) {
                      final key = entry.key; // 'A', 'B', 'C', 'D'
                      final text = entry.value;

                      Color optionBg = Colors.white;
                      Color borderColor = const Color(0xFFE2E8F0);
                      Color shadowColor = const Color(0xFFCBD5E1).withOpacity(0.6);
                      Color textColor = AppColors.textPrimary;
                      Widget? statusIcon;

                      if (isAnswered) {
                        if (key == currentQ.correctOption) {
                          optionBg = const Color(0xFFF0FDF4);
                          borderColor = const Color(0xFF10B981);
                          shadowColor = const Color(0xFF059669).withOpacity(0.45);
                          textColor = const Color(0xFF047857);
                          statusIcon = const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 22);
                        } else if (key == selectedOpt) {
                          optionBg = const Color(0xFFFEF2F2);
                          borderColor = const Color(0xFFEF4444);
                          shadowColor = const Color(0xFFDC2626).withOpacity(0.45);
                          textColor = const Color(0xFFB91C1C);
                          statusIcon = const Icon(Icons.cancel_rounded, color: Color(0xFFEF4444), size: 22);
                        }
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: InkWell(
                          onTap: () => _selectOption(key),
                          borderRadius: BorderRadius.circular(16),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: optionBg,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: borderColor,
                                width: isAnswered && (key == currentQ.correctOption || key == selectedOpt) ? 1.8 : 1.4,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: shadowColor,
                                  offset: const Offset(0, 3),
                                  blurRadius: 0,
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                // Circular 3D Letter Badge
                                Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    color: isAnswered && key == currentQ.correctOption
                                        ? const Color(0xFFDCFCE7)
                                        : (isAnswered && key == selectedOpt
                                            ? const Color(0xFFFEE2E2)
                                            : const Color(0xFFEFF6FF)),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isAnswered && key == currentQ.correctOption
                                          ? const Color(0xFF86EFAC)
                                          : (isAnswered && key == selectedOpt
                                              ? const Color(0xFFFCA5A5)
                                              : const Color(0xFFBFDBFE)),
                                      width: 1,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      key,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: isAnswered && key == currentQ.correctOption
                                            ? const Color(0xFF15803D)
                                            : (isAnswered && key == selectedOpt
                                                ? const Color(0xFFDC2626)
                                                : const Color(0xFF2563EB)),
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
                                      height: 1.35,
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

                    const SizedBox(height: 6),

                    // 3D Next Question / Submit Test Button (placed directly after options)
                    InkWell(
                      onTap: isAnswered ? _onNext : null,
                      borderRadius: BorderRadius.circular(16),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: double.infinity,
                        height: 50,
                        decoration: BoxDecoration(
                          color: isAnswered
                              ? (isLast ? const Color(0xFF16A34A) : AppColors.primary)
                              : const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: isAnswered ? [
                            BoxShadow(
                              color: isLast
                                  ? const Color(0xFF15803D)
                                  : const Color(0xFF1D4ED8),
                              offset: const Offset(0, 3.5),
                              blurRadius: 0,
                            ),
                          ] : null,
                        ),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                isLast ? 'Submit Test' : 'Next Question',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isAnswered ? Colors.white : const Color(0xFF64748B),
                                  letterSpacing: 0.2,
                                ),
                              ),
                              if (isAnswered) ...[
                                const SizedBox(width: 8),
                                Icon(
                                  isLast ? Icons.check_circle_outline_rounded : Icons.arrow_forward_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Report Button (placed directly below Next button)
                    Center(
                      child: TextButton.icon(
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
                        icon: const Icon(Icons.outlined_flag_rounded, size: 16, color: Color(0xFF64748B)),
                        label: const Text(
                          'Report Question',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ),

                    // Generous bottom whitespace reserved for future banner placement
                    const SizedBox(height: 60),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
