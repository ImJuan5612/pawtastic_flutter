import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';

class ServiceProviderBenefitsScreen extends StatelessWidget {
  const ServiceProviderBenefitsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('Únete como Proveedor'),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.secondary,
                    ],
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.workspace_premium_rounded,
                    size: 80,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(theme),
                  const SizedBox(height: 32),
                  _buildBenefitsList(theme),
                  const SizedBox(height: 32),
                  _buildCallToAction(context, theme),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return FadeInDown(
      child: Card(
        elevation: 0,
        color: theme.colorScheme.primary.withOpacity(0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                '¡Conviértete en un Proveedor de Servicios!',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Únete a nuestra red de profesionales y haz crecer tu negocio',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBenefitsList(ThemeData theme) {
    final benefits = [
      {
        'icon': Icons.payments_rounded,
        'title': 'Ingresos Flexibles',
        'description': 'Establece tus propias tarifas y horarios de trabajo.',
        'color': Colors.green,
      },
      {
        'icon': Icons.trending_up_rounded,
        'title': 'Aumenta tu Visibilidad',
        'description': 'Llega a más clientes potenciales en tu área.',
        'color': Colors.blue,
      },
      {
        'icon': Icons.analytics_rounded,
        'title': 'Gestión Simplificada',
        'description':
            'Herramientas para administrar citas y pagos fácilmente.',
        'color': Colors.purple,
      },
      {
        'icon': Icons.star_rounded,
        'title': 'Construye tu Reputación',
        'description':
            'Recibe reseñas y construye una base de clientes leales.',
        'color': Colors.orange,
      },
      {
        'icon': Icons.support_agent_rounded,
        'title': 'Soporte Dedicado',
        'description': 'Ayuda personalizada cuando la necesites.',
        'color': Colors.teal,
      },
    ];

    return Column(
      children: benefits.asMap().entries.map((entry) {
        final index = entry.key;
        final benefit = entry.value;
        return FadeInLeft(
          delay: Duration(milliseconds: 100 * index),
          child: Card(
            margin: const EdgeInsets.only(bottom: 16),
            elevation: 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (benefit['color'] as Color).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  benefit['icon'] as IconData,
                  color: benefit['color'] as Color,
                  size: 28,
                ),
              ),
              title: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  benefit['title'] as String,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              subtitle: Text(
                benefit['description'] as String,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCallToAction(BuildContext context, ThemeData theme) {
    return FadeInUp(
      child: Card(
        elevation: 4,
        color: theme.colorScheme.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Text(
                '¿Listo para Empezar?',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Únete hoy y comienza a crecer tu negocio con nosotros',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onPrimary.withOpacity(0.9),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  // TODO: Implementar la lógica de registro
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content:
                          Text('¡Próximamente! Estamos trabajando en esto.'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: theme.colorScheme.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  textStyle: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                icon: const Icon(Icons.arrow_forward_rounded),
                label: const Text('Comenzar Registro'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
