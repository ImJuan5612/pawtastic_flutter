class Profile {
  final String id;
  final String? nombre;
  final String? apellido;
  final String? telefono;
  final String? direccion;
  final String? ciudad;
  final String? codigoPostal;
  final String email;
  final DateTime createdAt;
  final DateTime updatedAt;

  Profile({
    required this.id,
    this.nombre,
    this.apellido,
    this.telefono,
    this.direccion,
    this.ciudad,
    this.codigoPostal,
    required this.email,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      nombre: json['nombre'] as String?,
      apellido: json['apellido'] as String?,
      telefono: json['telefono'] as String?,
      direccion: json['direccion'] as String?,
      ciudad: json['ciudad'] as String?,
      codigoPostal: json['codigo_postal'] as String?,
      email: json['email'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'apellido': apellido,
      'telefono': telefono,
      'direccion': direccion,
      'ciudad': ciudad,
      'codigo_postal': codigoPostal,
      'email': email,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Profile copyWith({
    String? nombre,
    String? apellido,
    String? telefono,
    String? direccion,
    String? ciudad,
    String? codigoPostal,
    String? email,
  }) {
    return Profile(
      id: id,
      nombre: nombre ?? this.nombre,
      apellido: apellido ?? this.apellido,
      telefono: telefono ?? this.telefono,
      direccion: direccion ?? this.direccion,
      ciudad: ciudad ?? this.ciudad,
      codigoPostal: codigoPostal ?? this.codigoPostal,
      email: email ?? this.email,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
