import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

import '../../services/api_service.dart';
import '../auth/login.dart';
import '../../widgets/app_bar.dart';
import 'models/bus_model.dart';
import 'data/buses_mock.dart';
import '../../widgets/bus_info_card.dart';
import '../../widgets/top_overlay.dart';
import '../Bus/bus_catalogo_screen.dart';
import 'services/tracking_service.dart';

// Puntos de la demo — OSRM calculará la ruta real entre ellos por calles
const _demoOrigen = LatLng(9.546987, -69.192543); // UPTP
const _demoDestino = LatLng(9.554500, -69.183500); // Destino demo

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
  static const _red = Color(0xFFB71C1C);

  int _currentIndex = 0;
  GoogleMapController? mapController;
  BitmapDescriptor? _busMovingIcon;
  BitmapDescriptor? _busStoppedIcon;
  BusEnMapa? _busSeleccionado;

  late AnimationController _pulseCtrl;
  late Animation<double> pulseAnim;

  final TrackingService _trackingService = TrackingService();

  bool _trackingActivo = false;
  bool _esModoDemo = false;
  bool _cargandoRuta = false;
  LatLng? _miUbicacion;
  Timer? _demoTimer;
  int _demoPuntoActual = 0;
  List<LatLng> _rutaCalles = [];

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
    pulseAnim = Tween<double>(
      begin: 0.6,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _crearIconos();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _demoTimer?.cancel();
    _trackingService.detenerTracking();
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
      text: TextSpan(
        text: moving ? '🚎' : '🚌',
        style: const TextStyle(fontSize: 32),
      ),
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

  // ── OSRM — ruta por calles reales, sin API key, sin billing ──────────────
  // Usa OpenStreetMap. Servidor público: router.project-osrm.org
  Future<List<LatLng>> _obtenerRutaCalles(LatLng origen, LatLng destino) async {
    // OSRM usa formato: lng,lat (al revés que Google)
    final url = Uri.parse(
      'https://router.project-osrm.org/route/v1/driving/'
      '${origen.longitude},${origen.latitude};'
      '${destino.longitude},${destino.latitude}'
      '?overview=full&geometries=geojson',
    );

    try {
      final response = await http
          .get(url, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) return _rutaFallback();

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final code = data['code'] as String?;
      if (code != 'Ok') return _rutaFallback();

      final routes = data['routes'] as List?;
      if (routes == null || routes.isEmpty) return _rutaFallback();

      // GeoJSON devuelve coordenadas como [lng, lat]
      final coords = routes[0]['geometry']['coordinates'] as List;
      return coords.map((c) {
        final punto = c as List;
        return LatLng(
          (punto[1] as num).toDouble(),
          (punto[0] as num).toDouble(),
        );
      }).toList();
    } catch (e) {
      debugPrint('OSRM error: $e');
      return _rutaFallback();
    }
  }

  // Fallback: interpola puntos en línea recta si OSRM no responde
  List<LatLng> _rutaFallback() {
    const pasos = 20;
    return List.generate(pasos + 1, (i) {
      final t = i / pasos;
      return LatLng(
        _demoOrigen.latitude +
            (_demoDestino.latitude - _demoOrigen.latitude) * t,
        _demoOrigen.longitude +
            (_demoDestino.longitude - _demoOrigen.longitude) * t,
      );
    });
  }

  // ── Marcadores ────────────────────────────────────────────────────────────
  Set<Marker> get _allMarkers {
    final markers = <Marker>{};

    for (final bus in busesSimulados) {
      markers.add(
        Marker(
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
        ),
      );
    }

    if (_miUbicacion != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('mi_bus'),
          position: _miUbicacion!,
          icon:
              _busMovingIcon ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: const InfoWindow(title: 'Mi Bus'),
          zIndex: 2,
        ),
      );
    }

    if (_trackingActivo && _rutaCalles.isNotEmpty) {
      markers.add(
        Marker(
          markerId: const MarkerId('ruta_inicio'),
          position: _rutaCalles.first,
          infoWindow: const InfoWindow(title: 'Salida'),
        ),
      );
      // Destino: UPTP fijo en modo real, último punto en demo
      markers.add(
        Marker(
          markerId: const MarkerId('ruta_fin'),
          position: _esModoDemo ? _rutaCalles.last : _destinoReal,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
          infoWindow: const InfoWindow(title: 'Destino · UPTP'),
        ),
      );
    }

    return markers;
  }

  // ── Polilíneas ────────────────────────────────────────────────────────────
  Set<Polyline> get _polylines {
    if (!_trackingActivo || _rutaCalles.isEmpty) return {};
    final total = _rutaCalles.length;
    return {
      Polyline(
        polylineId: const PolylineId('ruta_completa'),
        points: _rutaCalles,
        color: _red.withValues(alpha: 0.35),
        width: 6,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        jointType: JointType.round,
      ),
      if (_demoPuntoActual > 0)
        Polyline(
          polylineId: const PolylineId('ruta_recorrida'),
          points: _rutaCalles.sublist(0, _demoPuntoActual.clamp(1, total)),
          color: _red,
          width: 6,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
          jointType: JointType.round,
        ),
    };
  }

  // ── Demo ──────────────────────────────────────────────────────────────────
  Future<void> _iniciarDemo() async {
    setState(() => _cargandoRuta = true);

    final puntos = await _obtenerRutaCalles(_demoOrigen, _demoDestino);

    if (!mounted) return;

    setState(() {
      _rutaCalles = puntos;
      _esModoDemo = true;
      _trackingActivo = true;
      _demoPuntoActual = 0;
      _miUbicacion = puntos.first;
      _cargandoRuta = false;
    });

    mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: puntos.first, zoom: 16),
      ),
    );

    _demoTimer = Timer.periodic(const Duration(milliseconds: 300), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_demoPuntoActual >= _rutaCalles.length - 1) {
        timer.cancel();
        _llegarAlDestino();
        return;
      }

      setState(() {
        _demoPuntoActual++;
        _miUbicacion = _rutaCalles[_demoPuntoActual];
      });

      mapController?.animateCamera(
        CameraUpdate.newLatLng(_rutaCalles[_demoPuntoActual]),
      );
    });
  }

  void _llegarAlDestino() {
    if (!mounted) return;
    setState(() {
      _trackingActivo = false;
      _esModoDemo = false;
      _miUbicacion = null;
      _rutaCalles = [];
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 10),
            Text('¡Ruta completada exitosamente!'),
          ],
        ),
        backgroundColor: const Color(0xFF2E7D32),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _cancelarRuta() {
    _demoTimer?.cancel();
    _trackingService.detenerTracking();
    setState(() {
      _trackingActivo = false;
      _esModoDemo = false;
      _miUbicacion = null;
      _demoPuntoActual = 0;
      _rutaCalles = [];
    });
  }

  // Destino fijo — punto de salida y llegada de los estudiantes
  static const _destinoReal = LatLng(9.546987, -69.192543);
  static const _radioLlegada = 50.0; // metros

  Future<void> _iniciarRutaReal() async {
    final ok = await _trackingService.solicitarPermisos();
    if (!mounted) return;

    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permisos de ubicación requeridos')),
      );
      return;
    }

    setState(() {
      _cargandoRuta = true;
      _esModoDemo = false;
    });

    // Obtener posición actual como origen
    Position? posActual;
    try {
      posActual = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      ).timeout(const Duration(seconds: 10));
    } catch (_) {}

    if (!mounted) return;

    final origen = posActual != null
        ? LatLng(posActual.latitude, posActual.longitude)
        : _destinoReal;

    final puntos = await _obtenerRutaCalles(origen, _destinoReal);
    if (!mounted) return;

    setState(() {
      _rutaCalles = puntos;
      _trackingActivo = true;
      _miUbicacion = origen;
      _demoPuntoActual = 0;
      _cargandoRuta = false;
    });

    // Mostrar toda la ruta en la cámara
    if (puntos.length > 1) {
      final bounds = _calcularBounds(puntos);
      mapController?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 60));
    }

    _trackingService.iniciarTracking((pos) {
      if (!mounted) return;
      final nuevaPos = LatLng(pos.latitude, pos.longitude);
      setState(() {
        _miUbicacion = nuevaPos;
        _demoPuntoActual = _puntoMasCercano(nuevaPos);
      });
      mapController?.animateCamera(CameraUpdate.newLatLng(nuevaPos));

      // Detectar llegada
      final distancia = Geolocator.distanceBetween(
        nuevaPos.latitude,
        nuevaPos.longitude,
        _destinoReal.latitude,
        _destinoReal.longitude,
      );
      if (distancia <= _radioLlegada) {
        _trackingService.detenerTracking();
        _llegarAlDestino();
      }
    });
  }

  // Punto de la ruta más cercano a la posición actual (solo avanza, no retrocede)
  int _puntoMasCercano(LatLng pos) {
    if (_rutaCalles.isEmpty) return 0;
    int mejor = _demoPuntoActual;
    double menorDist = double.infinity;
    for (int i = _demoPuntoActual; i < _rutaCalles.length; i++) {
      final d = Geolocator.distanceBetween(
        pos.latitude,
        pos.longitude,
        _rutaCalles[i].latitude,
        _rutaCalles[i].longitude,
      );
      if (d < menorDist) {
        menorDist = d;
        mejor = i;
      }
    }
    return mejor;
  }

  // Bounding box de la ruta para centrar la cámara
  LatLngBounds _calcularBounds(List<LatLng> puntos) {
    double minLat = puntos.first.latitude, maxLat = puntos.first.latitude;
    double minLng = puntos.first.longitude, maxLng = puntos.first.longitude;
    for (final p in puntos) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }
    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  void _mostrarInfoBus(BusEnMapa bus) {
    setState(() => _busSeleccionado = bus);
    HapticFeedback.lightImpact();
  }

  void _cerrarInfoBus() => setState(() => _busSeleccionado = null);

  bool get _esAdmin => widget.roles.any((r) {
    final nombre = (r['nombre'] ?? '').toString().toLowerCase();
    final slug = (r['slug'] ?? '').toString().toLowerCase();
    return nombre == 'administrador' || slug == 'administrador';
  });

  String? get _rolNombre =>
      widget.roles.isEmpty ? null : widget.roles.first['nombre'] as String?;

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
      label: 'Catalogo',
      icon: Icons.directions_bus_outlined,
      activeIcon: Icons.directions_bus,
    ),
    NavItem(
      label: 'Rutas',
      icon: Icons.route_outlined,
      activeIcon: Icons.route,
    ),
    NavItem(
      label: 'Agenda',
      icon: Icons.calendar_today_outlined,
      activeIcon: Icons.calendar_today,
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

  void _onNavTap(int index) {
    if (index == 0) {
      setState(() {
        _currentIndex = 0;
        _busSeleccionado = null;
      });
      return;
    }
    if (_esAdmin) {
      _abrirModuloAdmin(index);
      return;
    }
    setState(() => _currentIndex = index);
  }

  void _abrirModuloAdmin(int index) {
    Widget? destino;
    switch (index) {
      case 1:
        destino = BusCatalogoScreen(themeProvider: widget.themeProvider);
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_adminItems[index].label}: próximamente'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: _red,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        return;
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => destino!));
  }

  Widget _buildPage(int index) {
    if (index == 0) return _buildMapPage();
    return Center(
      child: Text(_navItems[index].label, style: const TextStyle(fontSize: 18)),
    );
  }

  Widget _buildMapPage() {
    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: _initialPosition,
          onMapCreated: (c) => mapController = c,
          mapType: MapType.normal,
          markers: _allMarkers,
          polylines: _polylines,
          onTap: (_) => _cerrarInfoBus(),
          padding: const EdgeInsets.only(bottom: 80),
        ),

        if (_cargandoRuta)
          Container(
            color: Colors.black.withValues(alpha: 0.3),
            child: const Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 12),
                      Text('Calculando ruta por calles...'),
                    ],
                  ),
                ),
              ),
            ),
          ),

        if (_busSeleccionado != null)
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: BusInfoCard(bus: _busSeleccionado!, onClose: _cerrarInfoBus),
          ),

        if (_busSeleccionado == null && !_cargandoRuta)
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: _trackingActivo
                ? _CancelarRutaButton(onTap: _cancelarRuta)
                : _IniciarRutaPanel(
                    onDemo: _iniciarDemo,
                    onReal: _iniciarRutaReal,
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
          if (_currentIndex == 0)
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              left: 16,
              right: 16,
              child: TopOverlay(
                usuario: widget.usuario,
                esAdmin: _esAdmin,
                busesActivos: busesSimulados
                    .where((b) => b.enMovimiento)
                    .length,
              ),
            ),
        ],
      ),
      bottomNavigationBar: AppBottomNav(
        items: _navItems,
        currentIndex: _currentIndex,
        onTap: _onNavTap,
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

// ─── Panel botones ────────────────────────────────────────────────────────────
class _IniciarRutaPanel extends StatelessWidget {
  final VoidCallback onDemo;
  final VoidCallback onReal;
  const _IniciarRutaPanel({required this.onDemo, required this.onReal});

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

// ─── Cancelar ruta ────────────────────────────────────────────────────────────
class _CancelarRutaButton extends StatefulWidget {
  final VoidCallback onTap;
  const _CancelarRutaButton({required this.onTap});

  @override
  State<_CancelarRutaButton> createState() => _CancelarRutaButtonState();
}

class _CancelarRutaButtonState extends State<_CancelarRutaButton> {
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

class _PulseDot extends StatefulWidget {
  const _PulseDot();
  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.3, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
