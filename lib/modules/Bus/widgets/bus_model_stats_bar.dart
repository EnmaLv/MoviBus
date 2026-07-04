import 'package:flutter/material.dart';
import '../model/bus_model.dart';
import '../model/bus_brand_model.dart';

class StatsBar extends StatelessWidget {
  final List<BusModelo> modelos;
  final List<BusMarca> marcas;
  const StatsBar({super.key, required this.modelos, required this.marcas});

  @override
  Widget build(BuildContext context) {
    final activos = modelos.where((m) => m.estado).length;
    final inactivos = modelos.length - activos;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final card = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          _StatChip(
            label: 'Total',
            value: modelos.length,
            color: const Color(0xFF1565C0),
            cardColor: card,
          ),
          const SizedBox(width: 8),
          _StatChip(
            label: 'Activos',
            value: activos,
            color: const Color(0xFF2E7D32),
            cardColor: card,
          ),
          const SizedBox(width: 8),
          _StatChip(
            label: 'Inactivos',
            value: inactivos,
            color: const Color(0xFF757575),
            cardColor: card,
          ),
          const SizedBox(width: 8),
          _StatChip(
            label: 'Marcas',
            value: marcas.length,
            color: const Color(0xFF6A1B9A),
            cardColor: card,
          ),
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
  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
    required this.cardColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              '$value',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: Color(0xFF888888)),
            ),
          ],
        ),
      ),
    );
  }
}