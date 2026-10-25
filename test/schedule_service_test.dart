import 'package:test/test.dart';
import 'package:medication_scheduler/core/date/date_utils.dart';
import 'package:medication_scheduler/features/schedule/domain/services/medication_schedule_service.dart';
import 'package:medication_scheduler/features/schedule/domain/entities/schedule_day.dart';
import 'package:medication_scheduler/features/history/domain/entities/medication_record.dart';

void main() {
  group('MedicationScheduleService', () {
    final service = const MedicationScheduleService();

    group('shouldTake - basic alternating pattern', () {
      test('reference date is always TAKE', () {
        final ref = AppDate(2026, 1, 5); // Monday
        expect(service.shouldTake(referenceDate: ref, date: ref), isTrue);
      });

      test('Monday reference: Monday TAKE, Tuesday SKIP, Wednesday TAKE', () {
        final ref = AppDate(2026, 1, 5); // Monday
        expect(service.shouldTake(referenceDate: ref, date: AppDate(2026, 1, 5)), isTrue);  // Mon
        expect(service.shouldTake(referenceDate: ref, date: AppDate(2026, 1, 6)), isFalse); // Tue
        expect(service.shouldTake(referenceDate: ref, date: AppDate(2026, 1, 7)), isTrue);  // Wed
        expect(service.shouldTake(referenceDate: ref, date: AppDate(2026, 1, 8)), isFalse); // Thu
        expect(service.shouldTake(referenceDate: ref, date: AppDate(2026, 1, 9)), isTrue);  // Fri
        expect(service.shouldTake(referenceDate: ref, date: AppDate(2026, 1, 10)), isFalse); // Sat
        expect(service.shouldTake(referenceDate: ref, date: AppDate(2026, 1, 11)), isTrue);  // Sun
      });

      test('Wednesday reference: Tue SKIP, Mon TAKE, Sun SKIP (past dates)', () {
        final ref = AppDate(2026, 1, 7); // Wednesday
        expect(service.shouldTake(referenceDate: ref, date: AppDate(2026, 1, 6)), isFalse); // Tue
        expect(service.shouldTake(referenceDate: ref, date: AppDate(2026, 1, 5)), isTrue);  // Mon
        expect(service.shouldTake(referenceDate: ref, date: AppDate(2026, 1, 4)), isFalse); // Sun
        expect(service.shouldTake(referenceDate: ref, date: AppDate(2026, 1, 3)), isTrue);  // Sat
      });
    });

    group('shouldTake - month boundaries', () {
      test('January 31 TAKE → February 1 SKIP → February 2 TAKE', () {
        final ref = AppDate(2026, 1, 31); // Saturday
        expect(service.shouldTake(referenceDate: ref, date: AppDate(2026, 1, 31)), isTrue);  // Jan 31
        expect(service.shouldTake(referenceDate: ref, date: AppDate(2026, 2, 1)), isFalse);  // Feb 1
        expect(service.shouldTake(referenceDate: ref, date: AppDate(2026, 2, 2)), isTrue);   // Feb 2
      });

      test('February 28 TAKE → March 1 SKIP (non-leap year)', () {
        final ref = AppDate(2026, 2, 28); // Saturday (2026 is not leap)
        expect(service.shouldTake(referenceDate: ref, date: AppDate(2026, 2, 28)), isTrue);  // Feb 28
        expect(service.shouldTake(referenceDate: ref, date: AppDate(2026, 3, 1)), isFalse);  // Mar 1
        expect(service.shouldTake(referenceDate: ref, date: AppDate(2026, 3, 2)), isTrue);   // Mar 2
      });

      test('February 28 TAKE → February 29 SKIP → March 1 TAKE (leap year)', () {
        final ref = AppDate(2024, 2, 28); // Wednesday (2024 is leap)
        expect(service.shouldTake(referenceDate: ref, date: AppDate(2024, 2, 28)), isTrue);  // Feb 28
        expect(service.shouldTake(referenceDate: ref, date: AppDate(2024, 2, 29)), isFalse); // Feb 29
        expect(service.shouldTake(referenceDate: ref, date: AppDate(2024, 3, 1)), isTrue);   // Mar 1
      });
    });

    group('shouldTake - year boundaries', () {
      test('December 31 TAKE → January 1 SKIP → January 2 TAKE', () {
        final ref = AppDate(2025, 12, 31); // Wednesday
        expect(service.shouldTake(referenceDate: ref, date: AppDate(2025, 12, 31)), isTrue);  // Dec 31
        expect(service.shouldTake(referenceDate: ref, date: AppDate(2026, 1, 1)), isFalse);   // Jan 1
        expect(service.shouldTake(referenceDate: ref, date: AppDate(2026, 1, 2)), isTrue);    // Jan 2
      });
    });

    group('shouldTake - leap years', () {
      test('February 28, 29, March 1 in leap year 2024', () {
        final ref = AppDate(2024, 2, 26); // Monday
        expect(service.shouldTake(referenceDate: ref, date: AppDate(2024, 2, 28)), isTrue);  // Wed
        expect(service.shouldTake(referenceDate: ref, date: AppDate(2024, 2, 29)), isFalse); // Thu
        expect(service.shouldTake(referenceDate: ref, date: AppDate(2024, 3, 1)), isTrue);   // Fri
      });

      test('February 28, March 1 in non-leap year 2025', () {
        final ref = AppDate(2025, 2, 24); // Monday
        expect(service.shouldTake(referenceDate: ref, date: AppDate(2025, 2, 26)), isTrue);  // Wed
        expect(service.shouldTake(referenceDate: ref, date: AppDate(2025, 2, 27)), isFalse); // Thu
        expect(service.shouldTake(referenceDate: ref, date: AppDate(2025, 2, 28)), isTrue);  // Fri
        expect(service.shouldTake(referenceDate: ref, date: AppDate(2025, 3, 1)), isFalse);  // Sat
      });
    });

    group('shouldTake - different month lengths', () {
      test('30-day month (April)', () {
        final ref = AppDate(2026, 4, 30); // Thursday
        expect(service.shouldTake(referenceDate: ref, date: AppDate(2026, 4, 30)), isTrue);  // Apr 30
        expect(service.shouldTake(referenceDate: ref, date: AppDate(2026, 5, 1)), isFalse);  // May 1
        expect(service.shouldTake(referenceDate: ref, date: AppDate(2026, 5, 2)), isTrue);   // May 2
      });

      test('31-day month (July)', () {
        final ref = AppDate(2026, 7, 31); // Friday
        expect(service.shouldTake(referenceDate: ref, date: AppDate(2026, 7, 31)), isTrue);  // Jul 31
        expect(service.shouldTake(referenceDate: ref, date: AppDate(2026, 8, 1)), isFalse);  // Aug 1
        expect(service.shouldTake(referenceDate: ref, date: AppDate(2026, 8, 2)), isTrue);   // Aug 2
      });
    });

    group('getNextDoseDate', () {
      test('returns same date if today is TAKE day', () {
        final ref = AppDate(2026, 1, 5); // Monday
        final next = service.getNextDoseDate(referenceDate: ref, fromDate: AppDate(2026, 1, 5));
        expect(next, equals(AppDate(2026, 1, 5)));
      });

      test('returns tomorrow if today is SKIP day', () {
        final ref = AppDate(2026, 1, 5); // Monday
        final next = service.getNextDoseDate(referenceDate: ref, fromDate: AppDate(2026, 1, 6));
        expect(next, equals(AppDate(2026, 1, 7))); // Wednesday
      });

      test('works for past dates', () {
        final ref = AppDate(2026, 1, 10); // Saturday
        final next = service.getNextDoseDate(referenceDate: ref, fromDate: AppDate(2026, 1, 8));
        expect(next, equals(AppDate(2026, 1, 9))); // Friday
      });
    });

    group('getPreviousDoseDate', () {
      test('returns same date if today is TAKE day', () {
        final ref = AppDate(2026, 1, 5); // Monday
        final prev = service.getPreviousDoseDate(referenceDate: ref, fromDate: AppDate(2026, 1, 5));
        expect(prev, equals(AppDate(2026, 1, 5)));
      });

      test('returns yesterday if today is SKIP day', () {
        final ref = AppDate(2026, 1, 5); // Monday
        final prev = service.getPreviousDoseDate(referenceDate: ref, fromDate: AppDate(2026, 1, 6));
        expect(prev, equals(AppDate(2026, 1, 5))); // Monday
      });
    });

    group('getUpcomingDoses', () {
      test('returns correct number of upcoming doses', () {
        final ref = AppDate(2026, 1, 5); // Monday
        final doses = service.getUpcomingDoses(
          referenceDate: ref,
          fromDate: AppDate(2026, 1, 5),
          count: 5,
        );
        expect(doses.length, equals(5));
        expect(doses[0], equals(AppDate(2026, 1, 5)));  // Mon
        expect(doses[1], equals(AppDate(2026, 1, 7)));  // Wed
        expect(doses[2], equals(AppDate(2026, 1, 9)));  // Fri
        expect(doses[3], equals(AppDate(2026, 1, 11))); // Sun
        expect(doses[4], equals(AppDate(2026, 1, 13))); // Tue
      });

      test('starts from next dose if today is SKIP', () {
        final ref = AppDate(2026, 1, 5); // Monday
        final doses = service.getUpcomingDoses(
          referenceDate: ref,
          fromDate: AppDate(2026, 1, 6), // Tuesday (SKIP)
          count: 3,
        );
        expect(doses.length, equals(3));
        expect(doses[0], equals(AppDate(2026, 1, 7)));  // Wednesday
        expect(doses[1], equals(AppDate(2026, 1, 9)));  // Friday
        expect(doses[2], equals(AppDate(2026, 1, 11))); // Sunday
      });
    });

    group('getPreviousDoses', () {
      test('returns correct number of previous doses', () {
        final ref = AppDate(2026, 1, 15); // Thursday
        final doses = service.getPreviousDoses(
          referenceDate: ref,
          fromDate: AppDate(2026, 1, 15),
          count: 5,
        );
        expect(doses.length, equals(5));
        expect(doses[0], equals(AppDate(2026, 1, 15))); // Thu
        expect(doses[1], equals(AppDate(2026, 1, 13))); // Tue
        expect(doses[2], equals(AppDate(2026, 1, 11))); // Sun
        expect(doses[3], equals(AppDate(2026, 1, 9)));  // Fri
        expect(doses[4], equals(AppDate(2026, 1, 7)));  // Wed
      });
    });

    group('getScheduleForRange', () {
      test('generates correct schedule for a week', () {
        final ref = AppDate(2026, 1, 5); // Monday
        final range = service.getScheduleForRange(
          referenceDate: ref,
          startDate: AppDate(2026, 1, 5),
          endDate: AppDate(2026, 1, 11),
        );

        expect(range.days.length, equals(7));
        expect(range.days[0].isTake, isTrue);   // Mon
        expect(range.days[1].isTake, isFalse);  // Tue
        expect(range.days[2].isTake, isTrue);   // Wed
        expect(range.days[3].isTake, isFalse);  // Thu
        expect(range.days[4].isTake, isTrue);   // Fri
        expect(range.days[5].isTake, isFalse);  // Sat
        expect(range.days[6].isTake, isTrue);   // Sun
      });

      test('merges history records correctly', () {
        final ref = AppDate(2026, 1, 5); // Monday
        final history = [
          MedicationRecord.create(
            medicationId: 'med1',
            date: AppDate(2026, 1, 5),
            scheduledStatus: ScheduledStatus.TAKE,
            actualStatus: ActualStatus.TAKEN,
          ),
          MedicationRecord.create(
            medicationId: 'med1',
            date: AppDate(2026, 1, 7),
            scheduledStatus: ScheduledStatus.TAKE,
            actualStatus: ActualStatus.MISSED,
          ),
        ];

        final range = service.getScheduleForRange(
          referenceDate: ref,
          startDate: AppDate(2026, 1, 5),
          endDate: AppDate(2026, 1, 7),
          historyRecords: history,
        );

        expect(range.days[0].isTaken, isTrue);   // Mon - Taken
        expect(range.days[1].isSkip, isTrue);    // Tue - Skip
        expect(range.days[2].isMissed, isTrue);  // Wed - Missed
      });
    });

    group('getWeekSchedule', () {
      test('returns Monday-Sunday week', () {
        final ref = AppDate(2026, 1, 5); // Monday
        final week = service.getWeekSchedule(
          referenceDate: ref,
          date: AppDate(2026, 1, 7), // Wednesday
        );

        expect(week.days.length, equals(7));
        expect(week.days[0].date.toDateTime().weekday, equals(1)); // Monday
        expect(week.days[6].date.toDateTime().weekday, equals(7)); // Sunday
      });
    });

    group('getMonthSchedule', () {
      test('returns full month', () {
        final ref = AppDate(2026, 1, 5);
        final month = service.getMonthSchedule(
          referenceDate: ref,
          date: AppDate(2026, 1, 15),
        );

        expect(month.startDate.day, equals(1));
        expect(month.endDate.day, equals(31)); // January has 31 days
        expect(month.days.length, equals(31));
      });
    });

    group('negative differences (past dates)', () {
      test('handles negative modulo correctly', () {
        // In Dart, -1 % 2 = -1, not 1
        // But we use diff % 2 == 0 which works for negative even numbers
        final ref = AppDate(2026, 1, 10); // Saturday
        // Jan 9 (Friday) is 1 day before = diff = -1, -1 % 2 = -1 != 0 → SKIP
        expect(service.shouldTake(referenceDate: ref, date: AppDate(2026, 1, 9)), isFalse);
        // Jan 8 (Thursday) is 2 days before = diff = -2, -2 % 2 = 0 → TAKE
        expect(service.shouldTake(referenceDate: ref, date: AppDate(2026, 1, 8)), isTrue);
        // Jan 7 (Wednesday) is 3 days before = diff = -3, -3 % 2 = -1 → SKIP
        expect(service.shouldTake(referenceDate: ref, date: AppDate(2026, 1, 7)), isFalse);
        // Jan 6 (Tuesday) is 4 days before = diff = -4, -4 % 2 = 0 → TAKE
        expect(service.shouldTake(referenceDate: ref, date: AppDate(2026, 1, 6)), isTrue);
      });
    });
  });

  group('AppDate', () {
    test('fromDateTime normalizes to midnight', () {
      final dt = DateTime(2026, 1, 15, 14, 30, 45);
      final appDate = AppDate.fromDateTime(dt);
      expect(appDate.year, equals(2026));
      expect(appDate.month, equals(1));
      expect(appDate.day, equals(15));
      expect(appDate.toDateTime().hour, equals(0));
      expect(appDate.toDateTime().minute, equals(0));
    });

    test('today returns current date', () {
      final today = AppDate.today();
      final now = DateTime.now();
      expect(today.year, equals(now.year));
      expect(today.month, equals(now.month));
      expect(today.day, equals(now.day));
    });

    test('differenceInDays calculates correctly', () {
      final d1 = AppDate(2026, 1, 10);
      final d2 = AppDate(2026, 1, 5);
      expect(d1.differenceInDays(d2), equals(5));
      expect(d2.differenceInDays(d1), equals(-5));
    });

    test('addDays and subtractDays work correctly', () {
      final d = AppDate(2026, 1, 10);
      expect(d.addDays(5), equals(AppDate(2026, 1, 15)));
      expect(d.subtractDays(5), equals(AppDate(2026, 1, 5)));
    });

    test('equality works correctly', () {
      expect(AppDate(2026, 1, 10), equals(AppDate(2026, 1, 10)));
      expect(AppDate(2026, 1, 10), isNot(equals(AppDate(2026, 1, 11))));
    });

    test('comparison operators work', () {
      final d1 = AppDate(2026, 1, 10);
      final d2 = AppDate(2026, 1, 15);
      expect(d1 < d2, isTrue);
      expect(d1 <= d2, isTrue);
      expect(d2 > d1, isTrue);
      expect(d2 >= d1, isTrue);
    });

    test('format methods work', () {
      final d = AppDate(2026, 10, 25);
      expect(d.formatShort(), equals('Oct 25'));
      expect(d.formatDay(), equals('Sun'));
      expect(d.toString(), equals('2026-10-25'));
    });
  });

  group('ScheduleDay', () {
    test('fromReference creates correct status', () {
      final ref = AppDate(2026, 1, 5); // Monday
      final takeDay = ScheduleDay.fromReference(date: AppDate(2026, 1, 5), referenceDate: ref);
      final skipDay = ScheduleDay.fromReference(date: AppDate(2026, 1, 6), referenceDate: ref);

      expect(takeDay.isTake, isTrue);
      expect(takeDay.scheduledStatus, equals(ScheduledStatus.TAKE));
      expect(skipDay.isSkip, isTrue);
      expect(skipDay.scheduledStatus, equals(ScheduledStatus.SKIP));
    });

    test('statusLabel returns correct text', () {
      final ref = AppDate(2026, 1, 5);
      var day = ScheduleDay.fromReference(date: AppDate(2026, 1, 5), referenceDate: ref);
      expect(day.statusLabel, equals('Take'));

      day = day.copyWith(actualStatus: ActualStatus.TAKEN);
      expect(day.statusLabel, equals('Taken'));

      day = day.copyWith(actualStatus: ActualStatus.MISSED);
      expect(day.statusLabel, equals('Missed'));

      day = ScheduleDay.fromReference(date: AppDate(2026, 1, 6), referenceDate: ref);
      expect(day.statusLabel, equals('Skip'));
    });
  });
}