import 'package:dartz/dartz.dart';
import 'package:medication_scheduler/core/errors/failures.dart';
import 'package:medication_scheduler/features/medications/domain/entities/medication.dart';

abstract class MedicationRepository {
  Future<Either<Failure, List<Medication>>> getAllMedications();
  Future<Either<Failure, Medication>> getMedication(String id);
  Future<Either<Failure, Medication>> createMedication(Medication medication);
  Future<Either<Failure, Medication>> updateMedication(Medication medication);
  Future<Either<Failure, void>> deleteMedication(String id);
  Future<Either<Failure, void>> deleteAllMedications();
}