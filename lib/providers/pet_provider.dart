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

      final petData = pet.toJson();
      // Si el ID es una cadena vacía (indicando nueva mascota), quitarlo del mapa
      // para que Supabase genere el UUID automáticamente.
      if (petData['id'] != null && petData['id'] is String && (petData['id'] as String).isEmpty) {
        petData.remove('id');
      }

      final response = await SupabaseConfig.client
          .from('pets').insert(petData).select().single();

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

      String? oldImageUrl;
      // Si estamos actualizando y la nueva URL de imagen es diferente (o null y antes había una),
      // necesitamos la URL antigua para eliminarla.
      if (pet.id.isNotEmpty) {
        final existingPetIndex = _pets.indexWhere((p) => p.id == pet.id);
        if (existingPetIndex != -1 && _pets[existingPetIndex].imageUrl != pet.imageUrl) {
          oldImageUrl = _pets[existingPetIndex].imageUrl;
        }
      }

      // Validar que la URL de la imagen existe si se proporciona
      if (pet.imageUrl != null && pet.imageUrl != oldImageUrl) { // Solo validar si es una imagen nueva o diferente
        final imageExists = await _validateImageUrl(pet.imageUrl!);
        if (!imageExists) {
          throw Exception('La nueva imagen no se subió correctamente o no es accesible.');
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

      // Si había una imagen antigua y se cambió, eliminarla de Storage
      if (oldImageUrl != null && oldImageUrl != updatedPet.imageUrl) {
        await _deleteImage(oldImageUrl);
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
      List<String> pathSegments = uri.pathSegments;
      // La URL pública de Supabase es algo como: /storage/v1/object/public/BUCKET_NAME/path/to/file.png
      // Necesitamos encontrar el nombre del bucket y tomar todo lo que sigue.
      int bucketNameIndex = pathSegments.indexOf(SupabaseConfig.petsBucket);

      if (bucketNameIndex == -1 || bucketNameIndex + 1 >= pathSegments.length) {
        debugPrint('Error validando imagen: No se pudo encontrar el path del archivo en la URL: $imageUrl');
        return false;
      }
      // Unir los segmentos después del nombre del bucket para obtener el path relativo
      final String downloadPath = pathSegments.sublist(bucketNameIndex + 1).join('/');

      final response = await SupabaseConfig.client.storage
          .from(SupabaseConfig.petsBucket)
          .download(downloadPath);
      return response.isNotEmpty;
    } catch (e) {
      debugPrint('Error validando imagen URL $imageUrl: $e');
      return false;
    }
  }

  Future<void> _deleteImage(String imageUrl) async {
    try {
      final uri = Uri.parse(imageUrl);
      List<String> pathSegments = uri.pathSegments;
      int bucketNameIndex = pathSegments.indexOf(SupabaseConfig.petsBucket);
      if (bucketNameIndex == -1 || bucketNameIndex + 1 >= pathSegments.length) {
        debugPrint('Error eliminando imagen: No se pudo encontrar el path del archivo en la URL: $imageUrl');
        return;
      }
      final String removePath = pathSegments.sublist(bucketNameIndex + 1).join('/');
      await SupabaseConfig.client.storage
          .from(SupabaseConfig.petsBucket)
          .remove([removePath]);
    } catch (e) {
      debugPrint('Error eliminando imagen URL $imageUrl: $e');
    }
  }
}
