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
    marcaId: j['marca_id'] as int,
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
