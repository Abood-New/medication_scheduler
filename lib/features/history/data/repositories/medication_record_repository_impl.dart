import 'package:dartz/dartz.dart';
import 'package:medication_scheduler/core/date/date_utils.dart';
import 'package:medication_scheduler/core/errors/failures.dart';
import 'package:medication_scheduler/features/history/data/datasources/medication_record_local_datasource.dart';
import 'package:medication_scheduler/features/history/data/models/medication_record_hive_model.dart';
import 'package:medication_scheduler/features/history/domain/entities/medication_record.dart';
import 'package:medication_scheduler/features/history/domain/repositories/medication_record_repository.dart';

class MedicationRecordRepositoryImpl implements MedicationRecordRepository {
  final MedicationRecordLocalDataSource localDataSource;

  MedicationRecordRepositoryImpl(this.localDataSource);

  @override
  Future<Either<Failure, List<MedicationRecord>>> getRecordsForMedication(
    String medicationId,
  ) async {
    try {
      final models = await localDataSource.getRecordsForMedication(medicationId);
      return Right(models.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<MedicationRecord>>> getRecordsForDateRange(
    String medicationId,
    AppDate startDate,
    AppDate endDate,
  ) async {
    try {
      final models = await localDataSource.getRecordsForDateRange(
        medicationId,
        startDate,
        endDate,
      );
      return Right(models.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, MedicationRecord?>> getRecordForDate(
    String medicationId,
    AppDate date,
  ) async {
    try {
      final model = await localDataSource.getRecordForDate(medicationId, date);
      return Right(model?.toEntity());
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, MedicationRecord>> createOrUpdateRecord(
    MedicationRecord record,
  ) async {
    try {
      final model = MedicationRecordHiveModel.fromEntity(record);
      await localDataSource.createOrUpdateRecord(model);
      return Right(record);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteRecord(String id) async {
    try {
      await localDataSource.deleteRecord(id);
      return const Right(null);
    } catch (e) {
      if (e is NotFoundFailure) return Left(e);
      return Left(DatabaseFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteAllRecordsForMedication(
    String medicationId,
  ) async {
    try {
      await localDataSource.deleteAllRecordsForMedication(medicationId);
      return const Right(null);
    } catch (e) {
      return Left(DatabaseFailure(e.toString()));
    }
  }
}