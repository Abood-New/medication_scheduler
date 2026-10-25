import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:medication_scheduler/core/date/date_utils.dart';
import 'package:medication_scheduler/features/medications/domain/entities/medication.dart' as med_entity;
import 'package:medication_scheduler/features/medications/presentation/providers/medication_provider.dart';
import 'package:medication_scheduler/features/schedule/domain/services/medication_schedule_service.dart';
import 'package:medication_scheduler/core/constants/app_constants.dart';
import 'package:medication_scheduler/features/settings/presentation/providers/settings_provider.dart';
import 'package:medication_scheduler/core/services/notification_service.dart';

class MedicationSetupPage extends StatefulWidget {
  const MedicationSetupPage({super.key});

  @override
  State<MedicationSetupPage> createState() => _MedicationSetupPageState();
}

class _MedicationSetupPageState extends State<MedicationSetupPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();
  final _notesController = TextEditingController();

  int _currentStep = 0;
  AppDate _referenceDate = AppDate.today();
  bool _reminderEnabled = false;
  med_entity.TimeOfDay? _reminderTime;
  List<AppDate> _previewDoses = [];

  final _scheduleService = const MedicationScheduleService();

  @override
  void initState() {
    super.initState();
    _updatePreview();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _updatePreview() {
    final today = AppDate.today();
    _previewDoses = _scheduleService.getUpcomingDoses(
      referenceDate: _referenceDate,
      fromDate: today,
      count: 6,
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentStep == 0 ? 'Setup Medication' : 'Step ${_currentStep + 1} of 4'),
        automaticallyImplyLeading: false,
      ),
      body: Form(
        key: _formKey,
        child: Stepper(
          currentStep: _currentStep,
          onStepContinue: _onStepContinue,
          onStepCancel: _onStepCancel,
          controlsBuilder: (context, details) {
            return Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Row(
                children: [
                  if (_currentStep > 0)
                    TextButton(
                      onPressed: details.onStepCancel,
                      child: const Text('Back'),
                    ),
                  const Spacer(),
                  FilledButton(
                    onPressed: details.onStepContinue,
                    child: Text(_currentStep == 3 ? 'Finish' : 'Continue'),
                  ),
                ],
              ),
            );
          },
          steps: [
            // Step 1: Medication name and dosage
            Step(
              title: const Text('Medication'),
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "What's the name of your medication?",
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Medication Name',
                      hintText: 'e.g., Vitamin X',
                      prefixIcon: Icon(Icons.medication_outlined),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a medication name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Dosage (optional)',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _dosageController,
                    decoration: const InputDecoration(
                      labelText: 'Dosage',
                      hintText: 'e.g., 100 mg',
                      prefixIcon: Icon(Icons.straighten_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      labelText: 'Notes (optional)',
                      hintText: 'Any additional notes',
                      prefixIcon: Icon(Icons.note_outlined),
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
              isActive: _currentStep >= 0,
            ),

            // Step 2: Reference date
            Step(
              title: const Text('Reference Date'),
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'When did you last take this medication?',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This date is used as the starting point for calculating your alternating schedule.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 24),
                  InkWell(
                    onTap: _pickReferenceDate,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.primary,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 48,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _referenceDate.formatFull(),
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tap to change',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              isActive: _currentStep >= 1,
            ),

            // Step 3: Schedule preview
            Step(
              title: const Text('Schedule Preview'),
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your medication schedule (every other day):',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Reference date: ${_referenceDate.formatFull()}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 16),
                  ..._previewDoses.map((date) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                date.formatDay(),
                                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ),
                          ),
                          title: Text(date.formatFull()),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'TAKE',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ),
                        ),
                      )),
                  const SizedBox(height: 16),
                  Text(
                    'The pattern continues: Take → Skip → Take → Skip...',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                        ),
                  ),
                ],
              ),
              isActive: _currentStep >= 2,
            ),

            // Step 4: Reminders
            Step(
              title: const Text('Reminders'),
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Would you like reminders on medication days?',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Enable Reminders'),
                    subtitle: const Text('Get notified on days you should take your medication'),
                    value: _reminderEnabled,
                    onChanged: (value) {
                      setState(() {
                        _reminderEnabled = value;
                        if (!value) _reminderTime = null;
                      });
                    },
                  ),
                  if (_reminderEnabled) ...[
                    const SizedBox(height: 16),
                    ListTile(
                      leading: const Icon(Icons.access_time_outlined),
                      title: const Text('Reminder Time'),
                      subtitle: Text(
                        _reminderTime?.format() ?? 'Select time',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      onTap: _pickReminderTime,
                    ),
                  ],
                  const SizedBox(height: 24),
                  Text(
                    'Reminders work completely offline using local notifications.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
              isActive: _currentStep >= 3,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickReferenceDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _referenceDate.toDateTime(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _referenceDate = AppDate.fromDateTime(picked);
        _updatePreview();
      });
    }
  }

  Future<void> _pickReminderTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime != null
          ? med_entity.TimeOfDay(hour: _reminderTime!.hour, minute: _reminderTime!.minute)
          : med_entity.TimeOfDay(hour: 9, minute: 0),
    );
    if (picked != null) {
      setState(() {
        _reminderTime = med_entity.TimeOfDay(hour: picked.hour, minute: picked.minute);
      });
    }
  }

  void _onStepContinue() {
    if (_currentStep == 0) {
      if (!_formKey.currentState!.validate()) return;
    }
    if (_currentStep < 3) {
      setState(() => _currentStep++);
    } else {
      _finishSetup();
    }
  }

  void _onStepCancel() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  Future<void> _finishSetup() async {
    final medProvider = context.read<MedicationProvider>();
    final settingsProvider = context.read<SettingsProvider>();

    final medication = med_entity.Medication.create(
      name: _nameController.text.trim(),
      dosage: _dosageController.text.trim().isEmpty ? null : _dosageController.text.trim(),
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      scheduleType: med_entity.ScheduleType.EVERY_OTHER_DAY,
      referenceDate: _referenceDate,
      reminderEnabled: _reminderEnabled,
      reminderTime: _reminderTime,
    );

    final success = await medProvider.addMedication(medication);

    if (success && mounted) {
      // Schedule notifications if enabled
      if (_reminderEnabled && _reminderTime != null) {
        await NotificationService().scheduleMedicationNotifications(medication);
      }

      await settingsProvider.setFirstLaunchComplete();

      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(medProvider.error ?? 'Failed to create medication'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}