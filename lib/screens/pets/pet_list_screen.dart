import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pawtastic/models/pet.dart';
import 'package:pawtastic/providers/pet_provider.dart';
import 'package:pawtastic/providers/auth_provider.dart';
import 'package:pawtastic/screens/pets/pet_register_screen.dart';
import 'package:pawtastic/screens/pets/pet_detail_screen.dart';
import 'package:animate_do/animate_do.dart';
import 'package:cached_network_image/cached_network_image.dart';

class PetListScreen extends StatefulWidget {
  const PetListScreen({super.key});

  @override
  State<PetListScreen> createState() => _PetListScreenState();
}

class _PetListScreenState extends State<PetListScreen> {
  @override
  void initState() {
    super.initState();
    // Usar Future.microtask para evitar llamadas durante el build
    Future.microtask(() {
      if (mounted) {
        _loadPets();
      }
    });
  }

  Future<void> _loadPets() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.user != null) {
      await Provider.of<PetProvider>(context, listen: false)
          .loadUserPets(authProvider.user!.id);
    }
  }

  void _navigateToAddPet() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PetRegisterScreen()),
    ).then((_) => _loadPets());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = Provider.of<AuthProvider>(context);

    if (authProvider.user == null) {
      return Center(
        child: Text(
          'No has iniciado sesión',
          style: theme.textTheme.titleMedium,
        ),
      );
    }

    return Container(
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
      child: Consumer<PetProvider>(
        builder: (context, petProvider, _) {
          if (petProvider.loading) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'Cargando mascotas...',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onBackground.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            );
          }

          if (petProvider.pets.isEmpty) {
            return Center(
              child: FadeInUp(
                duration: const Duration(milliseconds: 500),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.pets_rounded,
                      size: 80,
                      color: theme.colorScheme.primary.withOpacity(0.3),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No tienes mascotas registradas',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onBackground.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _navigateToAddPet,
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Agregar Mascota'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _loadPets,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: petProvider.pets.length,
              itemBuilder: (context, index) {
                final pet = petProvider.pets[index];
                return FadeInUp(
                  delay: Duration(milliseconds: 100 * index),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _PetCard(pet: pet),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _PetCard extends StatelessWidget {
  final Pet pet;

  const _PetCard({required this.pet});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PetDetailScreen(pet: pet),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // ... (código del Hero y la imagen sin cambios)
              Hero(
                tag: 'pet-${pet.id}',
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: pet.imageUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: CachedNetworkImage(
                            imageUrl: pet.imageUrl!,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: theme.colorScheme.primary.withOpacity(0.1),
                              child: Icon(
                                Icons.pets_rounded,
                                color:
                                    theme.colorScheme.primary.withOpacity(0.3),
                              ),
                            ),
                            errorWidget: (context, url, error) => Icon(
                              Icons.error_outline_rounded,
                              color: theme.colorScheme.error,
                            ),
                          ),
                        )
                      : Icon(
                          Icons.pets_rounded,
                          size: 32,
                          color: theme.colorScheme.primary.withOpacity(0.3),
                        ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pet.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${pet.species} - ${pet.breed}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onBackground.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '${pet.age} años',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color:
                                theme.colorScheme.onBackground.withOpacity(0.6),
                          ),
                        ),
                        Text(
                          ' • ${pet.weight} kg',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color:
                                theme.colorScheme.onBackground.withOpacity(0.6),
                          ),
                        ),
                        if (pet.gender != null && pet.gender!.isNotEmpty)
                          Text(
                            ' • ${pet.gender}',
                            style: theme.textTheme.bodySmall?.copyWith(
                                color: pet.gender == 'Macho'
                                    ? Colors.blue.shade700
                                    : Colors.pink.shade700,
                                fontWeight: FontWeight.w500),
                          ),
                      ],
                    )
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert_rounded,
                    color: theme.colorScheme.onSurface.withOpacity(0.5)),
                onSelected: (value) {
                  if (value == 'edit') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PetRegisterScreen(petToEdit: pet),
                      ),
                    ).then((_) {
                      if (context.mounted) {
                        // <--- AÑADIR ESTA COMPROBACIÓN
                        final authProvider =
                            Provider.of<AuthProvider>(context, listen: false);
                        if (authProvider.user != null) {
                          Provider.of<PetProvider>(context, listen: false)
                              .loadUserPets(authProvider.user!.id);
                        }
                      }
                    });
                  } else if (value == 'delete') {
                    _showDeleteConfirmationDialog(context, pet);
                  }
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'edit',
                    child: ListTile(
                      leading: Icon(Icons.edit_rounded),
                      title: Text('Editar'),
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'delete',
                    child: ListTile(
                      leading: Icon(Icons.delete_rounded, color: Colors.red),
                      title:
                          Text('Eliminar', style: TextStyle(color: Colors.red)),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context, Pet petToDelete) {
    final petProvider = Provider.of<PetProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

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
                    text: petToDelete.name,
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
              onPressed: () async {
                Navigator.of(dialogContext).pop(); // Cerrar el diálogo
                if (authProvider.user != null) {
                  await petProvider.deletePet(
                      petToDelete.id, authProvider.user!.id);
                  // La lista se recargará automáticamente si loadUserPets se llama después o si el provider notifica cambios.
                }
              },
            ),
          ],
        );
      },
    );
  }
}
