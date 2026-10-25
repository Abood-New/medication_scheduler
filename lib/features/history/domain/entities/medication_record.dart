import 'package:equatable/equatable.dart';
import 'package:medication_scheduler/core/date/date_utils.dart';

enum ScheduledStatus { TAKE, SKIP }

enum ActualStatus { TAKEN, MISSED, NOT_RECORDED }

class MedicationRecord extends Equatable {
  final String id;
  final String medicationId;
  final AppDate date;
  final ScheduledStatus scheduledStatus;
  final ActualStatus actualStatus;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MedicationRecord({
    required this.id,
    required this.medicationId,
    required this.date,
    required this.scheduledStatus,
    required this.actualStatus,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MedicationRecord.create({
    required String medicationId,
    required AppDate date,
    required ScheduledStatus scheduledStatus,
    ActualStatus actualStatus = ActualStatus.NOT_RECORDED,
  }) {
    final now = DateTime.now();
    return MedicationRecord(
      id: '${medicationId}_${date.toString()}',
      medicationId: medicationId,
      date: date,
      scheduledStatus: scheduledStatus,
      actualStatus: actualStatus,
      createdAt: now,
      updatedAt: now,
    );
  }

  MedicationRecord copyWith({
    String? id,
    String? medicationId,
    AppDate? date,
    ScheduledStatus? scheduledStatus,
    ActualStatus? actualStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MedicationRecord(
      id: id ?? this.id,
      medicationId: medicationId ?? this.medicationId,
      date: date ?? this.date,
      scheduledStatus: scheduledStatus ?? this.scheduledStatus,
      actualStatus: actualStatus ?? this.actualStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  /// Marks this record as taken.
  MedicationRecord markTaken() => copyWith(
        actualStatus: ActualStatus.TAKEN,
        updatedAt: DateTime.now(),
      );

  /// Marks this record as missed.
  MedicationRecord markMissed() => copyWith(
        actualStatus: ActualStatus.MISSED,
        updatedAt: DateTime.now(),
      );

  /// Clears the actual status (back to NOT_RECORDED).
  MedicationRecord clearStatus() => copyWith(
        actualStatus: ActualStatus.NOT_RECORDED,
        updatedAt: DateTime.now(),
      );

  bool get isTaken => actualStatus == ActualStatus.TAKEN;
  bool get isMissed => actualStatus == ActualStatus.MISSED;
  bool get isNotRecorded => actualStatus == ActualStatus.NOT_RECORDED;
  bool get isScheduledTake => scheduledStatus == ScheduledStatus.TAKE;
  bool get isScheduledSkip => scheduledStatus == ScheduledStatus.SKIP;

  @override
  List<Object?> get props => [
        id,
        medicationId,
        date,
        scheduledStatus,
        actualStatus,
        createdAt,
        updatedAt,
      ];
}