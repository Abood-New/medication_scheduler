import 'package:hive/hive.dart';
import 'package:medication_scheduler/core/constants/app_constants.dart';
import 'package:medication_scheduler/core/date/date_utils.dart';
import 'package:medication_scheduler/core/errors/failures.dart';
import 'package:medication_scheduler/features/history/data/models/medication_record_hive_model.dart';

class MedicationRecordLocalDataSource {
  Box<MedicationRecordHiveModel>? _box;

  Future<Box<MedicationRecordHiveModel>> get _recordBox async {
    _box ??= await Hive.openBox<MedicationRecordHiveModel>(
      AppConstants.hiveBoxRecords,
    );
    return _box!;
  }

  Future<List<MedicationRecordHiveModel>> getRecordsForMedication(
    String medicationId,
  ) async {
    try {
      final box = await _recordBox;
      return box.values
          .where((r) => r.medicationId == medicationId)
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));
    } catch (e) {
      throw DatabaseFailure('Failed to get records: $e');
    }
  }

  Future<List<MedicationRecordHiveModel>> getRecordsForDateRange(
    String medicationId,
    AppDate startDate,
    AppDate endDate,
  ) async {
    try {
      final box = await _recordBox;
      final startStr = startDate.toString();
      final endStr = endDate.toString();
      return box.values
          .where((r) =>
              r.medicationId == medicationId &&
              r.date.compareTo(startStr) >= 0 &&
              r.date.compareTo(endStr) <= 0)
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));
    } catch (e) {
      throw DatabaseFailure('Failed to get records for range: $e');
    }
  }

  Future<MedicationRecordHiveModel?> getRecordForDate(
    String medicationId,
    AppDate date,
  ) async {
    try {
      final box = await _recordBox;
      final key = '${medicationId}_${date.toString()}';
      return box.get(key);
    } catch (e) {
      throw DatabaseFailure('Failed to get record for date: $e');
    }
  }

  Future<MedicationRecordHiveModel> createOrUpdateRecord(
    MedicationRecordHiveModel record,
  ) async {
    try {
      final box = await _recordBox;
      await box.put(record.id, record);
      return record;
    } catch (e) {
      throw DatabaseFailure('Failed to create/update record: $e');
    }
  }

  Future<void> deleteRecord(String id) async {
    try {
      final box = await _recordBox;
      if (!box.containsKey(id)) {
        throw NotFoundFailure('Record not found: $id');
      }
      await box.delete(id);
    } catch (e) {
      if (e is NotFoundFailure) rethrow;
      throw DatabaseFailure('Failed to delete record: $e');
    }
  }

  Future<void> deleteAllRecordsForMedication(String medicationId) async {
    try {
      final box = await _recordBox;
      final keysToDelete = box.values
          .where((r) => r.medicationId == medicationId)
          .map((r) => r.id)
          .toList();
      await box.deleteAll(keysToDelete);
    } catch (e) {
      throw DatabaseFailure('Failed to delete all records: $e');
    }
  }

  Future<void> close() async {
    await _box?.close();
    _box = null;
  }
}