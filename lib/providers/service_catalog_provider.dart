import 'package:flutter/material.dart';
import 'package:pawtastic/models/service_catalog_item.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ServiceCatalogProvider extends ChangeNotifier {
  List<ServiceCatalogItem> _services = [];
  bool _isLoading = false;
  String? _error;

  List<ServiceCatalogItem> get services => _services;
  bool get isLoading => _isLoading;
  String? get error => _error;

  ServiceCatalogProvider() {
    fetchServices();
  }

  Future<void> fetchServices() async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await Supabase.instance.client
          .from('service_catalog')
          .select()
          .order('name', ascending: true); // O el orden que prefieras

      _services = (response as List)
          .map((data) => ServiceCatalogItem.fromJson(data))
          .toList();
    } catch (e) {
      _error = e.toString();
      debugPrint('Error fetching service catalog: $_error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  ServiceCatalogItem? getServiceByName(String name) {
    return _services.firstWhere((service) => service.name == name,
        orElse: () =>
            _services.first); // Fallback a un valor por defecto o null
  }
}
