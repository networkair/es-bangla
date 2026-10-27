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
          _errorMessage = 'নোটস ফাইলটি লোড করা সম্ভব হয়নি। অনুগ্রহ করে আবার চেষ্টা করুন।';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (_totalPages > 0)
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$_currentPage / $_totalPages',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
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
                _errorMessage ?? 'ফাইল পাওয়া যায়নি',
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

    return PdfViewer.data(
      _pdfBytes!,
      sourceName: widget.assetPath,
      controller: _controller,
      passwordProvider: () => SecurityManager.getDecryptedPdfPassword(),
      params: PdfViewerParams(
        enableTextSelection: false, // Text copying disabled
        onPageChanged: (page) {
          if (mounted && page != null) {
            setState(() {
              _currentPage = page;
            });
          }
        },
        onViewerReady: (document, controller) {
          if (mounted) {
            setState(() {
              _totalPages = document.pages.length;
            });
          }
        },
      ),
    );
  }
}
