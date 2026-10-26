import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:medication_scheduler/core/constants/app_constants.dart';
import 'package:medication_scheduler/core/date/date_utils.dart';
import 'package:medication_scheduler/features/medications/domain/entities/medication.dart';
import 'package:medication_scheduler/features/medications/presentation/providers/medication_provider.dart';
import 'package:medication_scheduler/features/schedule/presentation/providers/schedule_provider.dart';
import 'package:medication_scheduler/features/history/presentation/providers/history_provider.dart';
import 'package:medication_scheduler/features/history/domain/entities/medication_record.dart';
import 'package:medication_scheduler/features/schedule/domain/entities/schedule_day.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer3<MedicationProvider, ScheduleProvider, HistoryProvider>(
      builder: (context, medProvider, scheduleProvider, historyProvider, _) {
        final medication = scheduleProvider.medication;

        if (medication == null) {
          return _buildEmptyState(context, medProvider);
        }

        final today = AppDate.today();
        final todaySchedule = scheduleProvider.today;
        final nextDose = scheduleProvider.getNextDoseDate();
        final shouldTake = scheduleProvider.shouldTakeToday;

        return Scaffold(
          appBar: AppBar(
            title: Text(AppConstants.appName),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                onPressed: () => Navigator.pushNamed(context, '/settings'),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Main Status Card
                _buildStatusCard(context, medication, today, todaySchedule, shouldTake, nextDose),
                const SizedBox(height: 24),

                // Today's Schedule Info
                _buildTodaysSchedule(context, medication, today, todaySchedule, nextDose),
                const SizedBox(height: 24),

                // Quick Actions
                _buildQuickActions(context, medication, today, todaySchedule, historyProvider),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, MedicationProvider medProvider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.medication_outlined, size: 80, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              'No Medications Yet',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first medication to get started',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Add Medication'),
              onPressed: () => Navigator.pushNamed(context, '/setup'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(
    BuildContext context,
    Medication medication,
    AppDate today,
    ScheduleDay? todaySchedule,
    bool shouldTake,
    AppDate? nextDose,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final isTake = shouldTake;

    return Card(
      elevation: 0,
      color: isTake
          ? colorScheme.primaryContainer
          : colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: isTake ? colorScheme.primary : colorScheme.outlineVariant,
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Text(
              'TODAY',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: isTake ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant,
                    letterSpacing: 2,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              today.formatFull(),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: isTake ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 24),

            // Main status
            Icon(
              isTake ? Icons.check_circle_outline : Icons.cancel_outlined,
              size: 80,
              color: isTake ? colorScheme.primary : colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              isTake ? 'Take your medication' : 'Do not take your medication',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: isTake ? colorScheme.onPrimaryContainer : colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // Medication info
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isTake
                    ? colorScheme.primary.withOpacity(0.1)
                    : colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    medication.name,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  if (medication.dosage != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      medication.dosage!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ],
              ),
            ),

            if (!isTake && nextDose != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.schedule, size: 20, color: colorScheme.onSecondaryContainer),
                    const SizedBox(width: 8),
                    Text(
                      'Next dose: ${nextDose.formatFull()}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: colorScheme.onSecondaryContainer,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTodaysSchedule(
    BuildContext context,
    Medication medication,
    AppDate today,
    ScheduleDay? todaySchedule,
    AppDate? nextDose,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Today's Schedule",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              context,
              'Today',
              today.formatFull(),
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              context,
              'Medication',
              medication.name,
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              context,
              "Today's Status",
              todaySchedule?.isTake == true ? 'TAKE' : 'SKIP',
              valueStyle: TextStyle(
                fontWeight: FontWeight.bold,
                color: todaySchedule?.isTake == true
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              context,
              'Next Dose',
              nextDose?.formatFull() ?? '—',
            ),
            if (medication.dosage != null) ...[
              const SizedBox(height: 12),
              _buildInfoRow(
                context,
                'Dosage',
                medication.dosage!,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value, {
    TextStyle? valueStyle,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        Text(
          value,
          style: valueStyle ?? Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(
    BuildContext context,
    Medication medication,
    AppDate today,
    ScheduleDay? todaySchedule,
    HistoryProvider historyProvider,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final isTake = todaySchedule?.isTake ?? false;
    final existingRecord = historyProvider.getRecordForDate(today);

    if (!isTake) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 16),
            if (existingRecord?.isTaken ?? false) ...[
              _buildActionButton(
                context,
                'Mark as Not Taken',
                Icons.undo_outlined,
                colorScheme.secondary,
                () => historyProvider.clearStatus(medication.id, today),
              ),
            ] else if (existingRecord?.isMissed ?? false) ...[
              _buildActionButton(
                context,
                'Mark as Taken',
                Icons.check_circle_outlined,
                colorScheme.primary,
                () => historyProvider.markTaken(
                  medication.id,
                  today,
                  todaySchedule!.scheduledStatus,
                ),
              ),
              const SizedBox(height: 12),
              _buildActionButton(
                context,
                'Clear Status',
                Icons.clear_outlined,
                colorScheme.outline,
                () => historyProvider.clearStatus(medication.id, today),
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      context,
                      'Mark Taken',
                      Icons.check_circle_outlined,
                      colorScheme.primary,
                      () => historyProvider.markTaken(
                        medication.id,
                        today,
                        todaySchedule!.scheduledStatus,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildActionButton(
                      context,
                      'Mark Missed',
                      Icons.cancel_outlined,
                      colorScheme.error,
                      () => historyProvider.markMissed(
                        medication.id,
                        today,
                        todaySchedule!.scheduledStatus,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return FilledButton.icon(
      icon: Icon(icon),
      label: Text(label),
      style: FilledButton.styleFrom(
        backgroundColor: color,
        foregroundColor: color.computeLuminance() > 0.5 ? Colors.black : Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: onPressed,
    );
  }
}