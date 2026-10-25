import 'package:dartz/dartz.dart';
import 'package:medication_scheduler/core/errors/failures.dart';
import 'package:medication_scheduler/features/medications/domain/entities/medication.dart';
import 'package:medication_scheduler/features/medications/domain/repositories/medication_repository.dart';

class GetMedication {
  final MedicationRepository repository;

  GetMedication(this.repository);

  Future<Either<Failure, Medication>> call(String id) async {
    return await repository.getMedication(id);
  }
}