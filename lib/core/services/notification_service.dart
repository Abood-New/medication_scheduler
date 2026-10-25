import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:medication_scheduler/core/constants/app_constants.dart';
import 'package:medication_scheduler/features/medications/domain/entities/medication.dart';
import 'package:medication_scheduler/features/schedule/domain/services/medication_schedule_service.dart';
import 'package:medication_scheduler/core/date/date_utils.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  final MedicationScheduleService _scheduleService = const MedicationScheduleService();
  bool _initialized = false;

  /// Check if we're on a platform that supports local notifications
  bool get _supportsNotifications {
    return Platform.isAndroid || Platform.isIOS || Platform.isMacOS || Platform.isWindows || Platform.isLinux;
  }

  Future<void> initialize() async {
    if (_initialized) return;

    // Initialize timezone
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.local);

    if (!_supportsNotifications) {
      debugPrint('Notifications not supported on this platform (web)');
      _initialized = true;
      return;
    }

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _notifications.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _initialized = true;
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap - could navigate to specific medication
  }

  /// Schedule notifications for a medication's upcoming TAKE days.
  Future<void> scheduleMedicationNotifications(Medication medication) async {
    if (!_supportsNotifications) return;
    if (!medication.reminderEnabled || medication.reminderTime == null) return;

    await cancelMedicationNotifications(medication.id);

    final upcomingDoses = _scheduleService.getUpcomingDoses(
      referenceDate: medication.referenceDate,
      fromDate: AppDate.today(),
      count: AppConstants.notificationScheduleDays ~/ 2, // Every other day
    );

    for (final doseDate in upcomingDoses) {
      await _scheduleSingleNotification(medication, doseDate);
    }
  }

  Future<void> _scheduleSingleNotification(Medication medication, AppDate date) async {
    if (!_supportsNotifications) return;

    final scheduledDateTime = date.toDateTime();
    final reminderTime = medication.reminderTime!;
    final notificationDateTime = DateTime(
      scheduledDateTime.year,
      scheduledDateTime.month,
      scheduledDateTime.day,
      reminderTime.hour,
      reminderTime.minute,
    );

    // Don't schedule past notifications
    if (notificationDateTime.isBefore(DateTime.now())) return;

    final tzDateTime = tz.TZDateTime.from(notificationDateTime, tz.local);
    const androidDetails = AndroidNotificationDetails(
      'medication_reminders',
      'Medication Reminders',
      channelDescription: 'Reminders for scheduled medication doses',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    if (Platform.isAndroid || Platform.isIOS) {
      await _notifications.zonedSchedule(
        _getNotificationId(medication.id, date),
        'Medication Reminder',
        "It's time to take ${medication.name}${medication.dosage != null ? ' (${medication.dosage})' : ''}.",
        tzDateTime,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.date,
        payload: medication.id,
      );
    }
  }

  /// Cancel all notifications for a medication.
  Future<void> cancelMedicationNotifications(String medicationId) async {
    if (!_supportsNotifications) return;

    // We can't easily get all IDs, so we'll cancel by tag pattern if needed
    // For now, cancel a reasonable range
    for (int i = 0; i < AppConstants.notificationScheduleDays; i++) {
      final date = AppDate.today().addDays(i);
      final id = _getNotificationId(medicationId, date);
      await _notifications.cancel(id);
    }
  }

  /// Reschedule notifications for all medications.
  Future<void> rescheduleAllNotifications(List<Medication> medications) async {
    if (!_supportsNotifications) return;

    await _notifications.cancelAll();
    for (final medication in medications) {
      if (medication.reminderEnabled) {
        await scheduleMedicationNotifications(medication);
      }
    }
  }

  /// Cancel all notifications.
  Future<void> cancelAllNotifications() async {
    if (!_supportsNotifications) return;
    await _notifications.cancelAll();
  }

  int _getNotificationId(String medicationId, AppDate date) {
    // Generate a unique ID based on medication ID hash and date
    final medHash = medicationId.hashCode.abs();
    final dateHash = date.toString().hashCode.abs();
    return (medHash + dateHash) % 1000000;
  }

  /// Request notification permissions (iOS).
  Future<bool> requestPermissions() async {
    if (!_supportsNotifications) return false;

    final result = await _notifications
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    return result ?? false;
  }
}