import 'package:flutter/foundation.dart';
import 'package:medication_scheduler/core/date/date_utils.dart';
import 'package:medication_scheduler/features/history/domain/entities/medication_record.dart';
import 'package:medication_scheduler/features/history/domain/usecases/create_or_update_record.dart';
import 'package:medication_scheduler/features/history/domain/usecases/get_medication_records.dart';
import 'package:medication_scheduler/features/history/domain/usecases/get_records_for_date_range.dart';

class HistoryProvider extends ChangeNotifier {
  final GetMedicationRecords getMedicationRecords;
  final GetRecordsForDateRange getRecordsForDateRange;
  final CreateOrUpdateRecord createOrUpdateRecord;

  List<MedicationRecord> _records = [];
  bool _isLoading = false;
  String? _error;

  HistoryProvider({
    required this.getMedicationRecords,
    required this.getRecordsForDateRange,
    required this.createOrUpdateRecord,
  });

  List<MedicationRecord> get records => _records;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Load all records for a medication.
  Future<void> loadRecords(String medicationId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await getMedicationRecords(medicationId);
    result.fold(
      (failure) => _error = failure.message,
      (records) => _records = records,
    );

    _isLoading = false;
    notifyListeners();
  }

  /// Load records for a date range.
  Future<void> loadRecordsForRange(
    String medicationId,
    AppDate startDate,
    AppDate endDate,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await getRecordsForDateRange(medicationId, startDate, endDate);
    result.fold(
      (failure) => _error = failure.message,
      (records) => _records = records,
    );

    _isLoading = false;
    notifyListeners();
  }

  /// Mark a dose as taken.
  Future<bool> markTaken(String medicationId, AppDate date, ScheduledStatus scheduledStatus) async {
    final existing = getRecordForDate(date);

    final record = existing?.copyWith(
          actualStatus: ActualStatus.TAKEN,
        ) ??
        MedicationRecord.create(
          medicationId: medicationId,
          date: date,
          scheduledStatus: scheduledStatus,
          actualStatus: ActualStatus.TAKEN,
        );

    final result = await createOrUpdateRecord(record);
    final success = result.fold(
      (failure) {
        _error = failure.message;
        return false;
      },
      (_) => true,
    );

    if (success) {
      await loadRecords(medicationId);
    }

    return success;
  }

  /// Mark a dose as missed.
  Future<bool> markMissed(String medicationId, AppDate date, ScheduledStatus scheduledStatus) async {
    final existing = getRecordForDate(date);

    final record = existing?.copyWith(
          actualStatus: ActualStatus.MISSED,
        ) ??
        MedicationRecord.create(
          medicationId: medicationId,
          date: date,
          scheduledStatus: scheduledStatus,
          actualStatus: ActualStatus.MISSED,
        );

    final result = await createOrUpdateRecord(record);
    final success = result.fold(
      (failure) {
        _error = failure.message;
        return false;
      },
      (_) => true,
    );

    if (success) {
      await loadRecords(medicationId);
    }

    return success;
  }

  /// Clear the actual status for a date.
  Future<bool> clearStatus(String medicationId, AppDate date) async {
    final existing = getRecordForDate(date);

    if (existing == null) return false;

    final record = existing.clearStatus();
    final result = await createOrUpdateRecord(record);
    final success = result.fold(
      (failure) {
        _error = failure.message;
        return false;
      },
      (_) => true,
    );

    if (success) {
      await loadRecords(medicationId);
    }

    return success;
  }

  /// Get record for a specific date.
  MedicationRecord? getRecordForDate(AppDate date) {
    try {
      return _records.firstWhere((r) => r.date == date);
    } catch (_) {
      return null;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}