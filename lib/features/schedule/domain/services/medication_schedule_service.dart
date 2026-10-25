import 'package:medication_scheduler/core/date/date_utils.dart';
import 'package:medication_scheduler/features/history/domain/entities/medication_record.dart';
import 'package:medication_scheduler/features/schedule/domain/entities/schedule_day.dart';

/// Core schedule calculation engine.
/// All calculations use calendar dates only (AppDate) to avoid DST/timezone issues.
class MedicationScheduleService {
  const MedicationScheduleService();

  /// Determines if medication should be taken on [date] given [referenceDate].
  /// Returns true for TAKE days, false for SKIP days.
  /// Works for past, present, and future dates.
  bool shouldTake({
    required AppDate referenceDate,
    required AppDate date,
  }) {
    final diff = date.differenceInDays(referenceDate);
    return diff % 2 == 0;
  }

  /// Gets the scheduled status for a date.
  ScheduledStatus getScheduledStatus({
    required AppDate referenceDate,
    required AppDate date,
  }) {
    return shouldTake(referenceDate: referenceDate, date: date)
        ? ScheduledStatus.TAKE
        : ScheduledStatus.SKIP;
  }

  /// Gets the next dose date on or after [fromDate].
  /// If [fromDate] is a TAKE day, returns [fromDate].
  /// Otherwise returns the next TAKE day.
  AppDate? getNextDoseDate({
    required AppDate referenceDate,
    required AppDate fromDate,
  }) {
    final diff = fromDate.differenceInDays(referenceDate);
    if (diff % 2 == 0) {
      return fromDate;
    }
    return fromDate.addDays(1);
  }

  /// Gets the previous dose date on or before [fromDate].
  /// If [fromDate] is a TAKE day, returns [fromDate].
  /// Otherwise returns the previous TAKE day.
  AppDate? getPreviousDoseDate({
    required AppDate referenceDate,
    required AppDate fromDate,
  }) {
    final diff = fromDate.differenceInDays(referenceDate);
    if (diff % 2 == 0) {
      return fromDate;
    }
    return fromDate.subtractDays(1);
  }

  /// Gets the schedule for a range of dates.
  /// Optionally merges with actual history records.
  ScheduleRange getScheduleForRange({
    required AppDate referenceDate,
    required AppDate startDate,
    required AppDate endDate,
    List<MedicationRecord>? historyRecords,
  }) {
    final days = <ScheduleDay>[];
    final historyMap = <String, MedicationRecord>{};

    if (historyRecords != null) {
      for (final record in historyRecords) {
        historyMap[record.date.toString()] = record;
      }
    }

    var current = startDate;
    while (current <= endDate) {
      final record = historyMap[current.toString()];
      days.add(ScheduleDay.fromReference(
        date: current,
        referenceDate: referenceDate,
        actualStatus: record?.actualStatus,
      ));
      current = current.addDays(1);
    }

    return ScheduleRange(
      startDate: startDate,
      endDate: endDate,
      days: days,
    );
  }

  /// Gets the schedule for a week containing [date].
  /// Week starts on Monday.
  ScheduleRange getWeekSchedule({
    required AppDate referenceDate,
    required AppDate date,
    List<MedicationRecord>? historyRecords,
  }) {
    // Find Monday of the week
    final dateTime = date.toDateTime();
    final monday = dateTime.subtract(Duration(days: dateTime.weekday - 1));
    final startDate = AppDate.fromDateTime(monday);
    final endDate = startDate.addDays(6);

    return getScheduleForRange(
      referenceDate: referenceDate,
      startDate: startDate,
      endDate: endDate,
      historyRecords: historyRecords,
    );
  }

  /// Gets the schedule for a month containing [date].
  ScheduleRange getMonthSchedule({
    required AppDate referenceDate,
    required AppDate date,
    List<MedicationRecord>? historyRecords,
  }) {
    final dateTime = date.toDateTime();
    final firstDay = DateTime(dateTime.year, dateTime.month, 1);
    final lastDay = DateTime(dateTime.year, dateTime.month + 1, 0);
    final startDate = AppDate.fromDateTime(firstDay);
    final endDate = AppDate.fromDateTime(lastDay);

    return getScheduleForRange(
      referenceDate: referenceDate,
      startDate: startDate,
      endDate: endDate,
      historyRecords: historyRecords,
    );
  }

  /// Gets the next N dose dates from [fromDate].
  List<AppDate> getUpcomingDoses({
    required AppDate referenceDate,
    required AppDate fromDate,
    int count = 10,
  }) {
    final doses = <AppDate>[];
    var current = getNextDoseDate(referenceDate: referenceDate, fromDate: fromDate);

    while (current != null && doses.length < count) {
      doses.add(current);
      current = current.addDays(2); // Every other day
    }

    return doses;
  }

  /// Gets the previous N dose dates from [fromDate].
  List<AppDate> getPreviousDoses({
    required AppDate referenceDate,
    required AppDate fromDate,
    int count = 10,
  }) {
    final doses = <AppDate>[];
    var current = getPreviousDoseDate(referenceDate: referenceDate, fromDate: fromDate);

    while (current != null && doses.length < count) {
      doses.add(current);
      current = current.subtractDays(2);
    }

    return doses;
  }
}