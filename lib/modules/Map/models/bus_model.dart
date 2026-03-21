import 'package:google_maps_flutter/google_maps_flutter.dart';

class BusEnMapa {
  final String id;
  final String placa;
  final String rutaNombre;
  final LatLng posicion;
  final bool enMovimiento;
  final int pasajeros;

  const BusEnMapa({
    required this.id,
    required this.placa,
    required this.rutaNombre,
    required this.posicion,
    required this.enMovimiento,
    required this.pasajeros,
  });
}