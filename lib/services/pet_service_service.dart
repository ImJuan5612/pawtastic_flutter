import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pawtastic/models/pet_service.dart';

class PetServiceService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<PetService>> getServicesByPetId(String petId) async {
    final response = await _client
        .from('services')
        .select()
        .eq('pet_id', petId)
        .order('date', ascending: false);

    return (response as List).map((data) => PetService.fromJson(data)).toList();
  }

  Future<PetService> createService(PetService service) async {
    final response = await _client
        .from('services')
        .insert(service.toJson())
        .select()
        .single();

    return PetService.fromJson(response);
  }

  Future<PetService> updateService(PetService service) async {
    final response = await _client
        .from('services')
        .update(service.toJson())
        .eq('id', service.id)
        .select()
        .single();

    return PetService.fromJson(response);
  }

  Future<void> deleteService(String serviceId) async {
    await _client.from('services').delete().eq('id', serviceId);
  }
}
