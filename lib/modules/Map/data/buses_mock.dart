import '../models/bus_model.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

const busesSimulados = [
  BusEnMapa(
    id: 'bus_1', 
    placa: 'AB-123-CD',
    rutaNombre: 'Sede Principal → Anexo Norte',
    posicion: LatLng(9.548200, -69.190100),
    enMovimiento: true,
    pasajeros: 12,
  ),
  BusEnMapa(
    id: 'bus_2',
    placa: 'EF-456-GH',
    rutaNombre: 'Sede Principal → Anexo Sur',
    posicion: LatLng(9.545500, -69.194800),
    enMovimiento: false,
    pasajeros: 0,
  ),
  BusEnMapa(
    id: 'bus_3',
    placa: 'IJ-789-KL',
    rutaNombre: 'Sede Principal → Anexo Este',
    posicion: LatLng(9.549800, -69.188500),
    enMovimiento: true,
    pasajeros: 8,
  ),
];