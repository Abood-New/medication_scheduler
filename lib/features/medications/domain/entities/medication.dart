import 'package:equatable/equatable.dart';
import 'package:medication_scheduler/core/date/date_utils.dart';

enum ScheduleType {
  EVERY_OTHER_DAY,
  DAILY,
  EVERY_3_DAYS,
  WEEKLY,
  CUSTOM,
}

class Medication extends Equatable {
  final String id;
  final String name;
  final String? dosage;
  final String? notes;
  final ScheduleType scheduleType;
  final AppDate referenceDate;
  final bool reminderEnabled;
  final TimeOfDay? reminderTime;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Medication({
    required this.id,
    required this.name,
    this.dosage,
    this.notes,
    required this.scheduleType,
    required this.referenceDate,
    this.reminderEnabled = false,
    this.reminderTime,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Creates a new medication with the given reference date.
  factory Medication.create({
    required String name,
    String? dosage,
    String? notes,
    required ScheduleType scheduleType,
    required AppDate referenceDate,
    bool reminderEnabled = false,
    TimeOfDay? reminderTime,
  }) {
    final now = DateTime.now();
    return Medication(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      dosage: dosage,
      notes: notes,
      scheduleType: scheduleType,
      referenceDate: referenceDate,
      reminderEnabled: reminderEnabled,
      reminderTime: reminderTime,
      createdAt: now,
      updatedAt: now,
    );
  }

  Medication copyWith({
    String? id,
    String? name,
    String? dosage,
    String? notes,
    ScheduleType? scheduleType,
    AppDate? referenceDate,
    bool? reminderEnabled,
    TimeOfDay? reminderTime,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Medication(
      id: id ?? this.id,
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      notes: notes ?? this.notes,
      scheduleType: scheduleType ?? this.scheduleType,
      referenceDate: referenceDate ?? this.referenceDate,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderTime: reminderTime ?? this.reminderTime,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        dosage,
        notes,
        scheduleType,
        referenceDate,
        reminderEnabled,
        reminderTime,
        createdAt,
        updatedAt,
      ];
}

/// Simple time-of-day representation for reminders.
class TimeOfDay extends Equatable {
  final int hour; // 0-23
  final int minute; // 0-59

  const TimeOfDay({required this.hour, required this.minute});

  factory TimeOfDay.fromDateTime(DateTime dateTime) {
    return TimeOfDay(hour: dateTime.hour, minute: dateTime.minute);
  }

  DateTime toDateTimeOn(AppDate date) {
    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  String format({bool use24Hour = false}) {
    if (use24Hour) {
      return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
    }
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
  }

  @override
  bool operator ==(Object other) =>
      other is TimeOfDay && hour == other.hour && minute == other.minute;

  @override
  int get hashCode => Object.hash(hour, minute);

  @override
  List<Object?> get props => [hour, minute];
}