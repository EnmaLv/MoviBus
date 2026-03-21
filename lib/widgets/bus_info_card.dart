import 'package:flutter/material.dart';
import '../modules/Map/models/bus_model.dart';

class BusInfoCard extends StatelessWidget {
  final BusEnMapa bus;
  final VoidCallback onClose;
  static const _red = Color(0xFFB71C1C);

  const BusInfoCard({super.key, required this.bus, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          // Ícono bus
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: bus.enMovimiento
                  ? _red.withValues(alpha: 0.1)
                  : Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.directions_bus_rounded,
              color: bus.enMovimiento ? _red : Colors.grey,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      bus.placa,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: bus.enMovimiento
                            ? const Color(0xFF4CAF50).withValues(alpha: 0.15)
                            : Colors.grey.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        bus.enMovimiento ? 'En ruta' : 'Estacionado',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: bus.enMovimiento
                              ? const Color(0xFF2E7D32)
                              : Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  bus.rutaNombre,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? const Color(0xFF888888)
                        : const Color(0xFF666666),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (bus.enMovimiento) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.people_outline,
                        size: 13,
                        color: Color(0xFF888888),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${bus.pasajeros} pasajeros',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF888888),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close, size: 18),
            color: const Color(0xFF888888),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}