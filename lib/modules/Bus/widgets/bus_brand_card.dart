import 'package:flutter/material.dart';
import '../model/bus_brand_model.dart';

class MarcaCard extends StatelessWidget {
  final BusMarca marca;
  final bool isDark;
  final VoidCallback onEdit;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  static const _red = Color(0xFFB71C1C);

  const MarcaCard({super.key, 
    required this.marca,
    required this.isDark,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: marca.estado
            ? null
            : Border.all(color: Colors.grey.withValues(alpha: 0.3)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: marca.estado
                ? _red.withValues(alpha: 0.1)
                : Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.directions_car_rounded,
            color: marca.estado ? _red : Colors.grey,
            size: 22,
          ),
        ),
        title: Text(
          marca.nombre,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            color: marca.estado
                ? (isDark ? Colors.white : const Color(0xFF1A1A1A))
                : Colors.grey,
            decoration: marca.estado ? null : TextDecoration.lineThrough,
          ),
        ),
        subtitle: Text(
          marca.estado ? 'Activa' : 'Inactiva',
          style: TextStyle(
            fontSize: 12,
            color: marca.estado
                ? const Color(0xFF2E7D32)
                : const Color(0xFF9E9E9E),
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Toggle activo/inactivo
            GestureDetector(
              onTap: onToggle,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 38,
                height: 22,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(11),
                  color: marca.estado ? _red : Colors.grey[300],
                ),
                child: AnimatedAlign(
                  duration: const Duration(milliseconds: 200),
                  alignment: marca.estado
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.all(2),
                    width: 18,
                    height: 18,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Editar
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20),
              onPressed: onEdit,
              color: const Color(0xFF555555),
              tooltip: 'Editar',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }
}