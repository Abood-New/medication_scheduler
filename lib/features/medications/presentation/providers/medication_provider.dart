import 'package:flutter/foundation.dart';
import 'package:medication_scheduler/features/medications/domain/entities/medication.dart';
import 'package:medication_scheduler/features/medications/domain/usecases/create_medication.dart';
import 'package:medication_scheduler/features/medications/domain/usecases/delete_medication.dart';
import 'package:medication_scheduler/features/medications/domain/usecases/get_all_medications.dart';
import 'package:medication_scheduler/features/medications/domain/usecases/get_medication.dart';
import 'package:medication_scheduler/features/medications/domain/usecases/update_medication.dart';

class MedicationProvider extends ChangeNotifier {
  final GetAllMedications getAllMedications;
  final GetMedication getMedication;
  final CreateMedication createMedication;
  final UpdateMedication updateMedication;
  final DeleteMedication deleteMedication;

  List<Medication> _medications = [];
  Medication? _selectedMedication;
  bool _isLoading = false;
  String? _error;

  MedicationProvider({
    required this.getAllMedications,
    required this.getMedication,
    required this.createMedication,
    required this.updateMedication,
    required this.deleteMedication,
  });

  List<Medication> get medications => _medications;
  Medication? get selectedMedication => _selectedMedication;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Load all medications.
  Future<void> loadMedications() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await getAllMedications();
    result.fold(
      (failure) => _error = failure.message,
      (medications) => _medications = medications,
    );

    _isLoading = false;
    notifyListeners();
  }

  /// Load a specific medication by ID.
  Future<void> loadMedication(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await getMedication(id);
    result.fold(
      (failure) => _error = failure.message,
      (medication) => _selectedMedication = medication,
    );

    _isLoading = false;
    notifyListeners();
  }

  /// Create a new medication.
  Future<bool> addMedication(Medication medication) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await createMedication(medication);
    final bool success = result.fold(
      (failure) => (_error = failure.message, false),
      (_) => true,
    );

    if (success) {
      await loadMedications();
    }

    _isLoading = false;
    notifyListeners();
    return success;
  }

  /// Update an existing medication.
  Future<bool> editMedication(Medication medication) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await updateMedication(medication);
    final bool success = result.fold(
      (failure) => (_error = failure.message, false),
      (_) => true,
    );

    if (success) {
      await loadMedications();
    }

    _isLoading = false;
    notifyListeners();
    return success;
  }

  /// Delete a medication.
  Future<bool> removeMedication(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await deleteMedication(id);
    final bool success = result.fold(
      (failure) => (_error = failure.message, false),
      (_) => true,
    );

    if (success) {
      await loadMedications();
    }

    _isLoading = false;
    notifyListeners();
    return success;
  }

  /// Set the currently selected medication.
  void selectMedication(Medication? medication) {
    _selectedMedication = medication;
    notifyListeners();
  }

  /// Clear error.
  void clearError() {
    _error = null;
    notifyListeners();
  }
}