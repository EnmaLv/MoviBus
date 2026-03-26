import 'package:flutter/material.dart';
class IniciarRutaPanel extends StatelessWidget {
  final VoidCallback onDemo;
  final VoidCallback onReal;
  const IniciarRutaPanel({super.key, required this.onDemo, required this.onReal});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _RutaBtn(
          label: 'INICIAR RUTA',
          icon: Icons.navigation_rounded,
          color: const Color(0xFFB71C1C),
          onTap: onReal,
        ),
        const SizedBox(height: 8),
        _RutaBtn(
          label: 'MODO DEMO',
          icon: Icons.play_circle_outline_rounded,
          color: const Color(0xFF424242),
          onTap: onDemo,
        ),
      ],
    );
  }
}


class _RutaBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _RutaBtn({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CancelarRutaButton extends StatefulWidget {
  final VoidCallback onTap;
  const CancelarRutaButton({super.key, required this.onTap});

  @override
  State<CancelarRutaButton> createState() => _CancelarRutaButtonState();
}

class _CancelarRutaButtonState extends State<CancelarRutaButton> {
  Future<void> _confirmar() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('¿Cancelar ruta?'),
        content: const Text(
          'Úsalo solo en caso de emergencia o accidente.\n'
          'La ruta quedará marcada como cancelada.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Continuar ruta'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Cancelar ruta'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (confirm == true) widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _confirmar,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: const Color(0xFFB71C1C),
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cancel_outlined, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Text(
              'CANCELAR RUTA',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
