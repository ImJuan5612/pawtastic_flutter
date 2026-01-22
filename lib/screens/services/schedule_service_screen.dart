import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pawtastic/models/pet.dart';
import 'package:pawtastic/models/hotel.dart';
import 'package:provider/provider.dart';
import 'package:pawtastic/providers/auth_provider.dart';
import 'package:pawtastic/providers/pet_provider.dart';
import 'package:pawtastic/providers/service_catalog_provider.dart';
import 'package:pawtastic/providers/hotel_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:animate_do/animate_do.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';

class ScheduleServiceScreen extends StatefulWidget {
  final String? preselectedServiceType;

  const ScheduleServiceScreen({super.key, this.preselectedServiceType});

  @override
  State<ScheduleServiceScreen> createState() => _ScheduleServiceScreenState();
}

class _ScheduleServiceScreenState extends State<ScheduleServiceScreen> {
  // Cambia el tipo de _selectedHotel
  Hotel? _selectedHotel;
  final _formKey = GlobalKey<FormState>();
  List<Pet> _selectedPets = [];
  String? _selectedServiceType;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  final _notesController = TextEditingController();
  bool _isLoading = false;

  // Añadir estas constantes para los horarios disponibles
  static const List<TimeOfDay> _availableTimeSlots = [
    TimeOfDay(hour: 9, minute: 0), // 9:00 AM
    TimeOfDay(hour: 10, minute: 0), // 10:00 AM
    TimeOfDay(hour: 11, minute: 0), // 11:00 AM
    TimeOfDay(hour: 12, minute: 0), // 12:00 PM
    TimeOfDay(hour: 14, minute: 0), // 2:00 PM
    TimeOfDay(hour: 15, minute: 0), // 3:00 PM
    TimeOfDay(hour: 16, minute: 0), // 4:00 PM
    TimeOfDay(hour: 17, minute: 0), // 5:00 PM
  ];

  @override
  void initState() {
    super.initState();

    Future.microtask(() async {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.user != null) {
        await Provider.of<PetProvider>(context, listen: false)
            .loadUserPets(authProvider.user!.id);
      }

      final serviceCatalogProvider =
          Provider.of<ServiceCatalogProvider>(context, listen: false);

      // Esperar a que los servicios estén cargados
      if (!serviceCatalogProvider.isLoading &&
          widget.preselectedServiceType != null) {
        final availableServices = serviceCatalogProvider.services;
        final normalizedPreselectedType =
            widget.preselectedServiceType?.toLowerCase().trim();

        if (normalizedPreselectedType != null) {
          final matchingService = availableServices.firstWhere(
              (service) =>
                  service.name.toLowerCase().trim() ==
                  normalizedPreselectedType,
              orElse: () => availableServices.first);

          if (mounted) {
            setState(() {
              _selectedServiceType = matchingService.name;
            });
          }
        }
      }

      // Cargar hoteles si el servicio preseleccionado es hospedaje
      if (widget.preselectedServiceType?.toLowerCase() == 'hospedaje') {
        await Provider.of<HotelProvider>(context, listen: false).loadHotels();
      }
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  // Reemplazar el método _pickTime con este nuevo método
  Future<void> _pickTime(BuildContext context) async {
    final now = TimeOfDay.now();
    final isToday = _selectedDate?.year == DateTime.now().year &&
        _selectedDate?.month == DateTime.now().month &&
        _selectedDate?.day == DateTime.now().day;

    // Filtrar horarios disponibles para hoy
    final availableSlots = _availableTimeSlots.where((slot) {
      if (!isToday) return true;
      return slot.hour > now.hour ||
          (slot.hour == now.hour && slot.minute > now.minute);
    }).toList();

    if (availableSlots.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'No hay horarios disponibles para hoy. Por favor, selecciona otro día.'),
          ),
        );
      }
      return;
    }

    final TimeOfDay? picked = await showDialog<TimeOfDay>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Seleccionar Horario'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: availableSlots.length,
              itemBuilder: (context, index) {
                final slot = availableSlots[index];
                return ListTile(
                  leading: const Icon(Icons.schedule),
                  title: Text(slot.format(context)),
                  onTap: () => Navigator.of(context).pop(slot),
                );
              },
            ),
          ),
        );
      },
    );

    if (picked != null && mounted) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _scheduleService() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedPets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Por favor, selecciona al menos una mascota.')));
      return;
    }
    if (_selectedServiceType == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Por favor, selecciona un tipo de servicio.')));
      return;
    }
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor, selecciona una fecha.')));
      return;
    }
    if (_selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor, selecciona una hora.')));
      return;
    }

    // Validación de hora pasada si la fecha es hoy (doble chequeo)
    final now = DateTime.now();
    if (_selectedDate!.year == now.year &&
        _selectedDate!.month == now.month &&
        _selectedDate!.day == now.day &&
        (_selectedTime!.hour < now.hour ||
            (_selectedTime!.hour == now.hour &&
                _selectedTime!.minute < now.minute))) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'La hora seleccionada para hoy ya ha pasado. Por favor, elige una hora futura.')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.user == null) {
        throw Exception('Usuario no autenticado.');
      }

      final serviceCatalogProvider =
          Provider.of<ServiceCatalogProvider>(context, listen: false);
      final selectedServiceInfo =
          serviceCatalogProvider.getServiceByName(_selectedServiceType!);
      final serviceCost = _selectedServiceType?.toLowerCase() == 'hospedaje'
          ? _selectedHotel?.price
          : selectedServiceInfo?.basePrice;

      // Crear la fecha y hora combinada
      final DateTime serviceDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      List<Map<String, dynamic>> servicesToInsert = [];
      for (Pet pet in _selectedPets) {
        servicesToInsert.add({
          'pet_id': pet.id,
          'user_id': authProvider.user!.id,
          'tipo_servicio': _selectedServiceType,
          'fecha': serviceDateTime.toIso8601String(),
          'estado': 'Programado',
          'notas': _notesController.text.trim(),
          if (serviceCost != null) 'costo_servicio': serviceCost,
          if (_selectedHotel != null) 'hotel_id': _selectedHotel!.id,
        });
      }

      await Supabase.instance.client.from('services').insert(servicesToInsert);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('¡Servicio agendado con éxito!'),
            backgroundColor: Colors.green),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error al agendar el servicio: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _handleServiceSelection(
      String? serviceName, ServiceCatalogProvider provider) {
    if (serviceName == null) return;

    final service = provider.services.firstWhere(
      (s) => s.name == serviceName,
      orElse: () => provider.services.first,
    );

    setState(() {
      _selectedServiceType = service.name;
    });
  }

  TimeOfDay _getInitialTime() {
    if (_selectedTime != null) return _selectedTime!;

    final now = DateTime.now();
    if (_selectedDate != null &&
        _selectedDate!.year == now.year &&
        _selectedDate!.month == now.month &&
        _selectedDate!.day == now.day) {
      return TimeOfDay.fromDateTime(now.add(const Duration(
          minutes:
              1))); // Un minuto en el futuro para evitar conflictos exactos
    }
    return const TimeOfDay(
        hour: 9, minute: 0); // Hora por defecto para otros días (ej. 9 AM)
  }

  // Modificar el widget que muestra la hora seleccionada
  Widget _buildTimeSelector(BuildContext context) {
    return InkWell(
      onTap: () => _pickTime(context),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Hora',
          prefixIcon: const Icon(Icons.access_time_rounded),
          border: const OutlineInputBorder(),
          errorText: _selectedTime == null ? 'Selecciona una hora' : null,
        ),
        child: Text(
          _selectedTime == null
              ? 'Seleccionar hora'
              : 'Hora: ${_selectedTime!.format(context)}',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // Mantener esta línea
    final serviceCatalogProvider = Provider.of<ServiceCatalogProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Agendar Servicio'),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.primary.withOpacity(0.05),
              theme.colorScheme.background,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  FadeInDown(
                    child: Consumer<PetProvider>(
                      builder: (context, petProviderConsumer, child) {
                        if (petProviderConsumer
                                .loading && // Usar el getter 'loading' de PetProvider
                            petProviderConsumer.pets.isEmpty) {
                          // Usar el getter 'pets' de PetProvider
                          // Mostrar CircularProgressIndicator si está cargando y no hay mascotas aún
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        if (petProviderConsumer.pets.isEmpty) {
                          // Acceder a 'pets' a través de la instancia petProvider
                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text(
                                'No tienes mascotas registradas. Por favor, registra una mascota primero.',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium
                                    ?.copyWith(color: theme.colorScheme.error),
                              ),
                            ),
                          );
                        }
                        return MultiSelectDialogField<Pet>(
                          items: petProviderConsumer.pets
                              .map((pet) => MultiSelectItem<Pet>(pet, pet.name))
                              .toList(),
                          title: const Text("Mascotas"),
                          selectedColor: theme.colorScheme.primary,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius:
                                const BorderRadius.all(Radius.circular(4)),
                            border: Border.all(
                              color:
                                  theme.colorScheme.onSurface.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          buttonIcon: const Icon(Icons.pets_rounded),
                          buttonText: Text(
                            "Selecciona tu(s) Mascota(s)",
                            style: theme.textTheme.bodyLarge?.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withOpacity(0.7)),
                          ),
                          onConfirm: (results) {
                            _selectedPets = results;
                          },
                          chipDisplay: MultiSelectChipDisplay(
                            onTap: (value) {
                              setState(() {
                                _selectedPets.remove(value);
                              });
                            },
                          ),
                          validator: (value) => (value == null || value.isEmpty)
                              ? 'Selecciona al menos una mascota'
                              : null,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  FadeInDown(
                    delay: const Duration(milliseconds: 100),
                    child: serviceCatalogProvider.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : Builder(
                            builder: (context) {
                              if (serviceCatalogProvider.services.isEmpty) {
                                return const Center(
                                    child:
                                        Text('No hay servicios disponibles'));
                              }

                              // Si hay un servicio preseleccionado pero no coincide con ninguno existente,
                              // reseteamos la selección
                              String? validSelectedType = _selectedServiceType;
                              if (_selectedServiceType != null &&
                                  !serviceCatalogProvider.services.any(
                                      (service) =>
                                          service.name ==
                                          _selectedServiceType)) {
                                validSelectedType = null;
                              }

                              return DropdownButtonFormField<String>(
                                decoration: const InputDecoration(
                                  labelText: 'Tipo de Servicio',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                                value: validSelectedType,
                                items: serviceCatalogProvider.services
                                    .map((service) {
                                  return DropdownMenuItem<String>(
                                    value: service.name,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (service.iconData != null) ...[
                                              Icon(service.iconData,
                                                  color: service.iconColor ??
                                                      theme.colorScheme.primary,
                                                  size: 20),
                                              const SizedBox(width: 8),
                                            ],
                                            Text(service.name,
                                                overflow:
                                                    TextOverflow.ellipsis),
                                          ],
                                        ),
                                        Text(
                                          NumberFormat.currency(
                                                  locale: 'es_MX', symbol: '\$')
                                              .format(service.basePrice),
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                            color: theme.colorScheme.secondary,
                                          ),
                                          textAlign: TextAlign.end,
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                onChanged: (String? newValue) {
                                  setState(() {
                                    _selectedServiceType = newValue;
                                    // Cargar hoteles si se selecciona hospedaje
                                    if (newValue?.toLowerCase() ==
                                        'hospedaje') {
                                      Provider.of<HotelProvider>(context,
                                              listen: false)
                                          .loadHotels();
                                    }
                                  });
                                },
                                validator: (value) {
                                  if (value == null) {
                                    return 'Selecciona un tipo de servicio';
                                  }
                                  if (!serviceCatalogProvider.services
                                      .any((s) => s.name == value)) {
                                    return 'Servicio seleccionado no válido';
                                  }
                                  return null;
                                },
                              );
                            },
                          ),
                  ),
                  if (_selectedServiceType != null &&
                      !serviceCatalogProvider.isLoading &&
                      _selectedServiceType?.toLowerCase() !=
                          'hospedaje') // Añadir esta condición
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: FadeIn(
                        child: Text(
                          "Costo: ${NumberFormat.currency(locale: 'es_MX', symbol: '\$').format(serviceCatalogProvider.getServiceByName(_selectedServiceType!)?.basePrice ?? 0.0)}",
                          textAlign: TextAlign.end,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                  FadeInDown(
                    delay: const Duration(milliseconds: 200),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: InkWell(
                            onTap: () => _pickDate(context),
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Fecha',
                                prefixIcon: Icon(Icons.calendar_today_rounded),
                                border: OutlineInputBorder(),
                              ),
                              child: Text(
                                _selectedDate == null
                                    ? 'No seleccionada'
                                    : DateFormat('dd/MM/yyyy')
                                        .format(_selectedDate!),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildTimeSelector(context),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  FadeInDown(
                    delay: const Duration(milliseconds: 300),
                    child: TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: 'Notas Adicionales (Opcional)',
                        prefixIcon: Icon(Icons.notes_rounded),
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 3,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Agregar selector de hotel después del selector de servicio
                  if (_selectedServiceType?.toLowerCase() == 'hospedaje') ...[
                    FadeInDown(
                      delay: const Duration(milliseconds: 200),
                      child: Consumer<HotelProvider>(
                        builder: (context, hotelProvider, _) {
                          if (hotelProvider.isLoading) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }

                          final hotels = hotelProvider.hotels;
                          if (hotels.isEmpty) {
                            return const Card(
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Text('No hay hoteles disponibles'),
                              ),
                            );
                          }

                          return DropdownButtonFormField<Hotel>(
                            isExpanded: true,
                            isDense: true,
                            menuMaxHeight: 300,
                            decoration: const InputDecoration(
                              labelText: 'Seleccionar Hotel',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                            ),
                            value: _selectedHotel,
                            selectedItemBuilder: (BuildContext context) {
                              return hotels.map((Hotel hotel) {
                                return Container(
                                  height: 20,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    hotel.name,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                );
                              }).toList();
                            },
                            items: hotels.map((hotel) {
                              return DropdownMenuItem<Hotel>(
                                value: hotel,
                                child: Container(
                                  height: 48,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceEvenly,
                                          children: [
                                            Text(
                                              hotel.name,
                                              style: theme.textTheme.bodyMedium
                                                  ?.copyWith(
                                                fontWeight: FontWeight.w500,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            Text(
                                              hotel.address,
                                              style: theme.textTheme.bodySmall
                                                  ?.copyWith(
                                                fontSize: 11,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        NumberFormat.currency(
                                          locale: 'es_MX',
                                          symbol: '\$',
                                        ).format(hotel.price),
                                        style:
                                            theme.textTheme.bodySmall?.copyWith(
                                          color: theme.colorScheme.primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (Hotel? value) {
                              setState(() => _selectedHotel = value);
                            },
                            validator: (value) {
                              if (_selectedServiceType?.toLowerCase() ==
                                      'hospedaje' &&
                                  value == null) {
                                return 'Por favor selecciona un hotel';
                              }
                              return null;
                            },
                          );
                        },
                      ),
                    ),
                  ],
                  const SizedBox(height: 30),
                  FadeInUp(
                    delay: const Duration(milliseconds: 400),
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.schedule_send_rounded),
                      label: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Agendar Servicio'),
                      onPressed: _isLoading ||
                              context
                                  .watch<PetProvider>()
                                  .pets
                                  .isEmpty // Usar el getter 'pets'
                          ? null
                          : _scheduleService,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
