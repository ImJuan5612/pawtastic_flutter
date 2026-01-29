import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pawtastic/models/pet.dart';
import 'package:pawtastic/models/pet_service.dart';
import 'package:pawtastic/providers/pet_provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:animate_do/animate_do.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pawtastic/screens/pets/pet_register_screen.dart';
import 'package:pawtastic/providers/auth_provider.dart';

class PetDetailScreen extends StatefulWidget {
  final Pet pet;

  const PetDetailScreen({super.key, required this.pet});

  @override
  State<PetDetailScreen> createState() => _PetDetailScreenState();
}

class _PetDetailScreenState extends State<PetDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<PetService> _services = [];
  bool _isLoading = true;
  String? _error;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  Map<DateTime, List<PetService>> _events = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _selectedDay = _focusedDay;
    _fetchServices();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchServices() async {
    try {
      final response =
          await Supabase.instance.client.from('services').select('''
            id,
            pet_id,
            tipo_servicio,
            fecha,
            estado,
            notas,
            costo_servicio,
            hotels (
              id,
              name,
              price
            )
          ''').eq('pet_id', widget.pet.id).order('fecha', ascending: false);

      setState(() {
        _services = (response as List)
            .map((data) => PetService(
                  id: data['id'],
                  petId: data['pet_id'],
                  type: _mapTipoServicioToServiceType(data['tipo_servicio']),
                  date: DateTime.parse(data['fecha']),
                  description: data['notas'] ?? '',
                  cost: (data['costo_servicio'] ?? 0).toDouble(),
                  status: data['estado'],
                  hotelInfo: data['hotels'] != null
                      ? {
                          'name': data['hotels']['name'],
                          'price': data['hotels']['price'],
                        }
                      : null,
                ))
            .toList();
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  ServiceType _mapTipoServicioToServiceType(String tipoServicio) {
    switch (tipoServicio.toLowerCase()) {
      case 'veterinario':
        return ServiceType.veterinario;
      case 'peluqueria':
        return ServiceType.peluqueria;
      case 'paseo':
        return ServiceType.paseo;
      case 'hospedaje':
        return ServiceType.hospedaje;
      default:
        return ServiceType.otro;
    }
  }

  List<PetService> _getEventsForDay(DateTime day) {
    return _events[DateTime(day.year, day.month, day.day)] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight:
                280, // Aumentamos la altura para mostrar más información
            pinned: true,
            actions: [
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onSelected: (value) {
                  if (value == 'edit') {
                    _editPet();
                  } else if (value == 'delete') {
                    _confirmDeletePet();
                  }
                },
                itemBuilder: (BuildContext context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, color: Colors.blue),
                        SizedBox(width: 8),
                        Text('Editar'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Eliminar'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.pet.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: 'pet-${widget.pet.id}',
                    child: widget.pet.imageUrl != null
                        ? CachedNetworkImage(
                            imageUrl: widget.pet.imageUrl!,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.1),
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.1),
                              child: Icon(
                                Icons.pets_rounded,
                                size: 64,
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withOpacity(0.3),
                              ),
                            ),
                          )
                        : Container(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.1),
                            child: Icon(
                              Icons.pets_rounded,
                              size: 64,
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.3),
                            ),
                          ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.8),
                        ],
                      ),
                    ),
                  ),
                  // Información adicional de la mascota
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 48, // Ajustamos para que no se solape con el título
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildPetInfo(
                          icon: Icons.pets,
                          label: widget.pet.species,
                        ),
                        _buildPetInfo(
                          icon: Icons.assignment,
                          label: widget.pet.breed,
                        ),
                        _buildPetInfo(
                          icon: Icons.cake,
                          label: '${widget.pet.age} años',
                        ),
                        _buildPetInfo(
                          icon: Icons.monitor_weight,
                          label: '${widget.pet.weight} kg',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverAppBarDelegate(
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Historial'),
                  Tab(text: 'Calendario'),
                ],
                labelColor: Theme.of(context).colorScheme.primary,
                indicatorColor: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildServiceHistory(),
            _buildCalendarView(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddServiceDialog(context),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  Widget _buildPetInfo({
    required IconData icon,
    required String label,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: Colors.white,
          size: 20,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildServiceHistory() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Text(
          'Error: $_error',
          style: const TextStyle(color: Colors.red),
        ),
      );
    }

    if (_services.isEmpty) {
      return const Center(
        child: Text('No hay historial de servicios'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _services.length,
      itemBuilder: (context, index) {
        final service = _services[index];
        return FadeInUp(
          delay: Duration(milliseconds: 100 * index),
          child: _buildServiceCard(
            service,
          ),
        );
      },
    );
  }

  Widget _buildServiceCard(PetService service) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: service.getColor(context).withOpacity(0.1),
          child: Icon(
            service.icon,
            color: service.getColor(context),
          ),
        ),
        title: Text(
          service.type.toString().split('.').last,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(service.description),
            if (service.hotelInfo != null)
              Text(
                'Hotel: ${service.hotelInfo!['name']}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.secondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            Text(
              DateFormat('dd/MM/yyyy').format(service.date),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ],
        ),
        trailing: Text(
          NumberFormat.currency(locale: 'es_MX', symbol: '\$')
              .format(service.hotelInfo?['price'] ?? service.cost),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildCalendarView() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TableCalendar<PetService>(
            firstDay: DateTime.utc(2024, 1, 1),
            lastDay: DateTime.utc(2026, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            startingDayOfWeek: StartingDayOfWeek.monday,
            calendarStyle: const CalendarStyle(
              markersMaxCount: 3,
              markersAnchor: 0.7,
              selectedDecoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
            ),
            headerStyle: const HeaderStyle(
              formatButtonShowsNext: false,
              titleCentered: true,
            ),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
            eventLoader: _getEventsForDay,
          ),
          if (_selectedDay != null) ...[
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Servicios para ${DateFormat.yMMMMd('es').format(_selectedDay!)}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            ..._getEventsForDay(_selectedDay!).map((service) => Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          service.getColor(context).withOpacity(0.1),
                      child: Icon(
                        service.icon,
                        color: service.getColor(context),
                      ),
                    ),
                    title: Text(
                      service.type.toString().split('.').last,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    subtitle: Text(service.description),
                    trailing: Text(
                      '\$${service.cost.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                  ),
                )),
          ] else
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(
                child: Text('Selecciona un día para ver los servicios'),
              ),
            ),
          const SizedBox(height: 16), // Espacio extra al final para el FAB
        ],
      ),
    );
  }

  Future<void> _showAddServiceDialog(BuildContext context) async {
    final formKey = GlobalKey<FormState>();
    ServiceType? selectedType;
    final descriptionController = TextEditingController();
    final costController = TextEditingController();
    String selectedStatus = 'pendiente';
    DateTime selectedDate = DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.now();

    Future<void> _pickDate() async {
      final picked = await showDatePicker(
        context: context,
        initialDate: selectedDate,
        firstDate: DateTime(2020),
        lastDate: DateTime(2030),
        locale: const Locale('es', 'ES'),
      );
      if (picked != null) {
        setState(() {
          selectedDate = DateTime(
            picked.year,
            picked.month,
            picked.day,
            selectedTime.hour,
            selectedTime.minute,
          );
        });
      }
    }

    Future<void> _pickTime() async {
      final picked = await showTimePicker(
        context: context,
        initialTime: selectedTime,
      );
      if (picked != null) {
        setState(() {
          selectedTime = picked;
          selectedDate = DateTime(
            selectedDate.year,
            selectedDate.month,
            selectedDate.day,
            picked.hour,
            picked.minute,
          );
        });
      }
    }

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nuevo Servicio'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<ServiceType>(
                  value: selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de Servicio',
                    border: OutlineInputBorder(),
                  ),
                  items: ServiceType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Row(
                        children: [
                          Icon(_getServiceIcon(type), size: 20),
                          const SizedBox(width: 8),
                          Text(type.toString().split('.').last),
                        ],
                      ),
                    );
                  }).toList(),
                  validator: (value) {
                    if (value == null) {
                      return 'Por favor selecciona un tipo de servicio';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    setState(() {
                      selectedType = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextButton.icon(
                        onPressed: _pickDate,
                        icon: const Icon(Icons.calendar_today),
                        label: Text(
                          DateFormat('dd/MM/yyyy').format(selectedDate),
                        ),
                      ),
                    ),
                    Expanded(
                      child: TextButton.icon(
                        onPressed: _pickTime,
                        icon: const Icon(Icons.access_time),
                        label: Text(selectedTime.format(context)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Notas',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingresa una descripción';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedStatus,
                  decoration: const InputDecoration(
                    labelText: 'Estado',
                    border: OutlineInputBorder(),
                  ),
                  items: ['pendiente', 'completado', 'cancelado'].map((status) {
                    return DropdownMenuItem(
                      value: status,
                      child:
                          Text(status[0].toUpperCase() + status.substring(1)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        selectedStatus = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: costController,
                  decoration: const InputDecoration(
                    labelText: 'Costo',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingresa el costo';
                    }
                    final cost = double.tryParse(value);
                    if (cost == null || cost <= 0) {
                      return 'Ingresa un costo válido';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate() && selectedType != null) {
                try {
                  setState(() => _isLoading = true);

                  final authUserId =
                      Supabase.instance.client.auth.currentUser?.id;
                  if (authUserId == null) {
                    throw Exception('Usuario no autenticado');
                  }

                  final service = PetService(
                    id: '',
                    petId: widget.pet.id,
                    userId: authUserId,
                    type: selectedType!,
                    date: selectedDate,
                    status: selectedStatus,
                    description: descriptionController.text,
                    cost: double.parse(costController.text),
                  );

                  await Supabase.instance.client
                      .from('services')
                      .insert(service.toJson())
                      .select();

                  if (mounted) {
                    Navigator.pop(context);
                    _fetchServices();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Servicio agregado con éxito'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } finally {
                  if (mounted) {
                    setState(() => _isLoading = false);
                  }
                }
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  IconData _getServiceIcon(ServiceType type) {
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

  void _editPet() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PetRegisterScreen(petToEdit: widget.pet),
      ),
    );
    // Al volver, lo ideal sería recargar la información.
    // Como este widget recibe 'pet' por parámetro inmutable, lo correcto es salir para que la lista se refresque
    // o convertir este widget para que escuche cambios específicos del provider para este ID.
    // Una solución simple es hacer pop y dejar que el usuario vuelva a entrar,
    // o mejor: reemplazar la ruta con la misma pantalla actualizada si el provider notifica.
    // Por simplicidad y UX: al volver de editar, cerramos esta pantalla para forzar refresh en la lista anterior.
    if (mounted) {
      Navigator.pop(context);
    }
  }

  void _confirmDeletePet() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        final dialogTheme = Theme.of(dialogContext);
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          icon: Icon(Icons.warning_amber_rounded,
              color: dialogTheme.colorScheme.error, size: 48),
          title: Text(
            'Lo sentimos... 😭',
            style: dialogTheme.textTheme.titleLarge?.copyWith(
              color: dialogTheme.colorScheme.error,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: dialogTheme.textTheme.bodyMedium?.copyWith(
                  color: dialogTheme.colorScheme.onSurface.withOpacity(0.8)),
              children: <TextSpan>[
                const TextSpan(text: 'A veces las despedidas son difíciles.¿Estás seguro de que deseas eliminar a '),
                TextSpan(
                    text: widget.pet.name,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const TextSpan(text: '?'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('No',
                  style: TextStyle(
                      color:
                          dialogTheme.colorScheme.onSurface.withOpacity(0.7))),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            ElevatedButton.icon(
              // icon: const Icon(Icons.delete_forever_rounded),
              label: const Text('Despedirme 👋🏻'),
              style: ElevatedButton.styleFrom(
                backgroundColor: dialogTheme.colorScheme.error,
                foregroundColor: dialogTheme.colorScheme.onError,
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Cerrar diálogo
                _deletePet();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _deletePet() async {
    try {
      final petProvider = Provider.of<PetProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context,
          listen:
              false); // Asumiendo AuthProvider está disponible y tiene el usuario

      if (authProvider.user == null) return;

      await petProvider.deletePet(widget.pet.id, authProvider.user!.id);

      if (mounted) {
        Navigator.pop(context); // Volver a la lista de mascotas
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mascota eliminada correctamente')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al eliminar: $e')),
        );
      }
    }
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
