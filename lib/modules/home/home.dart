import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../auth/login.dart';

class HomeScreen extends StatelessWidget {
  final Map<String, dynamic> usuario;
  final List<dynamic> modulos;

  const HomeScreen({super.key, required this.usuario, required this.modulos});

  static const colorRed = Color(0xFFB71C1C);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: colorRed,
        foregroundColor: Colors.white,
        title: Text('Hola, ${usuario['nombre'] ?? 'Usuario'}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ApiService.logout();
              if (context.mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Módulos disponibles',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: modulos.isEmpty
                  ? const Center(child: Text('No tienes módulos asignados.'))
                  : GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 1.3,
                          ),
                      itemCount: modulos.length,
                      itemBuilder: (_, i) {
                        final mod = modulos[i] as Map<String, dynamic>;
                        return _ModuloCard(modulo: mod);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModuloCard extends StatelessWidget {
  final Map<String, dynamic> modulo;
  const _ModuloCard({required this.modulo});

  static const colorRed = Color(0xFFB71C1C);

  IconData _iconForKey(String key) {
    switch (key) {
      case 'salud':
        return Icons.local_hospital;
      case 'comedor':
        return Icons.restaurant;
      case 'administracion':
        return Icons.settings;
      default:
        return Icons.apps;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Módulo: ${modulo['nombre']}')),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(_iconForKey(modulo['key'] ?? ''), size: 36, color: colorRed),
              const SizedBox(height: 10),
              Text(
                modulo['nombre'] ?? '',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}