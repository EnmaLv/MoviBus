import 'package:flutter/material.dart';

class TopOverlay extends StatelessWidget {
  final Map<String, dynamic> usuario;
  final bool esAdmin;
  final int busesActivos;
  static const _red = Color(0xFFB71C1C);

  const TopOverlay({super.key, 
    required this.usuario,
    required this.esAdmin,
    required this.busesActivos,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: _red,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.directions_bus, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Hola, ${usuario['nombre'] ?? 'Usuario'}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.circle, size: 7, color: Color(0xFF4CAF50)),
                const SizedBox(width: 4),
                Text(
                  '$busesActivos activos',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
