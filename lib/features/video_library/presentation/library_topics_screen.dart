import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';
import '../data/youtube_helper.dart';
import 'video_player_screen.dart';

class LibraryTopicsScreen extends StatefulWidget {
  final int semester;
  final String subjectId;
  final String subjectName;
  final String subjectThumbnailUrl;

  const LibraryTopicsScreen({
    super.key,
    required this.semester,
    required this.subjectId,
    required this.subjectName,
    required this.subjectThumbnailUrl,
  });

  @override
  State<LibraryTopicsScreen> createState() => _LibraryTopicsScreenState();
}

class _LibraryTopicsScreenState extends State<LibraryTopicsScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header Bar (Matching Reference Image 2)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: const Border(bottom: BorderSide(color: AppColors.border, width: 1)),
              ),
              child: Row(
                children: [
                  // Circular Back Button
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.border),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary, size: 20),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Header Title or Search Field
                  Expanded(
                    child: _isSearching
                        ? TextField(
                            controller: _searchController,
                            autofocus: true,
                            decoration: const InputDecoration(
                              hintText: 'ভিডিও টপিক খুঁজুন...',
                              border: InputBorder.none,
                              isDense: true,
                            ),
                            onChanged: (val) {
                              setState(() {
                                _searchQuery = val.trim().toLowerCase();
                              });
                            },
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    widget.subjectName.isNotEmpty ? widget.subjectName : 'Video Library',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                      letterSpacing: -0.3,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.play_circle_fill_rounded, color: AppColors.primary, size: 18),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${widget.subjectName} বিষয়ের শিক্ষামূলক ভিডিও',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                  ),

                  // Circular Search Button
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        if (_isSearching) {
                          _isSearching = false;
                          _searchQuery = '';
                          _searchController.clear();
                        } else {
                          _isSearching = true;
                        }
                      });
                    },
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.border),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Icon(
                        _isSearching ? Icons.close_rounded : Icons.search_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Real-Time Video Grid Stream
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('library_videos')
                    .where('semester', isEqualTo: widget.semester)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation(AppColors.primary),
                      ),
                    );
                  }

                  final docs = snapshot.data?.docs ?? [];
                  List<Map<String, dynamic>> videos = [];

                  for (final doc in docs) {
                    final data = doc.data() as Map<String, dynamic>? ?? {};
                    final bool isActive = data['isActive'] ?? true;
                    if (!isActive) continue;

                    // Match by subjectId or subjectName
                    final docSubjId = (data['subjectId'] ?? '').toString().trim();
                    final docSubjName = (data['subjectName'] ?? data['subject'] ?? '').toString().trim();

                    final bool matches = (docSubjId.isNotEmpty && docSubjId.toLowerCase() == widget.subjectId.toLowerCase()) ||
                        (docSubjName.isNotEmpty && docSubjName.toLowerCase() == widget.subjectName.toLowerCase());

                    if (!matches) continue;

                    final title = (data['title'] ?? data['topicName'] ?? '').toString().trim();
                    if (_searchQuery.isNotEmpty && !title.toLowerCase().contains(_searchQuery)) {
                      continue;
                    }

                    videos.add({
                      'id': doc.id,
                      'title': title,
                      'thumbnailUrl': (data['thumbnailUrl'] ?? data['imageUrl'] ?? data['image'] ?? '').toString().trim(),
                      'youtubeInput': (data['youtubeUrl'] ?? data['youtubeVideoId'] ?? data['videoUrl'] ?? data['embedCode'] ?? '').toString().trim(),
                      'isFree': data['isFree'] ?? true,
                      'order': data['order'] is num ? (data['order'] as num).toInt() : 0,
                    });
                  }

                  // Sort by order ascending
                  videos.sort((a, b) => (a['order'] as int).compareTo(b['order'] as int));

                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top Hero Banner (as seen in Reference Image 2)
                        _buildHeroBanner(),
                        const SizedBox(height: 18),

                        // Video Grid
                        if (videos.isEmpty)
                          _buildEmptyState()
                        else
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 14,
                              childAspectRatio: 1.35, // Wide card ratio matching Image 2
                            ),
                            itemCount: videos.length,
                            itemBuilder: (context, index) {
                              final video = videos[index];
                              return _buildVideoCard(video);
                            },
                          ),

                        const SizedBox(height: 22),

                        // Bottom Student Community Banner (from Reference Image 2)
                        _buildCommunityBanner(),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withOpacity(0.4),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.primary.withOpacity(0.18), width: 1.2),
        boxShadow: AppColors.softCardShadow,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${widget.subjectName} ভিডিও লেকচার',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDark,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'গদ্য, কবিতা ও অধ্যায়ভিত্তিক সম্পূর্ণ শিক্ষামূলক ভিডিও ক্লাস।',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(
              Icons.school_rounded,
              size: 30,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoCard(Map<String, dynamic> video) {
    final String thumbnailUrl = video['thumbnailUrl'] ?? '';
    final String title = video['title'] ?? '';
    final String youtubeInput = video['youtubeInput'] ?? '';
    final bool isFree = video['isFree'] ?? true;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            final String videoId = YoutubeHelper.extractVideoId(youtubeInput);
            if (videoId.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('এই ভিডিওটির লিঙ্ক শীঘ্রই যুক্ত করা হবে।'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
              return;
            }

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => VideoPlayerScreen(
                  title: title.isNotEmpty ? title : widget.subjectName,
                  youtubeVideoId: videoId,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Background Thumbnail Image
                if (thumbnailUrl.isNotEmpty)
                  CachedNetworkImage(
                    imageUrl: thumbnailUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: AppColors.primaryLight.withOpacity(0.3),
                      child: const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(AppColors.primary)),
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => _buildFallbackTopicCard(title),
                  )
                else
                  _buildFallbackTopicCard(title),

                // Top-Right FREE Badge (Matching Reference Image 2)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isFree ? AppColors.correctGreen : AppColors.premiumGold,
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Text(
                      isFree ? 'FREE' : 'PRO',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                        color: isFree ? AppColors.correctGreen : AppColors.premiumGold,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),

                // Bottom-Right Circular White Play Button (Matching Reference Image 2)
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.play_arrow_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackTopicCard(String title) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryLight.withOpacity(0.7),
            AppColors.surfaceMuted,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title.isNotEmpty ? title : 'ভিডিও লেকচার',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              height: 1.2,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildCommunityBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.group_rounded, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'হাজারো শিক্ষার্থী ইতিমধ্যে Es Bangla-র সাথে নিয়মিত প্রস্তুতি নিচ্ছেন।',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.ondemand_video_rounded, size: 32, color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          Text(
            '${widget.subjectName}-এ কোনো ভিডিও যুক্ত করা হয়নি',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          const Text(
            'এডমিন প্যানেল (Firebase Firestore: library_videos) থেকে থাম্বনেল ও ইউটিউব ভিডিও লিঙ্ক যুক্ত করা হলে তা সরাসরি এখানে চলে আসবে।',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
