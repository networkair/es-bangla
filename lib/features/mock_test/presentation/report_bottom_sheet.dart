import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/storage/local_storage_service.dart';
import '../data/mock_test_repository.dart';
import '../domain/mock_test_models.dart';

class ReportBottomSheet extends StatefulWidget {
  final QuestionModel question;
  final TestMetadataModel metadata;
  final int questionIndex;
  final String? selectedOption;

  const ReportBottomSheet({
    super.key,
    required this.question,
    required this.metadata,
    required this.questionIndex,
    this.selectedOption,
  });

  @override
  State<ReportBottomSheet> createState() => _ReportBottomSheetState();
}

class _ReportBottomSheetState extends State<ReportBottomSheet> {
  final TextEditingController _messageController = TextEditingController();
  final MockTestRepository _repository = MockTestRepository();

  String _selectedType = 'wrong_question';
  bool _isSending = false;
  String? _statusMessage;
  bool _isSuccess = false;

  final Map<String, String> _typeLabels = {
    'wrong_question': '🚩 Incorrect Question / Options',
    'feedback': '💡 Feedback / Suggestion',
    'bug': '🐛 App / Quiz Bug',
    'other': '📝 Other Issue',
  };

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  int _getWordCount(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return 0;
    return trimmed.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
  }

  Future<void> _submitReport() async {
    final message = _messageController.text.trim();
    final wordCount = _getWordCount(message);
    if (wordCount > 100) {
      setState(() => _statusMessage = 'Your observation exceeds the 100-word limit ($wordCount/100 words). Please shorten your message.');
      return;
    }
    if (message.isEmpty && _selectedType != 'wrong_question') {
      setState(() => _statusMessage = 'Please enter a brief message or observation.');
      return;
    }

    setState(() {
      _isSending = true;
      _statusMessage = null;
    });

    final storage = LocalStorageService();
    final name = storage.userName;
    final email = storage.userEmail;

    final contextStr =
        'Class ${widget.metadata.className} | Semester ${widget.metadata.semester} | ${widget.metadata.subjectName} | ${widget.metadata.topicName} | Set ${widget.metadata.setNumber} | Q${widget.questionIndex + 1} (${widget.question.qId})';

    final meta = {
      'test_title': '${widget.metadata.subjectName} - ${widget.metadata.topicName} (Set ${widget.metadata.setNumber})',
      'question_id': widget.question.qId,
      'question_text': widget.question.questionText,
      'correct_answer_id': widget.question.correctOption,
      'selected_option': widget.selectedOption ?? 'unanswered',
      'options': widget.question.options.entries
          .map((e) => {'id': e.key, 'text': e.value})
          .toList(),
      'explanation': widget.question.explanation,
      'class': widget.metadata.className,
      'semester': widget.metadata.semester,
      'subject_id': widget.metadata.subjectId,
      'subject_name': widget.metadata.subjectName,
      'topic_id': widget.metadata.topicId,
      'topic_name': widget.metadata.topicName,
      'test_id': widget.metadata.testId,
      'set_file': widget.metadata.setFile,
      'q_id': widget.question.qId,
      'q_number': widget.questionIndex + 1,
      'question': {
        'text': widget.question.questionText,
        'options': widget.question.options,
        'correct_option': widget.question.correctOption,
        'selected_option': widget.selectedOption ?? 'unanswered',
      },
      'app_version': '1.1.7',
    };

    final finalMessage = message.isNotEmpty
        ? message
        : 'Auto-reported: Question ${widget.questionIndex + 1} flagged as incorrect.';

    final success = await _repository.sendReport(
      type: _selectedType,
      name: name,
      email: email,
      message: finalMessage,
      contextSummary: contextStr,
      meta: meta,
    );

    if (mounted) {
      setState(() {
        _isSending = false;
        _isSuccess = success;
        _statusMessage = success
            ? 'Thank you! Your report has been submitted to the admin.'
            : 'Could not send report right now. Please try again.';
      });

      if (success) {
        Future.delayed(const Duration(milliseconds: 1600), () {
          if (mounted) Navigator.pop(context, true);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Report an Issue',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Dropdown for report type (in English)
          DropdownButtonFormField<String>(
            value: _selectedType,
            decoration: InputDecoration(
              labelText: 'Issue Type',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            items: _typeLabels.entries.map((entry) {
              return DropdownMenuItem(value: entry.key, child: Text(entry.value));
            }).toList(),
            onChanged: (val) {
              if (val != null) setState(() => _selectedType = val);
            },
          ),
          const SizedBox(height: 14),

          // Auto-attached Question Box (Appears automatically for 'wrong_question')
          if (_selectedType == 'wrong_question') ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.auto_awesome_rounded, size: 14, color: AppColors.primary),
                      const SizedBox(width: 6),
                      const Text(
                        'Auto-attached Question Details:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Q: ${widget.question.questionText}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ...widget.question.options.entries.map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      '${e.key}) ${e.value}',
                      style: TextStyle(
                        fontSize: 12,
                        color: e.key == widget.selectedOption
                            ? AppColors.primaryDark
                            : AppColors.textSecondary,
                        fontWeight: e.key == widget.selectedOption
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  )),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          // Feedback text box
          TextField(
            controller: _messageController,
            maxLines: 3,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'Your Feedback / Comment (Optional)',
              hintText: 'Tell us what is wrong or needs correction...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.all(14),
            ),
          ),
          const SizedBox(height: 6),
          Builder(
            builder: (context) {
              final words = _getWordCount(_messageController.text);
              final isOver = words > 100;
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Maximum 100 words allowed',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary.withOpacity(0.8),
                    ),
                  ),
                  Text(
                    '$words / 100 words',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: isOver ? AppColors.wrongRed : (words >= 80 ? Colors.orange : AppColors.textSecondary),
                    ),
                  ),
                ],
              );
            },
          ),

          if (_statusMessage != null) ...[
            const SizedBox(height: 10),
            Text(
              _statusMessage!,
              style: TextStyle(
                color: _isSuccess ? AppColors.correctGreen : AppColors.wrongRed,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],

          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _isSending || _isSuccess ? null : _submitReport,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isSending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text(
                      'Submit Report',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
