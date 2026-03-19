import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app.dart';
// import 'core/services/timezone_service.dart';
import 'core/database/database_helper.dart';
import 'core/services/notification_service.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'features/quran/data/datasources/quran_local_datasource.dart';
import 'features/quran/data/datasources/quran_remote_datasource.dart';
import 'features/quran/data/models/ayah_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // await TimezoneService.init();
  tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));
  await initializeDateFormatting('id', null);

  final notificationService = NotificationService();
  await notificationService.init();

  await DatabaseHelper.instance.database;

  final dbHelper = DatabaseHelper.instance;
  final local = QuranLocalDataSource(dbHelper);
  final remote = QuranRemoteDataSource();

  final isEmpty = await local.isAyahTableEmpty();

  if (isEmpty) {
    print("Fetching real Quran data...");

    final ayahs = await remote.fetchAllAyahs();

    await local.insertAyahs(ayahs);

    print("Real Quran inserted!");
  }

  runApp(const ProviderScope(child: MyApp()));
}