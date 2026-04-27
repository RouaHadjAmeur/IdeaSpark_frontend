import 'dart:async';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';

class StabilityService {
  StreamSubscription<AccelerometerEvent>? _subscription;
  double _shakeMagnitude = 0.0;

  double get shakeMagnitude => _shakeMagnitude;
  bool get isStable => _shakeMagnitude < 1.5;

  void initialize() {
    _subscription = accelerometerEventStream().listen((AccelerometerEvent event) {
      // Calcul de la magnitude du mouvement : sqrt(x² + y² + z²) - 9.8 (gravité)
      double magnitude = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
      _shakeMagnitude = (magnitude - 9.8).abs();
    });
  }

  void dispose() {
    _subscription?.cancel();
  }
}
