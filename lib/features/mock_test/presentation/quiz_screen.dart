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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFFCF8F4);

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
        backgroundColor: bgColor,
        body: SafeArea(
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textColor = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F1E36);
    final textMuted = isDark ? const Color(0xFF94A3B8) : const Color(0xFF5B6E85);

    if (_isLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: [
            AppShimmer.box(width: double.infinity, height: 42, borderRadius: 10),
            const SizedBox(height: 14),
            AppShimmer.box(width: double.infinity, height: 115, borderRadius: 18),
            const SizedBox(height: 14),
            ...List.generate(
              4,
              (index) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AppShimmer.box(width: double.infinity, height: 56, borderRadius: 16),
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
                style: TextStyle(fontSize: 15, color: textMuted),
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

    // 3D Shadow Palette matching Result Screen
    final card3DShadow = isDark
        ? const BoxShadow(
            color: Color(0xFF0F172A),
            offset: Offset(0, 3.5),
            blurRadius: 0,
          )
        : BoxShadow(
            color: const Color(0xFFCBD5E1).withOpacity(0.65),
            offset: const Offset(0, 3.5),
            blurRadius: 0,
          );

    return Column(
      children: [
        // 1. Sleek Compact Top Header: Compact Back button + Divider + Question counter pill badge
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              // Compact rounded square card with back arrow (clean 38x38)
              InkWell(
                onTap: () async {
                  final shouldLeave = await _onWillPop();
                  if (shouldLeave && context.mounted) {
                    Navigator.pop(context);
                  }
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: borderColor, width: 1.1),
                    boxShadow: [
                      BoxShadow(
                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFCBD5E1).withOpacity(0.5),
                        offset: const Offset(0, 2),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      Icons.arrow_back_rounded,
                      size: 20,
                      color: textColor,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Vertical Divider Line
              Container(
                width: 1.2,
                height: 22,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),

              const Spacer(),

              // Question Counter Pill Badge (Clean, compact & 3D subtle depth)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEBF5FF),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF3B82F6).withOpacity(0.4)
                        : const Color(0xFFB9E1FF),
                    width: 1.1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFBFDBFE).withOpacity(0.4),
                      offset: const Offset(0, 1.5),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: Text(
                  'Question ${_currentIndex + 1} of ${questions.length}',
                  style: const TextStyle(
                    fontSize: 12.8,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0066FF),
                    letterSpacing: 0.1,
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
              final isAns = userAns != null;
              final isCurrent = idx == _currentIndex;

              Color capsuleColor;
              if (isAns) {
                final isCorrect = userAns == questions[idx].correctOption;
                capsuleColor = isCorrect
                    ? const Color(0xFF10B981) // Emerald green
                    : const Color(0xFFEF4444); // Red
              } else if (isCurrent) {
                capsuleColor = const Color(0xFF0066FF); // Royal blue
              } else {
                capsuleColor = isDark
                    ? const Color(0xFF334155)
                    : const Color(0xFFD6E8FA); // Soft light sky blue
              }

              return Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  height: 5.0,
                  margin: EdgeInsets.only(
                    right: idx == questions.length - 1 ? 0 : 3.5,
                  ),
                  decoration: BoxDecoration(
                    color: capsuleColor,
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
              );
            }),
          ),
        ),

        const SizedBox(height: 8),

        // 3. Question & Options Content with Silky Smooth Directional Slide + Fade Transition
        Expanded(
          child: ClipRect(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 320),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              layoutBuilder: (currentChild, previousChildren) {
                return Stack(
                  alignment: Alignment.topCenter,
                  clipBehavior: Clip.hardEdge,
                  children: <Widget>[
                    ...previousChildren,
                    if (currentChild != null) currentChild,
                  ],
                );
              },
              transitionBuilder: (Widget child, Animation<double> animation) {
                final isCurrent = (child.key as ValueKey<int>?)?.value == _currentIndex;
                final slideAnimation = Tween<Offset>(
                  begin: isCurrent ? const Offset(0.12, 0.0) : const Offset(-0.12, 0.0),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: isCurrent ? Curves.easeOutCubic : Curves.easeInCubic,
                  ),
                );

                return SlideTransition(
                  position: slideAnimation,
                  child: FadeTransition(
                    opacity: animation,
                    child: child,
                  ),
                );
              },
              child: SingleChildScrollView(
                key: ValueKey<int>(_currentIndex),
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sleek 3D Question Card with Golden Accent Underline
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: borderColor, width: 1.2),
                        boxShadow: [
                          card3DShadow,
                          BoxShadow(
                            color: isDark ? Colors.transparent : const Color(0xFF0F172A).withOpacity(0.02),
                            offset: const Offset(0, 1),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentQ.questionText,
                            style: TextStyle(
                              fontSize: 17.5,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                              height: 1.42,
                              letterSpacing: -0.2,
                            ),
                          ),
                          // Golden yellow accent underline bar
                          Container(
                            margin: const EdgeInsets.only(top: 10),
                            width: 44,
                            height: 4,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF59E0B),
                              borderRadius: BorderRadius.circular(2),
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

                    const SizedBox(height: 14),

                    // Sleek 3D Option Cards (A, B, C, D)
                    ...currentQ.options.entries.map((entry) {
                      final key = entry.key; // 'A', 'B', 'C', 'D'
                      final text = entry.value;

                      Color optionBg = cardBg;
                      Color optBorderColor = borderColor;
                      Color optTextColor = textColor;
                      Color badgeBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFEBF5FF);
                      Color badgeBorderColor = isDark ? const Color(0xFF334155) : const Color(0xFFD4E9FD);
                      Color badgeTextColor = const Color(0xFF0066FF);
                      Color shadow3DColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFCBD5E1).withOpacity(0.55);
                      Widget? statusIcon;

                      if (isAnswered) {
                        if (key == currentQ.correctOption) {
                          optionBg = isDark ? const Color(0xFF064E3B).withOpacity(0.3) : const Color(0xFFF0FDF4);
                          optBorderColor = const Color(0xFF10B981);
                          optTextColor = isDark ? const Color(0xFF34D399) : const Color(0xFF047857);
                          badgeBg = const Color(0xFFDCFCE7);
                          badgeBorderColor = const Color(0xFF86EFAC);
                          badgeTextColor = const Color(0xFF15803D);
                          shadow3DColor = isDark ? const Color(0xFF065F46) : const Color(0xFF86EFAC);
                          statusIcon = const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 22);
                        } else if (key == selectedOpt) {
                          optionBg = isDark ? const Color(0xFF7F1D1D).withOpacity(0.3) : const Color(0xFFFEF2F2);
                          optBorderColor = const Color(0xFFEF4444);
                          optTextColor = isDark ? const Color(0xFFF87171) : const Color(0xFFB91C1C);
                          badgeBg = const Color(0xFFFEE2E2);
                          badgeBorderColor = const Color(0xFFFCA5A5);
                          badgeTextColor = const Color(0xFFDC2626);
                          shadow3DColor = isDark ? const Color(0xFF991B1B) : const Color(0xFFFCA5A5);
                          statusIcon = const Icon(Icons.cancel_rounded, color: Color(0xFFEF4444), size: 22);
                        }
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          onTap: () => _selectOption(key),
                          borderRadius: BorderRadius.circular(16),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13.5),
                            decoration: BoxDecoration(
                              color: optionBg,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: optBorderColor,
                                width: isAnswered && (key == currentQ.correctOption || key == selectedOpt) ? 1.6 : 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: shadow3DColor,
                                  blurRadius: 0,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                // Circular Letter Badge
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: badgeBg,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: badgeBorderColor,
                                      width: 1,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      key,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 15,
                                        color: badgeTextColor,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text(
                                    text,
                                    style: TextStyle(
                                      fontSize: 15.8,
                                      fontWeight: FontWeight.w600,
                                      color: optTextColor,
                                      height: 1.34,
                                    ),
                                  ),
                                ),
                                if (statusIcon != null) ...[
                                  const SizedBox(width: 8),
                                  statusIcon,
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    }),

                    const SizedBox(height: 12),

                    // Next Question / Submit Test Button with 3D tactile style
                    InkWell(
                      onTap: isAnswered ? _onNext : null,
                      borderRadius: BorderRadius.circular(16),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: double.infinity,
                        height: 52,
                        decoration: BoxDecoration(
                          color: isAnswered
                              ? (isLast ? const Color(0xFF16A34A) : const Color(0xFF0066FF))
                              : (isDark ? const Color(0xFF334155) : const Color(0xFFCAD7E5)),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: isAnswered
                                  ? (isLast
                                      ? (isDark ? const Color(0xFF14532D) : const Color(0xFF15803D))
                                      : (isDark ? const Color(0xFF1E40AF) : const Color(0xFF1D4ED8)))
                                  : (isDark ? const Color(0xFF1E293B) : const Color(0xFF94A3B8).withOpacity(0.4)),
                              offset: const Offset(0, 3.5),
                              blurRadius: 0,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                isLast ? 'Submit Test' : 'Next Question',
                                style: TextStyle(
                                  fontSize: 16.5,
                                  fontWeight: FontWeight.bold,
                                  color: isAnswered
                                      ? Colors.white
                                      : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF5B6E85)),
                                  letterSpacing: 0.1,
                                ),
                              ),
                              if (isAnswered) ...[
                                const SizedBox(width: 8),
                                Icon(
                                  isLast ? Icons.check_circle_outline_rounded : Icons.arrow_forward_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Report Question Action (placed directly below Next button)
                    Center(
                      child: InkWell(
                        onTap: () {
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
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.flag_outlined,
                                size: 17,
                                color: textMuted,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Report Question',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                  color: textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Reserved buffer space at bottom for future banner ad (50% remaining space)
                    const SizedBox(height: 72),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
