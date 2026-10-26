import 'package:hive/hive.dart';
import 'package:medication_scheduler/core/date/date_utils.dart';
import 'package:medication_scheduler/features/history/domain/entities/medication_record.dart';

part 'medication_record_hive_model.g.dart';

@HiveType(typeId: 1)
class MedicationRecordHiveModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String medicationId;

  @HiveField(2)
  String date; // Stored as ISO string YYYY-MM-DD

  @HiveField(3)
  int scheduledStatus;

  @HiveField(4)
  int actualStatus;

  @HiveField(5)
  String createdAt;

  @HiveField(6)
  String updatedAt;

  MedicationRecordHiveModel({
    required this.id,
    required this.medicationId,
    required this.date,
    required this.scheduledStatus,
    required this.actualStatus,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MedicationRecordHiveModel.fromEntity(MedicationRecord record) {
    return MedicationRecordHiveModel(
      id: record.id,
      medicationId: record.medicationId,
      date: record.date.toString(),
      scheduledStatus: record.scheduledStatus.index,
      actualStatus: record.actualStatus.index,
      createdAt: record.createdAt.toIso8601String(),
      updatedAt: record.updatedAt.toIso8601String(),
    );
  }

  MedicationRecord toEntity() {
    return MedicationRecord(
      id: id,
      medicationId: medicationId,
      date: AppDate.fromDateTime(DateTime.parse(date)),
      scheduledStatus: ScheduledStatus.values[scheduledStatus],
      actualStatus: ActualStatus.values[actualStatus],
      createdAt: DateTime.parse(createdAt),
      updatedAt: DateTime.parse(updatedAt),
    );
  }
}