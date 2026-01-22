import 'package:flutter/material.dart';
import 'package:pawtastic/models/pet.dart';

class Service {
  final String id;
  final String petId;
  final String userId;
  final String serviceType;
  final DateTime date;
  String status; // Modificable para reflejar cancelación
  final String? notes;
  final double? cost;
  Pet? pet; // Para almacenar los detalles de la mascota asociada
  final Map<String, dynamic>? hotelInfo; // Añadir campo hotelInfo

  Service({
    required this.id,
    required this.petId,
    required this.userId,
    required this.serviceType,
    required this.date,
    required this.status,
    this.notes,
    this.cost,
    this.pet,
    this.hotelInfo, // Añadir al constructor
  });

  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      id: json['id'] as String,
      petId: json['pet_id'] as String,
      userId: json['user_id'] as String,
      serviceType: json['tipo_servicio'] as String,
      date: DateTime.parse(json['fecha'] as String)
          .toLocal(), // Convertir a local
      status: json['estado'] as String,
      notes: json['notas'] as String?,
      cost: (json['costo_servicio'] as num?)?.toDouble(),
      hotelInfo: json['hotels'] != null
          ? {
              'name': json['hotels']['name'] as String,
              'price': (json['hotels']['price'] as num).toDouble(),
            }
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pet_id': petId,
      'user_id': userId,
      'tipo_servicio': serviceType,
      'fecha': date.toIso8601String(),
      'estado': status,
      'notas': notes,
      'costo_servicio': cost,
      if (hotelInfo != null) 'hotel_info': hotelInfo,
    };
  }

  Color getStatusColor(BuildContext context) {
    final theme = Theme.of(context);
    switch (status.toLowerCase()) {
      case 'programado':
        return Colors.blue.shade600;
      case 'completado':
        return Colors.green.shade600;
      case 'cancelado':
        return theme.colorScheme.error;
      default:
        return theme.colorScheme.onSurface.withOpacity(0.7);
    }
  }

  IconData getStatusIcon() {
    switch (status.toLowerCase()) {
      case 'programado':
        return Icons.event_available_rounded;
      case 'completado':
        return Icons.check_circle_outline_rounded;
      case 'cancelado':
        return Icons.cancel_outlined;
      default:
        return Icons.help_outline_rounded; // Corregido el icono
    }
  }
}
