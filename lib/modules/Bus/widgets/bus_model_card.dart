import 'package:flutter/material.dart';
import '../model/bus_model.dart';

class ModeloCard extends StatelessWidget {
  final BusModelo modelo;
  final bool isDark;
  final VoidCallback onEdit;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  static const _red = Color(0xFFB71C1C);

  const ModeloCard({
    super.key,
    required this.modelo,
    required this.isDark,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final card = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: modelo.estado
            ? null
            : Border.all(color: Colors.grey.withValues(alpha: 0.3)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: modelo.estado
                ? _red.withValues(alpha: 0.1)
                : Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.car_repair_rounded,
            color: modelo.estado ? _red : Colors.grey,
            size: 22,
          ),
        ),
        title: Text(
          modelo.nombre,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            color: modelo.estado
                ? (isDark ? Colors.white : const Color(0xFF1A1A1A))
                : Colors.grey,
            decoration: modelo.estado ? null : TextDecoration.lineThrough,
          ),
        ),
        subtitle: Row(
          children: [
            const SizedBox(),
            Text(
              modelo.estado ? 'Activo' : 'Inactivo',
              style: TextStyle(
                fontSize: 11,
                color: modelo.estado
                    ? const Color(0xFF2E7D32)
                    : const Color(0xFF9E9E9E),
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Toggle
            GestureDetector(
              onTap: onToggle,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 38,
                height: 22,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(11),
                  color: modelo.estado ? _red : Colors.grey[300],
                ),
                child: AnimatedAlign(
                  duration: const Duration(milliseconds: 200),
                  alignment: modelo.estado
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
