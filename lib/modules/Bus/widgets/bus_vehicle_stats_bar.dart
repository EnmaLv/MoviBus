import 'package:flutter/material.dart';
import '../model/bus_vehicle_model.dart';

class VehicleStatsBar extends StatelessWidget {
  final List<BusVehiculo> vehiculos;
  const VehicleStatsBar({super.key, required this.vehiculos});

  @override
  Widget build(BuildContext context) {
    final disponibles = vehiculos.where((v) => v.estado == 'disponible' && v.activo).length;
    final enRuta = vehiculos.where((v) => v.estado == 'en_ruta').length;
    final taller = vehiculos.where((v) => v.estado == 'mantenimiento').length;
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final card = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          _StatChip(label: 'Total', value: vehiculos.length, color: const Color(0xFF1565C0), cardColor: card),
          const SizedBox(width: 6),
          _StatChip(label: 'Dispo.', value: disponibles, color: const Color(0xFF2E7D32), cardColor: card),
          const SizedBox(width: 6),
          _StatChip(label: 'En Ruta', value: enRuta, color: const Color(0xFFEF6C00), cardColor: card),
          const SizedBox(width: 6),
          _StatChip(label: 'Taller', value: taller, color: const Color(0xFFC62828), cardColor: card),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final Color cardColor;
  const _StatChip({required this.label, required this.value, required this.color, required this.cardColor});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4)],
        ),
        child: Column(
          children: [
            Text('$value', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color)),
            Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF888888))),
          ],
        ),
      ),
    );
  }
}