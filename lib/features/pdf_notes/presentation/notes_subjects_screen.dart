import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../data/content_manifest_repository.dart';
import 'secure_pdf_viewer_screen.dart';

class NotesSubjectsScreen extends StatefulWidget {
  final int semester;

  const NotesSubjectsScreen({super.key, required this.semester});

  @override
  State<NotesSubjectsScreen> createState() => _NotesSubjectsScreenState();
}

class _NotesSubjectsScreenState extends State<NotesSubjectsScreen> {
  final ContentManifestRepository _repo = ContentManifestRepository();
  List<NoteSubject> _subjects = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    final list = await _repo.getNotesForSemester(widget.semester);
    if (mounted) {
      setState(() {
        _subjects = list;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('সেমিস্টার ${widget.semester} - বুক নোটস'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(AppColors.primary)))
          : _subjects.isEmpty
              ? const Center(child: Text('কোনো নোটস পাওয়া যায়নি'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _subjects.length,
                  itemBuilder: (context, index) {
                    final subject = _subjects[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: AppColors.border),
                      ),
                      child: ExpansionTile(
                        leading: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.menu_book_rounded, color: AppColors.primary),
                        ),
                        title: Text(
                          subject.subjectName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        subtitle: Text(
                          '${subject.topics.length} টি অধ্যায় / নোটস',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        ),
                        children: subject.topics.map((topic) {
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                            leading: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.primary, size: 22),
                            title: Text(
                              topic.title,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                            ),
                            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMuted),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => SecurePdfViewerScreen(
                                    title: topic.title,
                                    assetPath: topic.filePath,
                                  ),
                                ),
                              );
                            },
                          );
                        }).toList(),
                      ),
                    );
                  },
                ),
    );
  }
}
