import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/storage/local_storage_service.dart';

class ReminderHistoryScreen extends StatelessWidget {
  const ReminderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final storage = LocalStorageService();
    final all = storage.getStudyReminders();
    final completed = all.where((r) => r['status'] == 'completed').toList();
    final missed = all.where((r) {
      if (r['status'] == 'completed') return false;
      final time = DateTime.tryParse(r['time'] ?? '');
      return time != null && time.isBefore(DateTime.now());
    }).toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('রিমাইন্ডার ইতিহাস'),
          bottom: const TabBar(
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            tabs: [
              Tab(text: 'সম্পন্ন (Completed)'),
              Tab(text: 'মিসড (Missed)'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildList(completed, isCompleted: true),
            _buildList(missed, isCompleted: false),
          ],
        ),
      ),
    );
  }

  Widget _buildList(List<Map<String, dynamic>> items, {required bool isCompleted}) {
    if (items.isEmpty) {
      return Center(
        child: Text(
          isCompleted ? 'কোনো সম্পন্ন রিমাইন্ডার নেই' : 'কোনো মিসড রিমাইন্ডার নেই',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final r = items[index];
        final date = DateTime.tryParse(r['time'] ?? '') ?? DateTime.now();

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.border),
          ),
          child: ListTile(
            leading: Icon(
              isCompleted ? Icons.check_circle_rounded : Icons.cancel_rounded,
              color: isCompleted ? AppColors.correctGreen : AppColors.wrongRed,
              size: 26,
            ),
            title: Text(
              r['title'] ?? '',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                decoration: isCompleted ? TextDecoration.lineThrough : null,
              ),
            ),
            subtitle: Text(
              DateFormat('dd MMM yyyy, hh:mm a').format(date),
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ),
        );
      },
    );
  }
}
