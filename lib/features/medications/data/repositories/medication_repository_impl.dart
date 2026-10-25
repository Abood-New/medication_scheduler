import 'package:dartz/dartz.dart';
import 'package:medication_scheduler/core/errors/failures.dart';
import 'package:medication_scheduler/features/medications/data/datasources/medication_local_datasource.dart';
import 'package:medication_scheduler/features/medications/data/models/medication_hive_model.dart';
import 'package:medication_scheduler/features/medications/domain/entities/medication.dart';
import 'package:medication_scheduler/features/medications/domain/repositories/medication_repository.dart';

class MedicationRepositoryImpl implements MedicationRepository {
  final MedicationLocalDataSource localDataSource;

  MedicationRepositoryImpl(this.localDataSource);

  @override
  Future<Either<Failure, List<Medication>>> getAllMedications() async {
    try {
      final models = await localDataSource.getAllMedications();
      return Right(models.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Medication>> getMedication(String id) async {
    try {
      final model = await localDataSource.getMedication(id);
      if (model == null) {
        return Left(NotFoundFailure('Medication not found: $id'));
      }
      return Right(model.toEntity());
    } catch (e) {
      if (e is NotFoundFailure) return Left(e);
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Medication>> createMedication(Medication medication) async {
    try {
      final model = MedicationHiveModel.fromEntity(medication);
      await localDataSource.createMedication(model);
      return Right(medication);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Medication>> updateMedication(Medication medication) async {
    try {
      final model = MedicationHiveModel.fromEntity(medication);
      await localDataSource.updateMedication(model);
      return Right(medication);
    } catch (e) {
      if (e is NotFoundFailure) return Left(e);
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteMedication(String id) async {
    try {
      await localDataSource.deleteMedication(id);
      return const Right(null);
    } catch (e) {
      if (e is NotFoundFailure) return Left(e);
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteAllMedications() async {
    try {
      await localDataSource.deleteAllMedications();
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }
}