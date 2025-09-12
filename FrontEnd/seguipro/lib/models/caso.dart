class Caso {
  final int idCaso;
  final String titulo;
  final String? descripcion;
  final String tipo;
  final String estado;
  final DateTime fechaCreacion;
  final DateTime? fechaCierre;
  final String? areasAsignadas;
  final String? areaUsuario;
  final String? descripcionAreaUsuario;

  Caso({
    required this.idCaso,
    required this.titulo,
    this.descripcion,
    required this.tipo,
    required this.estado,
    required this.fechaCreacion,
    this.fechaCierre,
    this.areasAsignadas,
    this.areaUsuario,
    this.descripcionAreaUsuario,
  });

  factory Caso.fromJson(Map<String, dynamic> json) {
    return Caso(
      idCaso: json['id_caso'],
      titulo: json['titulo'],
      descripcion: json['descripcion'],
      tipo: json['tipo'],
      estado: json['estado'],
      fechaCreacion: DateTime.parse(json['fecha_creacion']),
      fechaCierre: json['fecha_cierre'] != null
          ? DateTime.parse(json['fecha_cierre'])
          : null,
      areasAsignadas: json['areas_asignadas'],
      areaUsuario: json['area_usuario'],
      descripcionAreaUsuario: json['descripcion_area_usuario'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_caso': idCaso,
      'titulo': titulo,
      'descripcion': descripcion,
      'tipo': tipo,
      'estado': estado,
      'fecha_creacion': fechaCreacion.toIso8601String(),
      'fecha_cierre': fechaCierre?.toIso8601String(),
      'areas_asignadas': areasAsignadas,
      'area_usuario': areaUsuario,
      'descripcion_area_usuario': descripcionAreaUsuario,
    };
  }
}
