import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pawtastic/providers/auth_provider.dart';
import 'package:pawtastic/screens/pets/pet_list_screen.dart';
import 'package:pawtastic/screens/pets/pet_register_screen.dart';
import 'package:pawtastic/screens/pets/pet_detail_screen.dart';
import 'package:pawtastic/providers/pet_provider.dart';
import 'package:pawtastic/providers/service_catalog_provider.dart';
// import 'package:pawtastic/models/service_catalog_item.dart';
import 'package:pawtastic/screens/services/service_history_screen.dart';
import 'package:pawtastic/screens/auth/personal_data_screen.dart'; // Para editar perfil
import 'package:pawtastic/screens/wallet/wallet_screen.dart'; // Importar WalletScreen
import 'package:pawtastic/screens/services/schedule_service_screen.dart';
import 'package:pawtastic/screens/services/service_provider_benefits_screen.dart';
import 'package:pawtastic/screens/settings/settings_screen.dart';
import 'package:pawtastic/screens/auth/login_screen.dart';
import 'package:animate_do/animate_do.dart';
import 'dart:math'; // Para frases aleatorias
import 'package:cached_network_image/cached_network_image.dart'; // Para la imagen de perfil
import 'package:intl/intl.dart'; // Para formatear moneda

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DashboardTab(), // Nueva pantalla principal
    ServicesTab(),
    PetListScreen(),
    ProfileTab(),
  ];

  final List<String> _titles = [
    'Inicio', // Título para la nueva pantalla
    'Servicios',
    'Mascotas',
    'Perfil',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: FadeInDown(
          duration: const Duration(milliseconds: 300),
          child: Text(
            _titles[_currentIndex],
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        centerTitle: true,
        actions: [
          if (_currentIndex ==
              2) // Ajustar índice para la pestaña de Mascotas (antes era 1)
            IconButton(
              icon: const Icon(Icons.add_rounded),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PetRegisterScreen()),
                ).then((_) {
                  // Después de agregar una mascota, recargar la lista.
                  final authProvider =
                      Provider.of<AuthProvider>(context, listen: false);
                  if (authProvider.user != null) {
                    Provider.of<PetProvider>(context, listen: false)
                        .loadUserPets(authProvider.user!.id);
                  }
                });
              },
            ),
        ],
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
        child: IndexedStack(
          index: _currentIndex,
          children: _screens
              .map(
                (screen) => FadeInUp(
                  duration: const Duration(milliseconds: 300),
                  child: screen,
                ),
              )
              .toList(),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            backgroundColor: theme.colorScheme.surface,
            selectedItemColor: theme.colorScheme.primary,
            unselectedItemColor: theme.colorScheme.onSurface.withOpacity(0.5),
            selectedLabelStyle: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            unselectedLabelStyle: theme.textTheme.labelSmall,
            type: BottomNavigationBarType.fixed,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.dashboard_rounded),
                activeIcon: Icon(Icons.dashboard_rounded),
                label: 'Principal',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.category_rounded),
                activeIcon: Icon(Icons.category_rounded),
                label: 'Servicios',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.pets_rounded),
                activeIcon: Icon(Icons.pets_rounded),
                label: 'Mascotas',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_rounded),
                activeIcon: Icon(Icons.person_rounded),
                label: 'Perfil',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  String _randomGreeting = "";
  final List<String> _greetingTemplates = [
    "¡Hola {userName}! ¿Listo para cuidar de tus mascotas?",
    "¡Bienvenido {userName}! Tus mascotas te esperan.",
    "¡Hola de nuevo {userName}!",
    "¡Qué gusto verte {userName}!",
    "¡Bienvenido a tu espacio pet-friendly, {userName}!",
  ];

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) {
        _setRandomGreeting();
      }
    });
  }

  void _setRandomGreeting() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    String userName = 'amigo';

    if (authProvider.user != null) {
      final displayNameFromMetadata =
          authProvider.user!.userMetadata?['display_name'] as String?;
      userName = displayNameFromMetadata ??
          authProvider.user!.email?.split('@').first ??
          'amigo';
    }

    final random = Random();
    final template =
        _greetingTemplates[random.nextInt(_greetingTemplates.length)];
    if (mounted) {
      setState(() {
        _randomGreeting = template.replaceAll('{userName}', userName);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final petProvider = Provider.of<PetProvider>(context);

    return RefreshIndicator(
      onRefresh: () async {
        if (authProvider.user != null) {
          await petProvider.loadUserPets(authProvider.user!.id);
        }
      },
      child: ListView(
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 8), // Ajuste de padding
        children: [
          // Encabezado con saludo personalizado y avatar
          FadeInDown(
            duration: const Duration(milliseconds: 400), // Ajuste de duración
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 20), // Mejor espaciado
                child: Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.center, // Centrado vertical
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor:
                          theme.colorScheme.primary.withOpacity(0.1),
                      backgroundImage:
                          authProvider.user?.userMetadata?['avatar_url'] != null
                              ? CachedNetworkImageProvider(authProvider
                                  .user!.userMetadata!['avatar_url'] as String)
                              : null,
                      child:
                          authProvider.user?.userMetadata?['avatar_url'] == null
                              ? Icon(Icons.person_rounded,
                                  color: theme.colorScheme.primary, size: 30)
                              : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _randomGreeting,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '¿Qué haremos hoy por tus mascotas?',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color:
                                  theme.colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20), // Ajuste de espaciado

          // Sección de mascotas
          if (petProvider.pets.isNotEmpty) ...[
            _buildSectionTitle(context, 'Tus Mascotas', Icons.pets_rounded),
            SizedBox(
              height: 140,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: petProvider.pets.length + 1,
                itemBuilder: (context, index) {
                  if (index == petProvider.pets.length) {
                    // Botón de agregar mascota
                    return Card(
                      margin: const EdgeInsets.only(right: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: theme.colorScheme.primary.withOpacity(0.2),
                          width: 2,
                        ),
                      ),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const PetRegisterScreen()),
                          );
                        },
                        child: SizedBox(
                          width: 100,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary
                                      .withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.add_rounded,
                                  color: theme.colorScheme.primary,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Agregar\nMascota',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: theme.colorScheme.primary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  final pet = petProvider.pets[index];
                  return Card(
                    margin: const EdgeInsets.only(right: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
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
                      child: SizedBox(
                        width: 100,
                        child: Stack(
                          fit: StackFit.expand, // Añadido para ajustar el Stack
                          children: [
                            Positioned.fill(
                              // Cambiado a Positioned.fill
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment:
                                    CrossAxisAlignment.center, // Añadido
                                children: [
                                  Container(
                                    padding: const EdgeInsets.only(
                                        top: 12), // Ajustado el padding
                                    child: CircleAvatar(
                                      radius: 30,
                                      backgroundColor: theme.colorScheme.primary
                                          .withOpacity(0.1),
                                      backgroundImage: pet.imageUrl != null
                                          ? CachedNetworkImageProvider(
                                              pet.imageUrl!)
                                          : null,
                                      child: pet.imageUrl == null
                                          ? Icon(Icons.pets_rounded,
                                              color: theme.colorScheme.primary,
                                              size:
                                                  28) // Ajustado tamaño del icono
                                          : null,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 4),
                                    child: Text(
                                      pet.name,
                                      style:
                                          theme.textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    pet.species,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurface
                                          .withOpacity(0.7),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Positioned(
                              right: 8,
                              top: 8,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary
                                      .withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 12,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ] else ...[
            _buildEmptyState(
              context,
              'No tienes mascotas registradas',
              'Registra a tus compañeros peludos para comenzar',
              Icons.pets_rounded,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PetRegisterScreen()),
                );
              },
            ),
          ],
          const SizedBox(height: 24),

          // Servicios Destacados en un grid compacto
          _buildSectionTitle(
              context, 'Servicios Destacados', Icons.star_rounded),
          Padding(
            padding: const EdgeInsets.only(top: 8), // Mejor espaciado
            child: GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.1, // Mejor proporción
              children: [
                _buildServiceGridItem(
                  context,
                  icon: Icons.medical_services_rounded,
                  title: 'Veterinario',
                  iconColor: theme.colorScheme.primary,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ScheduleServiceScreen(
                            preselectedServiceType: 'veterinario'),
                      ),
                    );
                  },
                ),
                _buildServiceGridItem(
                  context,
                  icon: Icons.content_cut_rounded,
                  title: 'Peluquería',
                  iconColor: Colors.pink,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ScheduleServiceScreen(
                            preselectedServiceType: 'peluqueria'),
                      ),
                    );
                  },
                ),
                _buildServiceGridItem(
                  context,
                  icon: Icons.directions_walk_rounded,
                  title: 'Paseos',
                  iconColor: Colors.green,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ScheduleServiceScreen(
                            preselectedServiceType: 'paseo'),
                      ),
                    );
                  },
                ),
                _buildServiceGridItem(
                  context,
                  icon: Icons.search_rounded,
                  title: 'Ver más',
                  iconColor: theme.colorScheme.secondary,
                  onTap: () {
                    // Cambiar a la pestaña de servicios
                    setState(() {
                      (context.findAncestorStateOfType<_HomeScreenState>())
                          ?._currentIndex = 1;
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceGridItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12), // Padding ajustado
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(14), // Padding del icono ajustado
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 32,
                ),
              ),
              const Spacer(),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 2, // Permitir dos líneas
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title, IconData icon) {
    final theme = Theme.of(context);
    return FadeInLeft(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12.0, top: 8.0),
        child: Row(
          children: [
            Icon(icon, color: theme.colorScheme.secondary, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    String title,
    String description,
    IconData icon, {
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.primary.withOpacity(0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.primary.withOpacity(0.1),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(
                icon,
                size: 48,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
              if (onTap != null) ...[
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: onTap,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Agregar'),
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.primary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class ServicesTab extends StatelessWidget {
  const ServicesTab({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final serviceCatalogProvider = Provider.of<ServiceCatalogProvider>(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: serviceCatalogProvider.isLoading &&
              serviceCatalogProvider.services.isEmpty
          ? [const Center(child: CircularProgressIndicator())]
          : serviceCatalogProvider.error != null
              ? [Center(child: Text('Error: ${serviceCatalogProvider.error}'))]
              : serviceCatalogProvider.services.map((service) {
                  return _buildServiceCard(
                    context,
                    icon: service.iconData ??
                        Icons.miscellaneous_services_rounded,
                    title: service.name,
                    description:
                        service.description ?? 'Servicio especializado.',
                    price: service.basePrice,
                    color: service.iconColor ?? theme.colorScheme.primary,
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => ScheduleServiceScreen(
                                  preselectedServiceType: service.name)));
                    },
                  );
                }).toList(),
    );
  }

  Widget _buildServiceCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    double? price,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    return FadeInUp(
      duration: const Duration(milliseconds: 300),
      child: Padding(
        padding: const EdgeInsets.only(
            bottom: 16), // Aumentado el espaciado entre tarjetas
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 24), // Aumentado el padding
              child: Row(
                crossAxisAlignment: CrossAxisAlignment
                    .start, // Cambiado a start para mejor alineación
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius:
                          BorderRadius.circular(14), // Ajustado el radio
                    ),
                    child: Icon(
                      icon,
                      color: color,
                      size: 32, // Aumentado el tamaño del icono
                    ),
                  ),
                  const SizedBox(width: 20), // Aumentado el espaciado
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 18, // Aumentado el tamaño del título
                          ),
                        ),
                        const SizedBox(height: 8), // Aumentado el espaciado
                        Text(
                          description,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                            height: 1.4, // Añadido interlineado
                          ),
                          maxLines: 2, // Permitir hasta 2 líneas
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (price != null) const SizedBox(height: 8),
                        if (price != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              NumberFormat.currency(
                                      locale: 'es_MX', symbol: '\$')
                                  .format(price),
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: theme.colorScheme.onSurface.withOpacity(0.3),
                    size: 16,
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

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        FadeInDown(
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: theme.colorScheme.primary.withOpacity(0.1),
                        ),
                      ),
                      Builder(
                        builder: (context) {
                          final avatarUrl = authProvider
                              .user?.userMetadata?['avatar_url'] as String?;
                          if (avatarUrl != null && avatarUrl.isNotEmpty) {
                            return Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                image: DecorationImage(
                                  image: CachedNetworkImageProvider(avatarUrl),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            );
                          } else {
                            return Icon(
                              Icons.person_rounded,
                              size: 50,
                              color: theme.colorScheme.primary,
                            );
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    authProvider.user?.userMetadata?['display_name']
                            as String? ??
                        authProvider.user?.email?.split('@').first ??
                        'Usuario',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Opciones de perfil
        ..._buildProfileOptions(context, authProvider),
      ],
    );
  }

  List<Widget> _buildProfileOptions(
      BuildContext context, AuthProvider authProvider) {
    return [
      _buildProfileOptionCard(
        context,
        icon: Icons.work_rounded,
        title: 'Ofrece tus servicios',
        subtitle: 'Conviértete en un proveedor de servicios',
        isHighlighted: true,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const ServiceProviderBenefitsScreen(),
            ),
          );
        },
      ),
      FadeInUp(
        delay: const Duration(milliseconds: 200),
        child: _buildProfileOption(
          context,
          icon: Icons.account_balance_wallet_rounded,
          title: 'Mi Billetera',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const WalletScreen()),
            );
          },
        ),
      ),
      FadeInUp(
        delay: const Duration(milliseconds: 300),
        child: _buildProfileOption(
          context,
          icon: Icons.history_rounded,
          title: 'Historial de Servicios',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ServiceHistoryScreen()),
            );
          },
        ),
      ),
      FadeInUp(
        delay: const Duration(milliseconds: 400),
        child: _buildProfileOption(
          context,
          icon: Icons.edit_note_rounded,
          title: 'Editar Perfil',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    const PersonalDataScreen(isEditingProfile: true),
              ),
            );
          },
        ),
      ),
      FadeInUp(
        delay: const Duration(milliseconds: 500),
        child: _buildProfileOption(
          context,
          icon: Icons.settings_rounded,
          title: 'Configuración',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            );
          },
        ),
      ),
      FadeInUp(
        delay: const Duration(milliseconds: 600),
        child: _buildProfileOption(
          context,
          icon: Icons.help_outline_rounded,
          title: 'Ayuda',
          onTap: () {
            // TODO: Implementar pantalla de ayuda
          },
        ),
      ),
      FadeInUp(
        delay: const Duration(milliseconds: 700),
        child: _buildProfileOption(
          context,
          icon: Icons.logout_rounded,
          title: 'Cerrar sesión',
          onTap: () => _showLogoutConfirmationDialog(context, authProvider),
        ),
      ),
    ];
  }

  Widget _buildProfileOptionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    bool isHighlighted = false,
    required VoidCallback onTap,
  }) {
    return FadeInUp(
      delay: const Duration(milliseconds: 100),
      child: Card(
        elevation: isHighlighted ? 4 : 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: _buildProfileOption(
          context,
          icon: icon,
          title: title,
          subtitle: subtitle,
          isHighlighted: isHighlighted,
          onTap: onTap,
        ),
      ),
    );
  }

  Widget _buildProfileOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    bool isHighlighted = false,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return Card(
      elevation: isHighlighted ? 4 : 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 12, // Mejor espaciado vertical
        ),
        leading: Container(
          padding: const EdgeInsets.all(10), // Padding del icono ajustado
          decoration: BoxDecoration(
            color: isHighlighted
                ? theme.colorScheme.primary.withOpacity(0.2)
                : theme.colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: isHighlighted
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface,
          ),
        ),
        title: Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: isHighlighted
                ? FontWeight.bold
                : FontWeight.w500, // Mejor peso de fuente
            color: isHighlighted ? theme.colorScheme.primary : null,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              )
            : null,
        trailing: Icon(
          Icons.arrow_forward_ios_rounded,
          color: isHighlighted
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurface.withOpacity(0.3),
          size: 16,
        ),
      ),
    );
  }

  void _showLogoutConfirmationDialog(
      BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        final theme = Theme.of(dialogContext);
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          icon: Icon(
            Icons.logout_rounded,
            color: theme.colorScheme.error,
            size: 48,
          ),
          title: Text(
            'Confirmar Cierre de Sesión',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.error,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            '¿Estás seguro de que deseas cerrar tu sesión?',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.8),
            ),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(
                    'Cancelar',
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.exit_to_app_rounded),
                  label: const Text('Cerrar Sesión'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.error,
                    foregroundColor: theme.colorScheme.onError,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  onPressed: () async {
                    Navigator.of(dialogContext).pop();
                    await authProvider.signOut();
                    if (context.mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                        (route) => false,
                      );
                    }
                  },
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
