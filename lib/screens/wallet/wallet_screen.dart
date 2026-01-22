import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:pawtastic/providers/auth_provider.dart';
import 'package:pawtastic/providers/payment_provider.dart';
import 'package:pawtastic/models/user_payment_method.dart';
import 'package:pawtastic/screens/wallet/add_payment_method_screen.dart'; // Crearemos esta pantalla
import 'package:animate_do/animate_do.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.user != null) {
        Provider.of<PaymentProvider>(context, listen: false)
            .fetchUserPaymentMethods(authProvider.user!.id);
        // Asegurarse que el perfil (y saldo) esté cargado
        if (authProvider.profile == null) {
          authProvider.fetchUserProfile();
        }
      }
    });
  }

  void _navigateToAddPaymentMethod() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddPaymentMethodScreen()),
    ).then((_) {
      // Recargar métodos de pago después de añadir uno nuevo
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.user != null) {
        Provider.of<PaymentProvider>(context, listen: false)
            .fetchUserPaymentMethods(authProvider.user!.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final paymentProvider = Provider.of<PaymentProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Billetera'),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          if (authProvider.user != null) {
            await paymentProvider.fetchUserPaymentMethods(authProvider.user!.id);
            await authProvider.fetchUserProfile();
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // Sección de Saldo
              FadeInDown(
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  color: theme.colorScheme.primaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        Text(
                          'Saldo Actual',
                          style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer),
                        ),
                        const SizedBox(height: 8),
                        authProvider.isLoading && authProvider.profile == null
                            ? const CircularProgressIndicator()
                            : Text(
                                NumberFormat.currency(locale: 'es_MX', symbol: '\$')
                                    .format(authProvider.profile?.walletBalance ?? 0.0),
                                style: theme.textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.onPrimaryContainer),
                              ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.add_card_rounded),
                          label: const Text('Recargar Saldo'),
                          onPressed: () {
                            // Lógica para recargar saldo (navegar a pantalla de selección de método y monto)
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Funcionalidad de recarga próximamente.')),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: theme.colorScheme.onPrimary,
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Sección de Métodos de Pago
              FadeInUp(
                delay: const Duration(milliseconds: 200),
                child: Text('Métodos de Pago Guardados', style: theme.textTheme.titleLarge),
              ),
              const SizedBox(height: 12),
              paymentProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : paymentProvider.error != null
                      ? Center(child: Text('Error: ${paymentProvider.error}'))
                      : paymentProvider.paymentMethods.isEmpty
                          ? FadeInUp(
                              delay: const Duration(milliseconds: 300),
                              child: Center(
                                child: Column(
                                  children: [
                                    const Text('No tienes métodos de pago guardados.'),
                                    const SizedBox(height: 16),
                                    ElevatedButton.icon(
                                      icon: const Icon(Icons.add_circle_outline_rounded),
                                      label: const Text('Añadir Método de Pago'),
                                      onPressed: _navigateToAddPaymentMethod,
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: paymentProvider.paymentMethods.length,
                              itemBuilder: (context, index) {
                                final method = paymentProvider.paymentMethods[index];
                                return FadeInUp(
                                  delay: Duration(milliseconds: 300 + (index * 100)),
                                  child: Card(
                                    margin: const EdgeInsets.symmetric(vertical: 6.0),
                                    child: ListTile(
                                      leading: Icon(
                                        method.cardBrand?.toLowerCase() == 'visa' ? Icons.credit_card_rounded // Podrías usar FontAwesome o imágenes para logos de tarjetas
                                            : method.cardBrand?.toLowerCase() == 'mastercard' ? Icons.credit_card_rounded
                                            : Icons.credit_card_outlined,
                                        color: theme.colorScheme.secondary,
                                      ),
                                      title: Text(method.cardBrand ?? 'Tarjeta'),
                                      subtitle: Text(method.maskedCardNumber),
                                      trailing: method.isDefault ? const Chip(label: Text('Default'), backgroundColor: Colors.greenAccent) : null,
                                      // onTap: () { /* Lógica para editar o marcar como default */ },
                                    ),
                                  ),
                                );
                              },
                            ),
              if (paymentProvider.paymentMethods.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      icon: const Icon(Icons.add_circle_outline_rounded),
                      label: const Text('Añadir Otro'),
                      onPressed: _navigateToAddPaymentMethod,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}