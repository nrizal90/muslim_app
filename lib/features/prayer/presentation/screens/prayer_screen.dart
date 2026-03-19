import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:jhijri/jhijri.dart';
import 'package:muslim_app/features/quran/presentation/screens/mushaf_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../qibla/presentation/screens/qibla_screen.dart';
import '../providers/prayer_provider.dart';
import '../../../../core/services/notification_service.dart';

class PrayerScreen extends ConsumerStatefulWidget {
  const PrayerScreen({super.key});

  @override
  ConsumerState<PrayerScreen> createState() => _PrayerScreenState();
}

class PrayerCountdown extends StatefulWidget {
  final DateTime targetTime;
  final TextStyle textStyle;

  const PrayerCountdown({
    super.key,
    required this.targetTime,
    required this.textStyle,
  });

  @override
  State<PrayerCountdown> createState() => _PrayerCountdownState();
}

class _PrayerCountdownState extends State<PrayerCountdown> {
  late Timer _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _updateRemaining();

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateRemaining();
    });
  }

  void _updateRemaining() {
    if (!mounted) return;

    final diff = widget.targetTime.difference(DateTime.now());

    setState(() {
      _remaining = diff.isNegative ? Duration.zero : diff;
    });
  }

  @override
  void didUpdateWidget(covariant PrayerCountdown oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.targetTime != widget.targetTime) {
      _updateRemaining();
    }
  }

  @override
  Widget build(BuildContext context) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");

    String formatted =
      "${twoDigits(_remaining.inHours)}:"
      "${twoDigits(_remaining.inMinutes.remainder(60))}:"
      "${twoDigits(_remaining.inSeconds.remainder(60))}";

    return Text(
      formatted,
      style: widget.textStyle.copyWith(
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }
}

class _PrayerScreenState extends ConsumerState<PrayerScreen> with WidgetsBindingObserver {
  bool notificationEnabled = false;
  Timer? _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadNotificationStatus();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _now = DateTime.now();
      });
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  String getCurrentPrayer(prayer) {
    final now = _now;

    final times = {
      "Subuh": prayer.fajr,
      "Dzuhur": prayer.dhuhr,
      "Ashar": prayer.asr,
      "Maghrib": prayer.maghrib,
      "Isya": prayer.isha,
    };

    final sorted = times.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    for (int i = 0; i < sorted.length; i++) {
      final current = sorted[i];
      final next = i + 1 < sorted.length ? sorted[i + 1] : null;

      if (next != null) {
        if (now.isAfter(current.value) && now.isBefore(next.value)) {
          return current.key;
        }
      } else {
        // Jika sudah lewat Isya → tetap Isya sampai Subuh besok
        if (now.isAfter(current.value)) {
          return current.key;
        }
      }
    }

    return ""; // sebelum Subuh
  }

  Future<void> _loadNotificationStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      // Ambil nilai 'isNotifOn', jika kosong (null) maka default-nya false
      notificationEnabled = prefs.getBool('isNotifOn') ?? false;
    });
  }

  Future<void> _saveNotificationStatus(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isNotifOn', value);
  }

  String formatTime(DateTime time) {
    // Hm() akan tetap 24 jam (14:00), 
    // jm() akan mengikuti format lokal (14.00 atau 2:00 PM)
    return DateFormat.Hm('id').format(time); 
  }

  String getIndonesianHijriMonth(int month) {
    const months = {
      1: "Muharram",
      2: "Safar",
      3: "Rabi'ul Awal",
      4: "Rabi'ul Akhir",
      5: "Jumadil Awal",
      6: "Jumadil Akhir",
      7: "Rajab",
      8: "Sya'ban",
      9: "Ramadhan",
      10: "Syawal",
      11: "Dzulqa'dah",
      12: "Dzulhijjah",
    };
    return months[month] ?? "";
  }

  String _formatHijri(DateTime date) {
    try {
      final jHijri = JHijri(fDate: date);
      
      // Ambil angka tanggal dan tahun
      String day = jHijri.day.toString();
      String year = jHijri.year.toString();
      
      // Ambil nama bulan dari mapper buatan kita sendiri
      String monthName = getIndonesianHijriMonth(jHijri.month);
      
      // Susun secara manual: Tanggal - Bulan - Tahun
      return "$day $monthName $year H";
    } catch (e) {
      debugPrint("Error Hijri: $e");
      return "Format Tanggal Error";
    }
  }

  Map<String, dynamic> getNextPrayer(prayer) {
    final times = {
      "Subuh": prayer.fajr,
      "Dzuhur": prayer.dhuhr,
      "Ashar": prayer.asr,
      "Maghrib": prayer.maghrib,
      "Isya": prayer.isha,
    };

    for (var entry in times.entries) {
      if (entry.value.isAfter(_now)) {
        return {
          "name": entry.key,
          "targetDateTime": entry.value, // Pastikan key ini ada
        };
      }
    }

    // Fallback: Jika semua waktu hari ini sudah lewat, targetnya Subuh besok
    return {
      "name": "Subuh (Besok)",
      "targetDateTime": prayer.fajr.add(Duration(days: 1)), // Jangan lupa ini!
    };
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String hours = twoDigits(duration.inHours);
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }

  Future<void> scheduleAllPrayer(prayer) async {
    final notificationService = NotificationService();
    await notificationService.init();
    await notificationService.cancelAll();

    int idCounter = 1;

    for (int dayOffset = 0; dayOffset < 7; dayOffset++) {
      final date = DateTime.now().add(Duration(days: dayOffset));

      final prayers = {
        "Subuh": prayer.fajr.add(Duration(days: dayOffset)),
        "Dzuhur": prayer.dhuhr.add(Duration(days: dayOffset)),
        "Ashar": prayer.asr.add(Duration(days: dayOffset)),
        "Maghrib": prayer.maghrib.add(Duration(days: dayOffset)),
        "Isya": prayer.isha.add(Duration(days: dayOffset)),
      };

      final now = DateTime.now();

      for (var entry in prayers.entries) {
        String title = entry.key;
        DateTime prayerTime = entry.value;
        final isFriday = prayerTime.weekday == DateTime.friday;

        /// 🔔 KHUSUS JUMAT (DZUHUR)
        if (isFriday && title == "Dzuhur") {
          DateTime beforeJumat =
              prayerTime.subtract(const Duration(minutes: 45));

          if (beforeJumat.isAfter(now)) {
            await notificationService.schedulePrayerNotification(
              id: idCounter++,
              title: "Persiapan Sholat Jumat",
              body:
                  "45 menit lagi waktu Sholat Jumat, yuk potong kuku dan mandi!",
              dateTime: beforeJumat,
            );
          }
        } else {
          /// 🔔 5 MENIT SEBELUM (normal)
          DateTime beforeTime =
              prayerTime.subtract(const Duration(minutes: 5));

          if (beforeTime.isAfter(now)) {
            await notificationService.schedulePrayerNotification(
              id: idCounter++,
              title: title,
              body: "5 menit lagi waktu $title",
              dateTime: beforeTime,
            );
          }
        }

        /// 🔔 PAS ADZAN (SEMUA)
        if (prayerTime.isAfter(now)) {
          await notificationService.schedulePrayerNotification(
            id: idCounter++,
            title: title,
            body: "Sudah masuk waktu sholat $title",
            dateTime: prayerTime,
          );
        }
      }
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'lastScheduleDate',
      DateFormat('yyyy-MM-dd').format(DateTime.now()),
    );
  }

  Future<void> _checkAndReschedule() async {
    if (!notificationEnabled) return;

    final prefs = await SharedPreferences.getInstance();
    final lastDate = prefs.getString('lastScheduleDate');

    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    if (lastDate != today) {
      final prayerAsync = ref.read(prayerTimeProvider);

      prayerAsync.whenData((prayer) async {
        await scheduleAllPrayer(prayer);
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkAndReschedule();
    }
  }

  Future<void> debugNotification60Seconds() async {
    final notificationService = NotificationService();
    // await notificationService.init();

    final now = DateTime.now();
    final debugTime = now.add(const Duration(seconds: 60));

    await notificationService.schedulePrayerNotification(
      id: 99999, // id khusus debug
      title: "DEBUG NOTIFICATION",
      body: "Kalau ini muncul, scheduling berhasil 🚀",
      dateTime: debugTime,
    );

    debugPrint("Debug notif dijadwalkan untuk: $debugTime");
  }

  IconData _getIconForPrayer(String name) {
    if (name == "Subuh") return Icons.wb_twilight;
    if (name == "Syuruq") return Icons.wb_sunny_outlined;
    if (name == "Dzuhur") return Icons.wb_sunny;
    if (name == "Ashar") return Icons.wb_sunny_outlined;
    if (name == "Maghrib") return Icons.nightlight_round;
    return Icons.dark_mode;
  }
  
  Widget _prayerTile(String name, DateTime time, bool isActive) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        color: isActive ? Colors.green.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: isActive ? Border.all(color: Colors.green, width: 1) : null,
      ),
      child: ListTile(
        leading: Icon(
          _getIconForPrayer(name),
          color: isActive ? Colors.green : Colors.grey,
        ),
        title: Text(
          name,
          style: TextStyle(
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        trailing: Text(
          formatTime(time),
          style: TextStyle(
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive ? Colors.green : Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _featureItem(
    BuildContext context, 
    String title, 
    IconData icon,
    {
      VoidCallback? onTap,
      bool isEnabled = false,
    }) {
    return InkWell(
      onTap: isEnabled ? onTap : () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Fitur $title akan segera hadir")),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isEnabled ? Theme.of(context).primaryColor : Colors.grey, size: 30),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  final notif = NotificationService();

  @override
  Widget build(BuildContext context) {
    final prayerAsync = ref.watch(prayerTimeProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text("Muslim App"),
        centerTitle: true,
      ),
      body: prayerAsync.when(
        data: (prayer) { 
          final nextPrayer = getNextPrayer(prayer);
          final currentPrayer = getCurrentPrayer(prayer);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [

              /// HEADER CARD
              Card(
                  color: Theme.of(context).primaryColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Text(
                          "Menuju ${nextPrayer['name']}",
                          style: const TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        PrayerCountdown(
                          targetTime: nextPrayer['targetDateTime'] ?? DateTime.now(), // Pastikan getNextPrayer mengirim DateTime
                          textStyle: const TextStyle(
                            color: Colors.white,
                            fontSize: 42,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          DateFormat('EEEE, d MMMM yyyy', 'id').format(_now),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                        ),

                        Text(
                          _formatHijri(_now),
                          style: const TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 20),

              /// PRAYER TIME CARD
              Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: [
                    _prayerTile("Subuh", prayer.fajr, currentPrayer == "Subuh"),
                    _prayerTile("Syuruq", prayer.syuruq, false),
                    _prayerTile("Dzuhur", prayer.dhuhr, currentPrayer == "Dzuhur"),
                    _prayerTile("Ashar", prayer.asr, currentPrayer == "Ashar"),
                    _prayerTile("Maghrib", prayer.maghrib, currentPrayer == "Maghrib"),
                    _prayerTile("Isya", prayer.isha, currentPrayer == "Isya"),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              /// NOTIFICATION SWITCH
              // Card(
              //   shape: RoundedRectangleBorder(
              //       borderRadius: BorderRadius.circular(16)),
              //   child: SwitchListTile(
              //     title: const Text("Notifikasi Adzan"),
              //     subtitle: const Text("Aktifkan pengingat waktu sholat"),
              //     value: notificationEnabled,
              //     onChanged: (value) async {
              //       setState(() {
              //         notificationEnabled = value;
              //       });

              //       await _saveNotificationStatus(value);

              //       if (value) {
              //         await scheduleAllPrayer(prayer);
              //       } else {
              //         final service = NotificationService();
              //         await service.cancelAll();
              //       }
              //     },
              //   ),
              // ),

              const SizedBox(height: 30),

              const Text(
                "Fitur Lainnya",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),

              const SizedBox(height: 12),

              GridView.count(
                shrinkWrap: true, // Penting: agar Grid mengikuti tinggi kontennya
                physics: const NeverScrollableScrollPhysics(), // Penting: agar tidak scroll sendiri
                crossAxisCount: 3, // Menampilkan 3 kolom
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.9, // Mengatur rasio lebar/tinggi kotak
                children: [
                  _featureItem(context, "Al-Qur'an", Icons.menu_book_rounded,
                    onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const MushafScreen(),
                          ),
                        );
                      },
                      isEnabled: true),
                  _featureItem(context, "Dzikir Pagi & Petang", Icons.import_contacts_rounded),
                  _featureItem(context, "Masjid Terdekat", Icons.mosque_rounded),
                  _featureItem(context, "Kiblat", Icons.explore_rounded, 
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const QiblaScreen(),
                        ),
                      );
                    },
                    isEnabled: true),
                  _featureItem(context, "Kumpulan Doa Harian", Icons.auto_stories_rounded),
                  _featureItem(context, "Zakat", Icons.payments_rounded),
                ],
              ),
              // ElevatedButton(
              //   onPressed: () async {
              //     await debugNotification60Seconds();
              //     // await notif.showInstantTest();
              //   },
              //   child: const Text("Test Notifikasi 60 Detik"),
              // ),
              // ElevatedButton(
              //   onPressed: () async {
              //     // await debugNotification60Seconds();
              //     await notif.showInstantTest();
              //   },
              //   child: const Text("Test Instant Notifikasi"),
              // ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text("Error: $e")),
      ),
    );
  }
}