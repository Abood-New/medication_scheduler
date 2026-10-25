import 'package:dartz/dartz.dart';
import 'package:medication_scheduler/core/errors/failures.dart';
import 'package:medication_scheduler/features/medications/domain/entities/medication.dart';
import 'package:medication_scheduler/features/medications/domain/repositories/medication_repository.dart';

class CreateMedication {
  final MedicationRepository repository;

  CreateMedication(this.repository);

  Future<Either<Failure, Medication>> call(Medication medication) async {
    return await repository.createMedication(medication);
  }
}