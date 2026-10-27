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
    'wrong_question': '🚩 ভুল প্রশ্ন রিপোর্ট',
    'feedback': '💡 মতামত',
    'bug': '🐛 বাগ রিপোর্ট',
    'other': '📝 অন্যান্য',
  };

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    final message = _messageController.text.trim();
    if (message.length < 5) {
      setState(() => _statusMessage = 'অনুগ্রহ করে ন্যূনতম ৫ অক্ষরের বিবরণ লিখুন।');
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
      'app_version': '1.0.0',
      'android_sdk': 34,
    };

    final success = await _repository.sendReport(
      type: _selectedType,
      name: name,
      email: email,
      message: message,
      contextSummary: contextStr,
      meta: meta,
    );

    if (mounted) {
      setState(() {
        _isSending = false;
        _isSuccess = success;
        _statusMessage = success
            ? 'ধন্যবাদ! আপনার রিপোর্টটি সফলভাবে অ্যাডমিনের কাছে পাঠানো হয়েছে।'
            : 'রিপোর্ট পাঠাতে ব্যর্থ হয়েছে। ইন্টারনেট সংযোগ দেখে পুনরায় চেষ্টা করুন।';
      });

      if (success) {
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) Navigator.pop(context, true);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
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
                'প্রশ্ন সংক্রান্ত রিপোর্ট',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _selectedType,
            decoration: const InputDecoration(labelText: 'রিপোর্টের ধরন'),
            items: _typeLabels.entries.map((entry) {
              return DropdownMenuItem(value: entry.key, child: Text(entry.value));
            }).toList(),
            onChanged: (val) {
              if (val != null) setState(() => _selectedType = val);
            },
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _messageController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'কী সমস্যা রয়েছে বিস্তারিত লিখুন (ন্যূনতম ৫ অক্ষর)...',
            ),
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
              child: _isSending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('রিপোর্ট পাঠান (Send)'),
            ),
          ),
        ],
      ),
    );
  }
}
