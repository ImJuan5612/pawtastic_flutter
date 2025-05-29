import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  // Reemplaza estas URLs con las de tu proyecto en Supabase
  static const String supabaseUrl = 'https://jbojtpcynltczlkegmsp.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Impib2p0cGN5bmx0Y3psa2VnbXNwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDg0NzU2NTMsImV4cCI6MjA2NDA1MTY1M30.CKw9xve-wmGQcNeZ9UhERata0TozSlmEjzmJonJjzTI'; // Encuentra esto en Project Settings > API

  // Constantes para storage
  static const String petsBucket = 'pets';
  static const String avatarsFolder = 'avatars';

  static Future<void> initialize() async {
    try {
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
      );

      // Verificar y crear el bucket si no existe
      // await _initializeStorage();
    } catch (e) {
      debugPrint('Error inicializando Supabase: $e');
      rethrow;
    }
  }

  // static Future<void> _initializeStorage() async {
  //   try {
  //     final storage = client.storage;
  //     final buckets = await storage.listBuckets();

  //     // Verificar si el bucket existe
  //     final petsBucketExists = buckets.any((bucket) => bucket.id == petsBucket);

  //     if (!petsBucketExists) {
  //       debugPrint('Creando bucket para mascotas...');
  //       await storage.createBucket(
  //         petsBucket,
  //         BucketOptions(public: true),
  //       );
  //     }

  //     debugPrint('Storage inicializado correctamente');
  //   } catch (e) {
  //     debugPrint('Error inicializando storage: $e');
  //     rethrow;
  //   }
  // }

  static SupabaseClient get client => Supabase.instance.client;
}

// 'MetalPiano815' password for the Supabase database
