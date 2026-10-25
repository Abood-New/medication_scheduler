import 'package:dartz/dartz.dart';
import 'package:medication_scheduler/core/errors/failures.dart';
import 'package:medication_scheduler/features/medications/domain/entities/medication.dart';
import 'package:medication_scheduler/features/medications/domain/repositories/medication_repository.dart';

class GetAllMedications {
  final MedicationRepository repository;

  GetAllMedications(this.repository);

  Future<Either<Failure, List<Medication>>> call() async {
    return await repository.getAllMedications();
  }
}