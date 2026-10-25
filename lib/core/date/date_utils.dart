import 'package:intl/intl.dart';

/// Date-only abstraction to eliminate DST/timezone issues.
/// All medication scheduling uses calendar dates (year, month, day) only.
/// Time of day is explicitly discarded by normalizing to local midnight.
class AppDate {
  final int year;
  final int month;
  final int day;

  const AppDate(this.year, this.month, this.day);

  /// Creates an AppDate from a DateTime, normalizing to local midnight.
  factory AppDate.fromDateTime(DateTime dateTime) {
    return AppDate(dateTime.year, dateTime.month, dateTime.day);
  }

  /// Creates an AppDate for today (local date).
  factory AppDate.today() {
    return AppDate.fromDateTime(DateTime.now());
  }

  /// Converts to DateTime at local midnight.
  DateTime toDateTime() {
    return DateTime(year, month, day);
  }

  /// Difference in calendar days between this date and [other].
  /// Positive if this is after [other], negative if before.
  int differenceInDays(AppDate other) {
    return toDateTime().difference(other.toDateTime()).inDays;
  }

  /// Adds [days] calendar days.
  AppDate addDays(int days) {
    return AppDate.fromDateTime(toDateTime().add(Duration(days: days)));
  }

  /// Subtracts [days] calendar days.
  AppDate subtractDays(int days) {
    return addDays(-days);
  }

  bool get isToday => this == AppDate.today();

  bool operator ==(Object other) =>
      other is AppDate && year == other.year && month == other.month && day == other.day;

  @override
  int get hashCode => Object.hash(year, month, day);

  /// Comparison operators for date ranges.
  bool operator <(AppDate other) => toDateTime().isBefore(other.toDateTime());
  bool operator <=(AppDate other) => toDateTime().isBefore(other.toDateTime()) || this == other;
  bool operator >(AppDate other) => toDateTime().isAfter(other.toDateTime());
  bool operator >=(AppDate other) => toDateTime().isAfter(other.toDateTime()) || this == other;

  /// Format for display.
  String format([String pattern = 'MMMM d, yyyy']) {
    return DateFormat(pattern).format(toDateTime());
  }

  String formatShort() => format('MMM d');
  String formatDay() => format('EEE');
  String formatFull() => format('EEEE, MMMM d, yyyy');

  @override
  String toString() => '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
}

/// Extension on DateTime for easy conversion.
extension DateTimeExt on DateTime {
  AppDate get toAppDate => AppDate.fromDateTime(this);
}