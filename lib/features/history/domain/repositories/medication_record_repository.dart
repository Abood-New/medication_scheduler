import 'package:dartz/dartz.dart';
import 'package:medication_scheduler/core/errors/failures.dart';
import 'package:medication_scheduler/core/date/date_utils.dart';
import 'package:medication_scheduler/features/history/domain/entities/medication_record.dart';

abstract class MedicationRecordRepository {
  Future<Either<Failure, List<MedicationRecord>>> getRecordsForMedication(
    String medicationId,
  );
  Future<Either<Failure, List<MedicationRecord>>> getRecordsForDateRange(
    String medicationId,
    AppDate startDate,
    AppDate endDate,
  );
  Future<Either<Failure, MedicationRecord?>> getRecordForDate(
    String medicationId,
    AppDate date,
  );
  Future<Either<Failure, MedicationRecord>> createOrUpdateRecord(
    MedicationRecord record,
  );
  Future<Either<Failure, void>> deleteRecord(String id);
  Future<Either<Failure, void>> deleteAllRecordsForMedication(String medicationId);
}