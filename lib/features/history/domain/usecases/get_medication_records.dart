import 'package:dartz/dartz.dart';
import 'package:medication_scheduler/core/date/date_utils.dart';
import 'package:medication_scheduler/core/errors/failures.dart';
import 'package:medication_scheduler/features/history/domain/entities/medication_record.dart';
import 'package:medication_scheduler/features/history/domain/repositories/medication_record_repository.dart';

class GetMedicationRecords {
  final MedicationRecordRepository repository;

  GetMedicationRecords(this.repository);

  Future<Either<Failure, List<MedicationRecord>>> call(String medicationId) async {
    return await repository.getRecordsForMedication(medicationId);
  }
}