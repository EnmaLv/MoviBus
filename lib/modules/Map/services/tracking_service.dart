import 'dart:async';
import 'package:geolocator/geolocator.dart';

class TrackingService {
  StreamSubscription<Position>? _positionStream;

  Future<bool> solicitarPermisos() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  void iniciarTracking(Function(Position) onUpdate) {
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5, // se actualiza cada 5 metros
      ),
    ).listen(onUpdate);
  }

  void detenerTracking() {
    _positionStream?.cancel();
  }
}