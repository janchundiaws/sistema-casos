class Usuario {
  final int idUsuario;
  final int idArea;
  final String? rol;

  Usuario({required this.idUsuario, required this.idArea, this.rol});

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      idUsuario: json['id_usuario'],
      idArea: json['id_area'],
      rol: json['rol'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'id_usuario': idUsuario, 'id_area': idArea, 'rol': rol};
  }
}
