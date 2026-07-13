import 'package:flutter/material.dart';
import '../model/bus_vehicle_model.dart';

class VehicleCard extends StatelessWidget {
  final BusVehiculo vehiculo;
  final bool isDark;
  final VoidCallback onEdit;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  static const _red = Color(0xFFB71C1C);

  const VehicleCard({
    super.key,
    required this.vehiculo,
    required this.isDark,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
  });

  Color _obtenerColorEstado() {
    switch (vehiculo.estado) {
      case 'disponible': return const Color(0xFF2E7D32);
      case 'en_ruta': return const Color(0xFFEF6C00);
      case 'mantenimiento': return const Color(0xFFC62828);
      default: return Colors.grey;
    }
  }

  String _obtenerTextoEstado() {
    switch (vehiculo.estado) {
      case 'disponible': return 'Disponible';
      case 'en_ruta': return 'En Ruta';
      case 'mantenimiento': return 'Mantenimiento';
      default: return 'Inactivo';
    }
  }

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final estadoColor = _obtenerColorEstado();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2))],
        border: vehiculo.activo ? null : Border.all(color: Colors.grey.withValues(alpha: 0.3)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: vehiculo.activo ? _red.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.directions_bus_rounded, color: vehiculo.activo ? _red : Colors.grey, size: 22),
        ),
        title: Row(
          children: [
            Text(
              vehiculo.placa,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                letterSpacing: 0.5,
                color: vehiculo.activo ? (isDark ? Colors.white : const Color(0xFF1A1A1A)) : Colors.grey,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: estadoColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
              child: Text(_obtenerTextoEstado(), style: TextStyle(color: estadoColor, fontSize: 10, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            '${vehiculo.marcaNombre} ${vehiculo.modeloNombre} (${vehiculo.anio}) • ${vehiculo.color}\nCapacidad: ${vehiculo.cantidadPasajeros} pas. • ${vehiculo.kmActual.toStringAsFixed(0)} KM',
            style: TextStyle(fontSize: 12, height: 1.4, color: isDark ? Colors.white54 : Colors.black54),
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: onToggle,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 36,
                height: 20,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: vehiculo.activo ? _red : Colors.grey[300]),
                child: AnimatedAlign(
                  duration: const Duration(milliseconds: 200),
                  alignment: vehiculo.activo ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(margin: const EdgeInsets.all(2), width: 16, height: 16, decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white)),
                ),
              ),
            ),
            const SizedBox(width: 6),
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 18),
              onPressed: onEdit,
              color: const Color(0xFF555555),
              constraints: const BoxConstraints(),
              padding: EdgeInsets.zero,
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, size: 18),
              onPressed: onDelete,
              color: _red,
              constraints: const BoxConstraints(),
              padding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }
}