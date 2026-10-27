import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/storage/local_storage_service.dart';
import '../data/content_manifest_repository.dart';
import 'secure_pdf_viewer_screen.dart';

class PyqScreen extends StatefulWidget {
  const PyqScreen({super.key});

  @override
  State<PyqScreen> createState() => _PyqScreenState();
}

class _PyqScreenState extends State<PyqScreen> {
  final ContentManifestRepository _repo = ContentManifestRepository();
  int _selectedSemester = LocalStorageService().semester;
  List<PyqSubject> _pyqSubjects = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPyqs();
  }

  Future<void> _loadPyqs() async {
    setState(() => _isLoading = true);
    final list = await _repo.getPyqForSemester(_selectedSemester);
    if (mounted) {
      setState(() {
        _pyqSubjects = list;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Previous Year Questions'),
      ),
      body: Column(
        children: [
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: _buildSemSelector(3, 'Semester 3 (সেমিস্টার ৩)'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSemSelector(4, 'Semester 4 (সেমিস্টার ৪)'),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(AppColors.primary)))
                : _pyqSubjects.isEmpty
                    ? const Center(child: Text('কোনো প্রশ্নপত্র পাওয়া যায়নি'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _pyqSubjects.length,
                        itemBuilder: (context, index) {
                          final subject = _pyqSubjects[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: const BorderSide(color: AppColors.border),
                            ),
                            child: ExpansionTile(
                              initiallyExpanded: index == 0,
                              leading: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.history_edu_rounded, color: AppColors.primary),
                              ),
                              title: Text(
                                subject.subjectName,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              children: subject.papers.map((paper) {
                                return ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                                  leading: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceMuted,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: AppColors.border),
                                    ),
                                    child: Text(
                                      paper.year,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primaryDark),
                                    ),
                                  ),
                                  title: Text(paper.title, style: const TextStyle(fontSize: 14)),
                                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMuted),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => SecurePdfViewerScreen(
                                          title: paper.title,
                                          assetPath: paper.filePath,
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
          ),
        ],
      ),
    );
  }

  Widget _buildSemSelector(int sem, String label) {
    final isSelected = _selectedSemester == sem;
    return GestureDetector(
      onTap: () {
        if (_selectedSemester != sem) {
          setState(() => _selectedSemester = sem);
          _loadPyqs();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryLight : AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? AppColors.primaryDark : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
