import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../services/api_service.dart';
import '../auth/login.dart';
import '../../widgets/app_bar.dart'; // ajusta el path si es distinto

class MoviMap extends StatefulWidget {
  final Map<String, dynamic> usuario;
  final AppThemeProvider themeProvider;

  const MoviMap({
    super.key,
    required this.usuario,
    required this.themeProvider,
  });

  @override
  State<MoviMap> createState() => _MoviMapState();
}

class _MoviMapState extends State<MoviMap> {
  static const colorRed = Color(0xFFB71C1C);

  int _currentIndex = 0;
  GoogleMapController? _mapController;

  final CameraPosition _initialPosition = const CameraPosition(
    target: LatLng(9.546987, -69.192543),
    zoom: 16,
  );

  final Set<Marker> _markers = {
    const Marker(
      markerId: MarkerId('UPTP'),
      position: LatLng(9.546987, -69.192543),
      infoWindow: InfoWindow(title: 'UPTP JJ Montilla'),
    ),
  };

  // ── Ítems de navegación según el rol ─────────────────────────────────────
  List<NavItem> get _navItems {
    final roles = widget.usuario['roles'] as List? ?? [];
    final esAdmin = roles.any(
      (r) => (r['nombre'] ?? '').toString().toLowerCase() == 'administrador',
    );
    return esAdmin ? _adminItems : _defaultItems;
  }

  static const _defaultItems = [
    NavItem(label: 'Mapa', icon: Icons.map_outlined, activeIcon: Icons.map),
    NavItem(
      label: 'Agenda',
      icon: Icons.calendar_today_outlined,
      activeIcon: Icons.calendar_today,
    ),
    NavItem(
      label: 'Transporte',
      icon: Icons.directions_bus_outlined,
      activeIcon: Icons.directions_bus,
    ),
    NavItem(
      label: 'Salud',
      icon: Icons.local_hospital_outlined,
      activeIcon: Icons.local_hospital,
    ),
    NavItem(
      label: 'Comedor',
      icon: Icons.restaurant_outlined,
      activeIcon: Icons.restaurant,
    ),
  ];

  static const _adminItems = [
    NavItem(label: 'Mapa', icon: Icons.map_outlined, activeIcon: Icons.map),
    NavItem(
      label: 'Agenda',
      icon: Icons.calendar_today_outlined,
      activeIcon: Icons.calendar_today,
    ),
    NavItem(
      label: 'Vehículos',
      icon: Icons.directions_bus_outlined,
      activeIcon: Icons.directions_bus,
    ),
    NavItem(
      label: 'Rutas',
      icon: Icons.route_outlined,
      activeIcon: Icons.route,
    ),
    NavItem(
      label: 'Usuarios',
      icon: Icons.people_outline,
      activeIcon: Icons.people,
    ),
    NavItem(
      label: 'Salud',
      icon: Icons.local_hospital_outlined,
      activeIcon: Icons.local_hospital,
    ),
    NavItem(
      label: 'Comedor',
      icon: Icons.restaurant_outlined,
      activeIcon: Icons.restaurant,
    ),
    NavItem(
      label: 'Reportes',
      icon: Icons.bar_chart_outlined,
      activeIcon: Icons.bar_chart,
    ),
  ];

  // ── Marcadores ────────────────────────────────────────────────────────────
  void _deleteMarker(String markerId, {LatLng? latLong}) {
    if (latLong != null) {
      setState(() {
        _markers.removeWhere(
          (m) =>
              m.position.latitude == latLong.latitude &&
              m.position.longitude == latLong.longitude,
        );
      });
    } else {
      setState(() {
        _markers.removeWhere((m) => m.markerId.value == markerId);
      });
    }
  }

  Future<void> _addMarker(LatLng position) async {
    final titleController = TextEditingController();
    final String markerId = 'marker_${_markers.length}';

    final title = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Agregar Marcador'),
        content: TextField(
          controller: titleController,
          decoration: const InputDecoration(hintText: 'Título del marcador'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(titleController.text),
            child: const Text('Agregar'),
          ),
        ],
      ),
    );

    if (title != null && title.isNotEmpty) {
      setState(() {
        _markers.add(
          Marker(
            markerId: MarkerId(markerId),
            position: position,
            infoWindow: InfoWindow(title: title),
          ),
        );
      });
    }
  }

  // ── Páginas por índice — agrega aquí tus módulos ──────────────────────────
  Widget _buildPage(int index) {
    switch (index) {
      case 0:
        return _buildMap();
      // case 1: return const AgendaScreen();
      // case 2: return const TransporteScreen();
      default:
        return Center(
          child: Text(
            _navItems[index].label,
            style: const TextStyle(fontSize: 18),
          ),
        );
    }
  }

  Widget _buildMap() {
    return GoogleMap(
      initialCameraPosition: _initialPosition,
      onMapCreated: (controller) => _mapController = controller,
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      mapType: MapType.normal,
      markers: _markers,
      onTap: _addMarker,
      onLongPress: (latLong) => _deleteMarker('', latLong: latLong),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Sin AppBar superior — la barra está abajo
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Página actual (el mapa ocupa toda la pantalla)
          _buildPage(_currentIndex),

          // Overlay superior con saludo y nombre — solo visible en el mapa
          if (_currentIndex == 0)
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              left: 16,
              right: 16,
              child: _TopOverlay(usuario: widget.usuario),
            ),
        ],
      ),
      bottomNavigationBar: AppBottomNav(
        items: _navItems,
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        themeProvider: widget.themeProvider,
        userName: widget.usuario['nombre'] as String?,
        onLogout: () async {
          await ApiService.logout();
          if (context.mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => LoginScreen(
                themeProvider: AppThemeProvider(),
              )),
            );
          }
        },
      ),
    );
  }
}

// ─── Overlay superior sobre el mapa ──────────────────────────────────────────
// Reemplaza al AppBar cuando estás en el mapa
class _TopOverlay extends StatelessWidget {
  final Map<String, dynamic> usuario;
  static const _red = Color(0xFFB71C1C);

  const _TopOverlay({required this.usuario});

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
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.circle, size: 7, color: Color(0xFF4CAF50)),
                SizedBox(width: 4),
                Text(
                  'En línea',
                  style: TextStyle(
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
