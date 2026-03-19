import 'package:go_router/go_router.dart';
import '../features/prayer/presentation/screens/prayer_screen.dart';

final appRouter = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const PrayerScreen(),
    ),
  ],
);