import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/services.dart';

import '../../services/api_service.dart';
import '../auth/login.dart';
import '../../widgets/app_bar.dart';
import 'models/bus_model.dart';
import 'data/buses_mock.dart';
import '../../widgets/bus_info_card.dart';
import '../../widgets/start_route_button.dart';
import '../../widgets/top_overlay.dart';

import '../Bus/bus_catalogo_screen.dart';

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
  GoogleMapController? mapController;
  BitmapDescriptor? _busMovingIcon;
  BitmapDescriptor? _busStoppedIcon;
  BusEnMapa? _busSeleccionado;

  late AnimationController _pulseCtrl;
  late Animation<double> pulseAnim;

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
    return busesSimulados.map((bus) {
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
    if (index == _currentIndex && index == 0) return;
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
      // case 3: destino = const BusRutasScreen(); break;
      // case 4: destino = const ConductoresScreen(); break;
      // case 5: destino = const CombustibleScreen(); break;
      // case 6: destino = const MantenimientoScreen(); break;
      // case 7: destino = const ReportesScreen(); break;
      default:
        // Módulo aún no implementado
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_adminItems[index].label}: próximamente'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFFB71C1C),
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
          markers: _busMarkers,
          onTap: (_) => _cerrarInfoBus(),
          padding: EdgeInsets.only(bottom: _verBotonIniciarRuta ? 80 : 16),
        ),

        if (_busSeleccionado != null)
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: BusInfoCard(bus: _busSeleccionado!, onClose: _cerrarInfoBus),
          ),

        if (_verBotonIniciarRuta && _busSeleccionado == null)
          Positioned(
            left: 24,
            right: 24,
            bottom: 16,
            child: IniciarRutaButton(
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
