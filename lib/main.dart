import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:medication_scheduler/core/constants/app_constants.dart';
import 'package:medication_scheduler/core/services/notification_service.dart';
import 'package:medication_scheduler/features/medications/data/datasources/medication_local_datasource.dart';
import 'package:medication_scheduler/features/medications/data/repositories/medication_repository_impl.dart';
import 'package:medication_scheduler/features/medications/domain/repositories/medication_repository.dart';
import 'package:medication_scheduler/features/medications/domain/usecases/get_all_medications.dart';
import 'package:medication_scheduler/features/medications/domain/usecases/get_medication.dart';
import 'package:medication_scheduler/features/medications/domain/usecases/create_medication.dart';
import 'package:medication_scheduler/features/medications/domain/usecases/update_medication.dart';
import 'package:medication_scheduler/features/medications/domain/usecases/delete_medication.dart';
import 'package:medication_scheduler/features/medications/presentation/providers/medication_provider.dart';
import 'package:medication_scheduler/features/medications/presentation/pages/medication_setup_page.dart';
import 'package:medication_scheduler/features/medications/presentation/pages/medication_list_page.dart';
import 'package:medication_scheduler/features/history/data/datasources/medication_record_local_datasource.dart';
import 'package:medication_scheduler/features/history/data/repositories/medication_record_repository_impl.dart';
import 'package:medication_scheduler/features/history/domain/repositories/medication_record_repository.dart';
import 'package:medication_scheduler/features/history/domain/usecases/get_medication_records.dart';
import 'package:medication_scheduler/features/history/domain/usecases/get_records_for_date_range.dart';
import 'package:medication_scheduler/features/history/domain/usecases/create_or_update_record.dart';
import 'package:medication_scheduler/features/history/presentation/providers/history_provider.dart';
import 'package:medication_scheduler/features/schedule/presentation/providers/schedule_provider.dart';
import 'package:medication_scheduler/features/settings/presentation/providers/settings_provider.dart';
import 'package:medication_scheduler/features/settings/presentation/pages/settings_page.dart';
import 'package:medication_scheduler/features/medications/presentation/pages/home_page.dart';
import 'package:medication_scheduler/features/schedule/presentation/pages/calendar_page.dart';
import 'package:medication_scheduler/features/history/presentation/pages/history_page.dart';
import 'package:medication_scheduler/features/medications/presentation/pages/medication_detail_page.dart';
import 'package:medication_scheduler/features/medications/data/models/medication_hive_model.dart';
import 'package:medication_scheduler/features/history/data/models/medication_record_hive_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive (platform-specific)
  if (Platform.isAndroid ||
      Platform.isIOS ||
      Platform.isMacOS ||
      Platform.isWindows ||
      Platform.isLinux) {
    await Hive.initFlutter();
  } else {
    // Web platform
    await Hive.initFlutter('medication_scheduler');
  }
  Hive.registerAdapter(MedicationHiveModelAdapter());
  Hive.registerAdapter(MedicationRecordHiveModelAdapter());

  // Initialize notifications (skip on web if not supported)
  try {
    await NotificationService().initialize();
  } catch (e) {
    // Notifications may not be available on all web platforms
    debugPrint('Notification initialization skipped: $e');
  }

  runApp(const MedicationSchedulerApp());
}

class MedicationSchedulerApp extends StatelessWidget {
  const MedicationSchedulerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Data sources
        Provider<MedicationLocalDataSource>(
          create: (_) => MedicationLocalDataSource(),
          dispose: (_, ds) => ds.close(),
        ),
        Provider<MedicationRecordLocalDataSource>(
          create: (_) => MedicationRecordLocalDataSource(),
          dispose: (_, ds) => ds.close(),
        ),
        // Repositories
        Provider<MedicationRepository>(
          create: (context) => MedicationRepositoryImpl(
            context.read<MedicationLocalDataSource>(),
          ),
        ),
        Provider<MedicationRecordRepository>(
          create: (context) => MedicationRecordRepositoryImpl(
            context.read<MedicationRecordLocalDataSource>(),
          ),
        ),
        // Use cases
        Provider<GetAllMedications>(
          create: (context) =>
              GetAllMedications(context.read<MedicationRepository>()),
        ),
        Provider<GetMedication>(
          create: (context) =>
              GetMedication(context.read<MedicationRepository>()),
        ),
        Provider<CreateMedication>(
          create: (context) =>
              CreateMedication(context.read<MedicationRepository>()),
        ),
        Provider<UpdateMedication>(
          create: (context) =>
              UpdateMedication(context.read<MedicationRepository>()),
        ),
        Provider<DeleteMedication>(
          create: (context) =>
              DeleteMedication(context.read<MedicationRepository>()),
        ),
        Provider<GetMedicationRecords>(
          create: (context) =>
              GetMedicationRecords(context.read<MedicationRecordRepository>()),
        ),
        Provider<GetRecordsForDateRange>(
          create: (context) => GetRecordsForDateRange(
              context.read<MedicationRecordRepository>()),
        ),
        Provider<CreateOrUpdateRecord>(
          create: (context) =>
              CreateOrUpdateRecord(context.read<MedicationRecordRepository>()),
        ),
        // Providers
        ChangeNotifierProvider<MedicationProvider>(
          create: (context) => MedicationProvider(
            getAllMedications: context.read<GetAllMedications>(),
            getMedication: context.read<GetMedication>(),
            createMedication: context.read<CreateMedication>(),
            updateMedication: context.read<UpdateMedication>(),
            deleteMedication: context.read<DeleteMedication>(),
          ),
        ),
        ChangeNotifierProvider<ScheduleProvider>(
          create: (_) => ScheduleProvider(),
        ),
        ChangeNotifierProvider<HistoryProvider>(
          create: (context) => HistoryProvider(
            getMedicationRecords: context.read<GetMedicationRecords>(),
            getRecordsForDateRange: context.read<GetRecordsForDateRange>(),
            createOrUpdateRecord: context.read<CreateOrUpdateRecord>(),
          ),
        ),
        ChangeNotifierProvider<SettingsProvider>(
          create: (_) => SettingsProvider(),
        ),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          return MaterialApp(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              useMaterial3: true,
              colorSchemeSeed: Colors.teal,
              brightness: Brightness.light,
            ),
            darkTheme: ThemeData(
              useMaterial3: true,
              colorSchemeSeed: Colors.teal,
              brightness: Brightness.dark,
            ),
            themeMode: settings.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            home: const AppEntryPoint(),
            routes: {
              '/setup': (_) => const MedicationSetupPage(),
              '/medications': (_) => const MedicationListPage(),
              '/settings': (_) => const SettingsPage(),
            },
          );
        },
      ),
    );
  }
}

class AppEntryPoint extends StatefulWidget {
  const AppEntryPoint({super.key});

  @override
  State<AppEntryPoint> createState() => _AppEntryPointState();
}

class _AppEntryPointState extends State<AppEntryPoint> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    final medProvider = context.read<MedicationProvider>();
    final settingsProvider = context.read<SettingsProvider>();

    await settingsProvider.loadSettings();
    await medProvider.loadMedications();

    // Check if first launch
    if (settingsProvider.isFirstLaunch && medProvider.medications.isEmpty) {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/setup');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MedicationProvider>(
      builder: (context, medProvider, _) {
        if (medProvider.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (medProvider.medications.isEmpty) {
          return const MedicationSetupPage();
        }

        // Select first medication by default
        final selectedMed =
            medProvider.selectedMedication ?? medProvider.medications.first;
        medProvider.selectMedication(selectedMed);

        return const MainNavigation();
      },
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomePage(),
    const CalendarPage(),
    const HistoryPage(),
    const MedicationListPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Calendar',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.medication_outlined),
            selectedIcon: Icon(Icons.medication),
            label: 'Meds',
          ),
        ],
      ),
    );
  }
}
