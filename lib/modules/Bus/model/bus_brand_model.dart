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

  BusMarca copyWith({String? nombre, bool? estado}) => BusMarca(
    id: id,
    nombre: nombre ?? this.nombre,
    estado: estado ?? this.estado,
  );
}