import 'dart:async';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/location_service.dart';
import '../../domain/usecases/get_qibla_direction.dart';

class QiblaState {
  final double? qiblaDirection;
  final double? heading;
  final bool isLoading;
  final String? error;

  const QiblaState({
    this.qiblaDirection,
    this.heading,
    this.isLoading = false,
    this.error,
  });

  factory QiblaState.initial() => const QiblaState();

  QiblaState copyWith({
    double? qiblaDirection,
    double? heading,
    bool? isLoading,
    String? error,
  }) {
    return QiblaState(
      qiblaDirection: qiblaDirection ?? this.qiblaDirection,
      heading: heading ?? this.heading,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}



class QiblaNotifier extends StateNotifier<QiblaState> {
  final LocationService locationService;
  final GetQiblaDirection getQiblaDirection;

  StreamSubscription<CompassEvent>? _compassSub;

  QiblaNotifier(
    this.locationService,
    this.getQiblaDirection,
  ) : super(QiblaState.initial());

  Future<void> init() async {
    try {
      state = state.copyWith(isLoading: true);

      final position = await locationService.getCurrentLocation();

      final direction = getQiblaDirection(
        position.latitude,
        position.longitude,
      );

      state = state.copyWith(
        qiblaDirection: direction,
        isLoading: false,
      );

      _listenCompass();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void _listenCompass() {
    _compassSub = FlutterCompass.events?.listen((event) {
      if (event.heading != null) {
        state = state.copyWith(
          heading: event.heading,
        );
      }
    });
  }

  @override
  void dispose() {
    _compassSub?.cancel();
    super.dispose();
  }
}

final qiblaProvider =
    StateNotifierProvider<QiblaNotifier, QiblaState>(
  (ref) {
    final locationService = LocationService();
    final getQiblaDirection = GetQiblaDirection();

    return QiblaNotifier(
      locationService,
      getQiblaDirection,
    );
  },
);