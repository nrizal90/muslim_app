import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/qibla_provider.dart';

class QiblaScreen extends ConsumerStatefulWidget {
  const QiblaScreen({super.key});

  @override
  ConsumerState<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends ConsumerState<QiblaScreen> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      ref.read(qiblaProvider.notifier).init();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(qiblaProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Arah Kiblat"),
      ),
      body: Center(
        child: _buildContent(state),
      ),
    );
  }

  Widget _buildContent(QiblaState state) {
    if (state.isLoading) {
      return const CircularProgressIndicator();
    }

    if (state.error != null) {
      return Text(
        state.error!,
        textAlign: TextAlign.center,
      );
    }

    if (state.qiblaDirection == null ||
        state.heading == null) {
      return const Text("Menunggu sensor...");
    }

    final angle =
        (state.qiblaDirection! - state.heading!) *
            (pi / 180);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Hadapkan ponsel ke arah panah",
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 32),

        // Kompas
        Stack(
          alignment: Alignment.center,
          children: [
            // Lingkaran background
            Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(width: 2),
              ),
            ),

            // Jarum kiblat
            AnimatedRotation(
              duration: const Duration(milliseconds: 300),
              turns: angle / (2 * pi),
              child: const Icon(
                Icons.navigation,
                size: 120,
                color: Colors.green,
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        Text(
          "Arah Kiblat: ${state.qiblaDirection!.toStringAsFixed(1)}°",
        ),
      ],
    );
  }
}