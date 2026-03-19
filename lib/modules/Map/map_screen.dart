import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../services/api_service.dart';
import '../auth/login.dart';

class MoviMap extends StatefulWidget {
  final Map<String, dynamic> usuario;
  const MoviMap({super.key, required this.usuario});

  @override
  State<MoviMap> createState() => _MoviMapState();
}

class _MoviMapState extends State<MoviMap> {
  static const colorRed = Color(0xFFB71C1C);

  GoogleMapController? _mapController;

  final CameraPosition _initialPosition = CameraPosition(
    target: LatLng(9.546987, -69.192543), // Buenos Aires
    zoom: 12,
  );

    

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: colorRed,
        foregroundColor: Colors.white,
        title: Text('Hola, ${widget.usuario['nombre'] ?? 'Usuario'}'),
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
      body: GoogleMap(
        initialCameraPosition: _initialPosition,
        onMapCreated: (controller) => _mapController = controller,
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
      ),
        
    );
  }
}
