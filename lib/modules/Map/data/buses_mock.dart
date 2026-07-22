import 'package:latlong2/latlong.dart';
import '../models/bus_model.dart';

const busesSimulados = [
  BusEnMapa(
    id: 'bus_1', 
    placa: 'AB-123-CD',
    rutaNombre: 'Sede Principal → Anexo Norte',
    posicion: LatLng(9.548200, -69.190100),
    enMovimiento: true,
    pasajeros: 12,
    sede: 'Acarigua',
  ),
  BusEnMapa(
    id: 'bus_2',
    placa: 'EF-456-GH',
    rutaNombre: 'Sede Principal → Anexo Sur',
    posicion: LatLng(9.545500, -69.194800),
    enMovimiento: false,
    pasajeros: 0,
    sede: 'Acarigua',
  ),
  BusEnMapa(
    id: 'bus_3',
    placa: 'IJ-789-KL',
    rutaNombre: 'Guanare Centro → Sede Guanare',
    posicion: LatLng(9.043100, -69.748800),
    enMovimiento: true,
    pasajeros: 8,
    sede: 'Guanare',
  ),
];