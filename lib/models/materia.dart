class Materia {
  final int id;
  final String codigo;
  final String nombre;
  final int creditos;
  final String nivelNombre;

  Materia({
    required this.id,
    required this.codigo,
    required this.nombre,
    required this.creditos,
    required this.nivelNombre,
  });

  factory Materia.fromJson(Map<String, dynamic> json) {
    return Materia(
      id: json['id'],
      codigo: json['codigo'],
      nombre: json['nombre'],
      creditos: json['creditos'],
      nivelNombre: json['nivel']['nombre'],
    );
  }
}
