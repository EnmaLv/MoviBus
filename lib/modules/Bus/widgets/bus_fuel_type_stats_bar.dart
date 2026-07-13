import 'package:flutter/material.dart';
import '../model/bus_fuel_type_model.dart';

class FuelTypeStatsBar extends StatelessWidget {
  final List<BusTipoCombustible> combustibles;
  const FuelTypeStatsBar({super.key, required this.combustibles});

  @override
  Widget build(BuildContext context) {
    final activas = combustibles.where((c) => c.estado).length;
    final inactivas = combustibles.length - activas;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          _StatChip(label: 'Total', value: combustibles.length, color: const Color(0xFF1565C0), cardColor: cardColor),
          const SizedBox(width: 8),
          _StatChip(label: 'Activos', value: activas, color: const Color(0xFF2E7D32), cardColor: cardColor),
          const SizedBox(width: 8),
          _StatChip(label: 'Inactivos', value: inactivas, color: const Color(0xFF757575), cardColor: cardColor),
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
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)],
        ),
        child: Column(
          children: [
            Text('$value', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
            Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF888888))),
          ],
        ),
      ),
    );
  }
}