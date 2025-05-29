enum ServiceStatus {
  pending('Pendiente'),
  inProgress('En Proceso'),
  completed('Completado'),
  cancelled('Cancelado');

  final String label;
  const ServiceStatus(this.label);
}

enum ServiceType {
  grooming('Peluquería'),
  veterinary('Veterinaria'),
  walking('Paseo');

  final String label;
  const ServiceType(this.label);
}

class Service {
  final String id;
  final String petId;
  final String userId;
  final ServiceType tipoServicio;
  final DateTime fecha;
  final ServiceStatus estado;
  final String? notas;
  final DateTime createdAt;
  final DateTime updatedAt;

  Service({
    required this.id,
    required this.petId,
    required this.userId,
    required this.tipoServicio,
    required this.fecha,
    required this.estado,
    this.notas,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      id: json['id'] as String,
      petId: json['pet_id'] as String,
      userId: json['user_id'] as String,
      tipoServicio: ServiceType.values.firstWhere(
        (type) => type.name == json['tipo_servicio'],
        orElse: () => ServiceType.grooming,
      ),
      fecha: DateTime.parse(json['fecha'] as String),
      estado: ServiceStatus.values.firstWhere(
        (status) => status.name == json['estado'],
        orElse: () => ServiceStatus.pending,
      ),
      notas: json['notas'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pet_id': petId,
      'user_id': userId,
      'tipo_servicio': tipoServicio.name,
      'fecha': fecha.toIso8601String(),
      'estado': estado.name,
      'notas': notas,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Service copyWith({
    ServiceType? tipoServicio,
    DateTime? fecha,
    ServiceStatus? estado,
    String? notas,
  }) {
    return Service(
      id: id,
      petId: petId,
      userId: userId,
      tipoServicio: tipoServicio ?? this.tipoServicio,
      fecha: fecha ?? this.fecha,
      estado: estado ?? this.estado,
      notas: notas ?? this.notas,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
