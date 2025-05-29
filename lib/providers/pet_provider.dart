import 'package:flutter/material.dart';
import 'package:pawtastic/models/pet.dart';
import 'package:pawtastic/config/supabase_config.dart';

class PetProvider extends ChangeNotifier {
  List<Pet> _pets = [];
  bool _loading = false;
  String? _error;

  List<Pet> get pets => _pets;
  bool get loading => _loading;
  String? get error => _error;

  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }

  void _setError(String? value) {
    _error = value;
    notifyListeners();
  }

  Future<void> loadUserPets(String userId) async {
    if (_loading) return;

    try {
      _setLoading(true);
      _error = null;

      final response = await SupabaseConfig.client
          .from('pets')
          .select()
          .eq('owner_id', userId)
          .order('created_at', ascending: false);

      _pets = (response as List).map((pet) => Pet.fromJson(pet)).toList();
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
      debugPrint('Error cargando mascotas: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addPet(Pet pet) async {
    if (_loading) return;

    try {
      _setLoading(true);
      _error = null;

      // Validar que la URL de la imagen existe si se proporciona
      if (pet.imageUrl != null) {
        final imageExists = await _validateImageUrl(pet.imageUrl!);
        if (!imageExists) {
          throw Exception('La imagen no se subió correctamente');
        }
      }

      final response = await SupabaseConfig.client
          .from('pets')
          .insert(pet.toJson())
          .select()
          .single();

      final newPet = Pet.fromJson(response);
      _pets.insert(0, newPet);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
      debugPrint('Error agregando mascota: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updatePet(Pet pet) async {
    if (_loading) return;

    try {
      _setLoading(true);
      _error = null;

      // Validar que la URL de la imagen existe si se proporciona
      if (pet.imageUrl != null) {
        final imageExists = await _validateImageUrl(pet.imageUrl!);
        if (!imageExists) {
          throw Exception('La imagen no se subió correctamente');
        }
      }

      final response = await SupabaseConfig.client
          .from('pets')
          .update(pet.toJson())
          .eq('id', pet.id)
          .select()
          .single();

      final updatedPet = Pet.fromJson(response);
      final index = _pets.indexWhere((p) => p.id == pet.id);
      if (index != -1) {
        _pets[index] = updatedPet;
        notifyListeners();
      }
    } catch (e) {
      _setError(e.toString());
      debugPrint('Error actualizando mascota: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deletePet(String petId, String userId) async {
    if (_loading) return;

    try {
      _setLoading(true);
      _error = null;

      // Obtener la mascota antes de eliminarla para eliminar su imagen
      final pet = _pets.firstWhere((p) => p.id == petId);
      if (pet.imageUrl != null) {
        await _deleteImage(pet.imageUrl!);
      }

      await SupabaseConfig.client.from('pets').delete().eq('id', petId);

      _pets.removeWhere((p) => p.id == petId);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
      debugPrint('Error eliminando mascota: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> _validateImageUrl(String imageUrl) async {
    try {
      final uri = Uri.parse(imageUrl);
      final response = await SupabaseConfig.client.storage
          .from(SupabaseConfig.petsBucket)
          .download(uri.pathSegments.last);
      return response.isNotEmpty;
    } catch (e) {
      debugPrint('Error validando imagen: $e');
      return false;
    }
  }

  Future<void> _deleteImage(String imageUrl) async {
    try {
      final uri = Uri.parse(imageUrl);
      final path = '${SupabaseConfig.avatarsFolder}/${uri.pathSegments.last}';
      await SupabaseConfig.client.storage
          .from(SupabaseConfig.petsBucket)
          .remove([path]);
    } catch (e) {
      debugPrint('Error eliminando imagen: $e');
    }
  }
}
