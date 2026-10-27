import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/storage/local_storage_service.dart';
import '../data/mock_test_repository.dart';
import '../domain/mock_test_models.dart';
import 'quiz_screen.dart';
import 'premium_lock_screen.dart';

class MockTopicsSetsScreen extends StatefulWidget {
  final SubjectModel subject;
  final bool isPremiumMode;

  const MockTopicsSetsScreen({
    super.key,
    required this.subject,
    required this.isPremiumMode,
  });

  @override
  State<MockTopicsSetsScreen> createState() => _MockTopicsSetsScreenState();
}

class _MockTopicsSetsScreenState extends State<MockTopicsSetsScreen> {
  final MockTestRepository _repository = MockTestRepository();
  List<TopicModel> _topics = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTopics();
  }

  Future<void> _loadTopics() async {
    final sem = LocalStorageService().semester;
    try {
      final list = await _repository.getTopics(sem, widget.subject.subjectId);
      if (mounted) {
        setState(() {
          _topics = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'অধ্যায় ও টেস্ট সেট লোড করা সম্ভব হয়নি।';
          _isLoading = false;
        });
      }
    }
  }

  bool _isSetAccessible(TestSetModel set) {
    if (!set.isPremium && !widget.isPremiumMode) return true;
    final entitlements = LocalStorageService().getEntitlements();
    final sem = LocalStorageService().semester;
    return entitlements.contains('premium_mock_sem$sem') ||
        entitlements.contains('subject_${widget.subject.subjectId}') ||
        entitlements.contains('combo_sem$sem');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.subject.name),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(AppColors.primary)),
      );
    }

    if (_error != null && _topics.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.wrongRed),
              const SizedBox(height: 16),
              Text(_error!, style: const TextStyle(fontSize: 15, color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() => _isLoading = true);
                  _loadTopics();
                },
                child: const Text('আবার চেষ্টা করুন'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _topics.length,
      itemBuilder: (context, index) {
        final topic = _topics[index];
        final setsToShow = widget.isPremiumMode
            ? topic.sets.where((s) => s.isPremium).toList()
            : topic.sets;

        if (widget.isPremiumMode && setsToShow.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.Border.all(color: AppColors.border),
            boxShadow: AppColors.softCardShadow,
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${index + 1 < 10 ? '0' : ''}${index + 1}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primaryDark),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      topic.name,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                  ),
                  Text(
                    'মোট ${setsToShow.length}টি সেট',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(color: AppColors.border, height: 1),
              const SizedBox(height: 14),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.5,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: setsToShow.length,
                itemBuilder: (context, sIndex) {
                  final set = setsToShow[sIndex];
                  final isUnlocked = _isSetAccessible(set);

                  return InkWell(
                    onTap: () {
                      if (!isUnlocked) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PremiumLockScreen(
                              title: set.title,
                              grantType: 'premium_mock_sem${LocalStorageService().semester}',
                            ),
                          ),
                        );
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => QuizScreen(
                              subjectId: widget.subject.subjectId,
                              subjectName: widget.subject.name,
                              topicId: topic.topicId,
                              topicName: topic.name,
                              setFile: set.setFile,
                              version: set.version,
                            ),
                          ),
                        );
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isUnlocked ? AppColors.surface : AppColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.Border.all(
                          color: isUnlocked ? AppColors.border : AppColors.premiumGold.withOpacity(0.4),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Set ${set.setNumber}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                              ),
                              if (set.isPremium)
                                Icon(
                                  isUnlocked ? Icons.lock_open_rounded : Icons.lock_outline_rounded,
                                  size: 16,
                                  color: isUnlocked ? AppColors.correctGreen : AppColors.premiumGold,
                                ),
                            ],
                          ),
                          Text(
                            '${set.questionCount} প্রশ্ন • ${set.totalMarks.toInt()} নম্বর',
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            decoration: BoxDecoration(
                              color: isUnlocked ? AppColors.primaryLight : AppColors.premiumLight,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Center(
                              child: Text(
                                isUnlocked ? 'মক টেস্ট দিন' : 'লক করা',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isUnlocked ? AppColors.primaryDark : AppColors.premiumGold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
