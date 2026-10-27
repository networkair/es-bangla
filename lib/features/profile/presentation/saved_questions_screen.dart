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
  String? _selectedSubjectId;

  @override
  void initState() {
    super.initState();
    _loadSaved();
  }

  void _loadSaved() {
    final list = _storage.getSavedQuestions();
    setState(() {
      _saved = list;
    });
  }

  Future<void> _removeSaved(Map<String, dynamic> q) async {
    await _storage.toggleSaveQuestion(q);
    _loadSaved();
  }

  @override
  Widget build(BuildContext context) {
    // Unique subjects
    final subjects = _saved.map((e) => e['subject_name']?.toString() ?? 'অন্যান্য').toSet().toList();
    final filtered = _selectedSubjectId == null
        ? _saved
        : _saved.where((e) => (e['subject_name'] ?? 'অন্যান্য') == _selectedSubjectId).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('সংরক্ষিত প্রশ্নাবলি (Saved Questions)'),
      ),
      body: _saved.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.bookmark_border_rounded, size: 36, color: AppColors.primary),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'কোনো প্রশ্ন সেভ করা নেই',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'পরীক্ষার ফলাফল পাতা থেকে গুরুত্বপূর্ণ প্রশ্ন বুকমার্ক করে রাখুন।',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                if (subjects.length > 1)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        FilterChip(
                          label: const Text('সকল বিষয়'),
                          selected: _selectedSubjectId == null,
                          onSelected: (_) => setState(() => _selectedSubjectId = null),
                        ),
                        const SizedBox(width: 8),
                        ...subjects.map((subj) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(subj),
                              selected: _selectedSubjectId == subj,
                              onSelected: (_) => setState(() => _selectedSubjectId = subj),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final q = filtered[index];
                      final correct = q['correct_option'] ?? 'A';
                      final options = Map<String, dynamic>.from(q['options'] ?? {});

                      return Dismissible(
                        key: Key('${q['test_id']}_${q['q_id']}'),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          decoration: BoxDecoration(
                            color: AppColors.wrongRed,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
                        ),
                        onDismissed: (_) => _removeSaved(q),
                        child: Card(
                          margin: const EdgeInsets.only(bottom: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: const BorderSide(color: AppColors.border),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryLight,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '${q['subject_name'] ?? ''} • ${q['topic_name'] ?? ''}',
                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                                      ),
                                    ),
                                    IconButton(
                                      constraints: const BoxConstraints(),
                                      padding: EdgeInsets.zero,
                                      icon: const Icon(Icons.bookmark_rounded, color: AppColors.primary, size: 22),
                                      onPressed: () => _removeSaved(q),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  q['question_text'] ?? '',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
                                ),
                                const SizedBox(height: 10),
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppColors.correctLight,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.check_circle_rounded, color: AppColors.correctGreen, size: 18),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'সঠিক উত্তর: $correct (${options[correct] ?? ''})',
                                          style: const TextStyle(
                                            color: AppColors.correctGreen,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (q['explanation'] != null && q['explanation'].toString().isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    'ব্যাখ্যা: ${q['explanation']}',
                                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
