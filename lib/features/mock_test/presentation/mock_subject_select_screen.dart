import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/storage/local_storage_service.dart';
import '../data/mock_test_repository.dart';
import '../domain/mock_test_models.dart';
import 'mock_topics_sets_screen.dart';

class MockSubjectSelectScreen extends StatefulWidget {
  final bool isPremiumMode;

  const MockSubjectSelectScreen({super.key, required this.isPremiumMode});

  @override
  State<MockSubjectSelectScreen> createState() => _MockSubjectSelectScreenState();
}

class _MockSubjectSelectScreenState extends State<MockSubjectSelectScreen> {
  final MockTestRepository _repository = MockTestRepository();
  List<SubjectModel> _subjects = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSubjects();
  }

  Future<void> _loadSubjects() async {
    final sem = LocalStorageService().semester;
    try {
      final list = await _repository.getSubjects(sem);
      if (mounted) {
        setState(() {
          _subjects = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'বিষয়সমূহ লোড করা যায়নি। ইন্টারনেট সংযোগ চেক করুন।';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isPremiumMode ? 'প্রিমিয়াম মক টেস্ট' : 'Choose Subject';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(title),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation(AppColors.primary),
        ),
      );
    }

    if (_error != null && _subjects.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.wrongRed),
              const SizedBox(height: 16),
              Text(
                _error!,
                style: const TextStyle(fontSize: 15, color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() => _isLoading = true);
                  _loadSubjects();
                },
                child: const Text('আবার চেষ্টা করুন'),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: widget.isPremiumMode ? AppColors.premiumLight : AppColors.primaryLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.isPremiumMode ? AppColors.premiumGold.withOpacity(0.3) : AppColors.primary.withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                widget.isPremiumMode ? Icons.workspace_premium_rounded : Icons.track_changes_rounded,
                color: widget.isPremiumMode ? AppColors.premiumGold : AppColors.primary,
                size: 32,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.isPremiumMode ? 'প্রিমিয়াম স্পেশাল মক টেস্ট' : 'সকল বিষয়ের ফ্রি মক টেস্ট',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'আপনার পছন্দের বিষয়টি বেছে নিন এবং পরীক্ষা শুরু করুন',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.15,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
            ),
            itemCount: _subjects.length,
            itemBuilder: (context, index) {
              final subject = _subjects[index];
              return _buildSubjectCard(subject);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSubjectCard(SubjectModel subject) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MockTopicsSetsScreen(
              subject: subject,
              isPremiumMode: widget.isPremiumMode,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: AppColors.softCardShadow,
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.menu_book_rounded, color: AppColors.primary, size: 22),
                ),
                if (widget.isPremiumMode && subject.hasPremium)
                  const Icon(Icons.lock_outline_rounded, size: 18, color: AppColors.premiumGold),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subject.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${subject.topicCount} টি অধ্যায়',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
