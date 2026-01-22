import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pawtastic/models/hotel.dart';

class HotelProvider with ChangeNotifier {
  final SupabaseClient _supabase;
  List<Hotel> _hotels = [];
  bool _isLoading = false;
  String? _error;

  HotelProvider(this._supabase);

  List<Hotel> get hotels => _hotels;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadHotels() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _supabase
          .from('hotels')
          .select()
          .eq('is_available', true)
          .order('name');

      _hotels =
          (response as List).map((hotel) => Hotel.fromJson(hotel)).toList();
    } catch (e) {
      _error = 'Error al cargar hoteles: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
