import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../services/api_service.dart';
import '../auth/login.dart';
import '../../widgets/app_bar.dart';

class BusEnMapa {
  final String id;
  final String placa;
  final String rutaNombre;
  final LatLng posicion;
  final bool enMovimiento;
  final int pasajeros;

  const BusEnMapa({
    required this.id,
    required this.placa,
    required this.rutaNombre,
    required this.posicion,
    required this.enMovimiento,
    required this.pasajeros,
  });
}

const _busesSimulados = [
  BusEnMapa(
    id: 'bus_1',
    placa: 'AB-123-CD',
    rutaNombre: 'Sede Principal → Anexo Norte',
    posicion: LatLng(9.548200, -69.190100),
    enMovimiento: true,
    pasajeros: 12,
  ),
  BusEnMapa(
    id: 'bus_2',
    placa: 'EF-456-GH',
    rutaNombre: 'Sede Principal → Anexo Sur',
    posicion: LatLng(9.545500, -69.194800),
    enMovimiento: false,
    pasajeros: 0,
  ),
  BusEnMapa(
    id: 'bus_3',
    placa: 'IJ-789-KL',
    rutaNombre: 'Sede Principal → Anexo Este',
    posicion: LatLng(9.549800, -69.188500),
    enMovimiento: true,
    pasajeros: 8,
  ),
];

class MoviMap extends StatefulWidget {
  final Map<String, dynamic> usuario;
  final List<dynamic> roles;
  final AppThemeProvider themeProvider;

  const MoviMap({
    super.key,
    required this.usuario,
    required this.roles,
    required this.themeProvider,
  });

  @override
  State<MoviMap> createState() => _MoviMapState();
}

class _MoviMapState extends State<MoviMap> with TickerProviderStateMixin {
  int _currentIndex = 0;
  GoogleMapController? _mapController;
  BitmapDescriptor? _busMovingIcon;
  BitmapDescriptor? _busStoppedIcon;
  BusEnMapa? _busSeleccionado;

  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  final CameraPosition _initialPosition = const CameraPosition(
    target: LatLng(9.546987, -69.192543),
    zoom: 15,
  );

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(
      begin: 0.6,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _crearIconos();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _crearIconos() async {
    _busMovingIcon = await _buildBusIcon(moving: true);
    _busStoppedIcon = await _buildBusIcon(moving: false);
    if (mounted) setState(() {});
  }

  Future<BitmapDescriptor> _buildBusIcon({required bool moving}) async {
    const size = 60.0;
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);

    final tp = TextPainter(
      text: TextSpan(text: '🚎', style: const TextStyle(fontSize: 18)),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, Offset(30 - tp.width / 2, 30 - tp.height / 2));

    final img = await recorder.endRecording().toImage(
      size.toInt(),
      size.toInt(),
    );
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(data!.buffer.asUint8List());
  }

  Set<Marker> get _busMarkers {
    return _busesSimulados.map((bus) {
      return Marker(
        markerId: MarkerId(bus.id),
        position: bus.posicion,
        icon: bus.enMovimiento
            ? (_busMovingIcon ??
                  BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueRed,
                  ))
            : (_busStoppedIcon ??
                  BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueAzure,
                  )),
        onTap: () => _mostrarInfoBus(bus),
      );
    }).toSet();
  }

  void _mostrarInfoBus(BusEnMapa bus) {
    setState(() => _busSeleccionado = bus);
    HapticFeedback.lightImpact();
  }

  void _cerrarInfoBus() => setState(() => _busSeleccionado = null);

  bool get _esAdmin {
    return widget.roles.any((r) {
      final nombre = (r['nombre'] ?? '').toString().toLowerCase();
      final slug = (r['slug'] ?? '').toString().toLowerCase();
      return nombre == 'administrador' || slug == 'administrador';
    });
  }

  // Todos ven el botón de momento (luego filtra por rol conductor)
  bool get _verBotonIniciarRuta => true;

  String? get _rolNombre {
    if (widget.roles.isEmpty) return null;
    return widget.roles.first['nombre'] as String?;
  }

  List<NavItem> get _navItems => _esAdmin ? _adminItems : _conductorItems;

  static const _conductorItems = [
    NavItem(label: 'Mapa', icon: Icons.map_outlined, activeIcon: Icons.map),
    NavItem(
      label: 'Agenda',
      icon: Icons.calendar_today_outlined,
      activeIcon: Icons.calendar_today,
    ),
    NavItem(
      label: 'Mi Viaje',
      icon: Icons.directions_bus_outlined,
      activeIcon: Icons.directions_bus,
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
      label: 'Conductores',
      icon: Icons.people_outline,
      activeIcon: Icons.people,
    ),
    NavItem(
      label: 'Combustible',
      icon: Icons.local_gas_station_outlined,
      activeIcon: Icons.local_gas_station,
    ),
    NavItem(
      label: 'Mant.',
      icon: Icons.build_outlined,
      activeIcon: Icons.build,
    ),
    NavItem(
      label: 'Reportes',
      icon: Icons.bar_chart_outlined,
      activeIcon: Icons.bar_chart,
    ),
  ];

  Widget _buildPage(int index) {
    if (index == 0) return _buildMapPage();
    return Center(
      child: Text(_navItems[index].label, style: const TextStyle(fontSize: 18)),
    );
  }

  Widget _buildMapPage() {
    return Stack(
      children: [
        // Mapa
        GoogleMap(
          initialCameraPosition: _initialPosition,
          onMapCreated: (c) => _mapController = c,
          mapType: MapType.normal,
          markers: _busMarkers,
          onTap: (_) => _cerrarInfoBus(),
          padding: EdgeInsets.only(bottom: _verBotonIniciarRuta ? 80 : 16),
        ),

        /* Positioned(
          right: 16,
          bottom: _verBotonIniciarRuta ? 100 : 32,
          child: _MapIconButton(
            icon: Icons.my_location,
            onTap: () {
              _mapController?.animateCamera(
                CameraUpdate.newCameraPosition(_initialPosition),
              );
            },
          ),
        ), */

        // Card info del bus seleccionado
        if (_busSeleccionado != null)
          Positioned(
            left: 16,
            right: 16,
            bottom: _verBotonIniciarRuta ? 16 : 16,
            child: _BusInfoCard(
              bus: _busSeleccionado!,
              onClose: _cerrarInfoBus,
            ),
          ),

        // Botón INICIAR RUTA — solo visible en el mapa
        if (_verBotonIniciarRuta && _busSeleccionado == null)
          Positioned(
            left: 24,
            right: 24,
            bottom: 16,
            child: _IniciarRutaButton(
              onTap: () {
                HapticFeedback.mediumImpact();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Próximamente: navegación en tiempo real'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          _buildPage(_currentIndex),

          // Overlay superior (solo en mapa)
          if (_currentIndex == 0)
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              left: 16,
              right: 16, // deja espacio para la leyenda
              child: _TopOverlay(
                usuario: widget.usuario,
                esAdmin: _esAdmin,
                busesActivos: _busesSimulados
                    .where((b) => b.enMovimiento)
                    .length,
              ),
            ),
        ],
      ),
      bottomNavigationBar: AppBottomNav(
        items: _navItems,
        currentIndex: _currentIndex,
        onTap: (i) {
          setState(() {
            _currentIndex = i;
            _busSeleccionado = null;
          });
        },
        themeProvider: widget.themeProvider,
        userName: widget.usuario['nombre'] as String?,
        userRole: _rolNombre,
        onLogout: () async {
          await ApiService.logout();
          if (context.mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    LoginScreen(themeProvider: widget.themeProvider),
              ),
            );
          }
        },
      ),
    );
  }
}

class _IniciarRutaButton extends StatefulWidget {
  final VoidCallback onTap;
  const _IniciarRutaButton({required this.onTap});

  @override
  State<_IniciarRutaButton> createState() => _IniciarRutaButtonState();
}

class _IniciarRutaButtonState extends State<_IniciarRutaButton>
    with SingleTickerProviderStateMixin {
  static const _red = Color(0xFFB71C1C);
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scale = Tween<double>(
      begin: 1,
      end: 0.96,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_red, Color(0xFFD32F2F)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                color: _red.withValues(alpha: 0.45),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.navigation_rounded, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Text(
                'INICIAR RUTA',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BusInfoCard extends StatelessWidget {
  final BusEnMapa bus;
  final VoidCallback onClose;
  static const _red = Color(0xFFB71C1C);

  const _BusInfoCard({required this.bus, required this.onClose});

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

class _MapIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _MapIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Icon(icon, size: 20, color: const Color(0xFF444444)),
      ),
    );
  }
}

class _TopOverlay extends StatelessWidget {
  final Map<String, dynamic> usuario;
  final bool esAdmin;
  final int busesActivos;
  static const _red = Color(0xFFB71C1C);

  const _TopOverlay({
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
