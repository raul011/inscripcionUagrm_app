class GrupoMateria {
  final int id;
  final String grupo;
  final int cupo;
  final String estado;
  final String docenteNombre;
  final String? docenteRegistro;
  final String? horarioDia;
  final String? horaInicio;
  final String? horaFin;

  GrupoMateria({
    required this.id,
    required this.grupo,
    required this.cupo,
    required this.estado,
    required this.docenteNombre,
    this.docenteRegistro,
    this.horarioDia,
    this.horaInicio,
    this.horaFin,
  });

  factory GrupoMateria.fromJson(Map<String, dynamic> json) {
    return GrupoMateria(
      id: json['id'],
      grupo: json['grupo'],
      cupo: json['cupo'],
      estado: json['estado'],
      docenteNombre: json['docente']?['nombre'] ?? '',
      docenteRegistro: json['docente']?['registro'],
      horarioDia: json['horario']?['dia'],
      horaInicio: json['horario']?['horaInicio'],
      horaFin: json['horario']?['horaFin'],
    );
  }
}
