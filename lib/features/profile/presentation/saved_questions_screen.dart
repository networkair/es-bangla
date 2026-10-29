import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/storage/local_storage_service.dart';

class SavedQuestionsScreen extends StatefulWidget {
  const SavedQuestionsScreen({super.key});

  @override
  State<SavedQuestionsScreen> createState() => _SavedQuestionsScreenState();
}

class _SavedQuestionsScreenState extends State<SavedQuestionsScreen> {
  final LocalStorageService _storage = LocalStorageService();
  List<Map<String, dynamic>> _saved = [];

  @override
  void initState() {
    super.initState();
    _loadSaved();
  }

  void _loadSaved() {
    final list = _storage.getSavedQuestions();
    if (mounted) {
      setState(() {
        _saved = list;
      });
    }
  }

  // Helper to get visually distinct theme color for subjects
  Color _getSubjectColor(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('বাংলা') || lower.contains('bengali')) return const Color(0xFF2563EB); // Royal Blue
    if (lower.contains('ইংরেজী') || lower.contains('ইংরেজি') || lower.contains('english')) return const Color(0xFF7C3AED); // Purple
    if (lower.contains('ইতিহাস') || lower.contains('history')) return const Color(0xFFD97706); // Amber
    if (lower.contains('ভূগোল') || lower.contains('geography')) return const Color(0xFF059669); // Emerald
    if (lower.contains('শিক্ষা') || lower.contains('education')) return const Color(0xFFE11D48); // Rose
    if (lower.contains('রাষ্ট্র') || lower.contains('pol')) return const Color(0xFF0891B2); // Cyan
    if (lower.contains('দর্শন') || lower.contains('philosophy')) return const Color(0xFFEA580C); // Orange
    return AppColors.primary;
  }

  IconData _getSubjectIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('বাংলা') || lower.contains('bengali')) return Icons.menu_book_rounded;
    if (lower.contains('ইংরেজি') || lower.contains('english')) return Icons.translate_rounded;
    if (lower.contains('ইতিহাস') || lower.contains('history')) return Icons.account_balance_rounded;
    if (lower.contains('ভূগোল') || lower.contains('geography')) return Icons.public_rounded;
    if (lower.contains('শিক্ষা') || lower.contains('education')) return Icons.school_rounded;
    if (lower.contains('রাষ্ট্র') || lower.contains('pol')) return Icons.policy_rounded;
    if (lower.contains('দর্শন') || lower.contains('philosophy')) return Icons.psychology_rounded;
    return Icons.auto_stories_rounded;
  }

  @override
  Widget build(BuildContext context) {
    // Group questions by subject_name
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (var q in _saved) {
      final sName = (q['subject_name']?.toString().trim().isNotEmpty == true)
          ? q['subject_name'].toString()
          : 'General Subjects';
      grouped.putIfAbsent(sName, () => []).add(q);
    }

    final subjectsList = grouped.keys.toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _saved.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(28.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 86,
                      height: 86,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2563EB).withOpacity(0.12),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.bookmark_outline_rounded, size: 42, color: Color(0xFF2563EB)),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'No Bookmarked Questions Yet',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Bookmark challenging questions from your mock tests or result reviews to organize and study them here by subject.',
                      style: TextStyle(fontSize: 13.5, color: Color(0xFF64748B), height: 1.45),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  const Text(
                    'Select Subject to Review',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 3D Subject Cards List
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: subjectsList.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      final subjectName = subjectsList[index];
                      final questions = grouped[subjectName] ?? [];
                      final subjectColor = _getSubjectColor(subjectName);
                      final iconData = _getSubjectIcon(subjectName);

                      return InkWell(
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SubjectSavedQuestionsScreen(
                                subjectName: subjectName,
                                initialQuestions: questions,
                                subjectColor: subjectColor,
                              ),
                            ),
                          );
                          _loadSaved();
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                            boxShadow: [
                              BoxShadow(
                                color: subjectColor.withOpacity(0.08),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                              BoxShadow(
                                color: const Color(0xFF0F172A).withOpacity(0.03),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              // 3D Subject Icon Pill
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      subjectColor.withOpacity(0.16),
                                      subjectColor.withOpacity(0.08),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: subjectColor.withOpacity(0.25), width: 1),
                                ),
                                child: Icon(iconData, color: subjectColor, size: 26),
                              ),
                              const SizedBox(width: 14),

                              // Subject Title & Count
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      subjectName,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: subjectColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '${questions.length} ${questions.length == 1 ? 'Question' : 'Questions'} Available',
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.bold,
                                          color: subjectColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Action Chevron
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF64748B)),
                              ),
                            ],
                          ),
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

/// Detailed Screen showing all Saved Questions of a Single Subject
class SubjectSavedQuestionsScreen extends StatefulWidget {
  final String subjectName;
  final List<Map<String, dynamic>> initialQuestions;
  final Color subjectColor;

  const SubjectSavedQuestionsScreen({
    super.key,
    required this.subjectName,
    required this.initialQuestions,
    required this.subjectColor,
  });

  @override
  State<SubjectSavedQuestionsScreen> createState() => _SubjectSavedQuestionsScreenState();
}

class _SubjectSavedQuestionsScreenState extends State<SubjectSavedQuestionsScreen> {
  final LocalStorageService _storage = LocalStorageService();
  late List<Map<String, dynamic>> _questions;

  @override
  void initState() {
    super.initState();
    _questions = List.from(widget.initialQuestions);
  }

  Future<void> _removeQuestion(Map<String, dynamic> q, int index) async {
    await _storage.toggleSaveQuestion(q);
    setState(() {
      _questions.removeAt(index);
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Bookmark removed successfully'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          action: SnackBarAction(
            label: 'Undo',
            textColor: Colors.amberAccent,
            onPressed: () async {
              await _storage.toggleSaveQuestion(q);
              setState(() {
                _questions.insert(index, q);
              });
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.subjectName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
            Text(
              '${_questions.length} Saved Questions',
              style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _questions.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.bookmark_remove_rounded, size: 48, color: Color(0xFF94A3B8)),
                  const SizedBox(height: 14),
                  const Text(
                    'All bookmarks in this subject cleared',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.subjectColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Return to Vault'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              itemCount: _questions.length,
              itemBuilder: (context, index) {
                final q = _questions[index];
                final correct = q['correct_option']?.toString().toUpperCase() ?? 'A';
                final options = Map<String, dynamic>.from(q['options'] ?? {});
                final topic = q['topic_name']?.toString() ?? '';
                final setTitle = q['set_title']?.toString() ?? '';

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0F172A).withOpacity(0.04),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                      BoxShadow(
                        color: const Color(0xFF0F172A).withOpacity(0.02),
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: Tag & Remove Bookmark Button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: widget.subjectColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Question #${index + 1}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: widget.subjectColor,
                                    ),
                                  ),
                                ),
                                if (topic.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      topic,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF475569),
                                      ),
                                    ),
                                  ),
                                if (setTitle.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      setTitle,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF475569),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          IconButton(
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.all(4),
                            icon: const Icon(Icons.bookmark_remove_rounded, color: Color(0xFFE11D48), size: 22),
                            tooltip: 'Remove Bookmark',
                            onPressed: () => _removeQuestion(q, index),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Question Text
                      Text(
                        q['question_text'] ?? '',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15.5,
                          color: Color(0xFF0F172A),
                          height: 1.45,
                        ),
                      ),

                      if (q['image_url'] != null && q['image_url'].toString().isNotEmpty) ...[
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            q['image_url'],
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                          ),
                        ),
                      ],

                      const SizedBox(height: 12),

                      // Correct Answer Pill Box
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFBBF7D0), width: 1),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: RichText(
                                text: TextSpan(
                                  style: const TextStyle(fontSize: 13, fontFamily: 'NotoSerifBengali'),
                                  children: [
                                    const TextSpan(
                                      text: 'Correct Solution: ',
                                      style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF15803D)),
                                    ),
                                    TextSpan(
                                      text: '($correct) ${options[correct] ?? ''}',
                                      style: const TextStyle(
                                        color: Color(0xFF166534),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Explanation block
                      if (q['explanation'] != null && q['explanation'].toString().trim().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.lightbulb_outline_rounded, color: Color(0xFF3B82F6), size: 16),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Explanation: ${q['explanation']}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF475569),
                                    height: 1.4,
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
    );
  }
}
