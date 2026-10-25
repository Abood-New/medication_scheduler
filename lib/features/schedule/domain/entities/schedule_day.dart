import 'package:equatable/equatable.dart';
import 'package:medication_scheduler/core/date/date_utils.dart';
import 'package:medication_scheduler/features/history/domain/entities/medication_record.dart';

class ScheduleDay extends Equatable {
  final AppDate date;
  final ScheduledStatus scheduledStatus;
  final ActualStatus? actualStatus;
  final bool isToday;

  const ScheduleDay({
    required this.date,
    required this.scheduledStatus,
    this.actualStatus,
    this.isToday = false,
  });

  /// Creates a ScheduleDay from a date and reference date.
  factory ScheduleDay.fromReference({
    required AppDate date,
    required AppDate referenceDate,
    ActualStatus? actualStatus,
  }) {
    final diff = date.differenceInDays(referenceDate);
    return ScheduleDay(
      date: date,
      scheduledStatus: diff % 2 == 0 ? ScheduledStatus.TAKE : ScheduledStatus.SKIP,
      actualStatus: actualStatus,
      isToday: date.isToday,
    );
  }

  ScheduleDay copyWith({
    AppDate? date,
    ScheduledStatus? scheduledStatus,
    ActualStatus? actualStatus,
    bool? isToday,
  }) {
    return ScheduleDay(
      date: date ?? this.date,
      scheduledStatus: scheduledStatus ?? this.scheduledStatus,
      actualStatus: actualStatus ?? this.actualStatus,
      isToday: isToday ?? this.isToday,
    );
  }

  bool get isTake => scheduledStatus == ScheduledStatus.TAKE;
  bool get isSkip => scheduledStatus == ScheduledStatus.SKIP;
  bool get isTaken => actualStatus == ActualStatus.TAKEN;
  bool get isMissed => actualStatus == ActualStatus.MISSED;

  String get statusLabel {
    if (isTake) {
      if (isTaken) return 'Taken';
      if (isMissed) return 'Missed';
      return 'Take';
    } else {
      return 'Skip';
    }
  }

  @override
  List<Object?> get props => [date, scheduledStatus, actualStatus, isToday];
}

/// Result of a schedule query for a range.
class ScheduleRange extends Equatable {
  final AppDate startDate;
  final AppDate endDate;
  final List<ScheduleDay> days;

  const ScheduleRange({
    required this.startDate,
    required this.endDate,
    required this.days,
  });

  List<ScheduleDay> get takeDays => days.where((d) => d.isTake).toList();
  List<ScheduleDay> get skipDays => days.where((d) => d.isSkip).toList();

  ScheduleDay? get today => days.firstWhere((d) => d.isToday, orElse: () => null);
  ScheduleDay? get nextTakeDay {
    final todayIndex = days.indexWhere((d) => d.isToday);
    if (todayIndex == -1) return null;
    for (int i = todayIndex; i < days.length; i++) {
      if (days[i].isTake) return days[i];
    }
    return null;
  }

  @override
  List<Object?> get props => [startDate, endDate, days];
}