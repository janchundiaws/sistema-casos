class Seguimiento {
  final int idSeguimiento;
  final int idCaso;
  final int idUsuario;
  final String retroalimentacion;
  final String estado;
  final DateTime fechaSeguimiento;
  final String? usuario;
  final String? areaUsuario;
  final String? descripcionAreaUsuario;

  Seguimiento({
    required this.idSeguimiento,
    required this.idCaso,
    required this.idUsuario,
    required this.retroalimentacion,
    required this.estado,
    required this.fechaSeguimiento,
    this.usuario,
    this.areaUsuario,
    this.descripcionAreaUsuario,
  });

  factory Seguimiento.fromJson(Map<String, dynamic> json) {
    return Seguimiento(
      idSeguimiento: json['id_seguimiento'],
      idCaso: json['id_caso'],
      idUsuario: json['id_usuario'],
      retroalimentacion: json['retroalimentacion'],
      estado: json['estado'],
      fechaSeguimiento: DateTime.parse(json['fecha_seguimiento']),
      usuario: json['usuario'],
      areaUsuario: json['area_usuario'],
      descripcionAreaUsuario: json['descripcion_area_usuario'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_seguimiento': idSeguimiento,
      'id_caso': idCaso,
      'id_usuario': idUsuario,
      'retroalimentacion': retroalimentacion,
      'estado': estado,
      'fecha_seguimiento': fechaSeguimiento.toIso8601String(),
      'usuario': usuario,
      'area_usuario': areaUsuario,
      'descripcion_area_usuario': descripcionAreaUsuario,
    };
  }
}
