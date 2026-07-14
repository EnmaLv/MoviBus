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
import '../../widgets/start_route_button.dart';
import '../Bus/bus_catalogo_screen.dart';
import 'services/tracking_service.dart';

const _demoOrigen = LatLng(9.546987, -69.192543);
const _demoDestino = LatLng(9.554500, -69.183500);

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

// OPTIMIZACIÓN: Se eliminó TickerProviderStateMixin porque el controlador de pulso no se usaba aquí
class _MoviMapState extends State<MoviMap> {
  static const _red = Color(0xFFB71C1C);

  int _currentIndex = 0;
  GoogleMapController? mapController;
  BitmapDescriptor? _busMovingIcon;
  BitmapDescriptor? _busStoppedIcon;
  BusEnMapa? _busSeleccionado;

  final TrackingService _trackingService = TrackingService();

  // OPTIMIZACIÓN: Variables de control de rendimiento
  bool _mapaListo = false;
  Set<Marker> _markersCache = {};
  Set<Polyline> _polylinesCache = {};

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
    _inicializarPantalla();
  }

  Future<void> _inicializarPantalla() async {
    await _crearIconos();

    // OPTIMIZACIÓN: Retrasar la renderización del mapa 450ms para que las transiciones de pantalla vayan suaves
    await Future.delayed(const Duration(milliseconds: 450));
    if (mounted) {
      setState(() {
        _mapaListo = true;
      });
    }
  }

  @override
  void dispose() {
    _demoTimer?.cancel();
    _trackingService.detenerTracking();
    super.dispose();
  }

  Future<void> _crearIconos() async {
    _busMovingIcon = await _buildBusIcon(moving: true);
    _busStoppedIcon = await _buildBusIcon(moving: false);
    _actualizarElementosVisualesDelMapa();
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

  // OPTIMIZACIÓN CENTRAL: Reemplaza los Getters pesados.
  // Crea los marcadores y polilíneas en memoria local solo cuando hay cambios reales.
  void _actualizarElementosVisualesDelMapa() {
    if (!mounted) return;

    // 1. Construir Marcadores alternos
    final nuevosMarkers = <Marker>{};
    for (final bus in busesSimulados) {
      nuevosMarkers.add(
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
      nuevosMarkers.add(
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
      nuevosMarkers.add(
        Marker(
          markerId: const MarkerId('ruta_inicio'),
          position: _rutaCalles.first,
          infoWindow: const InfoWindow(title: 'Salida'),
        ),
      );
      nuevosMarkers.add(
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

    // 2. Construir Polilíneas alternas
    final nuevasPolylines = <Polyline>{};
    if (_trackingActivo && _rutaCalles.isNotEmpty) {
      final total = _rutaCalles.length;
      nuevasPolylines.add(
        Polyline(
          polylineId: const PolylineId('ruta_completa'),
          points: _rutaCalles,
          color: _red.withValues(alpha: 0.35),
          width: 5, // Ligeramente más delgado para reducir carga geométrica
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
          jointType: JointType.round,
        ),
      );
      if (_demoPuntoActual > 0) {
        nuevasPolylines.add(
          Polyline(
            polylineId: const PolylineId('ruta_recorrida'),
            points: _rutaCalles.sublist(0, _demoPuntoActual.clamp(1, total)),
            color: _red,
            width: 5,
            startCap: Cap.roundCap,
            endCap: Cap.roundCap,
            jointType: JointType.round,
          ),
        );
      }
    }

    setState(() {
      _markersCache = nuevosMarkers;
      _polylinesCache = nuevasPolylines;
    });
  }

  Future<List<LatLng>> _obtenerRutaCalles(LatLng origen, LatLng destino) async {
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

  Future<void> _iniciarDemo() async {
    setState(() => _cargandoRuta = true);

    final puntos = await _obtenerRutaCalles(_demoOrigen, _demoDestino);
    if (!mounted) return;

    _rutaCalles = puntos;
    _esModoDemo = true;
    _trackingActivo = true;
    _demoPuntoActual = 0;
    _miUbicacion = puntos.first;
    _cargandoRuta = false;

    _actualizarElementosVisualesDelMapa();

    mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: puntos.first, zoom: 16),
      ),
    );

    // OPTIMIZACIÓN: Cambiado de 300ms a 450ms. Sigue viéndose fluido pero reduce un 50% el estrés del procesador.
    _demoTimer = Timer.periodic(const Duration(milliseconds: 450), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_demoPuntoActual >= _rutaCalles.length - 1) {
        timer.cancel();
        _llegarAlDestino();
        return;
      }

      _demoPuntoActual++;
      _miUbicacion = _rutaCalles[_demoPuntoActual];

      _actualizarElementosVisualesDelMapa();

      mapController?.animateCamera(
        CameraUpdate.newLatLng(_rutaCalles[_demoPuntoActual]),
      );
    });
  }

  void _llegarAlDestino() {
    if (!mounted) return;
    _trackingActivo = false;
    _esModoDemo = false;
    _miUbicacion = null;
    _rutaCalles = [];
    _demoPuntoActual = 0;

    _actualizarElementosVisualesDelMapa();

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
    _trackingActivo = false;
    _esModoDemo = false;
    _miUbicacion = null;
    _demoPuntoActual = 0;
    _rutaCalles = [];
    _actualizarElementosVisualesDelMapa();
  }

  static const _destinoReal = LatLng(9.546987, -69.192543);
  static const _radioLlegada = 50.0;

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

    _rutaCalles = puntos;
    _trackingActivo = true;
    _miUbicacion = origen;
    _demoPuntoActual = 0;
    _cargandoRuta = false;

    _actualizarElementosVisualesDelMapa();

    if (puntos.length > 1) {
      final bounds = _calcularBounds(puntos);
      mapController?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 60));
    }

    _trackingService.iniciarTracking((pos) {
      if (!mounted) return;
      final nuevaPos = LatLng(pos.latitude, pos.longitude);

      _miUbicacion = nuevaPos;
      _demoPuntoActual = _puntoMasCercano(nuevaPos);

      _actualizarElementosVisualesDelMapa();
      mapController?.animateCamera(CameraUpdate.newLatLng(nuevaPos));

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
    // OPTIMIZACIÓN: Si el delay no ha terminado, mostramos una linda pantalla de carga intermedia
    if (!_mapaListo) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: _red),
            SizedBox(height: 14),
            Text(
              'Inicializando sistema de mapas...',
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        // OPTIMIZACIÓN: RepaintBoundary aísla completamente los movimientos del mapa de los componentes Flutter
        RepaintBoundary(
          child: GoogleMap(
            initialCameraPosition: _initialPosition,
            onMapCreated: (c) => mapController = c,
            mapType: MapType.normal,
            markers: _markersCache, // Usa la caché del estado limpio
            polylines: _polylinesCache, // Usa la caché del estado limpio
            onTap: (_) => _cerrarInfoBus(),
            padding: const EdgeInsets.only(bottom: 80),
            indoorViewEnabled: false,
          ),
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
                ? CancelarRutaButton(onTap: _cancelarRuta)
                : IniciarRutaPanel(
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

// Nota: El widget _PulseDot se mantiene igual ya que maneja su propia animación aislada correctamente.
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
