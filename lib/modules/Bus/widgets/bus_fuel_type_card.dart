import 'package:flutter/material.dart';
import '../model/bus_fuel_type_model.dart';

class FuelTypeCard extends StatelessWidget {
  final BusTipoCombustible combustible;
  final bool isDark;
  final VoidCallback onEdit;
  final VoidCallback onToggle;

  static const _red = Color(0xFFB71C1C);

  const FuelTypeCard({super.key, required this.combustible, required this.isDark, required this.onEdit, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2))],
        border: combustible.estado ? null : Border.all(color: Colors.grey.withValues(alpha: 0.3)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: combustible.estado ? _red.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.local_gas_station_rounded, color: combustible.estado ? _red : Colors.grey, size: 22),
        ),
        title: Text(
          combustible.nombre,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            color: combustible.estado ? (isDark ? Colors.white : const Color(0xFF1A1A1A)) : Colors.grey,
            decoration: combustible.estado ? null : TextDecoration.lineThrough,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                combustible.descripcion,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.black54),
              ),
              const SizedBox(height: 2),
              Text(
                combustible.estado ? 'Activo' : 'Inactivo',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: combustible.estado ? const Color(0xFF2E7D32) : const Color(0xFF9E9E9E)),
              ),
            ],
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: onToggle,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 38,
                height: 22,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(11), color: combustible.estado ? _red : Colors.grey[300]),
                child: AnimatedAlign(
                  duration: const Duration(milliseconds: 200),
                  alignment: combustible.estado ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(margin: const EdgeInsets.all(2), width: 18, height: 18, decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20),
              onPressed: onEdit,
              color: const Color(0xFF555555),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }
}