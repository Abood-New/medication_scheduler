import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:medication_scheduler/core/date/date_utils.dart';
import 'package:medication_scheduler/features/medications/presentation/providers/medication_provider.dart';
import 'package:medication_scheduler/features/schedule/presentation/providers/schedule_provider.dart';
import 'package:medication_scheduler/features/schedule/domain/entities/schedule_day.dart';
import 'package:medication_scheduler/features/history/domain/entities/medication_record.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  late AppDate _currentWeekStart;
  late AppDate _currentMonth;

  @override
  void initState() {
    super.initState();
    final today = AppDate.today();
    _currentWeekStart = _getWeekStart(today);
    _currentMonth = AppDate(today.year, today.month, 1);
  }

  AppDate _getWeekStart(AppDate date) {
    final dt = date.toDateTime();
    final monday = dt.subtract(Duration(days: dt.weekday - 1));
    return AppDate.fromDateTime(monday);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<MedicationProvider, ScheduleProvider>(
      builder: (context, medProvider, scheduleProvider, _) {
        final medication = scheduleProvider.medication;

        if (medication == null) {
          return _buildEmptyState(context);
        }

        return DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: AppBar(
              title: Text(medication.name),
              bottom: const TabBar(
                tabs: [
                  Tab(text: 'Week'),
                  Tab(text: 'Month'),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.today_outlined),
                  onPressed: () => _goToToday(scheduleProvider),
                  tooltip: 'Today',
                ),
              ],
            ),
            body: TabBarView(
              children: [
                _buildWeekView(context, scheduleProvider),
                _buildMonthView(context, scheduleProvider),
              ],
            ),
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
          Icon(Icons.calendar_month_outlined,
              size: 80, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 16),
          Text('No medication selected',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text('Add a medication to view the schedule',
              style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }

  void _goToToday(ScheduleProvider scheduleProvider) {
    final today = AppDate.today();
    setState(() {
      _currentWeekStart = _getWeekStart(today);
      _currentMonth = AppDate(today.year, today.month, 1);
    });
    scheduleProvider.navigateToWeek(today);
    scheduleProvider.navigateToMonth(today);
  }

  Widget _buildWeekView(
      BuildContext context, ScheduleProvider scheduleProvider) {
    final weekSchedule = scheduleProvider.weekSchedule;

    return Column(
      children: [
        // Week navigation
        _buildWeekNavigation(context),
        const SizedBox(height: 8),
        // Week grid
        if (weekSchedule != null)
          Expanded(
            child: _buildWeekGrid(context, weekSchedule),
          ),
      ],
    );
  }

  Widget _buildWeekNavigation(BuildContext context) {
    final weekEnd = _currentWeekStart.addDays(6);
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
                  _currentWeekStart = _currentWeekStart.subtractDays(7);
                });
                context
                    .read<ScheduleProvider>()
                    .navigateToWeek(_currentWeekStart);
              },
            ),
            Column(
              children: [
                Text(
                  '${_currentWeekStart.formatShort()} - ${weekEnd.formatShort()}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                Text(
                  '${_currentWeekStart.format('MMMM yyyy')}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () {
                setState(() {
                  _currentWeekStart = _currentWeekStart.addDays(7);
                });
                context
                    .read<ScheduleProvider>()
                    .navigateToWeek(_currentWeekStart);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekGrid(BuildContext context, ScheduleRange weekSchedule) {
    final days = weekSchedule.days;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Day headers
          Row(
            children: days.map((day) => _buildDayHeader(context, day)).toList(),
          ),
          const SizedBox(height: 8),
          // Status row
          Row(
            children: days.map((day) => _buildDayStatus(context, day)).toList(),
          ),
          const SizedBox(height: 24),
          // Legend
          _buildLegend(context),
        ],
      ),
    );
  }

  Widget _buildDayHeader(BuildContext context, ScheduleDay day) {
    final isToday = day.isToday;
    final colorScheme = Theme.of(context).colorScheme;

    return Expanded(
      child: Column(
        children: [
          Text(
            day.date.formatDay(),
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: isToday
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                  fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            day.date.day.toString(),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: isToday ? colorScheme.primary : colorScheme.onSurface,
                  fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                ),
          ),
          if (isToday)
            Container(
              margin: const EdgeInsets.only(top: 4),
              height: 3,
              width: 24,
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDayStatus(BuildContext context, ScheduleDay day) {
    final isTake = day.isTake;
    final isToday = day.isToday;
    final isTaken = day.isTaken;
    final isMissed = day.isMissed;
    final colorScheme = Theme.of(context).colorScheme;

    Color backgroundColor;
    Color iconColor;
    IconData icon;

    if (isTake) {
      if (isTaken) {
        backgroundColor = colorScheme.primaryContainer;
        iconColor = colorScheme.onPrimaryContainer;
        icon = Icons.check;
      } else if (isMissed) {
        backgroundColor = colorScheme.errorContainer;
        iconColor = colorScheme.onErrorContainer;
        icon = Icons.close;
      } else {
        backgroundColor = colorScheme.primaryContainer;
        iconColor = colorScheme.onPrimaryContainer;
        icon = Icons.check;
      }
    } else {
      backgroundColor = colorScheme.surfaceContainerHighest;
      iconColor = colorScheme.onSurfaceVariant;
      icon = Icons.remove;
    }

    return Expanded(
      child: Container(
        height: 60,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border:
              isToday ? Border.all(color: colorScheme.primary, width: 2) : null,
        ),
        child: Center(
          child: Icon(
            icon,
            color: iconColor,
            size: 28,
          ),
        ),
      ),
    );
  }

  Widget _buildLegend(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Wrap(
      spacing: 16,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        _buildLegendItem(context, Icons.check, 'Take',
            colorScheme.primaryContainer, colorScheme.onPrimaryContainer),
        _buildLegendItem(context, Icons.remove, 'Skip',
            colorScheme.surfaceContainerHighest, colorScheme.onSurfaceVariant),
        _buildLegendItem(context, Icons.check, 'Taken',
            colorScheme.primaryContainer, colorScheme.onPrimaryContainer),
        _buildLegendItem(context, Icons.close, 'Missed',
            colorScheme.errorContainer, colorScheme.onErrorContainer),
        _buildLegendItem(context, Icons.circle_outlined, 'Today',
            Colors.transparent, colorScheme.primary,
            border: true),
      ],
    );
  }

  Widget _buildLegendItem(
    BuildContext context,
    IconData icon,
    String label,
    Color bgColor,
    Color iconColor, {
    bool border = false,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(6),
            border: border ? Border.all(color: iconColor, width: 2) : null,
          ),
          child: Icon(icon, color: iconColor, size: 16),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  Widget _buildMonthView(
      BuildContext context, ScheduleProvider scheduleProvider) {
    final monthSchedule = scheduleProvider.monthSchedule;

    return Column(
      children: [
        // Month navigation
        _buildMonthNavigation(context),
        const SizedBox(height: 8),
        // Month grid
        if (monthSchedule != null)
          Expanded(
            child: _buildMonthGrid(context, monthSchedule),
          ),
      ],
    );
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
                  _currentMonth =
                      AppDate(_currentMonth.year, _currentMonth.month - 1, 1);
                });
                context.read<ScheduleProvider>().navigateToMonth(_currentMonth);
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
                  _currentMonth =
                      AppDate(_currentMonth.year, _currentMonth.month + 1, 1);
                });
                context.read<ScheduleProvider>().navigateToMonth(_currentMonth);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthGrid(BuildContext context, ScheduleRange monthSchedule) {
    final days = monthSchedule.days;
    final colorScheme = Theme.of(context).colorScheme;

    // Group by week
    final weeks = <List<ScheduleDay>>[];
    var currentWeek = <ScheduleDay>[];

    for (final day in days) {
      currentWeek.add(day);
      if (day.date.toDateTime().weekday == 7) {
        weeks.add(currentWeek);
        currentWeek = [];
      }
    }
    if (currentWeek.isNotEmpty) {
      weeks.add(currentWeek);
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Day headers
          Row(
            children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                .map((d) => Expanded(
                      child: Center(
                        child: Text(
                          d,
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 4),
          // Weeks
          Expanded(
            child: ListView.builder(
              itemCount: weeks.length,
              itemBuilder: (context, weekIndex) {
                final week = weeks[weekIndex];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      // Fill empty days before week start
                      if (week.first.date.toDateTime().weekday > 1)
                        Expanded(
                          flex: week.first.date.toDateTime().weekday - 1,
                          child: const SizedBox(),
                        ),
                      ...week.map((day) => Expanded(
                            child: _buildMonthDayCell(context, day),
                          )),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          _buildLegend(context),
        ],
      ),
    );
  }

  Widget _buildMonthDayCell(BuildContext context, ScheduleDay day) {
    final isTake = day.isTake;
    final isToday = day.isToday;
    final isTaken = day.isTaken;
    final isMissed = day.isMissed;
    final colorScheme = Theme.of(context).colorScheme;

    Color bgColor;
    Color textColor;
    String text;

    if (isTake) {
      if (isTaken) {
        bgColor = colorScheme.primaryContainer;
        textColor = colorScheme.onPrimaryContainer;
        text = '✓';
      } else if (isMissed) {
        bgColor = colorScheme.errorContainer;
        textColor = colorScheme.onErrorContainer;
        text = '✗';
      } else {
        bgColor = colorScheme.primaryContainer;
        textColor = colorScheme.onPrimaryContainer;
        text = day.date.day.toString();
      }
    } else {
      bgColor = colorScheme.surfaceContainerHighest;
      textColor = colorScheme.onSurfaceVariant;
      text = day.date.day.toString();
    }

    return Container(
      height: 36,
      margin: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border:
            isToday ? Border.all(color: colorScheme.primary, width: 2) : null,
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            color: textColor,
            fontWeight: isToday || isTaken || isMissed
                ? FontWeight.bold
                : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
