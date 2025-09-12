class Adjunto {
  final int idAdjunto;
  final int? idCaso;
  final int? idSeguimiento;
  final String nombreArchivo;
  final String tipoMime;
  final String rutaArchivo;
  final DateTime fechaSubida;
  final int idUsuario;

  Adjunto({
    required this.idAdjunto,
    this.idCaso,
    this.idSeguimiento,
    required this.nombreArchivo,
    required this.tipoMime,
    required this.rutaArchivo,
    required this.fechaSubida,
    required this.idUsuario,
  });

  factory Adjunto.fromJson(Map<String, dynamic> json) {
    return Adjunto(
      idAdjunto: json['id_adjunto'],
      idCaso: json['id_caso'],
      idSeguimiento: json['id_seguimiento'],
      nombreArchivo: json['nombre_archivo'],
      tipoMime: json['tipo_mime'],
      rutaArchivo: json['ruta_archivo'],
      fechaSubida: DateTime.parse(json['fecha_subida']),
      idUsuario: json['id_usuario'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_adjunto': idAdjunto,
      'id_caso': idCaso,
      'id_seguimiento': idSeguimiento,
      'nombre_archivo': nombreArchivo,
      'tipo_mime': tipoMime,
      'ruta_archivo': rutaArchivo,
      'fecha_subida': fechaSubida.toIso8601String(),
      'id_usuario': idUsuario,
    };
  }
}
