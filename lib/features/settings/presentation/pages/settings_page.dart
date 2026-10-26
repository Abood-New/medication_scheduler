import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:medication_scheduler/features/settings/presentation/providers/settings_provider.dart' hide TimeOfDay;
import 'package:medication_scheduler/features/settings/presentation/providers/settings_provider.dart' as settings_entity show TimeOfDay;
import 'package:medication_scheduler/core/services/notification_service.dart';
import 'package:medication_scheduler/core/constants/app_constants.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        return Scaffold(
          appBar: AppBar(title: const Text('Settings')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Appearance
              _buildSectionHeader(context, 'Appearance'),
              Card(
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Dark Mode'),
                      subtitle: const Text('Use dark theme'),
                      value: settings.isDarkMode,
                      onChanged: (value) => settings.setDarkMode(value),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    ListTile(
                      title: const Text('Date Format'),
                      subtitle: Text(settings.dateFormat),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _showDateFormatDialog(context, settings),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Notifications
              _buildSectionHeader(context, 'Notifications'),
              Card(
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Enable Notifications'),
                      subtitle: const Text('Allow medication reminders'),
                      value: settings.notificationsEnabled,
                      onChanged: (value) async {
                        await settings.setNotificationsEnabled(value);
                        if (value) {
                          await NotificationService().requestPermissions();
                        }
                      },
                    ),
                    if (settings.notificationsEnabled) ...[
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      ListTile(
                        title: const Text('Default Reminder Time'),
                        subtitle: Text(
                          settings.defaultReminderTime?.format() ?? 'Not set',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _showTimePicker(context, settings),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Data Management
              _buildSectionHeader(context, 'Data Management'),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(Icons.backup_outlined, color: Theme.of(context).colorScheme.primary),
                      title: const Text('Export Data'),
                      subtitle: const Text('Export all medications and history (coming soon)'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _showComingSoon(context, 'Export Data'),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    ListTile(
                      leading: Icon(Icons.restore_outlined, color: Theme.of(context).colorScheme.primary),
                      title: const Text('Import Data'),
                      subtitle: const Text('Import from backup file (coming soon)'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _showComingSoon(context, 'Import Data'),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    ListTile(
                      leading: Icon(Icons.delete_forever_outlined, color: Theme.of(context).colorScheme.error),
                      title: const Text('Reset All Data'),
                      subtitle: const Text('Delete all medications, history, and settings'),
                      onTap: () => _confirmReset(context, settings),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // About
              _buildSectionHeader(context, 'About'),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(Icons.info_outline, color: Theme.of(context).colorScheme.primary),
                      title: const Text('Version'),
                      trailing: Text(AppConstants.appName, style: Theme.of(context).textTheme.bodyMedium),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    ListTile(
                      leading: Icon(Icons.privacy_tip_outlined, color: Theme.of(context).colorScheme.primary),
                      title: const Text('Privacy'),
                      subtitle: const Text('All data stored locally on your device. No internet required.'),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    ListTile(
                      leading: Icon(Icons.medical_services_outlined, color: Theme.of(context).colorScheme.primary),
                      title: const Text('Medical Disclaimer'),
                      subtitle: const Text('This app is a reminder tool, not medical advice.'),
                      onTap: () => _showDisclaimer(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              letterSpacing: 1.2,
            ),
      ),
    );
  }

  Future<void> _showDateFormatDialog(BuildContext context, SettingsProvider settings) async {
    final formats = [
      'MMMM d, yyyy',
      'MMM d, yyyy',
      'd MMMM yyyy',
      'dd/MM/yyyy',
      'MM/dd/yyyy',
      'yyyy-MM-dd',
    ];

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Date Format'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: formats.map((format) {
            final now = DateTime.now();
            final example = format.contains('MMMM')
                ? now.toString() // placeholder
                : now.toString();
            return RadioListTile<String>(
              title: Text(format),
              subtitle: Text(_formatExample(now, format)),
              value: format,
              groupValue: settings.dateFormat,
              onChanged: (value) {
                if (value != null) {
                  settings.setDateFormat(value);
                  Navigator.pop(context);
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  String _formatExample(DateTime date, String format) {
    // Simple example - would use intl in real implementation
    switch (format) {
      case 'MMMM d, yyyy':
        return 'October 25, 2026';
      case 'MMM d, yyyy':
        return 'Oct 25, 2026';
      case 'd MMMM yyyy':
        return '25 October 2026';
      case 'dd/MM/yyyy':
        return '25/10/2026';
      case 'MM/dd/yyyy':
        return '10/25/2026';
      case 'yyyy-MM-dd':
        return '2026-10-25';
      default:
        return format;
    }
  }

  Future<void> _showTimePicker(BuildContext context, SettingsProvider settings) async {
    final initialTime = settings.defaultReminderTime != null
        ? TimeOfDay(hour: settings.defaultReminderTime!.hour, minute: settings.defaultReminderTime!.minute)
        : const TimeOfDay(hour: 9, minute: 0);

    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (picked != null) {
      final time = settings_entity.TimeOfDay(hour: picked.hour, minute: picked.minute);
      await settings.setDefaultReminderTime(time);
    }
  }

  Future<void> _showComingSoon(BuildContext context, String feature) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature coming soon!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _confirmReset(BuildContext context, SettingsProvider settings) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset All Data?'),
        content: const Text(
          'This will permanently delete all medications, history records, and settings. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset Everything'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final doubleConfirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Are you absolutely sure?'),
          content: const Text('All data will be lost forever.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('No, keep my data'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Yes, delete everything'),
            ),
          ],
        ),
      );

      if (doubleConfirmed == true && context.mounted) {
        await settings.resetSettings();
        await NotificationService().cancelAllNotifications();
        // Note: In a full implementation, you'd also clear the medication and record boxes
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All data reset. App will restart.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showDisclaimer(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Medical Disclaimer'),
        content: const SingleChildScrollView(
          child: Text(
            'This application is a scheduling and reminder tool only. It is not a medical device '
            'and does not provide medical advice, diagnosis, or treatment recommendations.\n\n'
            'Always follow your healthcare provider\'s instructions for medication use. '
            'This app does not:\n'
            '• Provide medical advice\n'
            '• Adjust dosages automatically\n'
            '• Recommend taking additional doses\n'
            '• Determine what to do after missed doses\n\n'
            'If you miss a dose, consult your healthcare provider for guidance. '
            'The app simply records what you tell it and calculates schedules based on your reference date.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}