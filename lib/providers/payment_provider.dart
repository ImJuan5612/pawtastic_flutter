import 'package:flutter/material.dart';
import 'package:pawtastic/models/user_payment_method.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PaymentProvider extends ChangeNotifier {
  List<UserPaymentMethod> _paymentMethods = [];
  bool _isLoading = false;
  String? _error;

  List<UserPaymentMethod> get paymentMethods => _paymentMethods;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchUserPaymentMethods(String userId) async {
    if (_isLoading) return;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await Supabase.instance.client
          .from('user_payment_methods')
          .select()
          .eq('user_id', userId)
          .order('is_default', ascending: false) // Mostrar predeterminada primero
          .order('created_at', ascending: false);

      _paymentMethods = (response as List)
          .map((data) => UserPaymentMethod.fromJson(data as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _error = e.toString();
      debugPrint('Error fetching payment methods: $_error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addPaymentMethod(UserPaymentMethod newMethod, String userId) async {
    if (_isLoading) return false;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Si se marca como predeterminado, desmarcar otros
      if (newMethod.isDefault) {
        await Supabase.instance.client
            .from('user_payment_methods')
            .update({'is_default': false})
            .eq('user_id', userId)
            .neq('id', newMethod.id); // No actualizar el que se está añadiendo si ya tiene ID
      }

      final dataToInsert = newMethod.toJson();
      // Asegurarse que user_id está presente
      dataToInsert['user_id'] = userId;
      // Remover ID si es un método nuevo para que Supabase lo genere (si el modelo lo incluye)
      // En nuestro modelo actual, el ID se pasa, así que esto es más para la actualización.
      // Si el ID es generado por el cliente, está bien.

      final response = await Supabase.instance.client
          .from('user_payment_methods')
          .insert(dataToInsert)
          .select()
          .single();

      _paymentMethods.insert(0, UserPaymentMethod.fromJson(response));
      // Reordenar si es necesario por is_default
      _paymentMethods.sort((a, b) => (b.isDefault ? 1 : 0) - (a.isDefault ? 1 : 0));
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error adding payment method: $_error');
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

 Future<bool> deletePaymentMethod(String paymentMethodId) async {
    if (_isLoading) return false;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await Supabase.instance.client
          .from('user_payment_methods')
          .delete()
          .eq('id', paymentMethodId);
      _paymentMethods.removeWhere((method) => method.id == paymentMethodId);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error deleting payment method: $_error');
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  // Aquí podrías añadir métodos para setDefaultPaymentMethod, etc.
}