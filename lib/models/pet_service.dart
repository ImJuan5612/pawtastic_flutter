import 'package:flutter/material.dart';

enum ServiceType { veterinario, peluqueria, paseo, hospedaje, otro }

class PetService {
  final String id;
  final String petId;
  final String? userId;
  final ServiceType type;
  final DateTime date;
  final String description;
  final double cost;
  String? status;
  Map<String, dynamic>? hotelInfo; // Añadido campo para info del hotel

  PetService({
    required this.id,
    required this.petId,
    this.userId,
    required this.type,
    required this.date,
    required this.description,
    required this.cost,
    this.status = 'pendiente',
    this.hotelInfo, // Añadido al constructor
  });

  factory PetService.fromJson(Map<String, dynamic> json) {
    return PetService(
      id: json['id'] as String,
      petId: json['pet_id'] as String,
      userId: json['user_id'] as String?,
      type: _mapStringToServiceType(json['tipo_servicio'] as String),
      date: DateTime.parse(json['fecha'] as String),
      description: json['notas'] as String? ?? '',
      cost: (json['costo_servicio'] as num?)?.toDouble() ?? 0.0,
      status: json['estado'] as String?,
      hotelInfo: json['hotels'] != null
          ? {
              'name': json['hotels']['name'] as String,
              'price': (json['hotels']['price'] as num).toDouble(),
            }
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'pet_id': petId,
        'user_id': userId,
        'tipo_servicio': type.toString().split('.').last,
        'fecha': date.toIso8601String(),
        'estado': status,
        'notas': description,
        'costo_servicio': cost,
        'hotel_info': hotelInfo, // Añadido al toJson
      };

  IconData get icon {
    switch (type) {
      case ServiceType.veterinario:
        return Icons.local_hospital_rounded;
      case ServiceType.peluqueria:
        return Icons.content_cut_rounded;
      case ServiceType.paseo:
        return Icons.directions_walk_rounded;
      case ServiceType.hospedaje:
        return Icons.home_rounded;
      case ServiceType.otro:
        return Icons.pets_rounded;
    }
  }

  Color getColor(BuildContext context) {
    final theme = Theme.of(context);
    switch (type) {
      case ServiceType.veterinario:
        return Colors.red.shade400;
      case ServiceType.peluqueria:
        return theme.colorScheme.primary;
      case ServiceType.paseo:
        return Colors.green.shade400;
      case ServiceType.hospedaje:
        return Colors.orange.shade400;
      case ServiceType.otro:
        return Colors.grey.shade400;
    }
  }
}

ServiceType _mapStringToServiceType(String value) {
  return ServiceType.values.firstWhere(
    (e) => e.toString().split('.').last.toLowerCase() == value.toLowerCase(),
    orElse: () => ServiceType.otro,
  );
}
