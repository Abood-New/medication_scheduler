import 'package:dartz/dartz.dart';
import 'package:medication_scheduler/core/errors/failures.dart';
import 'package:medication_scheduler/features/history/domain/entities/medication_record.dart';
import 'package:medication_scheduler/features/history/domain/repositories/medication_record_repository.dart';

class CreateOrUpdateRecord {
  final MedicationRecordRepository repository;

  CreateOrUpdateRecord(this.repository);

  Future<Either<Failure, MedicationRecord>> call(MedicationRecord record) async {
    return await repository.createOrUpdateRecord(record);
  }
}