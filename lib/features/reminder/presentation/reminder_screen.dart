import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/storage/local_storage_service.dart';
import '../data/reminder_notification_service.dart';
import 'reminder_history_screen.dart';

class ReminderScreen extends StatefulWidget {
  const ReminderScreen({super.key});

  @override
  State<ReminderScreen> createState() => _ReminderScreenState();
}

class _ReminderScreenState extends State<ReminderScreen> {
  final LocalStorageService _storage = LocalStorageService();
  List<Map<String, dynamic>> _reminders = [];

  @override
  void initState() {
    super.initState();
    _loadReminders();
  }

  void _loadReminders() {
    setState(() {
      _reminders = _storage.getStudyReminders();
    });
  }

  Future<void> _addOrEditReminder({Map<String, dynamic>? existing, int? index}) async {
    final titleController = TextEditingController(text: existing?['title'] ?? '');
    DateTime selectedDate = existing != null
        ? DateTime.parse(existing['time'])
        : DateTime.now().add(const Duration(hours: 2));

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    existing != null ? 'রিমাইন্ডার সম্পাদনা করুন' : 'নতুন স্টাডি রিমাইন্ডার যোগ করুন',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      hintText: 'কী বিষয়ে পড়াশোনা করবেন? (যেমন: বাংলা পোটরাজ)',
                      labelText: 'টপিক বা বিষয়ের নাম',
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: AppColors.border),
                    ),
                    leading: const Icon(Icons.calendar_today_rounded, color: AppColors.primary),
                    title: Text(DateFormat('dd MMM yyyy, hh:mm a').format(selectedDate)),
                    trailing: const Icon(Icons.edit_calendar_rounded, size: 20, color: AppColors.primary),
                    onTap: () async {
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (pickedDate != null && ctx.mounted) {
                        final pickedTime = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.fromDateTime(selectedDate),
                        );
                        if (pickedTime != null) {
                          setModalState(() {
                            selectedDate = DateTime(
                              pickedDate.year,
                              pickedDate.month,
                              pickedDate.day,
                              pickedTime.hour,
                              pickedTime.minute,
                            );
                          });
                        }
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () async {
                        final title = titleController.text.trim();
                        if (title.isEmpty) return;

                        final notifId = existing?['id'] ?? DateTime.now().millisecondsSinceEpoch ~/ 1000;
                        final reminderData = {
                          'id': notifId,
                          'title': title,
                          'time': selectedDate.toIso8601String(),
                          'status': 'pending', // 'pending', 'completed', 'missed'
                        };

                        if (existing != null && index != null) {
                          _reminders[index] = reminderData;
                        } else {
                          _reminders.insert(0, reminderData);
                        }

                        await _storage.saveStudyReminders(_reminders);

                        // Schedule notification
                        if (selectedDate.isAfter(DateTime.now())) {
                          await ReminderNotificationService().scheduleNotification(
                            id: notifId,
                            title: 'Es Bangla - পড়াশোনার সময় হয়েছে! 📚',
                            body: title,
                            scheduledDate: selectedDate,
                          );
                        }

                        if (ctx.mounted) Navigator.pop(ctx);
                        _loadReminders();
                      },
                      child: Text(existing != null ? 'আপডেট করুন' : 'রিমাইন্ডার সেট করুন'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _toggleComplete(int index) async {
    final item = _reminders[index];
    final isDone = item['status'] == 'completed';
    item['status'] = isDone ? 'pending' : 'completed';
    await _storage.saveStudyReminders(_reminders);
    _loadReminders();
  }

  Future<void> _deleteReminder(int index) async {
    final item = _reminders.removeAt(index);
    await _storage.saveStudyReminders(_reminders);
    if (item['id'] != null) {
      await ReminderNotificationService().cancelNotification(item['id']);
    }
    _loadReminders();
  }

  @override
  Widget build(BuildContext context) {
    final pendingReminders = _reminders.where((r) => r['status'] == 'pending').toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Study Reminders ⏰'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'রিমাইন্ডার ইতিহাস',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ReminderHistoryScreen()),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addOrEditReminder(),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('নতুন রিমাইন্ডার', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: pendingReminders.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.alarm_on_rounded, size: 36, color: AppColors.primary),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'কোনো পেন্ডিং রিমাইন্ডার নেই',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'আপনার পড়ার রুটিন ধরে রাখতে নতুন রিমাইন্ডার যোগ করুন।',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              itemCount: pendingReminders.length,
              itemBuilder: (context, index) {
                final r = pendingReminders[index];
                final originalIndex = _reminders.indexOf(r);
                final date = DateTime.parse(r['time']);
                final isPast = date.isBefore(DateTime.now());

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: IconButton(
                      icon: const Icon(Icons.circle_outlined, color: AppColors.primary),
                      onPressed: () => _toggleComplete(originalIndex),
                    ),
                    title: Text(
                      r['title'] ?? '',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
                    ),
                    subtitle: Text(
                      '${DateFormat('dd MMM, hh:mm a').format(date)}${isPast ? ' (সময় অতিক্রান্ত)' : ''}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isPast ? AppColors.wrongRed : AppColors.textSecondary,
                        fontWeight: isPast ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (val) {
                        if (val == 'edit') {
                          _addOrEditReminder(existing: r, index: originalIndex);
                        } else if (val == 'delete') {
                          _deleteReminder(originalIndex);
                        }
                      },
                      itemBuilder: (ctx) => [
                        const PopupMenuItem(value: 'edit', child: Text('সম্পাদনা করুন')),
                        const PopupMenuItem(value: 'delete', child: Text('মুছে ফেলুন', style: TextStyle(color: AppColors.wrongRed))),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
