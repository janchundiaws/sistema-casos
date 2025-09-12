class Rol {
  final int idRol;
  final String nombre;
  final String? descripcion;

  Rol({required this.idRol, required this.nombre, this.descripcion});

  factory Rol.fromJson(Map<String, dynamic> json) {
    return Rol(
      idRol: json['id_rol'],
      nombre: json['nombre'],
      descripcion: json['descripcion'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'id_rol': idRol, 'nombre': nombre, 'descripcion': descripcion};
  }
}
