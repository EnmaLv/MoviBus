import 'package:flutter/material.dart';
import '../model/bus_brand_model.dart';

class MarcaFormSheet extends StatefulWidget {
  final BusMarca? marca;

  const MarcaFormSheet({super.key, this.marca});

  @override
  State<MarcaFormSheet> createState() => MarcaFormSheetState();
}

class MarcaFormSheetState extends State<MarcaFormSheet> {
  static const _red = Color(0xFFB71C1C);
  late TextEditingController _ctrl;
  final bool _loading = false;
  String? _fieldError;

  bool get _esEditar => widget.marca != null;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.marca?.nombre ?? '');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _submit() {
    final nombre = _ctrl.text.trim();
    if (nombre.isEmpty) {
      setState(() => _fieldError = 'El nombre es requerido.');
      return;
    }
    if (nombre.length > 100) {
      setState(() => _fieldError = 'Máximo 100 caracteres.');
      return;
    }
    Navigator.pop(context, nombre);
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
          // Handle
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

          // Título
          Text(
            _esEditar ? 'Editar Marca' : 'Nueva Marca',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            _esEditar
                ? 'Modifica el nombre de la marca.'
                : 'Agrega una nueva marca de vehículo.',
            style: const TextStyle(fontSize: 13, color: Color(0xFF888888)),
          ),
          const SizedBox(height: 24),

          // Campo nombre
          TextField(
            controller: _ctrl,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            onChanged: (_) => setState(() => _fieldError = null),
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              labelText: 'Nombre de la marca',
              hintText: 'Ej: Toyota, Mercedes-Benz',
              errorText: _fieldError,
              prefixIcon: const Icon(Icons.directions_car_outlined),
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

          // Botones
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
                  onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _esEditar ? 'Guardar cambios' : 'Crear marca',
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