import 'package:flutter/material.dart';
import '../model/bus_fuel_type_model.dart';

class FuelTypeFormSheet extends StatefulWidget {
  final BusTipoCombustible? combustible;
  const FuelTypeFormSheet({super.key, this.combustible});

  @override
  State<FuelTypeFormSheet> createState() => _FuelTypeFormSheetState();
}

class _FuelTypeFormSheetState extends State<FuelTypeFormSheet> {
  static const _red = Color(0xFFB71C1C);
  late TextEditingController _nameCtrl;
  late TextEditingController _descCtrl;
  String? _nameError;

  bool get _esEditar => widget.combustible != null;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.combustible?.nombre ?? '');
    _descCtrl = TextEditingController(text: widget.combustible?.descripcion == 'Ninguna' ? '' : widget.combustible?.descripcion ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final nombre = _nameCtrl.text.trim();
    final descripcion = _descCtrl.text.trim();

    if (nombre.isEmpty) {
      setState(() => _nameError = 'El nombre es requerido.');
      return;
    }
    if (nombre.length > 100) {
      setState(() => _nameError = 'Máximo 100 caracteres.');
      return;
    }

    // Retornamos un mapa estructurado con ambos campos recopilados
    Navigator.pop(context, {
      'nombre': nombre,
      'descripcion': descripcion.isEmpty ? 'Ninguna' : descripcion,
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
            child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
          ),
          const SizedBox(height: 20),
          Text(_esEditar ? 'Editar Combustible' : 'Nuevo Combustible', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(_esEditar ? 'Modifica los parámetros del combustible.' : 'Agrega un nuevo tipo de combustible al sistema.', style: const TextStyle(fontSize: 13, color: Color(0xFF888888))),
          const SizedBox(height: 24),

          // Campo Nombre
          TextField(
            controller: _nameCtrl,
            autofocus: !_esEditar,
            textCapitalization: TextCapitalization.words,
            onChanged: (_) => setState(() => _nameError = null),
            decoration: InputDecoration(
              labelText: 'Nombre del combustible',
              hintText: 'Ej: Gasolina, Diésel, Gas Natural',
              errorText: _nameError,
              prefixIcon: const Icon(Icons.local_gas_station_outlined),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: _red, width: 2), borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 16),

          // Campo Descripción
          TextField(
            controller: _descCtrl,
            maxLines: 2,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: 'Descripción / Observaciones (Opcional)',
              hintText: 'Escribe detalles adicionales...',
              prefixIcon: const Icon(Icons.description_outlined),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: _red, width: 2), borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 24),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: const Text('Cancelar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(backgroundColor: _red, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: Text(_esEditar ? 'Guardar cambios' : 'Crear combustible', style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}