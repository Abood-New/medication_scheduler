import 'package:hive/hive.dart';
import 'package:medication_scheduler/core/date/date_utils.dart';
import 'package:medication_scheduler/features/medications/domain/entities/medication.dart';

part 'medication_hive_model.g.dart';

@HiveType(typeId: 0)
class MedicationHiveModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String? dosage;

  @HiveField(3)
  String? notes;

  @HiveField(4)
  int scheduleType;

  @HiveField(5)
  String referenceDate; // Stored as ISO string YYYY-MM-DD

  @HiveField(6)
  bool reminderEnabled;

  @HiveField(7)
  int? reminderHour;

  @HiveField(8)
  int? reminderMinute;

  @HiveField(9)
  String createdAt; // ISO 8601 string

  @HiveField(10)
  String updatedAt; // ISO 8601 string

  MedicationHiveModel({
    required this.id,
    required this.name,
    this.dosage,
    this.notes,
    required this.scheduleType,
    required this.referenceDate,
    this.reminderEnabled = false,
    this.reminderHour,
    this.reminderMinute,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MedicationHiveModel.fromEntity(Medication medication) {
    return MedicationHiveModel(
      id: medication.id,
      name: medication.name,
      dosage: medication.dosage,
      notes: medication.notes,
      scheduleType: medication.scheduleType.index,
      referenceDate: medication.referenceDate.toString(),
      reminderEnabled: medication.reminderEnabled,
      reminderHour: medication.reminderTime?.hour,
      reminderMinute: medication.reminderTime?.minute,
      createdAt: medication.createdAt.toIso8601String(),
      updatedAt: medication.updatedAt.toIso8601String(),
    );
  }

  Medication toEntity() {
    return Medication(
      id: id,
      name: name,
      dosage: dosage,
      notes: notes,
      scheduleType: ScheduleType.values[scheduleType],
      referenceDate: AppDate.fromDateTime(DateTime.parse(referenceDate)),
      reminderEnabled: reminderEnabled,
      reminderTime: (reminderHour != null && reminderMinute != null)
          ? TimeOfDay(hour: reminderHour!, minute: reminderMinute!)
          : null,
      createdAt: DateTime.parse(createdAt),
      updatedAt: DateTime.parse(updatedAt),
    );
  }
}