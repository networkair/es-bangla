import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/storage/local_storage_service.dart';
import '../../../core/services/entitlement_service.dart';
import '../../auth/presentation/login_screen.dart';
import '../data/mock_test_repository.dart';
import '../domain/mock_test_models.dart';
import 'quiz_screen.dart';
import 'premium_lock_screen.dart';
import '../../../core/widgets/app_shimmer.dart';

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
    if (FirebaseAuth.instance.currentUser != null) {
      EntitlementService.syncUserEntitlements().then((_) {
        if (mounted) setState(() {});
      });
    }
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
          _error = 'অধ্যায় ও টেস্ট সেট লোড করা সম্ভব হয়নি। ইন্টারনেট সংযোগ চেক করুন।';
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
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        title: Text(
          widget.subject.name,
          style: const TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
            letterSpacing: -0.4,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: widget.isPremiumMode ? AppColors.premiumLight : AppColors.primaryLight,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: widget.isPremiumMode
                    ? AppColors.premiumGold.withOpacity(0.4)
                    : AppColors.primary.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.isPremiumMode
                      ? Icons.workspace_premium_rounded
                      : Icons.verified_outlined,
                  size: 14,
                  color: widget.isPremiumMode ? AppColors.premiumGold : AppColors.primaryDark,
                ),
                const SizedBox(width: 4),
                Text(
                  widget.isPremiumMode ? 'PREMIUM' : 'FREE',
                  style: TextStyle(
                    color: widget.isPremiumMode ? AppColors.premiumGold : AppColors.primaryDark,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 4,
        itemBuilder: (context, index) {
          return AppShimmer(
            child: Container(
              margin: const EdgeInsets.only(bottom: 14),
              height: 82,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 140,
                          height: 14,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: 80,
                          height: 11,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }

    if (_error != null && _topics.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.wrongRed),
              const SizedBox(height: 16),
              Text(_error!, style: const TextStyle(fontSize: 15, color: AppColors.textSecondary), textAlign: TextAlign.center),
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

    // Filter topics if in premium mode
    final validTopics = _topics.where((t) {
      if (!widget.isPremiumMode) return t.sets.isNotEmpty;
      return t.sets.any((s) => s.isPremium);
    }).toList();

    if (validTopics.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.isPremiumMode ? Icons.workspace_premium_outlined : Icons.quiz_outlined,
                size: 54,
                color: AppColors.textMuted,
              ),
              const SizedBox(height: 16),
              const Text(
                'শীঘ্রই নতুন টেস্ট সেট যুক্ত হবে',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 6),
              const Text(
                'আমাদের শিক্ষকবৃন্দ এই বিষয়ের টেস্ট সেট প্রস্তুত করছেন, খুব শীঘ্রই আপডেট চলে আসবে।',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 30),
      itemCount: validTopics.length,
      itemBuilder: (context, index) {
        final topic = validTopics[index];
        final setsToShow = widget.isPremiumMode
            ? topic.sets.where((s) => s.isPremium).toList()
            : topic.sets;

        return Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Topic Title Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 18,
                      decoration: BoxDecoration(
                        color: widget.isPremiumMode ? AppColors.premiumGold : AppColors.primary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        topic.name,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // 2. Horizontal Scrollable Row of Set Cards (Left-to-Right)
              SizedBox(
                height: 165,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  itemCount: setsToShow.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 14),
                  itemBuilder: (context, sIndex) {
                    final set = setsToShow[sIndex];
                    return _buildHorizontalSetCard(topic, set);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHorizontalSetCard(TopicModel topic, TestSetModel set) {
    final isUnlocked = _isSetAccessible(set);

    return Container(
      width: 148,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isUnlocked
              ? AppColors.border.withOpacity(0.8)
              : AppColors.premiumGold.withOpacity(0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: (isUnlocked ? AppColors.primary : AppColors.premiumGold).withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            final bool currentlyAccessible = _isSetAccessible(set);

            if (currentlyAccessible) {
              // Free mock tests or already accessible sets open directly without login
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
              return;
            }

            // Locked Premium mock test: Login is required to link access & preserve keys
            if (FirebaseAuth.instance.currentUser == null) {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
              if (FirebaseAuth.instance.currentUser == null) return;
              await EntitlementService.syncUserEntitlements();
              if (mounted) setState(() {});
            }

            // If account already owns the entitlement after sync, launch directly
            if (_isSetAccessible(set)) {
              if (!mounted) return;
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
              return;
            }

            if (!mounted) return;
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PremiumLockScreen(
                  title: set.title,
                  grantType: 'premium_mock_sem${LocalStorageService().semester}',
                ),
              ),
            ).then((_) {
              if (mounted) setState(() {});
            });
          },
          borderRadius: BorderRadius.circular(20),
          splashColor: (isUnlocked ? AppColors.primary : AppColors.premiumGold).withOpacity(0.12),
          highlightColor: (isUnlocked ? AppColors.primary : AppColors.premiumGold).withOpacity(0.06),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top: Set Name in English (e.g. Set 1, Set 2)
                Text(
                  'Set ${set.setNumber}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),

                // Middle: "Full Free" Badge in English (No Coins / No Question counts)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
                  decoration: BoxDecoration(
                    color: isUnlocked
                        ? const Color(0xFFECFDF5)
                        : AppColors.premiumLight,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isUnlocked
                          ? const Color(0xFFA7F3D0)
                          : AppColors.premiumGold.withOpacity(0.4),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isUnlocked
                            ? Icons.check_circle_rounded
                            : Icons.lock_rounded,
                        size: 13,
                        color: isUnlocked
                            ? const Color(0xFF10B981)
                            : AppColors.premiumGold,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        isUnlocked ? 'Full Free' : 'Premium',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: isUnlocked
                              ? const Color(0xFF047857)
                              : AppColors.premiumGold,
                          letterSpacing: 0.2,
                        ),
                      ),
                      if (isUnlocked) ...[
                        const SizedBox(width: 4),
                        Image.asset(
                          'assets/icons/ic_coin.png',
                          width: 14,
                          height: 14,
                          fit: BoxFit.contain,
                        ),
                      ],
                    ],
                  ),
                ),

                // Bottom: Clean English Action Row ("Start Test" with arrow)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isUnlocked ? 'Start Test' : 'Unlock',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isUnlocked
                            ? AppColors.primaryDark
                            : AppColors.premiumGold,
                        letterSpacing: 0.2,
                      ),
                    ),
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: isUnlocked
                            ? AppColors.primaryLight
                            : AppColors.premiumLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Icon(
                          isUnlocked
                              ? Icons.arrow_forward_rounded
                              : Icons.lock_outline_rounded,
                          size: 15,
                          color: isUnlocked
                              ? AppColors.primaryDark
                              : AppColors.premiumGold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
