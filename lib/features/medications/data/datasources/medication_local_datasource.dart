import 'package:hive/hive.dart';
import 'package:medication_scheduler/core/constants/app_constants.dart';
import 'package:medication_scheduler/core/errors/failures.dart';
import 'package:medication_scheduler/features/medications/data/models/medication_hive_model.dart';

class MedicationLocalDataSource {
  Box<MedicationHiveModel>? _box;

  Future<Box<MedicationHiveModel>> get _medicationBox async {
    _box ??= await Hive.openBox<MedicationHiveModel>(
      AppConstants.hiveBoxMedications,
    );
    return _box!;
  }

  Future<List<MedicationHiveModel>> getAllMedications() async {
    try {
      final box = await _medicationBox;
      return box.values.toList()..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    } catch (e) {
      throw DatabaseFailure('Failed to get medications: $e');
    }
  }

  Future<MedicationHiveModel?> getMedication(String id) async {
    try {
      final box = await _medicationBox;
      return box.get(id);
    } catch (e) {
      throw DatabaseFailure('Failed to get medication: $e');
    }
  }

  Future<MedicationHiveModel> createMedication(MedicationHiveModel medication) async {
    try {
      final box = await _medicationBox;
      await box.put(medication.id, medication);
      return medication;
    } catch (e) {
      throw DatabaseFailure('Failed to create medication: $e');
    }
  }

  Future<MedicationHiveModel> updateMedication(MedicationHiveModel medication) async {
    try {
      final box = await _medicationBox;
      if (!box.containsKey(medication.id)) {
        throw NotFoundFailure('Medication not found: ${medication.id}');
      }
      await box.put(medication.id, medication);
      return medication;
    } catch (e) {
      if (e is NotFoundFailure) rethrow;
      throw DatabaseFailure('Failed to update medication: $e');
    }
  }

  Future<void> deleteMedication(String id) async {
    try {
      final box = await _medicationBox;
      if (!box.containsKey(id)) {
        throw NotFoundFailure('Medication not found: $id');
      }
      await box.delete(id);
    } catch (e) {
      if (e is NotFoundFailure) rethrow;
      throw DatabaseFailure('Failed to delete medication: $e');
    }
  }

  Future<void> deleteAllMedications() async {
    try {
      final box = await _medicationBox;
      await box.clear();
    } catch (e) {
      throw DatabaseFailure('Failed to delete all medications: $e');
    }
  }

  Future<void> close() async {
    await _box?.close();
    _box = null;
  }
}