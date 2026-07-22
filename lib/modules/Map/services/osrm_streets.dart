import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

/// Recibe una lista de puntos ordenada: [Ubicación Actual, Parada 1, Parada 2, ..., Parada N]
Future<List<LatLng>> obtenerRutaCalles(List<LatLng> puntos) async {
  if (puntos.length < 2) return puntos;

  // Construye la cadena de coordenadas separadas por ";" para OSRM: lon1,lat1;lon2,lat2;lon3,lat3...
  final coordsString = puntos
      .map((p) => '${p.longitude},${p.latitude}')
      .join(';');

  final url = Uri.parse(
    'https://router.project-osrm.org/route/v1/driving/$coordsString?overview=full&geometries=geojson',
  );

  try {
    final response = await http
        .get(url, headers: {'Accept': 'application/json'})
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) return _rutaFallbackMulti(puntos);

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final code = data['code'] as String?;
    if (code != 'Ok') return _rutaFallbackMulti(puntos);

    final routes = data['routes'] as List?;
    if (routes == null || routes.isEmpty) {
      return _rutaFallbackMulti(puntos);
    }

    final coords = routes[0]['geometry']['coordinates'] as List;
    return coords.map((c) {
      final punto = c as List;
      return LatLng(
        (punto[1] as num).toDouble(),
        (punto[0] as num).toDouble(),
      );
    }).toList();
  } catch (e) {
    debugPrint('OSRM error: $e');
    return _rutaFallbackMulti(puntos);
  }
}

/// Fallback por segmentos si falla la conexión a internet
List<LatLng> _rutaFallbackMulti(List<LatLng> puntos) {
  List<LatLng> resultado = [];
  for (int i = 0; i < puntos.length - 1; i++) {
    final seg = _rutaFallback(puntos[i], puntos[i + 1]);
    if (i > 0 && seg.isNotEmpty) {
      resultado.addAll(seg.sublist(1));
    } else {
      resultado.addAll(seg);
    }
  }
  return resultado;
}

List<LatLng> _rutaFallback(LatLng origen, LatLng destino) {
  const pasos = 20;
  return List.generate(pasos + 1, (i) {
    final t = i / pasos;
    return LatLng(
      origen.latitude + (destino.latitude - origen.latitude) * t,
      origen.longitude + (destino.longitude - origen.longitude) * t,
    );
  });
}