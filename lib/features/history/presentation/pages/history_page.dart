import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:medication_scheduler/core/date/date_utils.dart';
import 'package:medication_scheduler/features/medications/domain/entities/medication.dart';
import 'package:medication_scheduler/features/medications/presentation/providers/medication_provider.dart';
import 'package:medication_scheduler/features/history/presentation/providers/history_provider.dart';
import 'package:medication_scheduler/features/history/domain/entities/medication_record.dart';
import 'package:medication_scheduler/features/schedule/domain/entities/schedule_day.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  late AppDate _currentMonth;

  @override
  void initState() {
    super.initState();
    _currentMonth = AppDate.today();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<MedicationProvider, HistoryProvider>(
      builder: (context, medProvider, historyProvider, _) {
        final medication = medProvider.selectedMedication;

        if (medication == null) {
          return _buildEmptyState(context);
        }

        // Load records when medication changes
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (historyProvider.records.isEmpty || historyProvider.isLoading == false) {
            historyProvider.loadRecords(medication.id);
          }
        });

        return Scaffold(
          appBar: AppBar(
            title: Text('History - ${medication.name}'),
            actions: [
              IconButton(
                icon: const Icon(Icons.today_outlined),
                onPressed: () => _goToCurrentMonth(historyProvider),
                tooltip: 'Current Month',
              ),
            ],
          ),
          body: Column(
            children: [
              // Month navigation
              _buildMonthNavigation(context),
              // History list
              Expanded(
                child: _buildHistoryList(context, historyProvider, medication),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_outlined, size: 80, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 16),
          Text('No medication selected', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text('Select a medication to view history', style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }

  void _goToCurrentMonth(HistoryProvider historyProvider) {
    setState(() {
      _currentMonth = AppDate.today();
    });
  }

  Widget _buildMonthNavigation(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () {
                setState(() {
                  _currentMonth = AppDate(_currentMonth.year, _currentMonth.month - 1, 1);
                });
              },
            ),
            Text(
              _currentMonth.format('MMMM yyyy'),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () {
                setState(() {
                  _currentMonth = AppDate(_currentMonth.year, _currentMonth.month + 1, 1);
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryList(
    BuildContext context,
    HistoryProvider historyProvider,
    Medication medication,
  ) {
    if (historyProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Filter records for current month
    final monthStart = _currentMonth;
    final monthEnd = AppDate(_currentMonth.year, _currentMonth.month + 1, 0);
    final monthRecords = historyProvider.records.where((r) {
      return r.date >= monthStart && r.date <= monthEnd;
    }).toList();

    if (monthRecords.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_outlined, size: 64, color: Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text('No records for this month', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Tap a date on a TAKE day to mark it as taken or missed',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Sort by date descending
    monthRecords.sort((a, b) => b.date.compareTo(a.date));

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: monthRecords.length,
      itemBuilder: (context, index) {
        final record = monthRecords[index];
        return _buildHistoryItem(context, record, medication);
      },
    );
  }

  Widget _buildHistoryItem(
    BuildContext context,
    MedicationRecord record,
    Medication medication,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final isTake = record.isScheduledTake;
    final isTaken = record.isTaken;
    final isMissed = record.isMissed;
    final isNotRecorded = record.isNotRecorded;

    Color statusColor;
    IconData statusIcon;
    String statusText;

    if (isTake) {
      if (isTaken) {
        statusColor = colorScheme.primary;
        statusIcon = Icons.check_circle;
        statusText = 'Taken';
      } else if (isMissed) {
        statusColor = colorScheme.error;
        statusIcon = Icons.cancel;
        statusText = 'Missed';
      } else {
        statusColor = colorScheme.primary;
        statusIcon = Icons.radio_button_unchecked;
        statusText = 'Scheduled';
      }
    } else {
      statusColor = colorScheme.onSurfaceVariant;
      statusIcon = Icons.remove_circle_outline;
      statusText = 'Rest Day';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(statusIcon, color: statusColor),
        ),
        title: Text(
          record.date.formatFull(),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
        ),
        subtitle: Text(
          isTake ? 'Medication day' : 'Scheduled rest day',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                statusText,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ],
        ),
        onTap: isTake && !isTaken && !isMissed
            ? () => _showActionDialog(context, record, medication, historyProvider)
            : null,
      ),
    );
  }

  void _showActionDialog(
    BuildContext context,
    MedicationRecord record,
    Medication medication,
    HistoryProvider historyProvider,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              record.date.formatFull(),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'How did this dose go?',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.check),
                    label: const Text('Taken'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.primary,
                      side: BorderSide(color: Theme.of(context).colorScheme.primary),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: () async {
                      await historyProvider.markTaken(
                        medication.id,
                        record.date,
                        record.scheduledStatus,
                      );
                      if (context.mounted) Navigator.pop(context);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.close),
                    label: const Text('Missed'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.error,
                      side: BorderSide(color: Theme.of(context).colorScheme.error),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: () async {
                      await historyProvider.markMissed(
                        medication.id,
                        record.date,
                        record.scheduledStatus,
                      );
                      if (context.mounted) Navigator.pop(context);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Dose marked as missed.\nYour schedule has not been changed.\nFollow your prescribed instructions for what to do next.',
                            ),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}