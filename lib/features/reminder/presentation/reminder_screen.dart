import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/storage/local_storage_service.dart';
import '../data/reminder_notification_service.dart';

class ReminderScreen extends StatefulWidget {
  const ReminderScreen({super.key});

  @override
  State<ReminderScreen> createState() => _ReminderScreenState();
}

class _ReminderScreenState extends State<ReminderScreen> with SingleTickerProviderStateMixin {
  final LocalStorageService _storage = LocalStorageService();
  final ReminderNotificationService _notificationService = ReminderNotificationService();

  List<Map<String, dynamic>> _reminders = [];
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    _loadReminders();
    _checkPermissions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _checkPermissions() async {
    await _notificationService.requestPermissions();
  }

  void _loadReminders() {
    setState(() {
      _reminders = _storage.getStudyReminders();
    });
  }

  List<Map<String, dynamic>> get _upcomingReminders {
    return _reminders.where((r) => r['status'] == 'pending').toList();
  }

  List<Map<String, dynamic>> get _historyReminders {
    return _reminders.where((r) => r['status'] != 'pending').toList();
  }

  Future<void> _addOrEditReminder({Map<String, dynamic>? existing, int? index}) async {
    final titleController = TextEditingController(text: existing?['title'] ?? '');
    DateTime selectedDate = existing != null
        ? DateTime.tryParse(existing['time'] ?? '') ?? DateTime.now().add(const Duration(hours: 1))
        : DateTime.now().add(const Duration(hours: 1));

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    existing != null ? 'Edit Study Reminder' : 'New Study Reminder',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Get a quiet reminder notification when it is time to study.',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 20),

                  // Topic input field
                  TextField(
                    controller: titleController,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      labelText: 'Topic or Subject',
                      hintText: 'e.g., Python Programming, History Unit 1',
                      prefixIcon: const Icon(Icons.menu_book_rounded, color: AppColors.primary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                      ),
                      filled: true,
                      fillColor: AppColors.background,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Date & Time Picker Tile
                  InkWell(
                    onTap: () async {
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: selectedDate.isBefore(DateTime.now())
                            ? DateTime.now()
                            : selectedDate,
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
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.calendar_month_rounded,
                              color: AppColors.primaryDark,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Scheduled Time',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  DateFormat('EEE, dd MMM yyyy • hh:mm a').format(selectedDate),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textSecondary),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Action Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () async {
                        final title = titleController.text.trim();
                        if (title.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please enter a topic name')),
                          );
                          return;
                        }

                        // Ensure permission
                        await _notificationService.requestPermissions();

                        final notifId = existing?['id'] ?? (DateTime.now().millisecondsSinceEpoch % 100000);
                        final reminderData = {
                          'id': notifId,
                          'title': title,
                          'time': selectedDate.toIso8601String(),
                          'status': 'pending',
                        };

                        if (existing != null && index != null) {
                          _reminders[index] = reminderData;
                        } else {
                          _reminders.insert(0, reminderData);
                        }

                        await _storage.saveStudyReminders(_reminders);

                        // Schedule exact or inexact quiet notification
                        await _notificationService.scheduleNotification(
                          id: notifId,
                          title: 'Study Reminder ⏰',
                          body: 'Time to study: $title',
                          scheduledDate: selectedDate,
                        );

                        if (ctx.mounted) Navigator.pop(ctx);
                        _loadReminders();

                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Reminder scheduled for ${DateFormat('dd MMM, hh:mm a').format(selectedDate)}'),
                              backgroundColor: AppColors.primaryDark,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        existing != null ? 'Update Reminder' : 'Set Reminder',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
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

  Future<void> _toggleComplete(int originalIndex) async {
    final item = _reminders[originalIndex];
    final isDone = item['status'] == 'completed';
    item['status'] = isDone ? 'pending' : 'completed';
    await _storage.saveStudyReminders(_reminders);

    if (!isDone) {
      // Cancel pending notification once completed
      final int notifId = item['id'] ?? 0;
      await _notificationService.cancelNotification(notifId);
    } else {
      // Re-scheduled if marked pending again and time is in future
      final date = DateTime.tryParse(item['time'] ?? '');
      if (date != null && date.isAfter(DateTime.now())) {
        await _notificationService.scheduleNotification(
          id: item['id'] ?? 0,
          title: 'Study Reminder ⏰',
          body: 'Time to study: ${item['title']}',
          scheduledDate: date,
        );
      }
    }

    _loadReminders();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isDone ? 'Marked as pending' : 'Marked as completed! 🎉'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _deleteReminder(int originalIndex) async {
    final item = _reminders.removeAt(originalIndex);
    await _storage.saveStudyReminders(_reminders);
    if (item['id'] != null) {
      await _notificationService.cancelNotification(item['id']);
    }
    _loadReminders();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reminder deleted'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final upcoming = _upcomingReminders;
    final history = _historyReminders;

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addOrEditReminder(),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Add Reminder',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top Navigation Bar (Header without right history action icon)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: const Border(bottom: BorderSide(color: AppColors.border, width: 1)),
              ),
              child: Row(
                children: [
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
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Study Reminders',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Keep your study schedule on track',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) {
                  return [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                        child: Column(
                          children: [
                            // Centered Prominent 3D Reminder Icon
                            const SizedBox(height: 12),
                            Center(
                              child: Image.asset(
                                'assets/icons/ic_reminder.png',
                                width: 125,
                                height: 125,
                                fit: BoxFit.contain,
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Segmented Tab Switcher (Upcoming vs History)
                            Container(
                              height: 48,
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: TabBar(
                                controller: _tabController,
                                indicator: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                labelColor: Colors.white,
                                unselectedLabelColor: AppColors.textSecondary,
                                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                                indicatorSize: TabBarIndicatorSize.tab,
                                dividerColor: Colors.transparent,
                                tabs: [
                                  Tab(text: 'Upcoming (${upcoming.length})'),
                                  Tab(text: 'History (${history.length})'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ];
                },
                body: TabBarView(
                  controller: _tabController,
                  children: [
                    // Tab 1: Upcoming Reminders
                    _buildUpcomingList(upcoming),

                    // Tab 2: Reminder History
                    _buildHistoryList(history),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingList(List<Map<String, dynamic>> items) {
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
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
                child: const Icon(Icons.notifications_none_rounded, size: 32, color: AppColors.primary),
              ),
              const SizedBox(height: 16),
              const Text(
                'No Upcoming Reminders',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Tap the button above to schedule your next study topic.',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final r = items[index];
        final originalIndex = _reminders.indexOf(r);
        final date = DateTime.tryParse(r['time'] ?? '') ?? DateTime.now();
        final isPast = date.isBefore(DateTime.now());

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            leading: GestureDetector(
              onTap: () => _toggleComplete(originalIndex),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary.withOpacity(0.5), width: 1.5),
                  color: AppColors.primaryLight.withOpacity(0.3),
                ),
                child: const Icon(Icons.circle_outlined, color: AppColors.primary, size: 20),
              ),
            ),
            title: Text(
              r['title'] ?? '',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: AppColors.textPrimary,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    size: 14,
                    color: isPast ? AppColors.wrongRed : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('dd MMM, hh:mm a').format(date),
                    style: TextStyle(
                      fontSize: 12,
                      color: isPast ? AppColors.wrongRed : AppColors.textSecondary,
                      fontWeight: isPast ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  if (isPast) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.wrongRed.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Time Passed',
                        style: TextStyle(fontSize: 10, color: AppColors.wrongRed, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            trailing: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded, color: AppColors.textSecondary),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              onSelected: (val) {
                if (val == 'edit') {
                  _addOrEditReminder(existing: r, index: originalIndex);
                } else if (val == 'delete') {
                  _deleteReminder(originalIndex);
                }
              },
              itemBuilder: (ctx) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, size: 18, color: AppColors.textPrimary),
                      SizedBox(width: 10),
                      Text('Edit'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.wrongRed),
                      SizedBox(width: 10),
                      Text('Delete', style: TextStyle(color: AppColors.wrongRed)),
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

  Widget _buildHistoryList(List<Map<String, dynamic>> items) {
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
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
                child: const Icon(Icons.history_rounded, size: 32, color: AppColors.primary),
              ),
              const SizedBox(height: 16),
              const Text(
                'No Reminder History Yet',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Completed and archived reminders will appear in this section.',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final r = items[index];
        final originalIndex = _reminders.indexOf(r);
        final isCompleted = r['status'] == 'completed';
        final date = DateTime.tryParse(r['time'] ?? '') ?? DateTime.now();

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            leading: GestureDetector(
              onTap: () => _toggleComplete(originalIndex),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted
                      ? AppColors.correctGreen.withOpacity(0.12)
                      : AppColors.wrongRed.withOpacity(0.12),
                ),
                child: Icon(
                  isCompleted ? Icons.check_circle_rounded : Icons.cancel_rounded,
                  color: isCompleted ? AppColors.correctGreen : AppColors.wrongRed,
                  size: 22,
                ),
              ),
            ),
            title: Text(
              r['title'] ?? '',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: isCompleted ? AppColors.textSecondary : AppColors.textPrimary,
                decoration: isCompleted ? TextDecoration.lineThrough : null,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  Icon(Icons.calendar_today_rounded, size: 12, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('dd MMM yyyy • hh:mm a').format(date),
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? AppColors.correctGreen.withOpacity(0.12)
                          : AppColors.wrongRed.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      isCompleted ? 'Completed' : 'Missed',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isCompleted ? AppColors.correctGreen : AppColors.wrongRed,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.textSecondary, size: 20),
              tooltip: 'Delete',
              onPressed: () => _deleteReminder(originalIndex),
            ),
          ),
        );
      },
    );
  }
}
