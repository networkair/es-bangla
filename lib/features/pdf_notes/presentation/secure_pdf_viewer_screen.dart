import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdfrx/pdfrx.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/security_manager.dart';

class SecurePdfViewerScreen extends StatefulWidget {
  final String title;
  final String assetPath;

  const SecurePdfViewerScreen({
    super.key,
    required this.title,
    required this.assetPath,
  });

  @override
  State<SecurePdfViewerScreen> createState() => _SecurePdfViewerScreenState();
}

class _SecurePdfViewerScreenState extends State<SecurePdfViewerScreen> {
  final PdfViewerController _controller = PdfViewerController();
  int _currentPage = 1;
  int _totalPages = 0;
  bool _isLoading = true;
  String? _errorMessage;
  Uint8List? _pdfBytes;
  bool _isHeaderVisible = true;

  @override
  void initState() {
    super.initState();
    // Block screenshots and screen recording immediately
    SecurityManager.enableSecureScreen();
    _loadPdfAsset();
  }

  @override
  void dispose() {
    // Unblock when leaving
    SecurityManager.disableSecureScreen();
    super.dispose();
  }

  Future<void> _loadPdfAsset() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final byteData = await rootBundle.load(widget.assetPath);
      if (mounted) {
        setState(() {
          _pdfBytes = byteData.buffer.asUint8List();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'নোটস লোড করা সম্ভব হয়নি। অনুগ্রহ করে আবার চেষ্টা করুন।';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 1. Full Screen Viewer
          Positioned.fill(
            child: _buildViewerContent(topPadding),
          ),

          // 2. Animated Top Full Header (Slides up/down)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeInOut,
            top: _isHeaderVisible ? 0 : -(topPadding + 70),
            left: 0,
            right: 0,
            child: _buildFullHeader(context, topPadding),
          ),

          // 3. Compact Floating Back Button (Visible when full header is hidden)
          Positioned(
            top: topPadding + 10,
            left: 16,
            child: AnimatedScale(
              scale: _isHeaderVisible ? 0.0 : 1.0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutBack,
              child: AnimatedOpacity(
                opacity: _isHeaderVisible ? 0.0 : 1.0,
                duration: const Duration(milliseconds: 180),
                child: _buildCompactBackButton(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullHeader(BuildContext context, double topPadding) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, topPadding + 8, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(bottom: BorderSide(color: AppColors.border, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary, size: 20),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              widget.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (_totalPages > 0) ...[
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primary.withOpacity(0.15)),
              ),
              child: Text(
                '$_currentPage / $_totalPages',
                style: const TextStyle(
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCompactBackButton(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppColors.surface.withOpacity(0.92),
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: const Icon(
          Icons.arrow_back_rounded,
          color: AppColors.textPrimary,
          size: 19,
        ),
      ),
    );
  }

  Widget _buildViewerContent(double topPadding) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      );
    }

    if (_errorMessage != null || _pdfBytes == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.wrongRed),
              const SizedBox(height: 16),
              Text(
                _errorMessage ?? 'নোটস লোড করা সম্ভব হয়নি',
                style: const TextStyle(fontSize: 15, color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _loadPdfAsset,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('আবার চেষ্টা করুন'),
              ),
            ],
          ),
        ),
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (scrollInfo) {
        if (scrollInfo is ScrollUpdateNotification && scrollInfo.scrollDelta != null) {
          if (scrollInfo.scrollDelta! > 15) {
            if (_isHeaderVisible) {
              setState(() => _isHeaderVisible = false);
            }
          } else if (scrollInfo.scrollDelta! < -15) {
            if (!_isHeaderVisible) {
              setState(() => _isHeaderVisible = true);
            }
          }
        }
        return false;
      },
      child: PdfViewer.data(
        _pdfBytes!,
        sourceName: widget.assetPath,
        controller: _controller,
        passwordProvider: () => SecurityManager.getDecryptedPdfPassword(),
        params: PdfViewerParams(
          backgroundColor: Colors.white,
          margin: 10.0,
          enableTextSelection: false,
          onGeneralTap: (_) {
            setState(() => _isHeaderVisible = !_isHeaderVisible);
          },
          layoutPages: (pages, params) {
            final width = pages.fold(0.0, (w, p) => max(w, p.width)) + params.margin * 2;
            final pageLayout = <Rect>[];
            // Generous top gap (~80px) so the first page starts cleanly below the header bar without top clipping
            double y = (topPadding + 62.0) + 18.0;

            for (int i = 0; i < pages.length; i++) {
              final page = pages[i];
              final rect = Rect.fromLTWH(
                (width - page.width) / 2,
                y,
                page.width,
                page.height,
              );
              pageLayout.add(rect);
              y += page.height + params.margin;
            }

            return PdfPageLayout(
              pageLayouts: pageLayout,
              documentSize: Size(width, y + 40.0),
            );
          },
          onPageChanged: (page) {
            if (mounted && page != null) {
              setState(() => _currentPage = page);
            }
          },
          onViewerReady: (document, controller) {
            if (mounted) {
              setState(() => _totalPages = document.pages.length);
            }
          },
        ),
      ),
    );
  }
}
