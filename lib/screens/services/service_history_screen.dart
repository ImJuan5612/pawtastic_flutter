import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pawtastic/models/service_model.dart';
import 'package:pawtastic/providers/auth_provider.dart';
import 'package:pawtastic/models/pet.dart'; // Importar el modelo Pet
import 'package:pawtastic/providers/pet_provider.dart';
import 'package:animate_do/animate_do.dart';

class ServiceHistoryScreen extends StatefulWidget {
  const ServiceHistoryScreen({super.key});

  @override
  State<ServiceHistoryScreen> createState() => _ServiceHistoryScreenState();
}

class _ServiceHistoryScreenState extends State<ServiceHistoryScreen> {
  List<Service> _services = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchServices();
  }

  Future<void> _fetchServices() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.user == null) {
        throw Exception('Usuario no autenticado.');
      }
      final userId = authProvider.user!.id;

      final response =
          await Supabase.instance.client.from('services').select('''
          id,
          pet_id,
          user_id,
          type,
          date,
          description,
          cost,
          completed,
          created_at,
          updated_at,
        ''').eq('user_id', userId).order('date', ascending: false);

      final List<Service> loadedServices = (response as List)
          .map((data) => Service.fromJson(data as Map<String, dynamic>))
          .toList();

      // Enriquecer con nombres de mascotas
      final petProvider = Provider.of<PetProvider>(context, listen: false);
      // Asegurarse que las mascotas estén cargadas
      if (petProvider.pets.isEmpty && authProvider.user != null) {
        await petProvider.loadUserPets(authProvider.user!.id);
      }

      for (var service in loadedServices) {
        final pet = petProvider.pets.firstWhere(
          (p) => p.id == service.petId,
          orElse: () => Pet(
            id: '', // ID vacío para un fallback
            userId:
                '', // Usar userId y puede ser vacío si es un fallback genérico
            name: 'Mascota Desconocida',
            species: 'Desconocida',
            breed: 'Desconocida',
            age: 0, // Edad por defecto
            weight: 0.0, // Peso por defecto
          ),
        );
        service.pet = pet;
      }

      if (mounted) {
        setState(() {
          _services = loadedServices;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
      debugPrint('Error fetching services: $e');
    }
  }

  Future<void> _cancelService(String serviceId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirmar Cancelación'),
          content:
              const Text('¿Estás seguro de que deseas cancelar este servicio?'),
          actions: <Widget>[
            TextButton(
              child: const Text('No'),
              onPressed: () => Navigator.of(dialogContext).pop(false),
            ),
            TextButton(
              style: TextButton.styleFrom(
                  foregroundColor: Theme.of(dialogContext).colorScheme.error),
              child: const Text('Sí, Cancelar'),
              onPressed: () => Navigator.of(dialogContext).pop(true),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        await Supabase.instance.client
            .from('services')
            .update({'estado': 'Cancelado'}).eq('id', serviceId);

        // Actualizar la UI
        setState(() {
          final index = _services.indexWhere((s) => s.id == serviceId);
          if (index != -1) {
            _services[index].status = 'Cancelado';
          }
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Servicio cancelado con éxito.'),
                backgroundColor: Colors.orange),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Error al cancelar el servicio: $e'),
                backgroundColor: Theme.of(context).colorScheme.error),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Servicios'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error. Intenta de nuevo.'))
              : _services.isEmpty
                  ? Center(
                      child: Text(
                        'No tienes servicios agendados.',
                        style: theme.textTheme.titleMedium,
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchServices,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(8.0),
                        itemCount: _services.length,
                        itemBuilder: (context, index) {
                          final service = _services[index];
                          return FadeInUp(
                            delay: Duration(milliseconds: 100 * (index % 10)),
                            child: Card(
                              margin: const EdgeInsets.symmetric(
                                  vertical: 8.0, horizontal: 4.0),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: service
                                      .getStatusColor(context)
                                      .withOpacity(0.15),
                                  child: Icon(service.getStatusIcon(),
                                      color: service.getStatusColor(context)),
                                ),
                                title: Text(
                                    '${service.serviceType} para ${service.pet?.name ?? "N/A"}',
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(
                                            fontWeight: FontWeight.w500)),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(DateFormat(
                                            'dd/MM/yyyy hh:mm a', 'es_MX')
                                        .format(service.date)),
                                    Text('Estado: ${service.status}',
                                        style: TextStyle(
                                            color:
                                                service.getStatusColor(context),
                                            fontWeight: FontWeight.bold)),
                                    if (service.hotelInfo != null)
                                      Text(
                                        'Hotel: ${service.hotelInfo!['name']} (${NumberFormat.currency(locale: 'es_MX', symbol: '\$').format(service.cost)})',
                                        style: TextStyle(
                                          fontStyle: FontStyle.italic,
                                          color: theme.colorScheme.secondary,
                                        ),
                                      ),
                                    if (service.serviceType.toLowerCase() !=
                                        'hospedaje')
                                      Text(
                                          'Total: ${NumberFormat.currency(locale: 'es_MX', symbol: '\$').format(service.cost)}'),
                                  ],
                                ),
                                trailing: service.status.toLowerCase() ==
                                        'programado'
                                    ? IconButton(
                                        icon: Icon(
                                            Icons.cancel_schedule_send_rounded,
                                            color: theme.colorScheme.error),
                                        tooltip: 'Cancelar Servicio',
                                        onPressed: () =>
                                            _cancelService(service.id),
                                      )
                                    : null,
                                isThreeLine: true,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
