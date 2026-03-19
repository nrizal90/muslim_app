import 'package:go_router/go_router.dart';
import '../features/prayer/presentation/screens/prayer_screen.dart';
import '../features/quran/presentation/screens/surah_list_screen.dart';
import '../features/quran/presentation/screens/mushaf_screen.dart';
import '../features/qibla/presentation/screens/qibla_screen.dart';

final appRouter = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const PrayerScreen(),
    ),
    GoRoute(
      path: '/quran',
      builder: (context, state) => const SurahListScreen(),
    ),
    GoRoute(
      path: '/quran/mushaf',
      builder: (context, state) {
        final initialPage = state.extra as int? ?? 1;
        return MushafScreen(initialPage: initialPage);
      },
    ),
    GoRoute(
      path: '/qibla',
      builder: (context, state) => const QiblaScreen(),
    ),
  ],
);