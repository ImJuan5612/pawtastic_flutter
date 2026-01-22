import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pawtastic/models/pet_hotel.dart';

class PetHotelProvider extends ChangeNotifier {
  List<PetHotel> _hotels = [];
  bool _loading = false;
  String? _error;
  DateTime? _selectedCheckIn;
  DateTime? _selectedCheckOut;

  List<PetHotel> get hotels => _hotels;
  bool get loading => _loading;
  String? get error => _error;
  DateTime? get selectedCheckIn => _selectedCheckIn;
  DateTime? get selectedCheckOut => _selectedCheckOut;

  Future<void> fetchHotels({DateTime? checkIn, DateTime? checkOut}) async {
    try {
      _loading = true;
      _error = null;
      notifyListeners();

      // Construir la consulta base
      final query = Supabase.instance.client
          .from('pet_hotels')
          .select()
          .gt('available_rooms', 0);

      // Si se proporcionan fechas, verificar disponibilidad
      if (checkIn != null && checkOut != null) {
        // Aquí podrías agregar lógica adicional para verificar reservas existentes
        _selectedCheckIn = checkIn;
        _selectedCheckOut = checkOut;
      }

      final response = await query;

      _hotels =
          (response as List).map((hotel) => PetHotel.fromJson(hotel)).toList();
    } catch (e) {
      _error = 'Error al cargar hoteles: ${e.toString()}';
      _hotels = [];
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void setDates(DateTime checkIn, DateTime checkOut) {
    _selectedCheckIn = checkIn;
    _selectedCheckOut = checkOut;
    fetchHotels(checkIn: checkIn, checkOut: checkOut);
  }

  void clearDates() {
    _selectedCheckIn = null;
    _selectedCheckOut = null;
    fetchHotels();
  }
}
