import 'package:dartz/dartz.dart';
import 'package:medication_scheduler/core/errors/failures.dart';
import 'package:medication_scheduler/features/medications/domain/repositories/medication_repository.dart';

class DeleteMedication {
  final MedicationRepository repository;

  DeleteMedication(this.repository);

  Future<Either<Failure, void>> call(String id) async {
    return await repository.deleteMedication(id);
  }
}