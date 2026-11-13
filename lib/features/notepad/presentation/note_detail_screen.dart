import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';

class NoteDetailScreen extends StatefulWidget {
  final Map<String, dynamic> note;
  final int noteIndex;
  final Function(Map<String, dynamic> updatedNote) onUpdate;
  final VoidCallback onDelete;

  const NoteDetailScreen({
    super.key,
    required this.note,
    required this.noteIndex,
    required this.onUpdate,
    required this.onDelete,
  });

  @override
  State<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends State<NoteDetailScreen> {
  late Map<String, dynamic> _currentNote;

  final List<Color> _noteColors = const [
    Color(0xFFF1F5F9), // Slate Cool
    Color(0xFFEFF6FF), // Soft Blue
    Color(0xFFFFFBEB), // Soft Amber
    Color(0xFFF0FDF4), // Soft Mint
    Color(0xFFFAF5FF), // Soft Purple
    Color(0xFFFFF1F2), // Soft Rose
  ];

  final List<Color> _accentColors = const [
    Color(0xFF64748B),
    Color(0xFF0070F3),
    Color(0xFFD97706),
    Color(0xFF16A34A),
    Color(0xFF9333EA),
    Color(0xFFE11D48),
  ];

  @override
  void initState() {
    super.initState();
    _currentNote = Map<String, dynamic>.from(widget.note);
  }

  int get _colorIndex {
    final idx = _currentNote['colorIndex'];
    if (idx is int && idx >= 0 && idx < _noteColors.length) {
      return idx;
    }
    return 1;
  }

  void _copyToClipboard() {
    final title = (_currentNote['title'] ?? '').toString().trim();
    final content = (_currentNote['content'] ?? '').toString().trim();
    final fullText = title.isNotEmpty ? '$title\n\n$content' : content;

    Clipboard.setData(ClipboardData(text: fullText));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('নোট ক্লিপবোর্ডে কপি করা হয়েছে'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('নোট ডিলিট করবেন?'),
        content: const Text('আপনি কি নিশ্চিত যে এই নোটটি চিরতরে ডিলিট করতে চান?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('বাতিল'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx); // Close dialog
              widget.onDelete();
              Navigator.pop(context); // Pop back to notepad list
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('ডিলিট করুন'),
          ),
        ],
      ),
    );
  }

  void _showEditSheet() {
    final titleController = TextEditingController(text: _currentNote['title'] ?? '');
    final contentController = TextEditingController(text: _currentNote['content'] ?? '');
    int selectedColorIndex = _colorIndex;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;

        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(modalContext).viewInsets.bottom + 20,
              ),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'নোট এডিট করুন',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.3,
                            color: isDark ? Colors.white : const Color(0xFF0F1E36),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(modalContext),
                          icon: const Icon(Icons.close_rounded, size: 22),
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Color tag selector
                    Text(
                      'কালার ট্যাগ বেছে নিন:',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: List.generate(_noteColors.length, (idx) {
                        final isSelected = selectedColorIndex == idx;
                        return GestureDetector(
                          onTap: () {
                            setModalState(() => selectedColorIndex = idx);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 32,
                            height: 32,
                            margin: const EdgeInsets.only(right: 10),
                            decoration: BoxDecoration(
                              color: isDark ? _accentColors[idx].withOpacity(0.3) : _noteColors[idx],
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? _accentColors[idx] : (isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1)),
                                width: isSelected ? 2.5 : 1.0,
                              ),
                            ),
                            child: isSelected
                                ? Icon(Icons.check_rounded, size: 16, color: _accentColors[idx])
                                : null,
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 16),

                    // Title Field
                    TextField(
                      controller: titleController,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                      decoration: InputDecoration(
                        hintText: 'নোটের শিরোনাম...',
                        hintStyle: TextStyle(
                          color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                        ),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Content Field
                    TextField(
                      controller: contentController,
                      minLines: 5,
                      maxLines: 10,
                      style: TextStyle(
                        fontSize: 14.5,
                        height: 1.4,
                        color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B),
                      ),
                      decoration: InputDecoration(
                        hintText: 'এখানে আপনার গুরুত্বপূর্ণ পড়া, সূত্র বা প্রশ্নের পয়েন্ট লিখুন...',
                        hintStyle: TextStyle(
                          color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                        ),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                        ),
                        contentPadding: const EdgeInsets.all(16),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Update Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          final title = titleController.text.trim();
                          final content = contentController.text.trim();
                          if (title.isEmpty && content.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('নোটের শিরোনাম বা বিবরণ লিখুন'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                            return;
                          }

                          final dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());
                          final updatedNote = {
                            'id': _currentNote['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
                            'title': title.isEmpty ? 'Untitled Note' : title,
                            'content': content,
                            'date': dateStr,
                            'colorIndex': selectedColorIndex,
                          };

                          setState(() {
                            _currentNote = updatedNote;
                          });
                          widget.onUpdate(updatedNote);
                          Navigator.pop(modalContext);

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('নোট সফলভাবে আপডেট করা হয়েছে!'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        icon: const Icon(Icons.check_circle_rounded, size: 20),
                        label: const Text(
                          'আপডেট করুন',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final title = (_currentNote['title'] ?? '').toString();
    final content = (_currentNote['content'] ?? '').toString();
    final date = (_currentNote['date'] ?? '').toString();
    final accentColor = _accentColors[_colorIndex];
    final cardBg = isDark ? const Color(0xFF1E293B) : _noteColors[_colorIndex];

    final wordCount = content.trim().isEmpty ? 0 : content.trim().split(RegExp(r'\s+')).length;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'নোট বিবরণ',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            tooltip: 'কপি করুন',
            icon: const Icon(Icons.copy_rounded, size: 20),
            onPressed: _copyToClipboard,
          ),
          IconButton(
            tooltip: 'এডিট করুন',
            icon: const Icon(Icons.edit_outlined, size: 20),
            onPressed: _showEditSheet,
          ),
          IconButton(
            tooltip: 'ডিলিট করুন',
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 21),
            onPressed: _confirmDelete,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.3 : 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header tag: Date & Category accent pill
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: accentColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (date.isNotEmpty)
                    Text(
                      date,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$wordCount words',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: accentColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Title (Large, bold, crisp)
              SelectableText(
                title.isEmpty ? 'Untitled Note' : title,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.3,
                  color: isDark ? Colors.white : const Color(0xFF0F1E36),
                ),
              ),
              const SizedBox(height: 14),

              // Divider
              Container(
                height: 1.2,
                color: accentColor.withOpacity(0.2),
              ),
              const SizedBox(height: 16),

              // Full content (Comfortable line spacing, clean selectable text)
              SelectableText(
                content.isEmpty ? '(কোনো বিবরণ নেই)' : content,
                style: TextStyle(
                  fontSize: 15.5,
                  height: 1.6,
                  color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showEditSheet,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 3,
        icon: const Icon(Icons.edit_rounded, size: 18),
        label: const Text(
          'নোট এডিট করুন',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
