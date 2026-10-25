import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:medication_scheduler/core/constants/app_constants.dart';

class SettingsProvider extends ChangeNotifier {
  Box? _settingsBox;

  Future<Box> get _box async {
    _settingsBox ??= await Hive.openBox(AppConstants.hiveBoxSettings);
    return _settingsBox!;
  }

  // Theme
  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;

  // Date format
  String _dateFormat = 'MMMM d, yyyy';
  String get dateFormat => _dateFormat;

  // Notifications
  bool _notificationsEnabled = true;
  bool get notificationsEnabled => _notificationsEnabled;

  TimeOfDay? _defaultReminderTime;
  TimeOfDay? get defaultReminderTime => _defaultReminderTime;

  // First launch
  bool _isFirstLaunch = true;
  bool get isFirstLaunch => _isFirstLaunch;

  Future<void> loadSettings() async {
    try {
      final box = await _box;
      _isDarkMode = box.get('isDarkMode', defaultValue: false);
      _dateFormat = box.get('dateFormat', defaultValue: 'MMMM d, yyyy');
      _notificationsEnabled = box.get('notificationsEnabled', defaultValue: true);
      _isFirstLaunch = box.get('isFirstLaunch', defaultValue: true);

      final hour = box.get('reminderHour');
      final minute = box.get('reminderMinute');
      if (hour != null && minute != null) {
        _defaultReminderTime = TimeOfDay(hour: hour, minute: minute);
      }

      notifyListeners();
    } catch (e) {
      // Ignore errors, use defaults
    }
  }

  Future<void> setDarkMode(bool value) async {
    final box = await _box;
    await box.put('isDarkMode', value);
    _isDarkMode = value;
    notifyListeners();
  }

  Future<void> setDateFormat(String format) async {
    final box = await _box;
    await box.put('dateFormat', format);
    _dateFormat = format;
    notifyListeners();
  }

  Future<void> setNotificationsEnabled(bool value) async {
    final box = await _box;
    await box.put('notificationsEnabled', value);
    _notificationsEnabled = value;
    notifyListeners();
  }

  Future<void> setDefaultReminderTime(TimeOfDay? time) async {
    final box = await _box;
    if (time != null) {
      await box.put('reminderHour', time.hour);
      await box.put('reminderMinute', time.minute);
    } else {
      await box.delete('reminderHour');
      await box.delete('reminderMinute');
    }
    _defaultReminderTime = time;
    notifyListeners();
  }

  Future<void> setFirstLaunchComplete() async {
    final box = await _box;
    await box.put('isFirstLaunch', false);
    _isFirstLaunch = false;
    notifyListeners();
  }

  Future<void> resetSettings() async {
    final box = await _box;
    await box.clear();
    _isDarkMode = false;
    _dateFormat = 'MMMM d, yyyy';
    _notificationsEnabled = true;
    _defaultReminderTime = null;
    _isFirstLaunch = true;
    notifyListeners();
  }
}

/// Simple time-of-day for settings (avoiding dependency on medication entity)
class TimeOfDay {
  final int hour;
  final int minute;

  const TimeOfDay({required this.hour, required this.minute});

  String format({bool use24Hour = false}) {
    if (use24Hour) {
      return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
    }
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
  }
}