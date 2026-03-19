import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app.dart';
import 'core/database/database_helper.dart';
import 'core/services/notification_service.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

import 'features/quran/data/datasources/quran_local_datasource.dart';
import 'features/quran/data/datasources/quran_remote_datasource.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  tz.initializeTimeZones();
  final localTimezone = await FlutterTimezone.getLocalTimezone();
  tz.setLocalLocation(tz.getLocation(localTimezone));
  await initializeDateFormatting('id', null);

  runApp(const ProviderScope(child: AppInitializer()));
}

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  bool _ready = false;
  String _status = "Memulai aplikasi...";

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    _setStatus("Menyiapkan notifikasi...");
    await NotificationService().init();

    _setStatus("Membuka database...");
    await DatabaseHelper.instance.database;

    final local = QuranLocalDataSource(DatabaseHelper.instance);
    final isEmpty = await local.isAyahTableEmpty();

    if (isEmpty) {
      _setStatus("Mengunduh data Al-Qur'an...\n(hanya sekali saat pertama install)");
      final ayahs = await QuranRemoteDataSource().fetchAllAyahs();

      _setStatus("Menyimpan data Al-Qur'an...");
      await local.insertAyahs(ayahs);
    }

    setState(() => _ready = true);
  }

  void _setStatus(String status) {
    if (mounted) setState(() => _status = status);
  }

  @override
  Widget build(BuildContext context) {
    if (_ready) return const MyApp();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 24),
              Text(
                _status,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}