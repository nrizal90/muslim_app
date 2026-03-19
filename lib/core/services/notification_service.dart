import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
// Untuk cek Platform

class NotificationService {
  NotificationService._internal();
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        print("Notifikasi di-klik: ${response.payload}");
      },
    );

    // 1. Minta izin Notifikasi (Android 13+)
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();
    
    // 2. Minta izin Exact Alarm (Android 12+)
    await _requestExactAlarmPermission();
  }

  Future<void> _requestExactAlarmPermission() async {
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidPlugin != null) {
      final bool? allowed = await androidPlugin.requestExactAlarmsPermission();
      print("Exact alarm permission allowed: $allowed");
    }
  }

  // TEST INSTAN
  Future<void> showInstantTest() async {
    await _plugin.show(
      123456,
      "INSTANT TEST",
      "Plugin Berjalan Lancar! 🚀",
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'test_channel',
          'Test Channel',
          importance: Importance.max,
          priority: Priority.high,
          fullScreenIntent: true,
          audioAttributesUsage: AudioAttributesUsage.alarm,
          category: AndroidNotificationCategory.alarm,
        ),
      ),
    );
  }

  // JADWAL SHOLAT
  Future<void> schedulePrayerNotification({
    required int id,
    required String title,
    required String body,
    required DateTime dateTime,
  }) async {
    // TIPS: Jika kamu mengubah setting channel (suara/priority), ganti ID-nya (misal: v13)
    // agar Android mendaftarkan ulang konfigurasinya.
    const String channelId = "prayer_channel_v12"; 

    final scheduledDate = tz.TZDateTime.from(dateTime, tz.local);

    final androidDetails = AndroidNotificationDetails(
      channelId,
      'Jadwal Sholat',
      channelDescription: 'Notifikasi pengingat sholat',
      importance: Importance.max,
      priority: Priority.high,
      fullScreenIntent: true, // Munculkan popup meski layar mati
      audioAttributesUsage: AudioAttributesUsage.alarm,
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
      playSound: true,
    );

    final details = NotificationDetails(android: androidDetails);
    
    if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) {
      print("SKIPPED: $title waktu sudah lewat.");
      return; 
    }

    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        details,
        // Gunakan alarmClock agar muncul ikon jam di status bar (Lebih prioritas bagi OS)
        androidScheduleMode: AndroidScheduleMode.alarmClock, 
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      print("Berhasil jadwal: $title pada $scheduledDate");
    } catch (e) {
      print("Gagal jadwal: $e");
    }
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}