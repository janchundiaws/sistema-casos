class Area {
  final int idArea;
  final String nombre;
  final String? descripcion;

  Area({required this.idArea, required this.nombre, this.descripcion});

  factory Area.fromJson(Map<String, dynamic> json) {
    return Area(
      idArea: json['id_area'],
      nombre: json['nombre'],
      descripcion: json['descripcion'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'id_area': idArea, 'nombre': nombre, 'descripcion': descripcion};
  }
}
