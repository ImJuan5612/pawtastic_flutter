import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:pawtastic/providers/service_catalog_provider.dart';

class ServiceSelector extends StatelessWidget {
  final String? value;
  final ValueChanged<String?> onChanged;
  final String? Function(String?)? validator;

  const ServiceSelector({
    super.key,
    this.value,
    required this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final serviceCatalogProvider = Provider.of<ServiceCatalogProvider>(context);

    if (serviceCatalogProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (serviceCatalogProvider.services.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'No hay servicios disponibles en este momento',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // Validar que el valor seleccionado exista en la lista
    String? validValue = value;
    if (value != null &&
        !serviceCatalogProvider.services.any((s) => s.name == value)) {
      validValue = null;
    }

    return DropdownButtonFormField<String>(
      decoration: const InputDecoration(
        labelText: 'Tipo de Servicio',
        border: OutlineInputBorder(),
        isDense: true,
      ),
      value: validValue,
      items: serviceCatalogProvider.services.map((service) {
        return DropdownMenuItem<String>(
          value: service.name,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (service.iconData != null) ...[
                    Icon(
                      service.iconData,
                      color: service.iconColor ?? theme.colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text(service.name, overflow: TextOverflow.ellipsis),
                ],
              ),
              Text(
                NumberFormat.currency(locale: 'es_MX', symbol: '\$')
                    .format(service.basePrice),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.secondary,
                ),
                textAlign: TextAlign.end,
              ),
            ],
          ),
        );
      }).toList(),
      onChanged: onChanged,
      validator: validator,
    );
  }
}
