import 'package:flutter/foundation.dart';
import 'package:medication_scheduler/core/date/date_utils.dart';
import 'package:medication_scheduler/features/history/domain/entities/medication_record.dart';
import 'package:medication_scheduler/features/medications/domain/entities/medication.dart';
import 'package:medication_scheduler/features/schedule/domain/entities/schedule_day.dart';
import 'package:medication_scheduler/features/schedule/domain/services/medication_schedule_service.dart';

class ScheduleProvider extends ChangeNotifier {
  final MedicationScheduleService _scheduleService = const MedicationScheduleService();
  Medication? _medication;
  List<MedicationRecord> _historyRecords = [];
  ScheduleRange? _weekSchedule;
  ScheduleRange? _monthSchedule;

  Medication? get medication => _medication;
  ScheduleRange? get weekSchedule => _weekSchedule;
  ScheduleRange? get monthSchedule => _monthSchedule;
  ScheduleDay? get today => _weekSchedule?.today;
  bool get shouldTakeToday => today?.isTake ?? false;

  /// Set the medication and recalculate schedules.
  void setMedication(Medication medication, List<MedicationRecord> historyRecords) {
    _medication = medication;
    _historyRecords = historyRecords;
    _recalculateSchedules();
    notifyListeners();
  }

  /// Update history records and recalculate.
  void updateHistory(List<MedicationRecord> records) {
    _historyRecords = records;
    _recalculateSchedules();
    notifyListeners();
  }

  /// Recalculate all schedules.
  void _recalculateSchedules() {
    if (_medication == null) return;

    final today = AppDate.today();
    _weekSchedule = _scheduleService.getWeekSchedule(
      referenceDate: _medication!.referenceDate,
      date: today,
      historyRecords: _historyRecords,
    );

    _monthSchedule = _scheduleService.getMonthSchedule(
      referenceDate: _medication!.referenceDate,
      date: today,
      historyRecords: _historyRecords,
    );
  }

  /// Get schedule for a specific date.
  ScheduleDay getScheduleForDate(AppDate date) {
    if (_medication == null) {
      return ScheduleDay(
        date: date,
        scheduledStatus: ScheduledStatus.SKIP,
        isToday: date.isToday,
      );
    }

    MedicationRecord? record;
    for (final r in _historyRecords) {
      if (r.date == date) {
        record = r;
        break;
      }
    }

    return ScheduleDay.fromReference(
      date: date,
      referenceDate: _medication!.referenceDate,
      actualStatus: record?.actualStatus,
    );
  }

  /// Get schedule for a custom range.
  ScheduleRange getScheduleForRange(AppDate startDate, AppDate endDate) {
    if (_medication == null) {
      return ScheduleRange(startDate: startDate, endDate: endDate, days: []);
    }

    return _scheduleService.getScheduleForRange(
      referenceDate: _medication!.referenceDate,
      startDate: startDate,
      endDate: endDate,
      historyRecords: _historyRecords,
    );
  }

  /// Get next dose date.
  AppDate? getNextDoseDate() {
    if (_medication == null) return null;
    return _scheduleService.getNextDoseDate(
      referenceDate: _medication!.referenceDate,
      fromDate: AppDate.today(),
    );
  }

  /// Get upcoming doses.
  List<AppDate> getUpcomingDoses({int count = 5}) {
    if (_medication == null) return [];
    return _scheduleService.getUpcomingDoses(
      referenceDate: _medication!.referenceDate,
      fromDate: AppDate.today(),
      count: count,
    );
  }

  /// Navigate to a different week.
  void navigateToWeek(AppDate date) {
    if (_medication == null) return;
    _weekSchedule = _scheduleService.getWeekSchedule(
      referenceDate: _medication!.referenceDate,
      date: date,
      historyRecords: _historyRecords,
    );
    notifyListeners();
  }

  /// Navigate to a different month.
  void navigateToMonth(AppDate date) {
    if (_medication == null) return;
    _monthSchedule = _scheduleService.getMonthSchedule(
      referenceDate: _medication!.referenceDate,
      date: date,
      historyRecords: _historyRecords,
    );
    notifyListeners();
  }
}