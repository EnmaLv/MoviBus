class BusTipoCombustible {
  final int id;
  final String nombre;
  final String descripcion;
  final bool estado;

  const BusTipoCombustible({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.estado,
  });

  factory BusTipoCombustible.fromJson(Map<String, dynamic> j) => BusTipoCombustible(
    id: j['id'] as int,
    nombre: j['nombre'] as String,
    descripcion: j['descripcion'] as String? ?? 'Ninguna',
    estado: j['estado'] == true || j['estado'] == 1,
  );

  BusTipoCombustible copyWith({String? nombre, String? descripcion, bool? estado}) => BusTipoCombustible(
    id: id,
    nombre: nombre ?? this.nombre,
    descripcion: descripcion ?? this.descripcion,
    estado: estado ?? this.estado,
  );
}