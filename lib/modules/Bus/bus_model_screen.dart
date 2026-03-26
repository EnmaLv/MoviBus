import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../services/api_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MODELOS DE DATOS
// ─────────────────────────────────────────────────────────────────────────────

class BusMarca {
  final int id;
  final String nombre;
  final bool estado;

  const BusMarca({
    required this.id,
    required this.nombre,
    required this.estado,
  });
  factory BusMarca.fromJson(Map<String, dynamic> j) => BusMarca(
    id: j['id'] as int,
    nombre: j['nombre'] as String,
    estado: j['estado'] == true || j['estado'] == 1,
  );
}

class BusModelo {
  final int id;
  final int marcaId;
  final String marcaNombre;
  final String nombre;
  final bool estado;

  const BusModelo({
    required this.id,
    required this.marcaId,
    required this.marcaNombre,
    required this.nombre,
    required this.estado,
  });

  factory BusModelo.fromJson(Map<String, dynamic> j) => BusModelo(
    id: j['id'] as int,
    marcaId: j['bus_marca_id'] as int,
    marcaNombre: j['marca']?['nombre'] as String? ?? '',
    nombre: j['nombre'] as String,
    estado: j['estado'] == true || j['estado'] == 1,
  );

  BusModelo copyWith({
    String? nombre,
    bool? estado,
    String? marcaNombre,
    int? marcaId,
  }) => BusModelo(
    id: id,
    marcaId: marcaId ?? this.marcaId,
    marcaNombre: marcaNombre ?? this.marcaNombre,
    nombre: nombre ?? this.nombre,
    estado: estado ?? this.estado,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// SERVICIO API
// ─────────────────────────────────────────────────────────────────────────────

class BusModeloService {
  static const _base = '/modelos';
  static const _marcas = '/marcas';

  static Future<List<BusModelo>> getAll() async {
    final res = await ApiService.get(_base);
    if (res['success'] == true) {
      return (res['data'] as List)
          .map((j) => BusModelo.fromJson(j as Map<String, dynamic>))
          .toList();
    }
    throw Exception(res['message'] ?? 'Error al cargar modelos.');
  }

  static Future<List<BusMarca>> getMarcas() async {
    final res = await ApiService.get('$_marcas?estado=1');
    if (res['success'] == true) {
      return (res['data'] as List)
          .map((j) => BusMarca.fromJson(j as Map<String, dynamic>))
          .toList();
    }
    throw Exception(res['message'] ?? 'Error al cargar marcas.');
  }

  static Future<BusModelo> create(int marcaId, String nombre) async {
    final res = await ApiService.post(_base, {
      'bus_marca_id': marcaId,
      'nombre': nombre,
    });
    if (res['success'] == true) return BusModelo.fromJson(res['data']);
    throw Exception(res['message'] ?? 'Error al crear modelo.');
  }

  static Future<BusModelo> update(int id, int marcaId, String nombre) async {
    final res = await ApiService.put('$_base/$id', {
      'bus_marca_id': marcaId,
      'nombre': nombre,
    });
    if (res['success'] == true) return BusModelo.fromJson(res['data']);
    throw Exception(res['message'] ?? 'Error al actualizar modelo.');
  }

  static Future<void> toggle(int id) async {
    final res = await ApiService.patch('$_base/$id/toggle', {});
    if (res['success'] != true) throw Exception(res['message'] ?? 'Error.');
  }

  static Future<void> delete(int id) async {
    final res = await ApiService.delete('$_base/$id');
    if (res['success'] != true) {
      throw Exception(res['message'] ?? 'Error al eliminar modelo.');
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PANTALLA PRINCIPAL
// ─────────────────────────────────────────────────────────────────────────────

class BusModeloScreen extends StatefulWidget {
  const BusModeloScreen({super.key});

  @override
  State<BusModeloScreen> createState() => _BusModeloScreenState();
}

class _BusModeloScreenState extends State<BusModeloScreen> {
  static const _red = Color(0xFFB71C1C);

  List<BusModelo> _modelos = [];
  List<BusModelo> _filtrados = [];
  List<BusMarca> _marcas = [];
  bool _cargando = true;
  String? _error;
  String? _filtroMarcaId; // null = todas las marcas
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cargar();
    _searchCtrl.addListener(_filtrar);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Datos ──────────────────────────────────────────────────────────────────
  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        BusModeloService.getAll(),
        BusModeloService.getMarcas(),
      ]);
      setState(() {
        _modelos = results[0] as List<BusModelo>;
        final marcas = results[1] as List<BusMarca>;
        _marcas = marcas
            .where((m) => m.estado == true || m.estado == 1)
            .toList();
        _filtrados = _modelos.where((m) => m.estado).toList();
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _cargando = false);
    }
  }

  void _filtrar() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtrados = _modelos.where((m) {
        final coincideTexto =
            m.nombre.toLowerCase().contains(q) ||
            m.marcaNombre.toLowerCase().contains(q);
        final coincideMarca =
            _filtroMarcaId == null || m.marcaId.toString() == _filtroMarcaId;
        return coincideTexto && coincideMarca;
      }).toList();
    });
  }

  void _setFiltroMarca(String? id) {
    setState(() => _filtroMarcaId = id);
    _filtrar();
  }

  // ── Acciones ───────────────────────────────────────────────────────────────
  Future<void> _crearOEditar({BusModelo? modelo}) async {
    if (_marcas.isEmpty) {
      _snack('Primero registra al menos una marca.');
      return;
    }

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ModeloFormSheet(modelo: modelo, marcas: _marcas),
    );
    if (result == null) return;

    final marcaId = result['marcaId'] as int;
    final nombre = result['nombre'] as String;

    try {
      if (modelo == null) {
        final nuevo = await BusModeloService.create(marcaId, nombre);
        setState(() {
          _modelos.add(nuevo);
          _filtrar();
        });
        _snack('Modelo "${nuevo.nombre}" creado.', success: true);
      } else {
        final actualizado = await BusModeloService.update(
          modelo.id,
          marcaId,
          nombre,
        );
        setState(() {
          final i = _modelos.indexWhere((m) => m.id == modelo.id);
          if (i != -1) _modelos[i] = actualizado;
          _filtrar();
        });
        _snack('Modelo actualizado.', success: true);
      }
    } catch (e) {
      _snack(e.toString());
    }
  }

  Future<void> _toggle(BusModelo modelo) async {
    try {
      await BusModeloService.toggle(modelo.id);
      setState(() {
        final i = _modelos.indexWhere((m) => m.id == modelo.id);
        if (i != -1) _modelos[i] = modelo.copyWith(estado: !modelo.estado);
        _filtrar();
      });
      HapticFeedback.lightImpact();
    } catch (e) {
      _snack(e.toString());
    }
  }

  Future<void> _eliminar(BusModelo modelo) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('¿Eliminar modelo?'),
        content: Text('Se eliminará "${modelo.nombre}" permanentemente.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: _red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    if (!mounted) return;

    try {
      await BusModeloService.delete(modelo.id);
      setState(() {
        _modelos.removeWhere((m) => m.id == modelo.id);
        _filtrar();
      });
      _snack('Modelo eliminado.', success: true);
    } catch (e) {
      _snack(e.toString());
    }
  }

  void _snack(String msg, {bool success = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: success ? const Color(0xFF2E7D32) : _red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ── UI ─────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F5);

    return Scaffold(
      backgroundColor: bg,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_bus_modelo',
        onPressed: () => _crearOEditar(),
        backgroundColor: _red,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Nuevo Modelo',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: Column(
        children: [
          // Barra de búsqueda (mismo estilo que marcas)
          Container(
            color: _red,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              children: [
                TextField(
                  controller: _searchCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Buscar modelo o marca...',
                    hintStyle: const TextStyle(color: Colors.white60),
                    prefixIcon: const Icon(Icons.search, color: Colors.white70),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.15),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
                const SizedBox(height: 10),
                // Filtro por marca — chips horizontales
                if (_marcas.isNotEmpty)
                  SizedBox(
                    height: 32,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _FiltroChip(
                          label: 'Todas',
                          activo: _filtroMarcaId == null,
                          onTap: () => _setFiltroMarca(null),
                        ),
                        ..._marcas.map(
                          (m) => _FiltroChip(
                            label: m.nombre,
                            activo: _filtroMarcaId == m.id.toString(),
                            onTap: () => _setFiltroMarca(m.id.toString()),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Stats
          _StatsBar(modelos: _modelos, marcas: _marcas),

          // Lista
          Expanded(child: _buildBody(isDark)),
        ],
      ),
    );
  }

  Widget _buildBody(bool isDark) {
    if (_cargando) return const Center(child: CircularProgressIndicator());

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: _cargar,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_filtrados.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.car_repair_outlined, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              _searchCtrl.text.isEmpty && _filtroMarcaId == null
                  ? 'No hay modelos registrados.'
                  : 'Sin resultados para la búsqueda.',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _cargar,
      color: _red,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        itemCount: _filtrados.length,
        itemBuilder: (_, i) => _ModeloCard(
          modelo: _filtrados[i],
          isDark: isDark,
          onEdit: () => _crearOEditar(modelo: _filtrados[i]),
          onToggle: () => _toggle(_filtrados[i]),
          onDelete: () => _eliminar(_filtrados[i]),
        ),
      ),
    );
  }
}

// ─── Chip de filtro por marca ─────────────────────────────────────────────────
class _FiltroChip extends StatelessWidget {
  final String label;
  final bool activo;
  final VoidCallback onTap;
  const _FiltroChip({
    required this.label,
    required this.activo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: activo ? Colors.white : Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: activo ? const Color(0xFFB71C1C) : Colors.white,
          ),
        ),
      ),
    );
  }
}

// ─── Stats bar ────────────────────────────────────────────────────────────────
class _StatsBar extends StatelessWidget {
  final List<BusModelo> modelos;
  final List<BusMarca> marcas;
  const _StatsBar({required this.modelos, required this.marcas});

  @override
  Widget build(BuildContext context) {
    final activos = modelos.where((m) => m.estado).length;
    final inactivos = modelos.length - activos;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final card = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          _StatChip(
            label: 'Total',
            value: modelos.length,
            color: const Color(0xFF1565C0),
            cardColor: card,
          ),
          const SizedBox(width: 8),
          _StatChip(
            label: 'Activos',
            value: activos,
            color: const Color(0xFF2E7D32),
            cardColor: card,
          ),
          const SizedBox(width: 8),
          _StatChip(
            label: 'Inactivos',
            value: inactivos,
            color: const Color(0xFF757575),
            cardColor: card,
          ),
          const SizedBox(width: 8),
          _StatChip(
            label: 'Marcas',
            value: marcas.length,
            color: const Color(0xFF6A1B9A),
            cardColor: card,
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final Color cardColor;
  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
    required this.cardColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              '$value',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: Color(0xFF888888)),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Card del modelo ──────────────────────────────────────────────────────────
class _ModeloCard extends StatelessWidget {
  final BusModelo modelo;
  final bool isDark;
  final VoidCallback onEdit;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  static const _red = Color(0xFFB71C1C);

  const _ModeloCard({
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
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, size: 20),
              onPressed: onDelete,
              color: _red,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Formulario (bottom sheet) ────────────────────────────────────────────────
class _ModeloFormSheet extends StatefulWidget {
  final BusModelo? modelo;
  final List<BusMarca> marcas;
  const _ModeloFormSheet({this.modelo, required this.marcas});

  @override
  State<_ModeloFormSheet> createState() => _ModeloFormSheetState();
}

class _ModeloFormSheetState extends State<_ModeloFormSheet> {
  static const _red = Color(0xFFB71C1C);
  late TextEditingController _ctrl;
  BusMarca? _marcaSeleccionada;
  String? _fieldErrorNombre;
  String? _fieldErrorMarca;

  bool get _esEditar => widget.modelo != null;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.modelo?.nombre ?? '');
    // Preseleccionar la marca si es edición
    if (widget.modelo != null) {
      _marcaSeleccionada = widget.marcas
          .where((m) => m.id == widget.modelo!.marcaId)
          .firstOrNull;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _submit() {
    final nombre = _ctrl.text.trim();
    setState(() {
      _fieldErrorNombre = nombre.isEmpty ? 'El nombre es requerido.' : null;
      _fieldErrorMarca = _marcaSeleccionada == null
          ? 'Selecciona una marca.'
          : null;
    });
    if (_fieldErrorNombre != null || _fieldErrorMarca != null) return;
    Navigator.pop(context, {
      'marcaId': _marcaSeleccionada!.id,
      'nombre': nombre,
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(24, 20, 24, 24 + bottom),
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _esEditar ? 'Editar Modelo' : 'Nuevo Modelo',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            _esEditar
                ? 'Modifica los datos del modelo.'
                : 'Agrega un nuevo modelo de vehículo.',
            style: const TextStyle(fontSize: 13, color: Color(0xFF888888)),
          ),
          const SizedBox(height: 24),

          // Dropdown de marca
          DropdownButtonFormField<BusMarca>(
            value: _marcaSeleccionada,
            hint: const Text('Selecciona una marca'),
            decoration: InputDecoration(
              labelText: 'Marca',
              prefixIcon: const Icon(Icons.directions_car_outlined),
              errorText: _fieldErrorMarca,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _red, width: 2),
              ),
            ),
            items: widget.marcas
                .map((m) => DropdownMenuItem(value: m, child: Text(m.nombre)))
                .toList(),
            onChanged: (m) => setState(() {
              _marcaSeleccionada = m;
              _fieldErrorMarca = null;
            }),
          ),

          const SizedBox(height: 16),

          // Campo nombre
          TextField(
            controller: _ctrl,
            autofocus: !_esEditar,
            textCapitalization: TextCapitalization.words,
            onChanged: (_) => setState(() => _fieldErrorNombre = null),
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              labelText: 'Nombre del modelo',
              hintText: 'Ej: Coaster, Sprinter, HiAce',
              errorText: _fieldErrorNombre,
              prefixIcon: const Icon(Icons.car_repair_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _red, width: 2),
              ),
            ),
          ),

          const SizedBox(height: 24),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Cancelar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _esEditar ? 'Guardar cambios' : 'Crear modelo',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
