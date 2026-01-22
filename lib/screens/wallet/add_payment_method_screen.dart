import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pawtastic/models/user_payment_method.dart';
import 'package:pawtastic/providers/auth_provider.dart';
import 'package:pawtastic/providers/payment_provider.dart';
import 'package:uuid/uuid.dart'; // Para generar IDs únicos para pruebas

class AddPaymentMethodScreen extends StatefulWidget {
  const AddPaymentMethodScreen({super.key});

  @override
  State<AddPaymentMethodScreen> createState() => _AddPaymentMethodScreenState();
}

class _AddPaymentMethodScreenState extends State<AddPaymentMethodScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cardHolderNameController = TextEditingController();
  final _lastFourDigitsController = TextEditingController();
  final _expiryMonthController = TextEditingController();
  final _expiryYearController = TextEditingController();
  String _selectedBrand = 'Visa'; // Valor inicial
  bool _isDefault = false;

  Future<void> _savePaymentMethod() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: Usuario no autenticado.')));
      return;
    }

    final newMethod = UserPaymentMethod(
      id: const Uuid().v4(), // ID generado para prueba
      userId: authProvider.user!.id,
      paymentGatewayMethodId: 'test_pm_${const Uuid().v4()}', // ID de pasarela de prueba
      cardBrand: _selectedBrand,
      lastFourDigits: _lastFourDigitsController.text,
      expiryMonth: int.tryParse(_expiryMonthController.text),
      expiryYear: int.tryParse(_expiryYearController.text),
      cardholderName: _cardHolderNameController.text,
      isDefault: _isDefault,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final success = await Provider.of<PaymentProvider>(context, listen: false)
        .addPaymentMethod(newMethod, authProvider.user!.id);

    if (success) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Método de pago añadido con éxito.'), backgroundColor: Colors.green),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al añadir método de pago.'), backgroundColor: Theme.of(context).colorScheme.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Añadir Método de Pago (Prueba)')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: <Widget>[
              TextFormField(controller: _cardHolderNameController, decoration: const InputDecoration(labelText: 'Nombre del Titular')),
              DropdownButtonFormField<String>(
                value: _selectedBrand,
                decoration: const InputDecoration(labelText: 'Marca de Tarjeta'),
                items: ['Visa', 'Mastercard', 'Amex Prueba']
                    .map((brand) => DropdownMenuItem(value: brand, child: Text(brand)))
                    .toList(),
                onChanged: (value) => setState(() => _selectedBrand = value!),
              ),
              TextFormField(controller: _lastFourDigitsController, decoration: const InputDecoration(labelText: 'Últimos 4 Dígitos (ej. 1234)'), keyboardType: TextInputType.number, maxLength: 4),
              Row(children: [
                Expanded(child: TextFormField(controller: _expiryMonthController, decoration: const InputDecoration(labelText: 'Mes Exp (MM)'), keyboardType: TextInputType.number, maxLength: 2)),
                const SizedBox(width: 16),
                Expanded(child: TextFormField(controller: _expiryYearController, decoration: const InputDecoration(labelText: 'Año Exp (YYYY)'), keyboardType: TextInputType.number, maxLength: 4)),
              ]),
              SwitchListTile(title: const Text('Marcar como predeterminado'), value: _isDefault, onChanged: (value) => setState(() => _isDefault = value)),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: _savePaymentMethod, child: const Text('Guardar Método de Pago')),
            ],
          ),
        ),
      ),
    );
  }
}