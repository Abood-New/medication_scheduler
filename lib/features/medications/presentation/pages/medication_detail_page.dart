import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:medication_scheduler/core/date/date_utils.dart';
import 'package:medication_scheduler/features/medications/domain/entities/medication.dart' as med_entity;
import 'package:medication_scheduler/features/medications/presentation/providers/medication_provider.dart';
import 'package:medication_scheduler/features/medications/presentation/pages/medication_setup_page.dart';
import 'package:medication_scheduler/features/schedule/domain/services/medication_schedule_service.dart';
import 'package:medication_scheduler/core/services/notification_service.dart';

class med_entity.MedicationDetailPage extends StatefulWidget {
  final med_entity.Medication medication;

  const med_entity.MedicationDetailPage({super.key, required this.medication});

  @override
  State<med_entity.MedicationDetailPage> createState() => _med_entity.MedicationDetailPageState();
}

class _med_entity.MedicationDetailPageState extends State<med_entity.MedicationDetailPage> {
  late med_entity.Medication _medication;
  bool _reminderEnabled = false;
  med_entity.TimeOfDay? _reminderTime;

  @override
  void initState() {
    super.initState();
    _medication = widget.medication;
    _reminderEnabled = _medication.reminderEnabled;
    _reminderTime = _medication.reminderTime;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_medication.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: _navigateToEdit,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // med_entity.Medication Info Card
            _buildInfoCard(context),
            const SizedBox(height: 16),

            // Schedule Info Card
            _buildScheduleCard(context),
            const SizedBox(height: 16),

            // Reminders Card
            _buildRemindersCard(context),
            const SizedBox(height: 16),

            // Reference Date Card
            _buildReferenceDateCard(context),
            const SizedBox(height: 16),

            // Danger Zone
            _buildDangerZone(context),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'med_entity.Medication Info',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 16),
            _buildDetailRow(context, 'Name', _medication.name),
            if (_medication.dosage != null)
              _buildDetailRow(context, 'Dosage', _medication.dosage!),
            if (_medication.notes != null && _medication.notes!.isNotEmpty)
              _buildDetailRow(context, 'Notes', _medication.notes!),
            _buildDetailRow(context, 'Schedule', 'Every other day'),
            _buildDetailRow(
              context,
              'Created',
              DateFormat('MMMM d, yyyy').format(_medication.createdAt),
            ),
            _buildDetailRow(
              context,
              'Updated',
              DateFormat('MMMM d, yyyy').format(_medication.updatedAt),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleCard(BuildContext context) {
    final scheduleService = const med_entity.MedicationScheduleService();
    final upcoming = scheduleService.getUpcomingDoses(
      referenceDate: _medication.referenceDate,
      fromDate: AppDate.today(),
      count: 5,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Upcoming Doses',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 16),
            ...upcoming.map((date) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            date.formatDay(),
                            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(date.formatFull(), style: Theme.of(context).textTheme.bodyMedium),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'TAKE',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: Theme.of(context).colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 8),
            Text(
              'Pattern: Take → Skip → Take → Skip...',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRemindersCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reminders',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Enable Reminders'),
              subtitle: const Text('Get notified on medication days'),
              value: _reminderEnabled,
              onChanged: _toggleReminders,
              contentPadding: EdgeInsets.zero,
            ),
            if (_reminderEnabled) ...[
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.access_time_outlined),
                title: const Text('Reminder Time'),
                subtitle: Text(
                  _reminderTime?.format() ?? 'Not set',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                onTap: _pickReminderTime,
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildReferenceDateCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reference Date',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'The date you last took this medication. All schedules are calculated from this date.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _medication.referenceDate.formatFull(),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Change'),
                  onPressed: _changeReferenceDate,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDangerZone(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      color: colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: colorScheme.onErrorContainer),
                const SizedBox(width: 8),
                Text(
                  'Danger Zone',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: colorScheme.onErrorContainer,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Changing the reference date will recalculate your entire medication schedule. This should only be done under medical guidance.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onErrorContainer,
                  ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              icon: const Icon(Icons.calendar_today_outlined),
              label: const Text('Change Reference Date'),
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.error,
                foregroundColor: colorScheme.onError,
              ),
              onPressed: _changeReferenceDate,
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              icon: const Icon(Icons.delete_outline),
              label: const Text('Delete med_entity.Medication'),
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.error,
                foregroundColor: colorScheme.onError,
              ),
              onPressed: _confirmDelete,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _navigateToEdit() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => med_entity.MedicationSetupPage(),
      ),
    );
    // Reload medication after edit
    if (result == true && mounted) {
      // The provider will reload
    }
  }

  Future<void> _toggleReminders(bool value) async {
    setState(() {
      _reminderEnabled = value;
      if (!value) _reminderTime = null;
    });
    await _saveReminderSettings();
  }

  Future<void> _pickReminderTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime != null
          ? med_entity.TimeOfDay(hour: _reminderTime!.hour, minute: _reminderTime!.minute)
          : med_entity.TimeOfDay(hour: 9, minute: 0),
    );
    if (picked != null) {
      setState(() {
        _reminderTime = med_entity.TimeOfDay(hour: picked.hour, minute: picked.minute);
      });
      await _saveReminderSettings();
    }
  }

  Future<void> _saveReminderSettings() async {
    final medProvider = context.read<med_entity.MedicationProvider>();
    final updated = _medication.copyWith(
      reminderEnabled: _reminderEnabled,
      reminderTime: _reminderTime,
    );
    await medProvider.editmed_entity.Medication(updated);
    _medication = updated;

    if (_reminderEnabled && _reminderTime != null) {
      await NotificationService().schedulemed_entity.MedicationNotifications(_medication);
    } else {
      await NotificationService().cancelmed_entity.MedicationNotifications(_medication.id);
    }
  }

  Future<void> _changeReferenceDate() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Reference Date?'),
        content: const Text(
          'Changing the reference date will change your medication schedule for all past and future dates.\n\n'
          'This should only be done under medical guidance. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Change Date'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final picked = await showDatePicker(
      context: context,
      initialDate: _medication.referenceDate.toDateTime(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null && mounted) {
      final medProvider = context.read<med_entity.MedicationProvider>();
      final updated = _medication.copyWith(
        referenceDate: AppDate.fromDateTime(picked),
      );
      await medProvider.editmed_entity.Medication(updated);
      _medication = updated;

      // Reschedule notifications
      if (_reminderEnabled && _reminderTime != null) {
        await NotificationService().schedulemed_entity.MedicationNotifications(_medication);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reference date updated. Schedule recalculated.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete med_entity.Medication?'),
        content: Text(
          'Are you sure you want to delete "${_medication.name}"? This will also delete all history records and cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final medProvider = context.read<med_entity.MedicationProvider>();
      await medProvider.removemed_entity.Medication(_medication.id);
      await NotificationService().cancelmed_entity.MedicationNotifications(_medication.id);
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }
}