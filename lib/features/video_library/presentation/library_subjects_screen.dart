import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import 'library_topics_screen.dart';

class LibrarySubjectsScreen extends StatelessWidget {
  final int semester;

  const LibrarySubjectsScreen({super.key, required this.semester});

  final List<Map<String, dynamic>> _demoSubjects = const [
    {
      'id': 'bengali',
      'name': 'বাংলা ভিডিও লেকচার',
      'subtitle': 'গদ্য, কবিতা ও সাহিত্যভিত্তিক ভিডিও',
      'isLocked': false,
      'topics': [
        {'title': 'পোটরাজ - বিশদ আলোচনা পর্ব ১', 'youtubeId': 'dQw4w9WgXcQ', 'access': 'free'},
        {'title': 'পোটরাজ - বিশদ আলোচনা পর্ব ২', 'youtubeId': 'dQw4w9WgXcQ', 'access': 'inherit'},
        {'title': 'আদরিণী - সম্পূর্ণ প্রেক্ষাপট ও বিশ্লেষণ', 'youtubeId': 'dQw4w9WgXcQ', 'access': 'free'},
      ],
    },
    {
      'id': 'english',
      'name': 'English Video Lectures',
      'subtitle': 'Prose, Poetry, Play & Grammar Lectures',
      'isLocked': false,
      'topics': [
        {'title': 'The Eyes Have It - Line by line explanation', 'youtubeId': 'dQw4w9WgXcQ', 'access': 'free'},
        {'title': 'Strong Roots - Dr. A.P.J. Abdul Kalam', 'youtubeId': 'dQw4w9WgXcQ', 'access': 'inherit'},
      ],
    },
    {
      'id': 'history',
      'name': 'ইতিহাস ভিডিও লেকচার',
      'subtitle': 'দ্বাদশ শ্রেণি ইতিহাস পাঠক্রম আলোচনা',
      'isLocked': false,
      'topics': [
        {'title': 'উপনিবেশবাদ ও সাম্রাজ্যবাদের প্রসার', 'youtubeId': 'dQw4w9WgXcQ', 'access': 'free'},
      ],
    },
    {
      'id': 'polscience',
      'name': 'রাষ্ট্রবিজ্ঞান লেকচার',
      'subtitle': 'সংবিধান, আন্তর্জাতিক সম্পর্ক ও রাজনীতি',
      'isLocked': false,
      'topics': [
        {'title': 'দ্বিতীয় বিশ্বযুদ্ধ পরবর্তী আন্তর্জাতিক সম্পর্ক', 'youtubeId': 'dQw4w9WgXcQ', 'access': 'free'},
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('সেমিস্টার $semester - ভিডিও লাইব্রেরি'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _demoSubjects.length,
        itemBuilder: (context, index) {
          final subj = _demoSubjects[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppColors.border),
            ),
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => LibraryTopicsScreen(
                      subjectName: subj['name'],
                      subjectId: subj['id'],
                      isSubjectLocked: subj['isLocked'] == true,
                      topics: List<Map<String, dynamic>>.from(subj['topics']),
                    ),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.video_library_rounded, color: AppColors.primary, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            subj['name'],
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subj['subtitle'],
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMuted),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
