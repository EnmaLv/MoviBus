import 'package:flutter/material.dart';
import '../model/bus_model.dart';
import '../model/bus_brand_model.dart';

class ModeloFormSheet extends StatefulWidget {
  final BusModelo? modelo;
  final List<BusMarca> marcas;
  const ModeloFormSheet({super.key, this.modelo, required this.marcas});

  @override
  State<ModeloFormSheet> createState() => ModeloFormSheetState();
}

class ModeloFormSheetState extends State<ModeloFormSheet> {
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
